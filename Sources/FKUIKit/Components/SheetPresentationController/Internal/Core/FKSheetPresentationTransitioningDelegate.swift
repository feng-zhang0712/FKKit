import UIKit

/// Internal transitioning delegate that builds presentation controller and animators.
final class FKSheetPresentationTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  weak var owner: FKSheetPresentationController?
  weak var activeContainerController: FKContainerSheetPresentationController?

  let interactiveDismiss = FKSheetPresentationInteractiveDismissTransition()

  private let configuration: FKSheetPresentationConfiguration

  init(configuration: FKSheetPresentationConfiguration) {
    self.configuration = configuration
    super.init()
  }

  func presentationController(
    forPresented presented: UIViewController,
    presenting: UIViewController?,
    source: UIViewController
  ) -> UIPresentationController? {
    let controller = FKContainerSheetPresentationController(
      presentedViewController: presented,
      presenting: presenting,
      owner: owner,
      configuration: configuration
    )
    activeContainerController = controller
    return controller
  }

  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController)
    -> (any UIViewControllerAnimatedTransitioning)? {
    if let provider = configuration.animation.customAnimatorProvider {
      return provider.makePresentationAnimator()
    }
    return FKSheetPresentationAnimator(
      isPresentation: true,
      layout: configuration.layout,
      animationConfiguration: configuration.animation,
      interactiveDismiss: nil
    )
  }

  func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
    if let provider = configuration.animation.customAnimatorProvider {
      return provider.makeDismissalAnimator()
    }
    let interactor = interactiveDismiss.isArmed ? interactiveDismiss : nil
    return FKSheetPresentationAnimator(
      isPresentation: false,
      layout: configuration.layout,
      animationConfiguration: configuration.animation,
      interactiveDismiss: interactor
    )
  }

  func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning)
    -> (any UIViewControllerInteractiveTransitioning)? {
    interactiveDismiss.isArmed ? interactiveDismiss : nil
  }

  /// Arms interactive dismiss before `dismiss(animated:)` so the remaining motion inherits finger velocity.
  func armInteractiveDismiss(completionFraction: CGFloat, dismissalVelocityY: CGFloat) {
    interactiveDismiss.arm(completionFraction: completionFraction, dismissalVelocityY: dismissalVelocityY)
  }
}
