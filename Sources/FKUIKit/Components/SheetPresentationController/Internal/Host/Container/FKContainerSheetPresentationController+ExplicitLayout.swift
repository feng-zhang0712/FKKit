import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  /// Applies an explicit layout pass when content geometry changes outside `preferredContentSizeDidChange`.
  func applyExplicitLayoutUpdate(
    animated: Bool,
    duration: TimeInterval,
    options: UIView.AnimationOptions
  ) {
    guard let containerView else { return }
    recalculateDetentsIfNeeded()
    let targetFrame = frameOfPresentedViewInContainerView
    let applyLayout: () -> Void = {
      self.wrapperView.frame = targetFrame
      self.layoutContentContainer()
      self.applyContainerAppearance()
      self.applyKeyboardAvoidance(in: containerView)
      self.updateBackdropForCurrentState()
      self.wrapperView.layoutIfNeeded()
    }

    guard animated else {
      applyLayout()
      return
    }

    UIView.animate(
      withDuration: max(0, duration),
      delay: 0,
      options: [options, .allowUserInteraction, .beginFromCurrentState],
      animations: applyLayout
    )
  }
}
