import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  // MARK: - Interactive Dismiss

  func presentationTransitioningDelegate() -> FKSheetPresentationTransitioningDelegate? {
    presentedViewController.transitioningDelegate as? FKSheetPresentationTransitioningDelegate
  }

  /// Arms UIKit interactive dismiss and calls `dismiss(animated:)` using the current on-screen geometry.
  func performInteractiveDismiss(velocityY: CGFloat, completionFraction: CGFloat) {
    keepsInteractiveFrameForDismissal = true
    dismissalStartingFrame = wrapperView.frame
    sheetPanVelocityY = velocityY

    let fraction = min(max(completionFraction, 0), 1)
    if let delegate = presentationTransitioningDelegate() {
      delegate.armInteractiveDismiss(completionFraction: fraction, dismissalVelocityY: velocityY)
    }
    presentedViewController.dismiss(animated: true)
  }

  // MARK: - Interactive Layout

  /// Applies sheet frame updates with a tiered layout cost model for pan tracking.
  func applyInteractiveFrame(_ frame: CGRect, updateKind: FKInteractiveLayoutUpdateKind = .tracking) {
    wrapperView.transform = .identity
    wrapperView.frame = frame
    layoutContentContainer()
    hostedPresentedView?.frame = contentContainerView.bounds

    switch updateKind {
    case .tracking:
      updateBackdropForCurrentState()
    case .settling:
      break
    case .full:
      applyContainerAppearance()
      if let containerView {
        applyKeyboardAvoidance(in: containerView)
      }
      updateBackdropForCurrentState()
    }
  }

  // MARK: - Center Interactive Dismiss

  func captureCenterDismissBaseBackdropAlphaIfNeeded() {
    guard case .center(_) = configuration.layout else { return }
    switch configuration.backdropStyle {
    case let .dim(_, alpha):
      centerDismissBaseBackdropAlpha = alpha
    default:
      centerDismissBaseBackdropAlpha = 1
    }
  }

  func applyCenterInteractiveDismissTransform(translationY: CGFloat, progress: CGFloat) {
    guard let containerView else { return }
    isCenterInteractivelyDragging = true
    wrapperView.transform = FKSheetPresentationInteractionSupport.centerDismissTransform(
      translationY: translationY,
      containerHeight: containerView.bounds.height
    )
    backdropView.alpha = FKSheetPresentationInteractionSupport.centerDismissBackdropAlpha(
      baseAlpha: centerDismissBaseBackdropAlpha,
      progress: progress
    )
  }

  func resetCenterInteractiveDismissVisuals(animated: Bool = false, completion: (() -> Void)? = nil) {
    isCenterInteractivelyDragging = false
    let updates = {
      self.wrapperView.transform = .identity
      self.updateBackdropForCurrentState()
      self.backdropView.alpha = 1
    }
    guard animated else {
      updates()
      completion?()
      return
    }
    let timing = UISpringTimingParameters(dampingRatio: 0.86, initialVelocity: .zero)
    let animator = UIViewPropertyAnimator(duration: 0.34, timingParameters: timing)
    animator.addAnimations(updates)
    animator.addCompletion { _ in completion?() }
    animator.startAnimation()
  }

  func commitCenterInteractiveStateForDismissal() {
    guard case .center(_) = configuration.layout else { return }
    guard wrapperView.transform != .identity else { return }
    let translationY = wrapperView.transform.ty
    wrapperView.transform = .identity
    guard translationY != 0 else { return }
    var frame = wrapperView.frame
    frame.origin.y += translationY
    wrapperView.frame = frame
    layoutContentContainer()
    hostedPresentedView?.frame = contentContainerView.bounds
    dismissalStartingFrame = frame
  }
}
