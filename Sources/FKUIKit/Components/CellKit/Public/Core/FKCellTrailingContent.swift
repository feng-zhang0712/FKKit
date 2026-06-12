import UIKit

/// Trailing slot content for status and badge display rows (D-33, D-34).
public enum FKCellTrailingContent: @unchecked Sendable, Equatable {
  case none
  case disclosure
  case value(String)
  case statusPill(FKStatusPillConfiguration)
  case badge(FKBadgeConfiguration)
  case custom(id: String)
}

extension FKCellTrailingContent {
  public static func == (lhs: FKCellTrailingContent, rhs: FKCellTrailingContent) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
      return true
    case (.disclosure, .disclosure):
      return true
    case let (.value(l), .value(r)):
      return l == r
    case let (.statusPill(l), .statusPill(r)):
      return l == r
    case let (.badge(l), .badge(r)):
      return l == r
    case let (.custom(l), .custom(r)):
      return l == r
    default:
      return false
    }
  }
}
