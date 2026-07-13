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
    sheetPanCoordinator.sheetPanVelocityY = velocityY

    let fraction = min(max(completionFraction, 0), 1)
    if let delegate = presentationTransitioningDelegate() {
      delegate.armInteractiveDismiss(completionFraction: fraction, dismissalVelocityY: velocityY)
    }
    presentedViewController.dismiss(animated: true)
  }

  // MARK: - Interactive Layout

  /// Applies sheet frame updates with a tiered layout cost model for pan tracking.
  func applyInteractiveFrame(_ frame: CGRect, updateKind: FKInteractiveLayoutUpdateKind = .tracking) {
    // Sheet interaction drives `frame`, not `transform`. Clear any leftover center-dismiss /
    // keyboard transform so frame math stays authoritative during sheet pans.
    if wrapperView.transform != .identity {
      wrapperView.transform = .identity
      keyboardCoordinator.clearAppliedTranslation()
    }
    wrapperView.frame = frame
    layoutContentContainer()

    switch updateKind {
    case .tracking:
      // Live multi-stage backdrop + progress while the finger moves.
      updateBackdropForCurrentState()
    case .settling:
      // Cheap snap while scroll owns the gesture — skip shadow/keyboard work.
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
      centerPanCoordinator.baseBackdropAlpha = alpha
    default:
      centerPanCoordinator.baseBackdropAlpha = 1
    }
  }

  func applyCenterInteractiveDismissTransform(translationY: CGFloat, progress: CGFloat) {
    guard let containerView else { return }
    // Compose with keyboard offset so dismiss drag does not drop the card behind the keyboard.
    wrapperView.transform = FKSheetPresentationInteractionSupport.centerDismissTransform(
      translationY: translationY,
      containerHeight: containerView.bounds.height,
      keyboardOffsetY: keyboardCoordinator.appliedTranslationY
    )
  }

  func resetCenterInteractiveDismissVisuals(animated: Bool = false, completion: (() -> Void)? = nil) {
    let updates = {
      // Restore keyboard avoidance (if any) rather than forcing identity, which would leave the
      // card under the keyboard until the next keyboard notification.
      self.restoreWrapperTransformAfterInteractiveGesture()
      self.updateBackdropForCurrentState()
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

  /// Re-applies keyboard translation or clears transform after interactive pan cancel/end.
  func restoreWrapperTransformAfterInteractiveGesture() {
    if configuration.keyboardAvoidance.isEnabled,
       keyboardCoordinator.bottomInset > 0,
       let containerView {
      keyboardCoordinator.translateWrapperAvoidingKeyboard(wrapperView, in: containerView)
    } else {
      wrapperView.transform = .identity
    }
  }

  func commitCenterInteractiveStateForDismissal() {
    guard case .center(_) = configuration.layout else { return }
    guard wrapperView.transform != .identity else { return }
    // Peel off keyboard offset so only the interactive pull is baked into the dismissal frame.
    let keyboardY = keyboardCoordinator.appliedTranslationY
    let translationY = wrapperView.transform.ty - keyboardY
    wrapperView.transform = keyboardCoordinator.keyboardAvoidanceTransform
    guard abs(translationY) > 0.5 else {
      dismissalStartingFrame = wrapperView.frame
      return
    }
    var frame = wrapperView.frame
    frame.origin.y += translationY
    wrapperView.frame = frame
    // Clear scale component; frame now carries the vertical offset for the dismiss animator.
    wrapperView.transform = .identity
    keyboardCoordinator.clearAppliedTranslation()
    layoutContentContainer()
    dismissalStartingFrame = frame
  }
}
