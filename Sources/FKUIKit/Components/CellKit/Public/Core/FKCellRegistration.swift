import FKCoreKit
import UIKit

/// Registers one or more CellKit table cell types with a ``UITableView``.
public struct FKCellRegistration: Sendable {
  private let registerBlock: @MainActor @Sendable (UITableView) -> Void

  private init(_ registerBlock: @escaping @MainActor @Sendable (UITableView) -> Void) {
    self.registerBlock = registerBlock
  }

  /// Registers a ``FKCellReusable`` cell type using its default reuse identifier.
  public static func table<Cell: FKCellReusable>(_ cellType: Cell.Type) -> FKCellRegistration {
    FKCellRegistration { tableView in
      tableView.register(cellType)
    }
  }

  /// Applies this registration to `tableView`.
  @MainActor
  public func register(in tableView: UITableView) {
    registerBlock(tableView)
  }
}
