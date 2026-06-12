import FKCoreKit
import UIKit

public extension UICollectionView {
  /// Registers multiple CellKit collection cell types in one call.
  func fk_registerCellKitCollectionCells(_ registrations: FKCellCollectionRegistration...) {
    registrations.forEach { $0.register(in: self) }
  }

  /// Dequeues a ``FKCellCollectionReusable`` cell.
  func dequeue<Cell: FKCellCollectionReusable>(
    _ cellType: Cell.Type,
    for indexPath: IndexPath
  ) -> Cell {
    dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
  }
}
