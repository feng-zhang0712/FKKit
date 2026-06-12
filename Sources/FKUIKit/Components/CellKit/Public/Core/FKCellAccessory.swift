import UIKit

/// Describes the trailing or leading accessory slot for display and settings rows.
public enum FKCellAccessory: @unchecked Sendable, Equatable {
  case none
  case disclosureIndicator
  case checkmark(isSelected: Bool)
  case switchControl(isOn: Bool)
  case value(String)
  case statusPill(FKStatusPillConfiguration)
  case badge(FKBadgeConfiguration)
  case copy(FKCopyChipConfiguration)
  case custom(id: String)
}

extension FKCellAccessory {
  public static func == (lhs: FKCellAccessory, rhs: FKCellAccessory) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
      return true
    case (.disclosureIndicator, .disclosureIndicator):
      return true
    case let (.checkmark(l), .checkmark(r)):
      return l == r
    case let (.switchControl(l), .switchControl(r)):
      return l == r
    case let (.value(l), .value(r)):
      return l == r
    case let (.statusPill(l), .statusPill(r)):
      return l == r
    case let (.badge(l), .badge(r)):
      return l == r
    case let (.copy(l), .copy(r)):
      return l == r
    case let (.custom(l), .custom(r)):
      return l == r
    default:
      return false
    }
  }
}
