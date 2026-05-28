import UIKit

/// Drives sheet detent pan gestures for modal container and overlay presentation hosts.
@MainActor
final class FKSheetPresentationSheetPanCoordinator {
  private(set) var isPanningSheet = false
  private(set) var sheetPanDeferredToScrollView = false
  private(set) var sheetPanBypassesScrollHandoff = false
  var sheetPanVelocityY: CGFloat = 0
  var panStartFrame: CGRect = .zero
  var sheetPanBeganDetentIndex: Int = 0

  struct Actions {
    var recalculateDetents: () -> Void
    var resolvedDetentHeights: () -> [CGFloat]
    var selectedDetentIndex: () -> Int
    var wrapperFrame: () -> CGRect
    var setWrapperFrame: (_ frame: CGRect, _ settling: Bool) -> Void
    var environment: () -> FKSheetPresentationInteractionEnvironment?
    var interactionState: () -> FKSheetPresentationInteractionState
    var trackedScrollView: () -> UIScrollView?
    var bypassScrollHandoff: (UIPanGestureRecognizer, UIScrollView?) -> Bool
    var notifyProgress: (CGFloat) -> Void
    var animateToSelectedDetent: (_ animated: Bool, _ settling: Bool) -> Void
    var selectDetent: (_ index: Int, _ animated: Bool) -> Void
    var dismiss: (_ velocityY: CGFloat, _ progress: CGFloat) -> Void
  }

  func handlePan(
    _ recognizer: UIPanGestureRecognizer,
    in coordinateView: UIView,
    actions: Actions
  ) {
    guard let environment = actions.environment() else { return }

    actions.recalculateDetents()
    guard !actions.resolvedDetentHeights().isEmpty else { return }

    let translation = recognizer.translation(in: coordinateView)
    let velocity = recognizer.velocity(in: coordinateView)
    let trackedScrollView = actions.trackedScrollView()

    switch recognizer.state {
    case .began:
      isPanningSheet = true
      sheetPanDeferredToScrollView = false
      sheetPanBypassesScrollHandoff = actions.bypassScrollHandoff(recognizer, trackedScrollView)
      panStartFrame = actions.wrapperFrame()
      sheetPanBeganDetentIndex = actions.selectedDetentIndex()
      sheetPanVelocityY = 0
      trackedScrollView?.panGestureRecognizer.isEnabled = true

    case .changed:
      guard isPanningSheet else { return }
      sheetPanVelocityY = velocity.y
      var state = actions.interactionState()

      if !sheetPanBypassesScrollHandoff,
         let trackedScrollView,
         !FKSheetPresentationInteractionEngine.shouldTransferPanFromScrollView(
          environment: environment,
          state: state,
          scrollView: trackedScrollView,
          translationY: translation.y
         ) {
        if !sheetPanDeferredToScrollView {
          sheetPanDeferredToScrollView = true
          actions.animateToSelectedDetent(false, true)
        }
        return
      }

      if sheetPanDeferredToScrollView {
        sheetPanDeferredToScrollView = false
      }

      state = actions.interactionState()
      let frame = FKSheetPresentationInteractionEngine.interactiveFrame(
        environment: environment,
        state: state,
        translationY: translation.y
      )
      actions.setWrapperFrame(frame, true)
      state.wrapperFrame = actions.wrapperFrame()
      actions.notifyProgress(
        FKSheetPresentationInteractionEngine.sheetDismissProgress(environment: environment, state: state)
      )

    case .ended, .cancelled, .failed:
      guard isPanningSheet else { return }
      isPanningSheet = false

      if sheetPanDeferredToScrollView {
        resetTransientPanState()
        return
      }

      sheetPanBypassesScrollHandoff = false
      let state = actions.interactionState()

      if FKSheetPresentationInteractionEngine.sheetShouldDismiss(
        environment: environment,
        state: state,
        translationY: translation.y,
        velocityY: velocity.y
      ) {
        let progress = FKSheetPresentationInteractionEngine.sheetDismissProgress(
          environment: environment,
          state: state
        )
        actions.notifyProgress(1)
        actions.dismiss(velocity.y, progress)
        sheetPanVelocityY = 0
        return
      }

      let target = FKSheetPresentationInteractionEngine.nearestDetentIndex(
        environment: environment,
        state: state,
        frame: actions.wrapperFrame(),
        velocityY: velocity.y
      )
      actions.selectDetent(target, true)
      actions.notifyProgress(0)
      sheetPanVelocityY = 0

    default:
      break
    }
  }

  func resetTransientPanState() {
    isPanningSheet = false
    sheetPanDeferredToScrollView = false
    sheetPanBypassesScrollHandoff = false
    sheetPanVelocityY = 0
  }
}
