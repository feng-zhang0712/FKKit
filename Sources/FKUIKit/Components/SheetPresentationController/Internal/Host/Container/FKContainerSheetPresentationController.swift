import UIKit

/// Container presentation controller responsible for frame calculation and backdrop wiring.
@MainActor
final class FKContainerSheetPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
  /// Bridges interactive/detent events back to the public controller.
  weak var owner: FKSheetPresentationController?
  /// Immutable runtime configuration snapshot for this presentation session.
  let configuration: FKSheetPresentationConfiguration
  /// Backdrop renderer shared by supported backdrop styles.
  let backdropView = FKSheetPresentationBackdropView()
  /// Optional blur material rendered behind the presented content (installed only when `configuration.containerBlur.isEnabled`).
  var containerBlurView: FKBlurView?
  /// Presentation shell carrying frame, corners, border, and shadow.
  let wrapperView = UIView()
  /// Content host that embeds the system provided presented view.
  let contentContainerView = UIView()
  /// Drag affordance for sheet-like layouts.
  let grabberView = UIView()
  /// Cached system-provided presented view after re-parenting into content container.
  weak var hostedPresentedView: UIView?

  lazy var tapToDismissGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToDismiss(_:)))
  lazy var panToDismissGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanToDismiss(_:)))

  var resolvedDetentHeights: [CGFloat] = []
  var selectedDetentIndex: Int = 0
  var keepsInteractiveFrameForDismissal = false
  var dismissalStartingFrame: CGRect = .zero

  let sheetPanCoordinator = FKSheetPresentationSheetPanCoordinator()
  let centerPanCoordinator = FKSheetPresentationCenterPanCoordinator()
  let keyboardCoordinator = FKSheetPresentationKeyboardCoordinator()

  var isPanningSheet: Bool { sheetPanCoordinator.isPanningSheet }
  var isCenterInteractivelyDragging: Bool { centerPanCoordinator.isInteractivelyDragging }
  weak var presentingEffectHostView: UIView?
  private var lastContainerBoundsSize: CGSize = .zero
  /// Stabilizes top-sheet bottom-pinned content height while a sheet pan is active.
  var pinnedHostedContentHeight: CGFloat = 0
  var pinnedHostedContentContainerWidth: CGFloat = 0

  /// Creates a container presentation controller with configuration and interaction dependencies.
  init(
    presentedViewController: UIViewController,
    presenting presentingViewController: UIViewController?,
    owner: FKSheetPresentationController?,
    configuration: FKSheetPresentationConfiguration
  ) {
    self.owner = owner
    self.configuration = configuration
    super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
  }

  /// We wrap the system-provided presented view to enable corner radius, shadow, transforms, and sheet grabber.
  public override var presentedView: UIView? {
    wrapperView
  }

  public override var frameOfPresentedViewInContainerView: CGRect {
    if keepsInteractiveFrameForDismissal {
      return dismissalStartingFrame
    }
    guard let containerView else { return .zero }

    recalculateDetentsIfNeeded()
    let environment = layoutEnvironment(in: containerView)
    return FKSheetPresentationLayoutEngine.wrapperFrame(
      environment: environment,
      detentState: currentDetentState(in: containerView)
    )
  }

  public override func presentationTransitionWillBegin() {
    guard let containerView else { return }

    backdropView.frame = containerView.bounds
    backdropView.configure(with: configuration.backdropStyle)
    backdropView.alpha = 0
    containerView.insertSubview(backdropView, at: 0)

    wrapperView.backgroundColor = .systemBackground
    // `grabberView` is added on top of `contentContainerView` when enabled (see `configureGrabberIfNeeded`).
    wrapperView.addSubview(contentContainerView)
    contentContainerView.backgroundColor = .clear
    contentContainerView.clipsToBounds = true

    if let systemPresentedView = super.presentedViewController.view {
      hostedPresentedView?.removeFromSuperview()
      hostedPresentedView = systemPresentedView
      systemPresentedView.removeFromSuperview()
      contentContainerView.addSubview(systemPresentedView)
      resetPinnedHostedContentHeightCache()
    }
    configureContainerBlurIfNeeded()

    selectedDetentIndex = configuration.sheet.initialSelectedDetentIndex
    recalculateDetentsIfNeeded()
    configureGrabberIfNeeded()
    installGesturesIfNeeded()
    startKeyboardTrackingIfNeeded()

    configureAccessibility()
    applyPresentingViewEffectIfNeeded(isPresenting: true)

    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in
        self.updateBackdropForCurrentState()
      }
    } else {
      updateBackdropForCurrentState()
    }
  }

  public override func dismissalTransitionWillBegin() {
    super.dismissalTransitionWillBegin()
    if keepsInteractiveFrameForDismissal {
      wrapperView.frame = dismissalStartingFrame
      layoutContentContainer()
    }
    applyPresentingViewEffectIfNeeded(isPresenting: false)
    if let coordinator = presentedViewController.transitionCoordinator {
      coordinator.animate { _ in
        self.backdropView.alpha = 0
      }
    } else {
      backdropView.alpha = 0
    }
  }

  public override func containerViewDidLayoutSubviews() {
    super.containerViewDidLayoutSubviews()
    backdropView.frame = containerView?.bounds ?? .zero

    guard let containerView else {
      layoutContentContainer()
      applyContainerAppearance()
      return
    }

    let newBoundsSize = containerView.bounds.size
    let containerBoundsChanged = lastContainerBoundsSize != .zero && newBoundsSize != lastContainerBoundsSize
    defer { lastContainerBoundsSize = newBoundsSize }

    let skipRotationRelayout = containerBoundsChanged && configuration.rotationHandling == .ignore
    let canAssignFrame = !sheetPanCoordinator.isPanningSheet && !centerPanCoordinator.isInteractivelyDragging
      && !keepsInteractiveFrameForDismissal
      && presentedViewController.transitionCoordinator == nil
      && !skipRotationRelayout

    if canAssignFrame {
      recalculateDetentsIfNeeded()
      let targetFrame = frameOfPresentedViewInContainerView
      let applyLayout = {
        self.wrapperView.frame = targetFrame
      }

      if containerBoundsChanged, configuration.rotationHandling == .relayoutAnimated {
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

    layoutContentContainer()

    applyContainerAppearance()
    applyKeyboardAvoidance(in: containerView)
  }

  public override func presentationTransitionDidEnd(_ completed: Bool) {
    super.presentationTransitionDidEnd(completed)
    if completed {
      publishInitialSelectedDetentIfNeeded()
      postPresentationAccessibilityAnnouncementIfNeeded()
    }
  }

  public override func dismissalTransitionDidEnd(_ completed: Bool) {
    super.dismissalTransitionDidEnd(completed)
    (presentedViewController.transitioningDelegate as? FKSheetPresentationTransitioningDelegate)?.interactiveDismiss.reset()
    if completed {
      backdropView.removeFromSuperview()
      stopKeyboardTracking()
      cleanupPresentingViewEffect()
      resetDismissalFrameLock()
      resetCenterInteractiveDismissVisuals()
    } else {
      // Interactive dismiss can cancel after intermediate visual changes; restore backdrop/effect state
      // so the re-presented sheet remains visually consistent and does not look half-dismissed.
      applyPresentingViewEffectIfNeeded(isPresenting: true)
      updateBackdropForCurrentState()
      resetDismissalFrameLock()
      resetCenterInteractiveDismissVisuals()
    }
  }

  public override func preferredContentSizeDidChange(forChildContentContainer container: any UIContentContainer) {
    super.preferredContentSizeDidChange(forChildContentContainer: container)
    guard let containerView else { return }
    resetPinnedHostedContentHeightCache()
    recalculateDetentsIfNeeded()
    let targetFrame = frameOfPresentedViewInContainerView
    let applyLayout: () -> Void = {
      self.wrapperView.frame = targetFrame
      UIView.performWithoutAnimation {
        self.layoutContentContainer()
        self.applyContainerAppearance()
        self.applyKeyboardAvoidance(in: containerView)
        if !self.isCenterInteractivelyDragging {
          self.updateBackdropForCurrentState()
        }
        self.wrapperView.layoutIfNeeded()
      }
    }

    // Keep fit-content updates close to system sheet behavior by animating size transitions.
    if presentedViewController.transitionCoordinator == nil {
      UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: applyLayout)
    } else {
      applyLayout()
    }
  }

  private func resetDismissalFrameLock() {
    keepsInteractiveFrameForDismissal = false
    dismissalStartingFrame = .zero
  }
}

