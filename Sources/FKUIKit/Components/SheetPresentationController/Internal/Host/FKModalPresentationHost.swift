import ObjectiveC
import UIKit

@MainActor
final class FKModalPresentationHost: NSObject, FKSheetPresentationHost {
  private static var associationKey: UInt8 = 0

  private unowned let owner: FKSheetPresentationController
  private let contentController: UIViewController
  private let configuration: FKSheetPresentationConfiguration
  private let transitioningDelegateBox: FKSheetPresentationTransitioningDelegate

  private(set) var isPresented: Bool = false

  init(owner: FKSheetPresentationController, contentController: UIViewController, configuration: FKSheetPresentationConfiguration) {
    self.owner = owner
    self.contentController = contentController
    self.configuration = configuration
    self.transitioningDelegateBox = FKSheetPresentationTransitioningDelegate(configuration: configuration)
    super.init()

    transitioningDelegateBox.owner = owner
    // Modal path relies on UIKit custom presentation so we configure style/delegate once up front.
    contentController.modalPresentationStyle = .custom
    contentController.transitioningDelegate = transitioningDelegateBox
    objc_setAssociatedObject(
      contentController,
      &Self.associationKey,
      transitioningDelegateBox,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
  }

  func present(from presentingViewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
    guard contentController.presentingViewController == nil else {
      completion?()
      return
    }
    isPresented = true
    presentingViewController.present(contentController, animated: animated, completion: completion)
  }

  func dismiss(animated: Bool, completion: (() -> Void)?) {
    guard contentController.presentingViewController != nil else {
      completion?()
      return
    }
    isPresented = false
    contentController.dismiss(animated: animated, completion: completion)
  }

  func updateLayout(animated: Bool, duration: TimeInterval, options: UIView.AnimationOptions) {
    (contentController.transitioningDelegate as? FKSheetPresentationTransitioningDelegate)?
      .activeContainerController?
      .applyExplicitLayoutUpdate(animated: animated, duration: duration, options: options)
  }
}

