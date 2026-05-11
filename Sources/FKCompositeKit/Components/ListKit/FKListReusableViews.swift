import UIKit

// MARK: - Table

/// Binds a reusable ``UITableViewCell`` to a stable view-model type.
///
/// Keep ``configure(with:)`` free of networking and heavy work; it runs on the main actor while scrolling.
@MainActor
public protocol FKListTableCellConfigurable: UITableViewCell {
  associatedtype Item
  func configure(with item: Item)
}

// MARK: - Collection

/// Binds a reusable ``UICollectionViewCell`` to a stable view-model type.
@MainActor
public protocol FKListCollectionCellConfigurable: UICollectionViewCell {
  associatedtype Item
  func configure(with item: Item)
}
