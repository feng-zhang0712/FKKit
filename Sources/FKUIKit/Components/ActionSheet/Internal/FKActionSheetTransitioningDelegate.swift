import ObjectiveC
import UIKit

/// Custom modal transition for ``FKActionSheet``.
@MainActor
final class FKActionSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
  private static var associationKey: UInt8 = 0

  private(set) var presentationConfiguration: FKActionSheetPresentationConfiguration
  weak var actionSheet: FKActionSheet?

  init(presentationConfiguration: FKActionSheetPresentationConfiguration) {
    self.presentationConfiguration = presentationConfiguration
    super.init()
  }

  func updatePresentationConfiguration(_ configuration: FKActionSheetPresentationConfiguration) {
    presentationConfiguration = configuration
  }

  func attach(to viewController: FKActionSheet) {
    guard presentationConfiguration.usesCustomModalPresentation else { return }
    actionSheet = viewController
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
      actionSheet: actionSheet
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
      actionSheet: actionSheet
    )
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    guard presentationConfiguration.usesCustomModalPresentation else { return nil }
    return FKActionSheetAnimator(
      isPresenting: false,
      configuration: presentationConfiguration,
      actionSheet: actionSheet
    )
  }
}
