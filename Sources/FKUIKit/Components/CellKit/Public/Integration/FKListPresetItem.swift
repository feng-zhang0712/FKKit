import Foundation
/// Thin ListKit preset mapping to CellKit row models (Phase 6).
public enum FKListPresetItem: Sendable, Equatable {
  case disclosure(FKCellDisclosureRow)
  case subtitle(FKCellValueDisclosureRow)
  case keyValue(FKCellKeyValueRow)
  case icon(FKCellIconDisclosureRow)
  case switchRow(FKCellSwitchRow)
  case checkbox(FKCellCheckboxRow)
  case customValue(FKCellValueDisclosureRow)
}
