import FKCoreKit
import UIKit

/// Contract for UICollectionView cells that support reuse identifiers and view-model binding.
@MainActor
public protocol FKCellCollectionReusable: UICollectionViewCell {
  associatedtype ViewModel: Sendable

  /// Reuse identifier registered with ``UICollectionView``.
  static var reuseIdentifier: String { get }

  /// Binds `viewModel` to UI. Keep this method lightweight (no network I/O).
  func configure(with viewModel: ViewModel)
}

public extension FKCellCollectionReusable {
  /// Default reuse identifier based on type name (avoids string typos).
  static var reuseIdentifier: String { String(describing: Self.self) }
}
