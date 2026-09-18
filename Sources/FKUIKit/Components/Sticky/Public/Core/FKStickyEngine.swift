import UIKit

/// Orchestrates sticky / affix behavior for views inside a ``UIScrollView``.
///
/// Attach via ``UIScrollView/fk_stickyEngine`` or construct manually and assign ``scrollView``.
/// The engine reparents stuck views into an overlay that tracks the scroll view’s visible frame
/// (sibling of the scroll view when possible) and optionally inserts placeholders so content does
/// not jump.
@MainActor
public final class FKStickyEngine: NSObject {
  /// Scroll view that drives sticky geometry. Held weakly.
  public weak var scrollView: UIScrollView? {
    didSet {
      guard oldValue !== scrollView else { return }
      tearDownObservation()
      uninstallOverlay()
      if configuration.observesAutomatically {
        startObservationIfNeeded()
      }
      layoutIfNeeded()
    }
  }

  /// Sendable sticky policy. Assign a new value or mutate fields then call ``reloadLayout()`` when needed.
  public var configuration: FKStickyConfiguration {
    didSet {
      syncObservationMode(from: oldValue)
      layoutIfNeeded()
    }
  }

  /// Optional dynamic inset consulted each layout pass. When non-`nil`, replaces ``FKStickyConfiguration/stickyInset``.
  public var stickyInsetProvider: (() -> CGFloat)?

  /// Invoked when the ordered set of stuck target ids changes after a layout pass.
  public var onStuckTargetsChange: (([String]) -> Void)?

  /// Registered targets in insertion order.
  public private(set) var targets: [FKStickyTarget] = []

  /// Identifier of a target forced to remain stuck, if any.
  public private(set) var forcedTargetID: String?

  /// Ordered ids currently in ``FKStickyState/stuck`` or ``FKStickyState/sticking``.
  public private(set) var stuckTargetIDs: [String] = []

  private var sessions: [String: FKStickyTargetSession] = [:]
  private var sessionOrder: [String] = []
  private var overlayHost: FKStickyOverlayHost?
  private var observations: [NSKeyValueObservation] = []
  private var isLayingOut = false
  private let progressEpsilon: CGFloat = 0.001

  /// Creates an engine with the given configuration.
  public init(configuration: FKStickyConfiguration = .default) {
    self.configuration = configuration
    super.init()
  }

  // MARK: - Targets

  /// Returns the registered target for `id`, if any.
  public func target(id: String) -> FKStickyTarget? {
    targets.first { $0.id == id }
  }

  /// Latest progress snapshot for `id`, or `nil` when the id is unknown.
  public func progress(for id: String) -> FKStickyProgress? {
    guard let session = sessions[id] else { return nil }
    return FKStickyProgress(value: session.progressValue, state: session.state)
  }

  /// Latest state for `id`, or `nil` when the id is unknown.
  public func state(for id: String) -> FKStickyState? {
    sessions[id]?.state
  }

  /// Adds or replaces a sticky target with the same ``FKStickyTarget/id``.
  public func add(_ target: FKStickyTarget) {
    if let existingIndex = targets.firstIndex(where: { $0.id == target.id }) {
      unstickSession(sessions[target.id])
      targets[existingIndex] = target
      sessions[target.id] = FKStickyTargetSession(target: target)
    } else {
      targets.append(target)
      sessions[target.id] = FKStickyTargetSession(target: target)
      sessionOrder.append(target.id)
    }
    captureNaturalOriginIfNeeded(for: sessions[target.id])
    startObservationIfNeeded()
    layoutIfNeeded()
    // Targets added before the first layout pass often have zero width in stacks —
    // remasure on the next turn so the first stick uses the real size.
    if sessions[target.id]?.hasCapturedNaturalOrigin != true {
      DispatchQueue.main.async { [weak self] in
        self?.reloadLayout()
      }
    }
  }

  /// Convenience builder that creates and adds a target.
  @discardableResult
  public func addTarget(
    id: String,
    view: UIView,
    isEnabled: Bool = true,
    priority: Int = 0,
    stickyInsetOverride: CGFloat? = nil,
    onProgressChange: ((FKStickyProgress) -> Void)? = nil
  ) -> FKStickyTarget {
    let target = FKStickyTarget(
      id: id,
      view: view,
      isEnabled: isEnabled,
      priority: priority,
      stickyInsetOverride: stickyInsetOverride,
      onProgressChange: onProgressChange
    )
    add(target)
    return target
  }

  /// Removes a target by id and restores it to the original hierarchy when stuck.
  public func removeTarget(id: String) {
    guard let session = sessions[id] else { return }
    unstickSession(session)
    sessions[id] = nil
    sessionOrder.removeAll { $0 == id }
    targets.removeAll { $0.id == id }
    if forcedTargetID == id {
      forcedTargetID = nil
    }
    cleanupOverlayIfEmpty()
    layoutIfNeeded()
  }

  /// Removes every target and tears down overlay / placeholders.
  public func removeAllTargets() {
    forcedTargetID = nil
    for id in sessionOrder {
      unstickSession(sessions[id])
    }
    sessions.removeAll()
    sessionOrder.removeAll()
    targets.removeAll()
    stuckTargetIDs = []
    uninstallOverlay()
  }

  // MARK: - Controls

  /// Enables or disables sticky behavior without removing targets.
  public func setEnabled(_ enabled: Bool) {
    configuration.isEnabled = enabled
  }

