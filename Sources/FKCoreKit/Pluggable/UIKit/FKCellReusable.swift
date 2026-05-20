#if canImport(UIKit)
  import UIKit

  // MARK: - Cell reusable

  /// Contract for UITableView cells that support reuse identifiers and view-model binding.
  ///
  /// Conform in feature modules; list infrastructure depends on this protocol instead of
  /// concrete cell subclasses.
  @MainActor
  public protocol FKCellReusable: UITableViewCell {
    associatedtype ViewModel: Sendable

    /// Reuse identifier registered with `UITableView`.
    static var reuseIdentifier: String { get }

    /// Binds `viewModel` to UI. Keep this method lightweight (no network I/O).
    func configure(with viewModel: ViewModel)
  }

  public extension FKCellReusable {
    /// Default reuse identifier based on type name (avoids string typos).
    static var reuseIdentifier: String { String(describing: Self.self) }
  }

  // MARK: - List cell configurable

  /// Binds a reusable table cell to a stable view-model type (ListKit-style contract).
  @MainActor
  public protocol FKListTableCellConfigurable: UITableViewCell {
    associatedtype Item: Sendable
    func configure(with item: Item)
  }

  /// Binds a reusable collection cell to a stable view-model type.
  @MainActor
  public protocol FKListCollectionCellConfigurable: UICollectionViewCell {
    associatedtype Item: Sendable
    func configure(with item: Item)
  }

  // MARK: - UITableView helpers

  public extension UITableView {
    /// Registers a ``FKCellReusable`` cell type.
    func register<Cell: FKCellReusable>(_ cellType: Cell.Type) {
      register(cellType, forCellReuseIdentifier: Cell.reuseIdentifier)
    }

    /// Dequeues a ``FKCellReusable`` cell.
    func dequeue<Cell: FKCellReusable>(_ cellType: Cell.Type, for indexPath: IndexPath) -> Cell {
      dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }
  }

  public extension UICollectionView {
    /// Registers a ``FKListCollectionCellConfigurable`` cell type using its type name.
    func register<Cell: FKListCollectionCellConfigurable>(_ cellType: Cell.Type) {
      register(cellType, forCellWithReuseIdentifier: String(describing: Cell.self))
    }

    /// Dequeues a ``FKListCollectionCellConfigurable`` cell.
    func dequeue<Cell: FKListCollectionCellConfigurable>(
      _ cellType: Cell.Type,
      for indexPath: IndexPath
    ) -> Cell {
      dequeueReusableCell(withReuseIdentifier: String(describing: Cell.self), for: indexPath) as! Cell
    }
  }
#endif
