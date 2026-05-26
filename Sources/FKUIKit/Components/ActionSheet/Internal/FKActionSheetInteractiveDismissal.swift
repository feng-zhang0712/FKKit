import UIKit

/// Interactive swipe-to-dismiss for the action sheet panel.
@MainActor
final class FKActionSheetInteractiveDismissal: UIPercentDrivenInteractiveTransition {
  private weak var viewController: FKActionSheetViewController?
  private var beganDismiss = false

  func attach(to viewController: FKActionSheetViewController) {
    self.viewController = viewController
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = viewController
    viewController.panelView.addGestureRecognizer(pan)
  }

  @objc
  private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard let viewController else { return }
    let translationY = max(0, gesture.translation(in: viewController.view).y)
    let panelHeight = max(viewController.resolvedPanelHeight, 1)
    let progress = min(1, translationY / panelHeight)

    switch gesture.state {
    case .began:
      beganDismiss = false
    case .changed:
      viewController.session?.recordInteractiveDismissProgress(progress)
      viewController.setPresentationProgress(1 - progress, animated: false)
      viewController.actionSheetPresentationController?.setBackdropAlpha(
        viewController.presentationConfiguration.backdropAlpha * (1 - progress)
      )
      if progress > 0.08, !beganDismiss {
        beganDismiss = true
        viewController.beginInteractiveDismissal(using: self)
      }
      update(progress)
    case .ended, .cancelled:
      let velocityY = gesture.velocity(in: viewController.view).y
      let shouldFinish = progress > 0.35 || velocityY > 900
      if shouldFinish {
        finish()
      } else {
        cancel()
        viewController.cancelInteractiveDismissal(using: self)
      }
      beganDismiss = false
    default:
      break
    }
  }
}
