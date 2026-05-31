import UIKit

@MainActor
enum FKPagingScrollUtilities {
  static func scrollPageToTop(in rootView: UIView) {
    if let tableView = findDescendant(of: UITableView.self, in: rootView) {
      scrollTableViewToTop(tableView)
      return
    }
    if let collectionView = findDescendant(of: UICollectionView.self, in: rootView) {
      scrollCollectionViewToTop(collectionView)
      return
    }
    if let scrollView = findDescendant(of: UIScrollView.self, in: rootView) {
      scrollView.setContentOffset(
        CGPoint(x: -scrollView.adjustedContentInset.left, y: -scrollView.adjustedContentInset.top),
        animated: true
      )
    }
  }

  static func horizontalScrollViews(in rootView: UIView) -> [UIScrollView] {
    var results: [UIScrollView] = []
    collectHorizontalScrollViews(in: rootView, into: &results)
    return results
  }

  private static func collectHorizontalScrollViews(in view: UIView, into results: inout [UIScrollView]) {
    if let scrollView = view as? UIScrollView,
       scrollView.contentSize.width > scrollView.bounds.width + 1,
       scrollView.isScrollEnabled {
      results.append(scrollView)
    }
    for subview in view.subviews {
      collectHorizontalScrollViews(in: subview, into: &results)
    }
  }

  static func detachFromParentIfNeeded(_ controller: UIViewController) {
    guard controller.parent != nil else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
  }

  private static func scrollTableViewToTop(_ tableView: UITableView) {
    let sections = tableView.numberOfSections
    guard sections > 0, tableView.numberOfRows(inSection: 0) > 0 else {
      tableView.setContentOffset(
        CGPoint(x: -tableView.adjustedContentInset.left, y: -tableView.adjustedContentInset.top),
        animated: true
      )
      return
    }
    tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
  }

  private static func scrollCollectionViewToTop(_ collectionView: UICollectionView) {
    let sections = collectionView.numberOfSections
    guard sections > 0, collectionView.numberOfItems(inSection: 0) > 0 else {
      collectionView.setContentOffset(
        CGPoint(x: -collectionView.adjustedContentInset.left, y: -collectionView.adjustedContentInset.top),
        animated: true
      )
      return
    }
    collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
  }

  private static func findDescendant<T: UIView>(of type: T.Type, in view: UIView) -> T? {
    if let match = view as? T { return match }
    for subview in view.subviews {
      if let found = findDescendant(of: type, in: subview) { return found }
    }
    return nil
  }
}
