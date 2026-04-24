import Foundation

/// Callback surface for observing page transitions.
@MainActor
public protocol FKPagingControllerDelegate: AnyObject {
  /// Called when controller phase changes.
  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase)
  /// Called when interactive transition updates.
  func pagingController(_ controller: FKPagingController, didUpdateProgress progress: CGFloat, from fromIndex: Int, to toIndex: Int)
  /// Called when controller settles at a final page.
  func pagingController(_ controller: FKPagingController, didSettleAt index: Int)
}

@MainActor
public extension FKPagingControllerDelegate {
  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase) {}
  func pagingController(_ controller: FKPagingController, didUpdateProgress progress: CGFloat, from fromIndex: Int, to toIndex: Int) {}
  func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {}
}
