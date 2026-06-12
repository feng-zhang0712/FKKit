import FKCoreKit
import UIKit
/// Configures UITableView cells from ``FKListPresetItem`` without duplicate layout code.
@MainActor
public enum FKListPresetCellConfigurator {
  public static func configure(cell: UITableViewCell, with item: FKListPresetItem) {
    switch item {
    case let .disclosure(row):
      (cell as? FKCellDisclosureCell)?.configure(with: row)
    case let .subtitle(row), let .customValue(row):
      (cell as? FKCellValueDisclosureCell)?.configure(with: row)
    case let .keyValue(row):
      (cell as? FKCellKeyValueCell)?.configure(with: row)
    case let .icon(row):
      (cell as? FKCellIconDisclosureCell)?.configure(with: row)
    case let .switchRow(row):
      (cell as? FKCellSwitchCell)?.configure(with: row)
    case let .checkbox(row):
      (cell as? FKCellCheckboxCell)?.configure(with: row)
    }
  }
}
