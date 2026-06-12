import FKCoreKit
import UIKit

public extension UITableView {
  /// Registers multiple CellKit cell types in one call.
  func fk_registerCellKitCells(_ registrations: FKCellRegistration...) {
    registrations.forEach { $0.register(in: self) }
  }

  /// Registers ``FKCellSectionHeaderView`` and ``FKCellSectionFooterView`` reuse identifiers.
  ///
  /// Also disables the table view's system row separators; CellKit rows draw separators with ``FKDivider``.
  func fk_registerCellKitStructureViews() {
    separatorStyle = .none
    register(
      FKCellSectionHeaderView.self,
      forHeaderFooterViewReuseIdentifier: FKCellSectionHeaderView.reuseIdentifier
    )
    register(
      FKCellSectionFooterView.self,
      forHeaderFooterViewReuseIdentifier: FKCellSectionFooterView.reuseIdentifier
    )
  }

  /// Dequeues a configured ``FKCellSectionHeaderView``.
  func fk_dequeueCellKitSectionHeader(for section: Int) -> FKCellSectionHeaderView {
    dequeueReusableHeaderFooterView(withIdentifier: FKCellSectionHeaderView.reuseIdentifier) as! FKCellSectionHeaderView
  }

  /// Registers ``FKFormSectionHeaderView`` reuse identifier.
  func fk_registerFormSectionHeaderView() {
    register(
      FKFormSectionHeaderView.self,
      forHeaderFooterViewReuseIdentifier: FKFormSectionHeaderView.reuseIdentifier
    )
  }

  /// Dequeues a configured ``FKFormSectionHeaderView``.
  func fk_dequeueFormSectionHeader(for section: Int) -> FKFormSectionHeaderView {
    dequeueReusableHeaderFooterView(withIdentifier: FKFormSectionHeaderView.reuseIdentifier) as! FKFormSectionHeaderView
  }
}
