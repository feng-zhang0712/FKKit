import ObjectiveC
import UIKit

/// Custom modal transition for ``FKActionSheet``.
@MainActor
final class FKActionSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  private static var associationKey: UInt8 = 0

  let presentationConfiguration: FKActionSheetPresentationConfiguration
  weak var actionSheetViewController: FKActionSheet?

  init(presentationConfiguration: FKActionSheetPresentationConfiguration) {
    self.presentationConfiguration = presentationConfiguration
    super.init()
  }

  func attach(to viewController: FKActionSheet) {
    guard presentationConfiguration.usesCustomModalPresentation else { return }
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
    guard presentationConfiguration.usesCustomModalPresentation else { return nil }
    return FKActionSheetUIKitPresentationController(
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
    guard presentationConfiguration.usesCustomModalPresentation else { return nil }
    return FKActionSheetAnimator(
      isPresenting: true,
      configuration: presentationConfiguration,
      actionSheetViewController: actionSheetViewController
    )
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    guard presentationConfiguration.usesCustomModalPresentation else { return nil }
    return FKActionSheetAnimator(
      isPresenting: false,
      configuration: presentationConfiguration,
      actionSheetViewController: actionSheetViewController
    )
  }

}
