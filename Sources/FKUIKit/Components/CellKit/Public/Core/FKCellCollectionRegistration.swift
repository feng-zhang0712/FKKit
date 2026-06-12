import FKCoreKit
import UIKit

/// Registers one or more CellKit collection cell types with a ``UICollectionView``.
public struct FKCellCollectionRegistration: Sendable {
  private let registerBlock: @MainActor @Sendable (UICollectionView) -> Void

  private init(_ registerBlock: @escaping @MainActor @Sendable (UICollectionView) -> Void) {
    self.registerBlock = registerBlock
  }

  /// Registers a ``FKCellCollectionReusable`` cell type using its default reuse identifier.
  public static func collection<Cell: FKCellCollectionReusable>(_ cellType: Cell.Type) -> FKCellCollectionRegistration {
    FKCellCollectionRegistration { collectionView in
      collectionView.register(cellType, forCellWithReuseIdentifier: Cell.reuseIdentifier)
    }
  }

  /// Applies this registration to `collectionView`.
  @MainActor
  public func register(in collectionView: UICollectionView) {
    registerBlock(collectionView)
  }
}