  /// Forces a target to stay stuck until ``clearForcedStick()`` or removal.
  public func forceStick(id: String) {
    guard sessions[id] != nil else { return }
    forcedTargetID = id
    layoutIfNeeded()
  }

  /// Clears any forced stick id.
  public func clearForcedStick() {
    forcedTargetID = nil
    layoutIfNeeded()
  }

  /// Recomputes natural content origins / sizes (including stuck targets) and runs a layout pass.
  ///
  /// Call after Dynamic Type changes, content height animations, or hierarchy edits.
  public func reloadLayout() {
    for id in sessionOrder {
      guard let session = sessions[id] else { continue }
      if session.isHostedInOverlay {
        // Prefer the placeholder’s content origin — the target itself lives in the overlay
        // and `convert` into the scroll view is not content space. Recapturing here also
        // repairs origins frozen before the first Auto Layout pass (premature stick).
        if let placeholder = session.placeholder, let scrollView {
          session.naturalContentOrigin = FKStickyGeometry.contentOrigin(of: placeholder, in: scrollView)
          session.naturalFrameInSuperview = placeholder.frame
          if session.naturalSize.height <= 0.5 {
            session.naturalSize = measuredSize(of: placeholder)
          }
          session.hasCapturedNaturalOrigin = session.naturalSize.height > 0.5
        }
        updateStuckMetrics(for: session)
      } else {
        session.hasCapturedNaturalOrigin = false
        captureNaturalOriginIfNeeded(for: session)
      }
    }
    layoutIfNeeded()
  }

  /// Unsticks all targets, removes placeholders, and optionally stops observation.
  public func reset(stopObserving shouldStopObserving: Bool = false) {
    forcedTargetID = nil
    for id in sessionOrder {
      unstickSession(sessions[id])
      sessions[id]?.hasCapturedNaturalOrigin = false
      sessions[id]?.state = .idle
      sessions[id]?.progressValue = 0
    }
    stuckTargetIDs = []
    uninstallOverlay()
    if shouldStopObserving {
      tearDownObservation()
    }
  }

  /// Manual scroll hook when ``FKStickyConfiguration/observesAutomatically`` is `false`.
  public func handleScroll() {
    layoutIfNeeded()
  }

  /// Starts KVO when automatic observation is enabled.
  public func startObserving() {
    configuration.observesAutomatically = true
    startObservationIfNeeded()
  }

  /// Stops KVO observation without removing targets.
  public func stopObserving() {
    configuration.observesAutomatically = false
    tearDownObservation()
  }

  // MARK: - Observation

  private func syncObservationMode(from oldValue: FKStickyConfiguration) {
    if configuration.observesAutomatically, !oldValue.observesAutomatically {
      startObservationIfNeeded()
    } else if !configuration.observesAutomatically, oldValue.observesAutomatically {
      tearDownObservation()
    }
  }

