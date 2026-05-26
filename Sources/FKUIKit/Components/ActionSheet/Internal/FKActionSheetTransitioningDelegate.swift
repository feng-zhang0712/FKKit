import ObjectiveC
import UIKit

/// Custom modal transition for ``FKActionSheetViewController``.
@MainActor
final class FKActionSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  private static var associationKey: UInt8 = 0

  let presentationConfiguration: FKActionSheetPresentationConfiguration
  weak var actionSheetViewController: FKActionSheetViewController?

  init(presentationConfiguration: FKActionSheetPresentationConfiguration) {
    self.presentationConfiguration = presentationConfiguration
    super.init()
  }

  func attach(to viewController: FKActionSheetViewController) {
    actionSheetViewController = viewController
    viewController.modalPresentationStyle = .custom
    viewController.transitioningDelegate = self
    objc_setAssociatedObject(
      viewController,
      &Self.associationKey,
      self,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  func presentationController(
    forPresented presented: UIViewController,
    presenting: UIViewController?,
    source: UIViewController
  ) -> UIPresentationController? {
    FKActionSheetUIKitPresentationController(
      presentedViewController: presented,
      presenting: presenting,
      configuration: presentationConfiguration,
      actionSheetViewController: actionSheetViewController
    )
  }

  func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> UIViewControllerAnimatedTransitioning? {
    FKActionSheetAnimator(
      isPresenting: true,
      configuration: presentationConfiguration,
      actionSheetViewController: actionSheetViewController
    )
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    FKActionSheetAnimator(
      isPresenting: false,
      configuration: presentationConfiguration,
      actionSheetViewController: actionSheetViewController
    )
  }

  func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    actionSheetViewController?.interactiveDismissal
  }
}
