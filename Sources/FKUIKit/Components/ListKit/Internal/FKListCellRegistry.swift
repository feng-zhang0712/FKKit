import FKCoreKit
import UIKit

/// Registry mapping custom cell identifiers to dequeue/configure closures.
@MainActor
final class FKListTableCellRegistry {
  private struct Entry {
    let configure: (UITableViewCell, FKListItemPayload) -> Void
    let reuseIdentifier: String
  }

  private var entries: [String: Entry] = [:]

  func register<Cell: FKListTableCellConfigurable>(
    _ cellType: Cell.Type,
    forPayloadType _: Cell.Item.Type,
    in tableView: UITableView
  ) {
    let reuseID = String(describing: cellType)
    tableView.register(cellType, forCellReuseIdentifier: reuseID)
    entries[reuseID] = Entry(
      configure: { cell, payload in
        guard let typedCell = cell as? Cell,
              let item = payload.unwrap(Cell.Item.self) else { return }
        typedCell.configure(with: item)
      },
      reuseIdentifier: reuseID
    )
  }

  func entry(for identifier: String) -> (reuseIdentifier: String, configure: (UITableViewCell, FKListItemPayload) -> Void)? {
    guard let entry = entries[identifier] else { return nil }
    return (entry.reuseIdentifier, entry.configure)
  }
}

/// Registry mapping custom collection cell identifiers to dequeue/configure closures.
@MainActor
final class FKListCollectionCellRegistry {
  private struct Entry {
    let configure: (UICollectionViewCell, FKListItemPayload) -> Void
    let reuseIdentifier: String
  }

  private var entries: [String: Entry] = [:]

  func register<Cell: FKListCollectionCellConfigurable>(
    _ cellType: Cell.Type,
    forPayloadType _: Cell.Item.Type,
    in collectionView: UICollectionView
  ) {
    let reuseID = String(describing: cellType)
    collectionView.register(cellType, forCellWithReuseIdentifier: reuseID)
    entries[reuseID] = Entry(
      configure: { cell, payload in
        guard let typedCell = cell as? Cell,
              let item = payload.unwrap(Cell.Item.self) else { return }
        typedCell.configure(with: item)
      },
      reuseIdentifier: reuseID
    )
  }

  func entry(for identifier: String) -> (reuseIdentifier: String, configure: (UICollectionViewCell, FKListItemPayload) -> Void)? {
    guard let entry = entries[identifier] else { return nil }
    return (entry.reuseIdentifier, entry.configure)
  }
}
