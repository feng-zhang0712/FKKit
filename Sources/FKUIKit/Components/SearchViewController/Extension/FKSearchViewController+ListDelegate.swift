import UIKit

extension FKSearchViewController: FKListDelegate {
  public func list(_ list: FKDiffableTableViewController, didSelect item: FKListItemID) {
    if let handler = callbacks.onResultSelected {
      handler(item)
    } else {
      delegate?.searchViewController(self, didSelect: item)
    }
  }
}
