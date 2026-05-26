import UIKit

/// Backdrop and container layout for the action sheet modal.
@MainActor
final class FKActionSheetUIKitPresentationController: UIPresentationController {
  private let configuration: FKActionSheetPresentationConfiguration
  private weak var actionSheetViewController: FKActionSheetViewController?

  private lazy var backdropTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBackdropTap))

  private(set) lazy var backdropView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.black.withAlphaComponent(configuration.backdropAlpha)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.isUserInteractionEnabled = true
    view.isAccessibilityElement = false
    view.accessibilityViewIsModal = false
    return view
  }()

  init(
    presentedViewController: UIViewController,
    presenting presentingViewController: UIViewController?,
    configuration: FKActionSheetPresentationConfiguration,
    actionSheetViewController: FKActionSheetViewController?
  ) {
    self.configuration = configuration
    self.actionSheetViewController = actionSheetViewController
    super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
  }

  override var frameOfPresentedViewInContainerView: CGRect {
    containerView?.bounds ?? .zero
  }

  override func presentationTransitionWillBegin() {
    guard let containerView else { return }
    backdropView.frame = containerView.bounds
    backdropView.alpha = 0
    if configuration.allowsTapOutsideDismiss {
      backdropView.addGestureRecognizer(backdropTapRecognizer)
    }
    containerView.insertSubview(backdropView, at: 0)

    presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
      self?.backdropView.alpha = 1
    })
  }

  override func dismissalTransitionWillBegin() {
    presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
      self?.backdropView.alpha = 0
    })
  }

  override func dismissalTransitionDidEnd(_ completed: Bool) {
    if completed {
      backdropView.removeFromSuperview()
    }
  }

  func setBackdropAlpha(_ alpha: CGFloat) {
    backdropView.alpha = alpha
  }

  @objc
  private func handleBackdropTap() {
    actionSheetViewController?.dismissForBackdropTap()
  }
}
