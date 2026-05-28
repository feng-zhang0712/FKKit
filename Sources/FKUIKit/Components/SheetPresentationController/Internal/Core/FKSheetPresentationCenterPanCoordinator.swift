import UIKit

/// Drives center-card interactive dismiss gestures for modal container and overlay hosts.
@MainActor
final class FKSheetPresentationCenterPanCoordinator {
  var isInteractivelyDragging = false
  var baseBackdropAlpha: CGFloat = 1

  struct Actions {
    var containerHeight: () -> CGFloat
    var captureBaseBackdropAlpha: () -> Void
    var applyInteractiveDismiss: (_ translationY: CGFloat, _ progress: CGFloat) -> Void
    var resetInteractiveDismiss: (_ animated: Bool) -> Void
    var notifyProgress: (CGFloat) -> Void
    var dismiss: (_ velocityY: CGFloat) -> Void
    var dismissProgressThreshold: () -> CGFloat
    var dismissVelocityThreshold: () -> CGFloat
  }

  func handlePan(
    _ recognizer: UIPanGestureRecognizer,
    in coordinateView: UIView,
    actions: Actions
  ) {
    let translation = recognizer.translation(in: coordinateView)
    let progress = min(max(abs(translation.y) / max(1, actions.containerHeight() * 0.4), 0), 1)

    switch recognizer.state {
    case .began:
      actions.captureBaseBackdropAlpha()
      isInteractivelyDragging = true
    case .changed:
      actions.applyInteractiveDismiss(translation.y, progress)
      actions.notifyProgress(progress)
    case .ended, .cancelled, .failed:
      let velocityY = recognizer.velocity(in: coordinateView).y
      let shouldDismiss = progress > actions.dismissProgressThreshold()
        || abs(velocityY) > actions.dismissVelocityThreshold()
      isInteractivelyDragging = false
      if shouldDismiss {
        actions.notifyProgress(1)
        actions.dismiss(velocityY)
      } else {
        actions.notifyProgress(0)
        actions.resetInteractiveDismiss(true)
      }
    default:
      break
    }
  }
}
