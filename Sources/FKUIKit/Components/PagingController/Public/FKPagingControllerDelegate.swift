import Foundation

/// Observes page lifecycle and interactive transition progress for ``FKPagingController``.
@MainActor
public protocol FKPagingControllerDelegate: AnyObject {
  /// Called whenever ``FKPagingController/stateSnapshot``’s phase changes.
  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase)
  /// Called during interactive swipes while the tab indicator tracks fractional progress.
  func pagingController(_ controller: FKPagingController, didUpdateProgress progress: CGFloat, from fromIndex: Int, to toIndex: Int)
  /// Called after the container settles on a page (interactive or programmatic).
  func pagingController(_ controller: FKPagingController, didSettleAt index: Int)
}

@MainActor
public extension FKPagingControllerDelegate {
  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase) {}
  func pagingController(_ controller: FKPagingController, didUpdateProgress progress: CGFloat, from fromIndex: Int, to toIndex: Int) {}
  func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {}
}
