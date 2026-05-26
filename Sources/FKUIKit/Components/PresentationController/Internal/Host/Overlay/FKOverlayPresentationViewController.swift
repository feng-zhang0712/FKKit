import UIKit

/// Overlay-based presentation container that supports passthrough outside the popup.
@MainActor
final class FKOverlayPresentationViewController: UIViewController, UIGestureRecognizerDelegate {
  var onRequestDismiss: (() -> Void)?
  var onProgress: ((CGFloat) -> Void)?
  var onSelectedDetentDidChange: ((FKPresentationDetent, Int) -> Void)?

  private let configuration: FKPresentationConfiguration

  private let rootView = FKOverlayRootView()
  private let backdropView = FKPresentationBackdropView()
  private let wrapperView = UIView()
  private let contentContainerView = UIView()

  private lazy var tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss(_:)))
  private lazy var panToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanToDismiss(_:)))

  private weak var hostedContentView: UIView?

  private var resolvedDetentHeights: [CGFloat] = []
  private var selectedDetentIndex: Int = 0
  private var sheetPanBeganDetentIndex: Int = 0
  private var panStartFrame: CGRect = .zero
  private var isPanningSheet: Bool = false
  private var sheetPanDeferredToScrollView = false
  private var sheetPanBypassesScrollHandoff = false
  private var sheetPanVelocityY: CGFloat = 0
  private var centerDismissBaseBackdropAlpha: CGFloat = 1
  private var isCenterInteractivelyDragging = false
  private var lastBoundsSize: CGSize = .zero

  init(configuration: FKPresentationConfiguration) {
    self.configuration = configuration
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { nil }

  override func loadView() {
    view = rootView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    backdropView.frame = view.bounds
    backdropView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backdropView.configure(with: configuration.backdropStyle)
    view.addSubview(backdropView)

    wrapperView.backgroundColor = .systemBackground
    wrapperView.addSubview(contentContainerView)

    contentContainerView.backgroundColor = .clear
    contentContainerView.clipsToBounds = true

    view.addSubview(wrapperView)

    installGestures()
    recalculateDetentsIfNeeded()
    selectedDetentIndex = configuration.sheet.initialSelectedDetentIndex
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let newBoundsSize = view.bounds.size
    let boundsChanged = lastBoundsSize != .zero && newBoundsSize != lastBoundsSize
    defer { lastBoundsSize = newBoundsSize }

    guard !isPanningSheet, !isCenterInteractivelyDragging, boundsChanged else {
      updatePassthroughHitTesting()
      return
    }

    switch configuration.rotationHandling {
    case .ignore:
      updatePassthroughHitTesting()
    case .relayoutImmediate, .relayoutAnimated:
      recalculateDetentsIfNeeded()
      let applyLayout = {
        self.wrapperView.frame = self.frameOfWrapper()
        self.layoutContent()
        self.applyAppearance()
        self.updatePassthroughHitTesting()
      }
      if configuration.rotationHandling == .relayoutAnimated {
        UIView.animate(
          withDuration: 0.32,
          delay: 0,
          options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
          animations: applyLayout
        )
      } else {
        applyLayout()
      }
    }
  }

  func publishInitialSelectedDetentIfNeeded() {
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      recalculateDetentsIfNeeded()
      guard configuration.sheet.detents.indices.contains(selectedDetentIndex) else { return }
      onSelectedDetentDidChange?(configuration.sheet.detents[selectedDetentIndex], selectedDetentIndex)
    default:
      break
    }
    if configuration.accessibility.announcesScreenChange {
      UIAccessibility.post(notification: .screenChanged, argument: configuration.accessibility.announcement)
    }
  }

  private func sheetInteractionEnvironment() -> FKSheetPresentationInteractionEnvironment? {
    guard let axis = FKSheetPresentationAxis(layout: configuration.layout) else { return nil }
    return FKSheetPresentationInteractionEnvironment(
      axis: axis,
      sheet: configuration.sheet,
      dismissBehaviorAllowsSwipe: configuration.dismissBehavior.allowsSwipe,
      safeAreaPolicy: configuration.safeAreaPolicy,
      containerBounds: view.bounds,
      containerSafeInsets: containerSafeInsets()
    )
  }

  private func sheetInteractionState() -> FKSheetPresentationInteractionState {
    FKSheetPresentationInteractionState(
      resolvedDetentHeights: resolvedDetentHeights,
      selectedDetentIndex: selectedDetentIndex,
      sheetPanBeganDetentIndex: sheetPanBeganDetentIndex,
      panStartFrame: panStartFrame,
      wrapperFrame: wrapperView.frame
    )
  }

  func selectDetent(_ detent: FKPresentationDetent, animated: Bool) {
    guard let index = configuration.sheet.detents.firstIndex(of: detent) else { return }
    selectDetent(at: index, animated: animated)
  }

  func selectDetent(at index: Int, animated: Bool) {
    recalculateDetentsIfNeeded()
    let clamped = max(0, min(index, max(0, resolvedDetentHeights.count - 1)))
    if clamped == selectedDetentIndex {
      animateToSelectedDetent(animated: animated)
      return
    }
    selectedDetentIndex = clamped
    if configuration.sheet.detents.indices.contains(clamped) {
      onSelectedDetentDidChange?(configuration.sheet.detents[clamped], clamped)
      if configuration.haptics.isEnabled {
        UIImpactFeedbackGenerator(style: configuration.haptics.feedbackStyle).impactOccurred()
      }
    }
    animateToSelectedDetent(animated: animated)
  }

  private func resolvedTrackedScrollView() -> UIScrollView? {
    FKSheetScrollTracking.resolvedTrackedScrollView(
      strategy: configuration.sheet.scrollTrackingStrategy,
      in: children.first?.view
    )
  }

  private func resolvesSheetPanBypassesScrollHandoff(
    recognizer: UIPanGestureRecognizer,
    trackedScrollView: UIScrollView?
  ) -> Bool {
    guard let trackedScrollView else { return true }
    let touchInWrapper = recognizer.location(in: wrapperView)
    let touchInScroll = recognizer.location(in: trackedScrollView)
    return FKSheetPresentationInteractionEngine.shouldBypassScrollHandoffForPan(
      touchLocationInWrapper: touchInWrapper,
      contentContainerFrame: contentContainerView.frame,
      scrollView: trackedScrollView,
      touchLocationInScrollView: touchInScroll
    )
  }

  private func animateToSelectedDetent(animated: Bool, appliesChrome: Bool = true) {
    let targetFrame = frameOfWrapper()
    let distance = max(1, abs(wrapperView.frame.minY - targetFrame.minY), abs(wrapperView.frame.height - targetFrame.height))
    let apply = {
      self.wrapperView.frame = targetFrame
      self.layoutContent()
      if appliesChrome {
        self.applyAppearance()
      }
      self.updatePassthroughHitTesting()
    }
    if animated {
      let duration = FKPresentationInteractionSupport.adaptiveDetentSnapDuration(
        distance: distance,
        velocityY: sheetPanVelocityY
      )
      let timing = UISpringTimingParameters(
        dampingRatio: 0.86,
        initialVelocity: FKPresentationInteractionSupport.normalizedDetentSnapVelocity(
          velocityY: sheetPanVelocityY,
          distance: distance
        )
      )
      let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timing)
      animator.addAnimations(apply)
      animator.startAnimation()
    } else {
      apply()
    }
  }

  private func applyOverlayInteractiveFrame(_ frame: CGRect, appliesChrome: Bool) {
    wrapperView.frame = frame
    layoutContent()
    if appliesChrome {
      applyAppearance()
    }
    updatePassthroughHitTesting()
  }

  func embedContent(_ contentController: UIViewController) {
    addChild(contentController)
    contentController.view.translatesAutoresizingMaskIntoConstraints = false
    contentContainerView.addSubview(contentController.view)
    NSLayoutConstraint.activate([
      contentController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
      contentController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
      contentController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
      contentController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
    ])
    contentController.didMove(toParent: self)
    hostedContentView = contentController.view
  }

  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    let apply = {
      self.backdropView.configure(with: self.configuration.backdropStyle)
      self.wrapperView.frame = self.frameOfWrapper()
      self.layoutContent()
      self.applyAppearance()
      self.updatePassthroughHitTesting()
    }
    if animated {
      UIView.animate(withDuration: max(0, duration), delay: 0, options: [options, .beginFromCurrentState, .allowUserInteraction], animations: apply)
    } else {
      apply()
    }
  }

  func animatePresentation(isPresentation: Bool, animated: Bool, completion: @escaping () -> Void) {
    if isPresentation {
      // Normalize frame before presenting animation.
      updateLayout(animated: false, duration: 0, options: .curveLinear)
    } else {
      // For dismissal, animate from the current on-screen interactive state to avoid snap/flash.
      updatePassthroughHitTesting()
    }

    let duration: TimeInterval = animated ? 0.28 : 0
    if duration == 0 {
      backdropView.alpha = isPresentation ? 1 : 0
      wrapperView.alpha = isPresentation ? 1 : 0
      wrapperView.transform = .identity
      completion()
      return
    }

    if isPresentation {
      wrapperView.alpha = 0
      wrapperView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
      backdropView.alpha = 0
    }

    UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
      self.backdropView.alpha = isPresentation ? 1 : 0
      self.wrapperView.alpha = isPresentation ? 1 : 0
      self.wrapperView.transform = isPresentation ? .identity : CGAffineTransform(scaleX: 0.98, y: 0.98)
    } completion: { _ in
      completion()
    }
  }

  // MARK: - Gestures

  private func installGestures() {
    // Backdrop tap-to-dismiss only when NOT in passthrough background interaction mode.
    if !configuration.backgroundInteraction.isEnabled,
       configuration.dismissBehavior.allowsTapOutside,
       configuration.dismissBehavior.allowsBackdropTap {
      backdropView.isUserInteractionEnabled = true
      backdropView.addGestureRecognizer(tapToDismissGesture)
    } else {
      backdropView.isUserInteractionEnabled = false
      backdropView.removeGestureRecognizer(tapToDismissGesture)
    }

    let allowsSwipe: Bool = {
      if case .center(_) = configuration.layout { return configuration.center.dismissEnabled }
      return configuration.dismissBehavior.allowsSwipe
    }()
    if allowsSwipe {
      panToDismissGesture.maximumNumberOfTouches = 1
      panToDismissGesture.delegate = self
      panToDismissGesture.cancelsTouchesInView = false
      wrapperView.addGestureRecognizer(panToDismissGesture)
    }
  }

  @objc private func handleTapToDismiss(_ recognizer: UITapGestureRecognizer) {
    guard recognizer.state == .ended else { return }
    guard configuration.dismissBehavior.allowsTapOutside else { return }
    onRequestDismiss?()
  }

  @objc private func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
    switch configuration.layout {
    case .bottomSheet(_), .topSheet(_):
      handleSheetPan(recognizer)
    case .center(_):
      handleCenterPan(recognizer)
    default:
      break
    }
  }

  private func handleCenterPan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.center.dismissEnabled else { return }
    let translation = recognizer.translation(in: view)
    let progress = min(max(abs(translation.y) / max(1, view.bounds.height * 0.4), 0), 1)

    switch recognizer.state {
    case .began:
      switch configuration.backdropStyle {
      case let .dim(_, alpha):
        centerDismissBaseBackdropAlpha = alpha
      default:
        centerDismissBaseBackdropAlpha = 1
      }
      isCenterInteractivelyDragging = true
    case .changed:
      wrapperView.transform = FKPresentationInteractionSupport.centerDismissTransform(
        translationY: translation.y,
        containerHeight: view.bounds.height
      )
      backdropView.alpha = FKPresentationInteractionSupport.centerDismissBackdropAlpha(
        baseAlpha: centerDismissBaseBackdropAlpha,
        progress: progress
      )
      onProgress?(progress)
    case .ended, .cancelled, .failed:
      let velocityY = recognizer.velocity(in: view).y
      let shouldDismiss = progress > configuration.center.dismissProgressThreshold
        || abs(velocityY) > configuration.center.dismissVelocityThreshold
      isCenterInteractivelyDragging = false
      if shouldDismiss {
        onProgress?(1)
        onRequestDismiss?()
      } else {
        onProgress?(0)
        let timing = UISpringTimingParameters(dampingRatio: 0.86, initialVelocity: .zero)
        let animator = UIViewPropertyAnimator(duration: 0.34, timingParameters: timing)
        animator.addAnimations {
          self.wrapperView.transform = .identity
          self.backdropView.alpha = 1
        }
        animator.startAnimation()
      }
    default:
      break
    }
  }

  private func handleSheetPan(_ recognizer: UIPanGestureRecognizer) {
    guard let environment = sheetInteractionEnvironment() else { return }

    recalculateDetentsIfNeeded()
    guard !resolvedDetentHeights.isEmpty else { return }

    let translation = recognizer.translation(in: view)
    let velocity = recognizer.velocity(in: view)
    let trackedScrollView = resolvedTrackedScrollView()

    switch recognizer.state {
    case .began:
      isPanningSheet = true
      sheetPanDeferredToScrollView = false
      sheetPanBypassesScrollHandoff = resolvesSheetPanBypassesScrollHandoff(
        recognizer: recognizer,
        trackedScrollView: trackedScrollView
      )
      panStartFrame = wrapperView.frame
      sheetPanBeganDetentIndex = selectedDetentIndex
      sheetPanVelocityY = 0
      trackedScrollView?.panGestureRecognizer.isEnabled = true

    case .changed:
      guard isPanningSheet else { return }
      sheetPanVelocityY = velocity.y
      var state = sheetInteractionState()

      if !sheetPanBypassesScrollHandoff,
         let trackedScrollView,
         !FKSheetPresentationInteractionEngine.shouldTransferPanFromScrollView(
          environment: environment,
          state: state,
          scrollView: trackedScrollView,
          translationY: translation.y
         ) {
        if !sheetPanDeferredToScrollView {
          sheetPanDeferredToScrollView = true
          animateToSelectedDetent(animated: false, appliesChrome: false)
        }
        return
      }

      if sheetPanDeferredToScrollView {
        sheetPanDeferredToScrollView = false
      }
      state = sheetInteractionState()
      let frame = FKSheetPresentationInteractionEngine.interactiveFrame(
        environment: environment,
        state: state,
        translationY: translation.y
      )
      applyOverlayInteractiveFrame(frame, appliesChrome: false)
      state.wrapperFrame = wrapperView.frame
      onProgress?(FKSheetPresentationInteractionEngine.sheetDismissProgress(environment: environment, state: state))

    case .ended, .cancelled, .failed:
      guard isPanningSheet else { return }
      isPanningSheet = false

      if sheetPanDeferredToScrollView {
        sheetPanDeferredToScrollView = false
        sheetPanBypassesScrollHandoff = false
        sheetPanVelocityY = 0
        return
      }

      sheetPanBypassesScrollHandoff = false
      let state = sheetInteractionState()

      if FKSheetPresentationInteractionEngine.sheetShouldDismiss(
        environment: environment,
        state: state,
        translationY: translation.y,
        velocityY: velocity.y
      ) {
        onProgress?(1)
        onRequestDismiss?()
        return
      }

      let target = FKSheetPresentationInteractionEngine.nearestDetentIndex(
        environment: environment,
        state: state,
        frame: wrapperView.frame,
        velocityY: velocity.y
      )
      selectDetent(at: target, animated: true)
      onProgress?(0)
      sheetPanVelocityY = 0

    default:
      break
    }
  }

  // MARK: - Layout helpers

  private func frameOfWrapper() -> CGRect {
    let bounds = view.bounds
    let safeInsets = containerSafeInsets()

    switch configuration.layout {
    case .bottomSheet(_):
      let height = resolvedSheetHeight(bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(bounds: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y = bounds.height - height - (configuration.safeAreaPolicy.positionsShellAtContainerBottomEdge ? 0 : safeInsets.bottom)
      return CGRect(x: x, y: y, width: width, height: height)
    case .topSheet(_):
      let height = resolvedSheetHeight(bounds: bounds, safeInsets: safeInsets)
      let width = resolvedSheetWidth(bounds: bounds, safeInsets: safeInsets)
      let x = (bounds.width - width) / 2
      let y: CGFloat = configuration.safeAreaPolicy.positionsShellAtContainerBottomEdge ? 0 : safeInsets.top
      return CGRect(x: x, y: y, width: width, height: height)
    case .center(_):
      return resolvedCenterFrame(bounds: bounds, safeInsets: safeInsets)
    case .anchor:
      return resolvedCenterFrame(bounds: bounds, safeInsets: safeInsets)
    case let .edge(edge):
      return edgeFrame(bounds: bounds, edge: edge)
    }
  }

  private func layoutContent() {
    contentContainerView.frame = wrapperView.bounds.inset(by: UIEdgeInsets(configuration.contentInsets))
    hostedContentView?.frame = contentContainerView.bounds
  }

  private func applyAppearance() {
    let radius = configuration.cornerRadius
    wrapperView.layer.cornerRadius = radius
    wrapperView.layer.masksToBounds = false
    let shadowPath = UIBezierPath(roundedRect: wrapperView.bounds, cornerRadius: radius).cgPath
    wrapperView.layer.fk_applyShadow(configuration.shadow, path: shadowPath)
    wrapperView.layer.fk_applyBorder(configuration.border)
    contentContainerView.layer.cornerRadius = radius
  }

  private func updatePassthroughHitTesting() {
    // In overlay host, passthrough means: only popup area intercepts.
    rootView.interactiveRect = wrapperView.frame
  }

  private func containerSafeInsets() -> UIEdgeInsets {
    switch configuration.safeAreaPolicy {
    case .contentRespectsSafeArea, .shellExtendsToScreenBottomEdge:
      return .zero
    case .containerRespectsSafeArea:
      return view.safeAreaInsets
    }
  }

  // MARK: - Sheet sizing

  private func recalculateDetentsIfNeeded() {
    let bounds = view.bounds
    let availableHeight = bounds.height - (configuration.safeAreaPolicy == .containerRespectsSafeArea ? (view.safeAreaInsets.top + view.safeAreaInsets.bottom) : 0)
    resolvedDetentHeights = configuration.sheet.detents.map { detent in
      resolve(detent: detent, availableHeight: availableHeight)
    }
    selectedDetentIndex = max(0, min(selectedDetentIndex, max(0, resolvedDetentHeights.count - 1)))
  }

  private func resolve(detent: FKPresentationDetent, availableHeight: CGFloat) -> CGFloat {
    let value: CGFloat
    switch detent {
    case .fitContent:
      let maxHeight = availableHeight * configuration.sheet.maximumFitContentHeightFraction
      let preferred = contentPreferredHeight()
      value = min(maxHeight, preferred)
    case let .fixed(points):
      value = min(availableHeight, max(0, points))
    case let .fraction(fraction):
      value = min(availableHeight, max(0, fraction) * availableHeight)
    case .medium:
      value = availableHeight * 0.5
    case .large:
      value = max(0, availableHeight - largeDetentEdgeGap())
    case .full:
      value = availableHeight
    }
    return value
  }

  /// System-sheet-like "large" detent that keeps a visible edge gap instead of true full-screen.
  private func largeDetentEdgeGap() -> CGFloat {
    let extraGap: CGFloat = 8
    switch configuration.layout {
    case .topSheet(_):
      let safeBottom = configuration.safeAreaPolicy == .containerRespectsSafeArea ? 0 : view.safeAreaInsets.bottom
      return safeBottom + extraGap
    default:
      let safeTop = configuration.safeAreaPolicy == .containerRespectsSafeArea ? 0 : view.safeAreaInsets.top
      return safeTop + extraGap
    }
  }

  private func contentPreferredHeight() -> CGFloat {
    let preferred = children.first?.preferredContentSize.height ?? 0
    switch configuration.preferredContentSizePolicy {
    case .strict:
      if preferred > 0 { return preferred }
    case .automatic:
      if preferred > 0 { return preferred }
    case .ignore:
      break
    }
    return 320
  }

  private func resolvedSheetHeight(bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    recalculateDetentsIfNeeded()
    if resolvedDetentHeights.indices.contains(selectedDetentIndex) {
      return resolvedDetentHeights[selectedDetentIndex]
    }
    return min(bounds.height * 0.5, 320)
  }

  private func resolvedSheetWidth(bounds: CGRect, safeInsets: UIEdgeInsets) -> CGFloat {
    let availableWidth = bounds.width - safeInsets.left - safeInsets.right
    switch configuration.sheet.widthPolicy {
    case .fill:
      return bounds.width
    case let .fraction(value):
      return min(availableWidth, max(220, availableWidth * min(max(value, 0.2), 1)))
    case let .max(value):
      return min(availableWidth, max(220, value))
    }
  }

  // MARK: - Center sizing

  private func resolvedCenterFrame(bounds: CGRect, safeInsets: UIEdgeInsets) -> CGRect {
    let margins = configuration.center.minimumMargins
    let maxWidth = bounds.width - (CGFloat(margins.leading + margins.trailing) + safeInsets.left + safeInsets.right)
    let maxHeight = bounds.height - (CGFloat(margins.top + margins.bottom) + safeInsets.top + safeInsets.bottom)

    let size: CGSize
    switch configuration.center.size {
    case let .fixed(fixed):
      size = .init(width: min(maxWidth, max(0, fixed.width)), height: min(maxHeight, max(0, fixed.height)))
    case let .fitted(maxSize):
      let contentW = max(220, children.first?.preferredContentSize.width ?? 0)
      let contentH = max(220, contentPreferredHeight())
      size = .init(
        width: min(maxWidth, min(maxSize.width, contentW)),
        height: min(maxHeight, min(maxSize.height, contentH))
      )
    }
    let originX = (bounds.width - size.width) / 2
    let originY = (bounds.height - size.height) / 2
    return CGRect(x: originX, y: originY, width: size.width, height: size.height)
  }

  private func edgeFrame(bounds: CGRect, edge: UIRectEdge) -> CGRect {
    let width = min(bounds.width * 0.85, 420)
    let height = min(bounds.height * 0.85, 640)
    if edge.contains(.left) {
      return CGRect(x: 0, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.right) {
      return CGRect(x: bounds.width - width, y: 0, width: width, height: bounds.height)
    }
    if edge.contains(.top) {
      return CGRect(x: 0, y: 0, width: bounds.width, height: height)
    }
    return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
  }

  // MARK: UIGestureRecognizerDelegate

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === panToDismissGesture else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: view)
    guard abs(velocity.y) >= abs(velocity.x) else { return false }

    guard let trackedScrollView = resolvedTrackedScrollView(),
          let environment = sheetInteractionEnvironment() else { return true }

    let touchInWrapper = pan.location(in: wrapperView)
    if !contentContainerView.frame.contains(touchInWrapper) { return true }

    let location = pan.location(in: trackedScrollView)
    return FKSheetPresentationInteractionEngine.shouldSheetPanBegin(
      environment: environment,
      state: sheetInteractionState(),
      scrollView: trackedScrollView,
      touchLocationInScrollView: location,
      verticalVelocity: velocity.y
    )
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    guard gestureRecognizer === panToDismissGesture || otherGestureRecognizer === panToDismissGesture else { return false }
    return otherGestureRecognizer.view is UIScrollView || gestureRecognizer.view is UIScrollView
  }
}

private final class FKOverlayRootView: UIView {
  var interactiveRect: CGRect = .zero

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    // Only the popup should intercept touches; the rest must passthrough.
    interactiveRect.contains(point)
  }
}