  private func startObservationIfNeeded() {
    guard configuration.observesAutomatically, let scrollView, observations.isEmpty else { return }

    // `bounds.origin` mirrors `contentOffset` — only react to size changes (rotation / resize).
    // Observing both origin and offset would run a full sticky layout twice per scroll tick and
    // amplify contentSize fights near max offset.
    observations = [
      scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
        self?.handleObservedScrollMetrics()
      },
      scrollView.observe(\.bounds, options: [.new, .old]) { [weak self] _, change in
        guard let newSize = change.newValue?.size else { return }
        if let oldSize = change.oldValue?.size, oldSize == newSize { return }
        self?.handleObservedScrollMetrics()
      },
      scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
        self?.handleObservedScrollMetrics()
      },
      scrollView.observe(\.adjustedContentInset, options: [.new]) { [weak self] _, _ in
        self?.handleObservedScrollMetrics()
      },
    ]
  }

  /// UIScrollView metric KVO arrives on the main thread during tracking; layout synchronously
  /// to avoid a one-frame sticky lag from hopping through `Task`.
  private nonisolated func handleObservedScrollMetrics() {
    if Thread.isMainThread {
      MainActor.assumeIsolated {
        layoutIfNeeded()
      }
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.layoutIfNeeded()
      }
    }
  }

  private func tearDownObservation() {
    observations.removeAll()
  }

  // MARK: - Layout

  private func layoutIfNeeded() {
    guard !isLayingOut else { return }
    isLayingOut = true
    defer { isLayingOut = false }

    guard let scrollView else { return }
    // Stick decisions need a real viewport. Calling `addTarget` from `viewDidLoad` before
    // Auto Layout assigns bounds would otherwise treat a zero origin as already past the pin.
    guard FKStickyGeometry.hasUsableBounds(scrollView) else { return }

    if let overlayHost {
      overlayHost.ensurePreferredHosting(in: scrollView)
    }

    if !configuration.isEnabled {
      for id in sessionOrder {
        let session = sessions[id]
        let previous = session?.state ?? .idle
        unstickSession(session)
        if let session {
          emitTransition(session: session, previousState: previous, newState: .idle, progressValue: 0)
        }
      }
      publishStuckTargetIDs([])
      cleanupOverlayIfEmpty()
      return
    }

    var candidates: [FKStickyLayoutCandidate] = []
    candidates.reserveCapacity(sessionOrder.count)

    for id in sessionOrder {
      guard let session = sessions[id] else { continue }
      let target = session.target

      guard target.isEnabled, let view = target.view else {
        let previous = session.state
        unstickSession(session)
        emitTransition(session: session, previousState: previous, newState: .idle, progressValue: 0)
        continue
      }

      if !session.isHostedInOverlay {
        captureNaturalOriginIfNeeded(for: session)
      }

      // Require a real laid-out content frame — height constraints alone must not enable stick.
      guard session.hasCapturedNaturalOrigin, session.naturalSize.height > 0.5 else { continue }
      if session.naturalSize.width <= 0.5 {
        session.naturalSize.width = max(view.bounds.width, scrollView.bounds.width)
      }

      let inset = FKStickyGeometry.resolvedInset(
        configuration: configuration,
        provider: stickyInsetProvider,
        targetOverride: target.stickyInsetOverride
      )
      let pinY = FKStickyGeometry.pinLineViewportY(
        edge: configuration.edge,
        scrollView: scrollView,
        inset: inset,
        targetHeight: session.naturalSize.height
      )
      let forced = forcedTargetID == id
      let currentlySticky = session.isHostedInOverlay
        || session.state == .stuck
        || session.state == .sticking

      // One-turn suppress after unstick so a nested contentSize layout cannot immediately
      // re-host from a stale overlay frame.
      if !currentlySticky, session.suppressStickForPasses > 0 {
        session.suppressStickForPasses -= 1
        candidates.append(
          FKStickyLayoutCandidate(
            session: session,
            view: view,
            pinLineViewportY: pinY,
            shouldStick: false,
            distancePastThreshold: 0,
            naturalContentOrigin: session.naturalContentOrigin,
            naturalSize: session.naturalSize
          )
        )
        continue
      }

      let crossed = forced || FKStickyGeometry.hasCrossedThreshold(
        edge: configuration.edge,
        view: view,
        scrollView: scrollView,
        pinLineViewportY: pinY,
        targetHeight: session.naturalSize.height,
        isCurrentlySticky: currentlySticky,
        hysteresis: configuration.unstickHysteresis,
        frozenContentOrigin: currentlySticky ? session.naturalContentOrigin : nil
      )
      let distance = forced
        ? configuration.transitionDistance
        : FKStickyGeometry.distancePastThreshold(
          edge: configuration.edge,
          view: view,
          scrollView: scrollView,
          pinLineViewportY: pinY,
          targetHeight: session.naturalSize.height,
          isCurrentlySticky: currentlySticky,
          frozenContentOrigin: currentlySticky ? session.naturalContentOrigin : nil
        )

      candidates.append(
        FKStickyLayoutCandidate(
          session: session,
          view: view,
          pinLineViewportY: pinY,
          shouldStick: crossed,
          distancePastThreshold: distance,
          naturalContentOrigin: session.naturalContentOrigin,
          naturalSize: session.naturalSize
        )
      )
    }

    let sorted = candidates.sorted { lhs, rhs in
      if lhs.naturalContentOrigin.y != rhs.naturalContentOrigin.y {
        switch configuration.edge {
        case .top:
          return lhs.naturalContentOrigin.y < rhs.naturalContentOrigin.y
        case .bottom:
          return lhs.naturalContentOrigin.y > rhs.naturalContentOrigin.y
        }
      }
      return lhs.session.target.priority > rhs.session.target.priority
    }

    let desiredY = desiredOverlayYs(for: sorted, scrollView: scrollView)

    for candidate in sorted {
      if let y = desiredY[candidate.session.target.id] {
        applyStuck(candidate: candidate, overlayY: y, scrollView: scrollView)
      } else {
        applyIdle(candidate: candidate)
      }
    }

    let activeIDs = sorted.compactMap { candidate -> String? in
      desiredY[candidate.session.target.id] == nil ? nil : candidate.session.target.id
    }
    publishStuckTargetIDs(activeIDs)

    cleanupOverlayIfEmpty()
    if let overlayHost {
      // Edge pins already track the scroll view frame; no per-tick frame write on rubber-band.
      overlayHost.syncToScrollViewFrame(scrollView)
    }
  }

  private func desiredOverlayYs(
    for sorted: [FKStickyLayoutCandidate],
    scrollView: UIScrollView
  ) -> [String: CGFloat] {
    var desiredY: [String: CGFloat] = [:]

    switch configuration.collisionBehavior {
    case .pushOff:
      for (index, candidate) in sorted.enumerated() where candidate.shouldStick {
        var y = candidate.pinLineViewportY
        if index + 1 < sorted.count {
          let next = sorted[index + 1]
          // Next target’s top in bounds space (from frozen content origin).
          let nextViewportOriginY = FKStickyGeometry.viewportY(
            contentY: next.naturalContentOrigin.y,
            scrollView: scrollView
          )
          switch configuration.edge {
          case .top:
            y = min(y, nextViewportOriginY - candidate.naturalSize.height)
          case .bottom:
            let nextBottom = nextViewportOriginY + next.naturalSize.height
            y = max(y, nextBottom)
          }
        }
        desiredY[candidate.session.target.id] = y
      }

    case .stack:
      guard let first = sorted.first(where: \.shouldStick) else { return desiredY }
      switch configuration.edge {
      case .top:
        var cursor = first.pinLineViewportY
        for candidate in sorted where candidate.shouldStick {
          desiredY[candidate.session.target.id] = cursor
          cursor += candidate.naturalSize.height
        }

      case .bottom:
        // Shared chrome edge = first pin line + first height; stack upward.
        var cursor = first.pinLineViewportY + first.naturalSize.height
        for candidate in sorted where candidate.shouldStick {
          let y = cursor - candidate.naturalSize.height
          desiredY[candidate.session.target.id] = y
          cursor = y
        }
      }
    }

    return desiredY
  }

  private func publishStuckTargetIDs(_ ids: [String]) {
    guard ids != stuckTargetIDs else { return }
    stuckTargetIDs = ids
    onStuckTargetsChange?(ids)
  }

  private func applyStuck(
    candidate: FKStickyLayoutCandidate,
    overlayY: CGFloat,
    scrollView: UIScrollView
  ) {
    let session = candidate.session
    let view = candidate.view
    let transition = max(configuration.transitionDistance, 0.1)
    let progress = min(1, candidate.distancePastThreshold / transition)
    let previousState = session.state

    // Freeze content origin / laid-out size before reparenting.
    if !session.isHostedInOverlay {
      // Prefer the idle-captured content origin. Recapturing from a mid-unstick / overlay
      // residual frame corrupts the release threshold (late unstick only at offset ≈ 0).
      if !session.hasCapturedNaturalOrigin {
        let origin = FKStickyGeometry.contentOrigin(of: view, in: scrollView)
        let frame = FKStickyGeometry.contentFrame(of: view, in: scrollView)
        if FKStickyGeometry.isPlausibleContentFrame(frame, in: scrollView) {
          session.naturalContentOrigin = origin
          session.hasCapturedNaturalOrigin = true
        }
      }
      session.naturalFrameInSuperview = view.frame
      session.naturalSize = measuredSize(of: view)
      if session.naturalSize.height <= 0.5 {
        session.hasCapturedNaturalOrigin = false
      }
    }

    let isFirstHost = !session.isHostedInOverlay
    // Capture / deactivate target-owned size constraints before overlay pins exist.
    if isFirstHost {
      prepareFrameHosting(session: session, view: view)
    }

    ensureHostedInOverlay(session: session, view: view, scrollView: scrollView)
    // First host install activates edge pins — force a layout so the stuck view is visible
    // on the same scroll turn (otherwise the strip vanishes until a later layout pass).
    if isFirstHost {
      scrollView.superview?.layoutIfNeeded()
      overlayHost?.layoutIfNeeded()
    }

    // Viewport-fill targets: derive width from the overlay host every frame so a bad
    // intrinsic/half-width `naturalSize` cannot stick permanently.
    if session.fillsViewportWidth {
      let leadingInset = max(
        FKStickyGeometry.viewportX(
          contentX: session.naturalContentOrigin.x,
          scrollView: scrollView
        ),
        0
      )
      session.naturalSize.width = max(scrollView.bounds.width - leadingInset * 2, 1)
    }

    let size = session.naturalSize
    let overlayX = FKStickyGeometry.viewportX(
      contentX: session.naturalContentOrigin.x,
      scrollView: scrollView
    )
    let nextFrame = CGRect(
      origin: CGPoint(x: overlayX, y: overlayY),
      size: size
    )
    if let host = overlayHost {
      applyOverlayLayout(session: session, view: view, frame: nextFrame, in: host)
      host.layoutIfNeeded()
    }

    let newState: FKStickyState = progress >= 1 - progressEpsilon ? .stuck : .sticking
    emitTransition(
      session: session,
      previousState: previousState,
      newState: newState,
      progressValue: progress
    )
    applyShadowIfNeeded(on: view, session: session, stuck: true)
  }

  private func applyIdle(candidate: FKStickyLayoutCandidate) {
    let session = candidate.session
    let previousState = session.state
    let wasHosted = session.isHostedInOverlay
    let preservedOrigin = session.naturalContentOrigin
    let preservedSize = session.naturalSize
    let preservedFrame = session.naturalFrameInSuperview
    let hadOrigin = session.hasCapturedNaturalOrigin
    unstickSession(session)
    if wasHosted {
      // Restoring into Auto Layout leaves a one-turn stale frame (often the overlay pin
      // frame). A nested contentSize KVO layout must not recapture that as the natural origin
      // or immediately re-stick with a near-zero release threshold.
      session.originalSuperview?.layoutIfNeeded()
      session.target.view?.layoutIfNeeded()
      session.suppressStickForPasses = max(session.suppressStickForPasses, 1)
      session.hasCapturedNaturalOrigin = false
      captureNaturalOriginIfNeeded(for: session)
      if !session.hasCapturedNaturalOrigin, hadOrigin {
        session.naturalContentOrigin = preservedOrigin
        session.naturalSize = preservedSize
        session.naturalFrameInSuperview = preservedFrame
        session.hasCapturedNaturalOrigin = true
      }
    }
    emitTransition(
      session: session,
      previousState: previousState,
      newState: .idle,
      progressValue: 0
    )
  }

  private func ensureHostedInOverlay(
    session: FKStickyTargetSession,
    view: UIView,
    scrollView: UIScrollView
  ) {
    if session.isHostedInOverlay { return }

    // Remeasure immediately before reparenting so overlay frames use post-layout size.
    captureNaturalOriginIfNeeded(for: session)

    if session.originalSuperview == nil {
      rememberOriginalPlacement(session: session, view: view)
    }

    if configuration.preservesPlaceholder, session.placeholder == nil, let superview = session.originalSuperview {
      installPlaceholder(session: session, view: view, in: superview)
    }

    let host = ensureOverlay(in: scrollView)
    host.ensurePreferredHosting(in: scrollView)
    view.removeFromSuperview()
    host.addSubview(view)
    session.isHostedInOverlay = true
    // UITableView only remeasures `tableHeaderView` when it is re-assigned. Placeholder swaps
    // inside the header otherwise leave contentSize stale and clamp/jitter at max offset.
    refreshTableHeaderViewIfNeeded(containing: session.originalSuperview)
  }

  private func rememberOriginalPlacement(session: FKStickyTargetSession, view: UIView) {
    session.originalSuperview = view.superview
    session.usesAutoresizingMask = view.translatesAutoresizingMaskIntoConstraints
    if let stack = view.superview as? UIStackView,
       let arrangedIndex = stack.arrangedSubviews.firstIndex(of: view) {
      session.isArrangedInStack = true
      session.arrangedStackIndex = arrangedIndex
      session.originalSiblingIndex = arrangedIndex
      // Vertical fill stacks always span the content width — never trust intrinsic label width.
      session.fillsViewportWidth = stack.axis == .vertical && stack.alignment == .fill
    } else if let superview = view.superview {
      session.isArrangedInStack = false
      session.originalSiblingIndex = superview.subviews.firstIndex(of: view) ?? superview.subviews.count
      // Table-header / collection content strips — span the viewport while stuck.
      session.fillsViewportWidth = true
    }
  }

  private func installPlaceholder(
    session: FKStickyTargetSession,
    view: UIView,
    in superview: UIView
  ) {
    let placeholder = FKStickyPlaceholderView(frame: view.frame)
    let size = session.naturalSize == .zero ? measuredSize(of: view) : session.naturalSize

    if let stack = superview as? UIStackView, session.isArrangedInStack {
      // Must use arranged API — plain `insertSubview` does not participate in stack layout.
      let index = min(session.arrangedStackIndex, stack.arrangedSubviews.count)
      placeholder.translatesAutoresizingMaskIntoConstraints = false
      stack.insertArrangedSubview(placeholder, at: index)
      let height = placeholder.heightAnchor.constraint(equalToConstant: max(size.height, 1))
      height.isActive = true
      session.placeholderHeightConstraint = height
      // Width comes from the stack’s alignment; avoid fixed width that fights the stack.
    } else if session.usesAutoresizingMask {
      let index = min(session.originalSiblingIndex, superview.subviews.count)
      placeholder.translatesAutoresizingMaskIntoConstraints = true
      placeholder.frame = view.frame
      placeholder.autoresizingMask = view.autoresizingMask
      superview.insertSubview(placeholder, at: index)
    } else {
      let index = min(session.originalSiblingIndex, superview.subviews.count)
      placeholder.translatesAutoresizingMaskIntoConstraints = false
      superview.insertSubview(placeholder, at: index)
      let width = placeholder.widthAnchor.constraint(equalToConstant: max(size.width, 1))
      let height = placeholder.heightAnchor.constraint(equalToConstant: max(size.height, 1))
      NSLayoutConstraint.activate([width, height])
      session.placeholderWidthConstraint = width
      session.placeholderHeightConstraint = height
    }
    session.placeholder = placeholder
  }

  private func unstickSession(_ session: FKStickyTargetSession?) {
    guard let session else { return }
    guard session.isHostedInOverlay, let view = session.target.view else {
      removePlaceholder(session)
      session.isHostedInOverlay = false
      applyShadowIfNeeded(on: session.target.view, session: session, stuck: false)
      return
    }

    applyShadowIfNeeded(on: view, session: session, stuck: false)

    let destination = session.originalSuperview
    clearOverlayLayoutConstraints(session: session)
    view.removeFromSuperview()
    restoreFrameHostingConstraints(session: session)
    view.translatesAutoresizingMaskIntoConstraints = session.usesAutoresizingMask

    if let stack = destination as? UIStackView, session.isArrangedInStack {
      // Placeholder currently occupies the arranged slot — remove it, then restore the target.
      if let placeholder = session.placeholder {
        stack.removeArrangedSubview(placeholder)
        placeholder.removeFromSuperview()
        session.placeholderWidthConstraint = nil
        session.placeholderHeightConstraint = nil
        session.placeholder = nil
      }
      let index = min(session.arrangedStackIndex, stack.arrangedSubviews.count)
      stack.insertArrangedSubview(view, at: index)
    } else if let destination {
      let index = min(session.originalSiblingIndex, destination.subviews.count)
      destination.insertSubview(view, at: index)
      if session.usesAutoresizingMask {
        // Prefer the frame captured before reparenting — contentOffset-based conversion is
        // unreliable for UITableView header restore at large offsets.
        view.frame = CGRect(
          origin: session.naturalFrameInSuperview.origin,
          size: session.naturalSize
        )
      }
      removePlaceholder(session)
    } else {
      removePlaceholder(session)
    }

    session.isHostedInOverlay = false
    refreshTableHeaderViewIfNeeded(containing: destination)
  }

  private func removePlaceholder(_ session: FKStickyTargetSession) {
    guard let placeholder = session.placeholder else {
      session.placeholderWidthConstraint = nil
      session.placeholderHeightConstraint = nil
      return
    }
    if let stack = placeholder.superview as? UIStackView {
      stack.removeArrangedSubview(placeholder)
    }
    placeholder.removeFromSuperview()
    session.placeholderWidthConstraint = nil
    session.placeholderHeightConstraint = nil
    session.placeholder = nil
  }

  /// Forces `UITableView` to refresh header geometry after subview/placeholder mutations.
  private func refreshTableHeaderViewIfNeeded(containing view: UIView?) {
    guard let tableView = scrollView as? UITableView, let header = tableView.tableHeaderView else { return }
    var current = view
    while let candidate = current {
      if candidate === header {
        tableView.tableHeaderView = header
        return
      }
      current = candidate.superview
    }
  }

  private func captureNaturalOriginIfNeeded(for session: FKStickyTargetSession?) {
    guard let session, let view = session.target.view, let scrollView, !session.isHostedInOverlay else { return }
    guard FKStickyGeometry.hasUsableBounds(scrollView) else {
      session.hasCapturedNaturalOrigin = false
      return
    }
    // Never sample while the view still sits in the sticky overlay (or its frame still
    // reflects the pin). That measurement is viewport-space garbage for release math.
    if view.superview is FKStickyOverlayHost {
      return
    }
    // Prefer already-laid-out frames during scroll ticks. Forcing a full scroll-view layout
    // here re-enters UITableView layout while contentOffset is rubber-banding.
    if view.bounds.height <= 0.5 || view.bounds.width <= 0.5 {
      view.superview?.layoutIfNeeded()
      view.layoutIfNeeded()
    }
    // Height constraints can yield a fitting size before the hierarchy has frames. Capturing
    // a zero / hugely negative content origin in that window prematurely pins the target.
    let contentFrame = FKStickyGeometry.contentFrame(of: view, in: scrollView)
    guard view.bounds.height > 0.5, contentFrame.height > 0.5 else {
      session.hasCapturedNaturalOrigin = false
      return
    }
    guard FKStickyGeometry.isPlausibleContentFrame(contentFrame, in: scrollView) else {
      session.hasCapturedNaturalOrigin = false
      return
    }

    // If we already have a stable origin, ignore one-frame post-unstick outliers that jump
    // toward the pin line (typical residual overlay frame before Auto Layout settles).
    if session.hasCapturedNaturalOrigin {
      let deltaY = abs(contentFrame.minY - session.naturalContentOrigin.y)
      if deltaY > 1 {
        let inOriginalHierarchy =
          view.superview === session.originalSuperview
          || (session.isArrangedInStack && view.superview is UIStackView)
        let looksLikePinnedResidual =
          abs(view.frame.minY) <= 1
          && contentFrame.minY + 1 < session.naturalContentOrigin.y
        if !inOriginalHierarchy || looksLikePinnedResidual {
          return
        }
      }
    }

    session.naturalContentOrigin = contentFrame.origin
    session.naturalFrameInSuperview = view.frame
    let measured = measuredSize(of: view)
    // Never collapse a previously laid-out full width back to an intrinsic/label width
    // when a later isolated `layoutIfNeeded` temporarily shrinks the stack.
    if session.naturalSize.width > measured.width + 0.5, measured.width > 0.5 {
      session.naturalSize = CGSize(width: session.naturalSize.width, height: measured.height)
    } else {
      session.naturalSize = measured
    }
    if session.naturalSize.height <= 0.5 {
      session.naturalSize.height = contentFrame.height
    }
    if session.naturalSize.width <= 0.5 {
      session.naturalSize.width = contentFrame.width
    }
    session.hasCapturedNaturalOrigin = session.naturalSize.height > 0.5
  }

  /// Updates size (and placeholder) for a target that is already hosted in the overlay.
  private func updateStuckMetrics(for session: FKStickyTargetSession) {
    guard let view = session.target.view, let scrollView, let host = overlayHost else { return }
    // Width stays frozen at the pre-stick layout width. Height may change when the host
    // calls ``reloadLayout()`` after resizing the target (e.g. Dynamic Type demos).
    if let heightConstraint = view.constraints.first(where: {
      $0.firstAttribute == .height && ($0.firstItem as? UIView) === view && $0.isActive
    }), heightConstraint.constant > 0.5 {
      session.naturalSize.height = heightConstraint.constant
    } else if view.bounds.height > 0.5 {
      session.naturalSize.height = view.bounds.height
    }

    let overlayX = FKStickyGeometry.viewportX(
      contentX: session.naturalContentOrigin.x,
      scrollView: scrollView
    )
    let overlayY = session.overlayTopConstraint?.constant ?? view.frame.minY
    applyOverlayLayout(
      session: session,
      view: view,
      frame: CGRect(origin: CGPoint(x: overlayX, y: overlayY), size: session.naturalSize),
      in: host
    )

    if let placeholder = session.placeholder {
      if session.isArrangedInStack {
        session.placeholderHeightConstraint?.constant = session.naturalSize.height
      } else if session.usesAutoresizingMask {
        var placeholderFrame = placeholder.frame
        placeholderFrame.size = session.naturalSize
        placeholder.frame = placeholderFrame
      } else {
        session.placeholderWidthConstraint?.constant = session.naturalSize.width
        session.placeholderHeightConstraint?.constant = session.naturalSize.height
      }
    }
  }

  /// Resolves the laid-out size used for overlay frames and placeholders.
  ///
  /// Vertical ``UIStackView`` + `.fill` assigns the stack’s full width to arranged children.
  /// Intrinsic label width must never win for fill stacks — that freezes a ~half-screen strip
  /// into ``FKStickyTargetSession/naturalSize``. Horizontal stacks keep the child’s laid-out
  /// width (e.g. `fillEqually` side-by-side rows).
  private func measuredSize(of view: UIView) -> CGSize {
    guard let scrollView else {
      return view.bounds.size
    }

    let contentFrame = FKStickyGeometry.contentFrame(of: view, in: scrollView)
    var height = max(view.bounds.height, view.frame.height, contentFrame.height)
    var width = max(view.bounds.width, view.frame.width, contentFrame.width)

    if let stack = view.superview as? UIStackView {
      switch stack.axis {
      case .vertical:
        if stack.alignment == .fill {
          let estimate = verticalFillWidthEstimate(for: stack, in: scrollView)
          width = max(width, stack.bounds.width, estimate)
          // Hard floor: intrinsic/label width is typically well below the fill estimate.
          if estimate > 1, width + 0.5 < estimate {
            width = estimate
          }
        } else if stack.bounds.width > 0.5, width < 0.5 {
          width = stack.bounds.width
        }
      case .horizontal:
        if width < 0.5, view.frame.width > 0.5 {
          width = view.frame.width
        }
      @unknown default:
        break
      }
    } else {
      width = max(width, nonStackFillWidthEstimate(for: view, in: scrollView))
    }

    if height < 0.5 {
      let fitting = view.systemLayoutSizeFitting(
        CGSize(width: max(width, 1), height: UIView.layoutFittingCompressedSize.height),
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
      )
      if fitting.height > 0.5 {
        height = fitting.height
      }
    }
    return CGSize(width: width, height: height)
  }

  /// Estimated arranged width for a vertical `.fill` stack pinned into the scroll viewport.
  private func verticalFillWidthEstimate(for stack: UIStackView, in scrollView: UIScrollView) -> CGFloat {
    guard scrollView.bounds.width > 0.5 else { return 0 }
    let originInContent = stack.convert(CGPoint.zero, to: scrollView)
    let leadingInBounds = originInContent.x - FKStickyGeometry.clampedContentOffset(of: scrollView).x
    let leading = max(leadingInBounds, 0)
    return max(scrollView.bounds.width - leading * 2, 1)
  }

  /// Fallback width when the target is not in a stack (table header / collection content strip).
  private func nonStackFillWidthEstimate(for view: UIView, in scrollView: UIScrollView) -> CGFloat {
    let laidOut = max(view.bounds.width, view.frame.width)
    guard scrollView.bounds.width > 0.5 else { return laidOut }
    if laidOut >= scrollView.bounds.width * 0.7 {
      return laidOut
    }
    let originInContent = FKStickyGeometry.contentOrigin(of: view, in: scrollView)
    let leadingInBounds = originInContent.x - FKStickyGeometry.clampedContentOffset(of: scrollView).x
    let leading = max(leadingInBounds, 0)
    return max(laidOut, scrollView.bounds.width - leading * 2, 1)
  }

  /// Pins a stuck target inside the overlay.
  ///
  /// Viewport-fill targets use leading + trailing (width tracks the host). Other targets keep
  /// an explicit width so side-by-side / custom widths are preserved.
  private func applyOverlayLayout(
    session: FKStickyTargetSession,
    view: UIView,
    frame: CGRect,
    in host: FKStickyOverlayHost
  ) {
    view.translatesAutoresizingMaskIntoConstraints = false
    let leadingInset = max(frame.minX, 0)
    let heightValue = max(frame.height, 1)

    if session.fillsViewportWidth {
      session.overlayWidthConstraint?.isActive = false
      session.overlayWidthConstraint = nil

      if let leading = session.overlayLeadingConstraint,
         let trailing = session.overlayTrailingConstraint,
         let top = session.overlayTopConstraint,
         let height = session.overlayHeightConstraint {
        let needsUpdate =
          abs(leading.constant - leadingInset) > 0.5
          || abs(trailing.constant + leadingInset) > 0.5
          || abs(top.constant - frame.minY) > 0.5
          || abs(height.constant - heightValue) > 0.5
        guard needsUpdate else { return }
        leading.constant = leadingInset
        trailing.constant = -leadingInset
        top.constant = frame.minY
        height.constant = heightValue
        if !leading.isActive || !trailing.isActive || !top.isActive || !height.isActive {
          NSLayoutConstraint.activate([leading, trailing, top, height])
        }
        return
      }

      clearOverlayLayoutConstraints(session: session)
      let leading = view.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: leadingInset)
      let trailing = view.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -leadingInset)
      let top = view.topAnchor.constraint(equalTo: host.topAnchor, constant: frame.minY)
      let height = view.heightAnchor.constraint(equalToConstant: heightValue)
      height.priority = .required
      NSLayoutConstraint.activate([leading, trailing, top, height])
      session.overlayLeadingConstraint = leading
      session.overlayTrailingConstraint = trailing
      session.overlayTopConstraint = top
      session.overlayHeightConstraint = height
      return
    }

    session.overlayTrailingConstraint?.isActive = false
    session.overlayTrailingConstraint = nil

    if let leading = session.overlayLeadingConstraint,
       let top = session.overlayTopConstraint,
       let width = session.overlayWidthConstraint,
       let height = session.overlayHeightConstraint {
      let needsUpdate =
        abs(leading.constant - frame.minX) > 0.5
        || abs(top.constant - frame.minY) > 0.5
        || abs(width.constant - frame.width) > 0.5
        || abs(height.constant - frame.height) > 0.5
      guard needsUpdate else { return }
      leading.constant = frame.minX
      top.constant = frame.minY
      width.constant = max(frame.width, 1)
      height.constant = max(frame.height, 1)
      return
    }

    clearOverlayLayoutConstraints(session: session)
    let leading = view.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: frame.minX)
    let top = view.topAnchor.constraint(equalTo: host.topAnchor, constant: frame.minY)
    let width = view.widthAnchor.constraint(equalToConstant: max(frame.width, 1))
    let height = view.heightAnchor.constraint(equalToConstant: max(frame.height, 1))
    width.priority = .required
    height.priority = .required
    NSLayoutConstraint.activate([leading, top, width, height])
    session.overlayLeadingConstraint = leading
    session.overlayTopConstraint = top
    session.overlayWidthConstraint = width
    session.overlayHeightConstraint = height
  }

  private func clearOverlayLayoutConstraints(session: FKStickyTargetSession) {
    session.overlayLeadingConstraint?.isActive = false
    session.overlayTrailingConstraint?.isActive = false
    session.overlayTopConstraint?.isActive = false
    session.overlayWidthConstraint?.isActive = false
    session.overlayHeightConstraint?.isActive = false
    session.overlayLeadingConstraint = nil
    session.overlayTrailingConstraint = nil
    session.overlayTopConstraint = nil
    session.overlayWidthConstraint = nil
    session.overlayHeightConstraint = nil
  }

  /// Deactivates the target’s own width/height constraints so overlay layout is not
  /// overridden by Auto Layout recovery (which collapses width to intrinsic text size).
  ///
  /// Must run only once per stick cycle and must ignore engine-owned overlay constraints.
  /// Otherwise the second scroll tick deactivates ``overlayHeightConstraint`` and the strip
  /// collapses to zero height while state remains `sticking` / `stuck`.
  private func prepareFrameHosting(session: FKStickyTargetSession, view: UIView) {
    guard !session.didPrepareFrameHosting else { return }
    session.didPrepareFrameHosting = true

    let overlayOwned: Set<ObjectIdentifier> = [
      session.overlayLeadingConstraint,
      session.overlayTrailingConstraint,
      session.overlayTopConstraint,
      session.overlayWidthConstraint,
      session.overlayHeightConstraint,
    ]
    .compactMap { $0 }
    .reduce(into: Set()) { $0.insert(ObjectIdentifier($1)) }

    let sizeConstraints = view.constraints.filter { constraint in
      guard (constraint.firstItem as? UIView) === view else { return false }
      guard !overlayOwned.contains(ObjectIdentifier(constraint)) else { return false }
      switch constraint.firstAttribute {
      case .width, .height:
        return constraint.isActive
      default:
        return false
      }
    }
    sizeConstraints.forEach { $0.isActive = false }
    session.deactivatedSizeConstraints = sizeConstraints
  }

  private func restoreFrameHostingConstraints(session: FKStickyTargetSession) {
    session.deactivatedSizeConstraints.forEach { $0.isActive = true }
    session.deactivatedSizeConstraints.removeAll()
    session.didPrepareFrameHosting = false
  }

  private func ensureOverlay(in scrollView: UIScrollView) -> FKStickyOverlayHost {
    if let overlayHost { return overlayHost }
    let host = FKStickyOverlayHost.install(in: scrollView)
    overlayHost = host
    return host
  }

  private func cleanupOverlayIfEmpty() {
    let anyHosted = sessions.values.contains(where: \.isHostedInOverlay)
    if !anyHosted {
      uninstallOverlay()
    }
  }

  private func uninstallOverlay() {
    overlayHost?.removeFromSuperview()
    overlayHost = nil
  }

  private func emitTransition(
    session: FKStickyTargetSession,
    previousState: FKStickyState,
    newState: FKStickyState,
    progressValue: CGFloat
  ) {
    let clamped = min(max(progressValue, 0), 1)
    let stateChanged = previousState != newState
    let progressChanged = abs(session.progressValue - clamped) > progressEpsilon
    session.state = newState
    session.progressValue = clamped

    guard stateChanged || progressChanged else { return }

    if previousState == .idle, newState == .sticking || newState == .stuck {
      session.target.onWillStick?()
    }
    if newState == .stuck, previousState != .stuck {
      session.target.onDidStick?()
    }
    if newState == .idle, previousState != .idle {
      session.target.onDidUnstick?()
    }

    session.target.onProgressChange?(FKStickyProgress(value: clamped, state: newState))
  }

  private func applyShadowIfNeeded(on view: UIView?, session: FKStickyTargetSession, stuck: Bool) {
    guard configuration.appliesStuckShadow, let view else { return }
    if stuck {
      if session.capturedShadow == nil {
        session.capturedShadow = FKStickyShadowCapture(
          opacity: view.layer.shadowOpacity,
          radius: view.layer.shadowRadius,
          offset: view.layer.shadowOffset,
          color: view.layer.shadowColor,
          path: view.layer.shadowPath
        )
      }
      view.layer.shadowOpacity = configuration.stuckShadowOpacity
      view.layer.shadowRadius = configuration.stuckShadowRadius
      view.layer.shadowOffset = configuration.stuckShadowOffset
      view.layer.shadowColor = UIColor.black.cgColor
      view.layer.masksToBounds = false
    } else if let captured = session.capturedShadow {
      view.layer.shadowOpacity = captured.opacity
      view.layer.shadowRadius = captured.radius
      view.layer.shadowOffset = captured.offset
      view.layer.shadowColor = captured.color
      view.layer.shadowPath = captured.path
      session.capturedShadow = nil
    }
  }
}

// MARK: - Layout candidate

@MainActor
private struct FKStickyLayoutCandidate {
  let session: FKStickyTargetSession
  let view: UIView
  let pinLineViewportY: CGFloat
  let shouldStick: Bool
  let distancePastThreshold: CGFloat
  let naturalContentOrigin: CGPoint
  let naturalSize: CGSize
}
