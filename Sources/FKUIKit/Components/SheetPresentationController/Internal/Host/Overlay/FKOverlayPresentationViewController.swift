import UIKit

/// Overlay-based presentation container that supports passthrough outside the popup.
@MainActor
final class FKOverlayPresentationViewController: UIViewController, UIGestureRecognizerDelegate {
  var onRequestDismiss: (() -> Void)?
  var onProgress: ((CGFloat) -> Void)?
  var onSelectedDetentDidChange: ((FKSheetPresentationDetent, Int) -> Void)?

  private let configuration: FKSheetPresentationConfiguration

  private let rootView = FKOverlayRootView()
  private let backdropView = FKSheetPresentationBackdropView()
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
  /// When true, ``FKOverlayPresentationHost`` tears down without running a second dismiss animation.
  private var skipsDismissPresentationAnimation = false

  /// Returns whether an interactive dismiss already animated off-screen and clears the latch.
  func consumeSkipsDismissPresentationAnimation() -> Bool {
    defer { skipsDismissPresentationAnimation = false }
    return skipsDismissPresentationAnimation
  }

  init(configuration: FKSheetPresentationConfiguration) {
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

  func selectDetent(_ detent: FKSheetPresentationDetent, animated: Bool) {
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
      let duration = FKSheetPresentationInteractionSupport.adaptiveDetentSnapDuration(
        distance: distance,
        velocityY: sheetPanVelocityY
      )
      let timing = UISpringTimingParameters(
        dampingRatio: 0.86,
        initialVelocity: FKSheetPresentationInteractionSupport.normalizedDetentSnapVelocity(
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
      updateLayout(animated: false, duration: 0, options: .curveLinear)
    } else {
      updatePassthroughHitTesting()
    }

    let baseFrame = frameOfWrapper()
    FKSheetPresentationOverlayTransition.animatePresentation(
      configuration: configuration,
      isPresentation: isPresentation,
      animated: animated,
      backdropView: backdropView,
      wrapperView: wrapperView,
      baseFrame: baseFrame,
      completion: completion
    )
  }

  /// Animates from the current interactive sheet state, then requests host dismissal without a second transition.
  func performInteractiveDismiss(velocityY: CGFloat) {
    skipsDismissPresentationAnimation = true
    let baseFrame = frameOfWrapper()
    FKSheetPresentationOverlayTransition.animateInteractiveDismiss(
      configuration: configuration,
      backdropView: backdropView,
      wrapperView: wrapperView,
      baseFrame: baseFrame,
      dismissalVelocityY: velocityY
    ) { [weak self] in
      self?.onRequestDismiss?()
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
      wrapperView.transform = FKSheetPresentationInteractionSupport.centerDismissTransform(
        translationY: translation.y,
        containerHeight: view.bounds.height
      )
      backdropView.alpha = FKSheetPresentationInteractionSupport.centerDismissBackdropAlpha(
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
        performInteractiveDismiss(velocityY: velocityY)
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
        performInteractiveDismiss(velocityY: velocity.y)
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

  private func layoutEnvironment() -> FKSheetPresentationLayoutEngine.Environment {
    FKSheetPresentationLayoutEngine.Environment(
      configuration: configuration,
      containerBounds: view.bounds,
      containerSafeAreaInsets: view.safeAreaInsets,
      preferredContentSize: children.first?.preferredContentSize ?? .zero,
      contentViewForFitting: children.first?.view
    )
  }

  private func currentDetentState() -> FKSheetPresentationLayoutEngine.DetentState {
    FKSheetPresentationLayoutEngine.DetentState(
      resolvedHeights: resolvedDetentHeights,
      selectedIndex: selectedDetentIndex
    )
  }

  private func frameOfWrapper() -> CGRect {
    recalculateDetentsIfNeeded()
    return FKSheetPresentationLayoutEngine.wrapperFrame(
      environment: layoutEnvironment(),
      detentState: currentDetentState()
    )
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
    FKSheetPresentationLayoutEngine.presentationSafeInsets(
      configuration: configuration,
      containerSafeAreaInsets: view.safeAreaInsets
    )
  }

  private func recalculateDetentsIfNeeded() {
    let state = FKSheetPresentationLayoutEngine.recalculateDetents(
      environment: layoutEnvironment(),
      selectedIndex: selectedDetentIndex
    )
    resolvedDetentHeights = state.resolvedHeights
    selectedDetentIndex = state.selectedIndex
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

