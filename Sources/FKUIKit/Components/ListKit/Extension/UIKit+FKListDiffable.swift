#if canImport(UIKit)
import UIKit

public extension UITableView {
  /// Applies a diffable data source snapshot with an explicit animation flag.
  func fk_applyDiffableDataSourceSnapshot<Section, Item>(
    _ dataSource: UITableViewDiffableDataSource<Section, Item>,
    animatingDifferences: Bool,
    snapshot: NSDiffableDataSourceSnapshot<Section, Item>,
    completion: (() -> Void)? = nil
  ) where Section: Hashable & Sendable, Item: Hashable & Sendable {
    dataSource.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
  }
}

public extension UICollectionView {
  /// Applies a diffable data source snapshot with an explicit animation flag.
  func fk_applyDiffableDataSourceSnapshot<Section, Item>(
    _ dataSource: UICollectionViewDiffableDataSource<Section, Item>,
    animatingDifferences: Bool,
    snapshot: NSDiffableDataSourceSnapshot<Section, Item>,
    completion: (() -> Void)? = nil
  ) where Section: Hashable & Sendable, Item: Hashable & Sendable {
    dataSource.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
  }
}
#endif
