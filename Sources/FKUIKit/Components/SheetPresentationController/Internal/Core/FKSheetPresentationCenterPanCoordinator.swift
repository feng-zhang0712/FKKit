import UIKit

/// Drives center-card interactive dismiss gestures for modal container and overlay hosts.
@MainActor
final class FKSheetPresentationCenterPanCoordinator {
  var isInteractivelyDragging = false
  /// Stays `true` for the remainder of the pan once scroll ownership is detected.
  private var stickyDeferredToScrollView = false
  /// Scroll offset captured at pan begin for detecting content scrolling during the gesture.
  private var scrollOffsetAtPanStart: CGFloat?
  /// Whether the tracked scroll view moved away from its start offset during this pan.
  private var scrollConsumedPanDuringGesture = false
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
    var trackedScrollView: () -> UIScrollView?
    var shouldDeferToScrollView: (_ translationY: CGFloat) -> Bool
  }

  func handlePan(
    _ recognizer: UIPanGestureRecognizer,
    in coordinateView: UIView,
    actions: Actions
  ) {
    let translation = recognizer.translation(in: coordinateView)
    // Center alerts dismiss only when dragged downward (not upward).
    let downwardTranslation = max(0, translation.y)
    let progress = min(max(downwardTranslation / max(1, actions.containerHeight() * 0.4), 0), 1)

    switch recognizer.state {
    case .began:
      actions.captureBaseBackdropAlpha()
      isInteractivelyDragging = true
      stickyDeferredToScrollView = false
      scrollConsumedPanDuringGesture = false
      if let scrollView = actions.trackedScrollView() {
        scrollOffsetAtPanStart = scrollView.contentOffset.y
      } else {
        scrollOffsetAtPanStart = nil
      }
    case .changed:
      updateScrollConsumptionDuringPan(trackedScrollView: actions.trackedScrollView())

      if actions.shouldDeferToScrollView(translation.y) {
        if !stickyDeferredToScrollView {
          stickyDeferredToScrollView = true
          actions.resetInteractiveDismiss(false)
          actions.notifyProgress(0)
        }
        return
      }

      guard !scrollConsumedPanDuringGesture, !stickyDeferredToScrollView else { return }

      if let scrollView = actions.trackedScrollView() {
        FKSheetPresentationInteractionEngine.clampScrollViewToSheetHandoffEdge(scrollView, axis: .bottom)
      }
      actions.applyInteractiveDismiss(downwardTranslation, progress)
      actions.notifyProgress(progress)
    case .ended, .cancelled, .failed:
      let velocityY = recognizer.velocity(in: coordinateView).y
      isInteractivelyDragging = false
      updateScrollConsumptionDuringPan(trackedScrollView: actions.trackedScrollView())

      if stickyDeferredToScrollView || scrollConsumedPanDuringGesture {
        resetTransientPanState()
        return
      }

      let shouldDismiss = progress > actions.dismissProgressThreshold()
        || velocityY > actions.dismissVelocityThreshold()
      if shouldDismiss {
        actions.notifyProgress(1)
        actions.dismiss(velocityY)
      } else {
        actions.notifyProgress(0)
        actions.resetInteractiveDismiss(true)
      }
      resetTransientPanState()
    default:
      break
    }
  }

  private func updateScrollConsumptionDuringPan(trackedScrollView: UIScrollView?) {
    guard let scrollView = trackedScrollView, let startOffset = scrollOffsetAtPanStart else { return }
    if scrollView.contentOffset.y > startOffset + 0.5 {
      scrollConsumedPanDuringGesture = true
    }
    if !FKSheetPresentationInteractionEngine.isScrollViewAtTopEdge(scrollView) {
      scrollConsumedPanDuringGesture = true
    }
  }

  private func resetTransientPanState() {
    stickyDeferredToScrollView = false
    scrollOffsetAtPanStart = nil
    scrollConsumedPanDuringGesture = false
  }
}
