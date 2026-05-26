import Foundation

/// Why an action sheet was dismissed.
public enum FKActionSheetDismissReason: Equatable, Sendable {
  /// User chose a non-cancel action (sheet may dismiss before the handler runs).
  case actionSelected
  /// User tapped an action with `.cancel` style or an explicit cancel row.
  case userCancel
  /// User tapped the backdrop.
  case tapOutside
  /// ``FKActionSheet/dismiss(reason:animated:completion:)`` or equivalent API.
  case programmatic
}
