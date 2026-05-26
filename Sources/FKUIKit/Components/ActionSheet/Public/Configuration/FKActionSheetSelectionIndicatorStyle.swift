import Foundation

/// Visual treatment for a selected row when ``FKActionSheetSelectionConfiguration/mode`` is active.
public enum FKActionSheetSelectionIndicatorStyle: Equatable, Sendable {
  /// Emphasizes the title with ``FKActionSheetAppearance/selectedTitleColor`` (no accessory image).
  case highlightedTitle
  /// Shows a check symbol when the row is selected.
  case check
  /// Shows a radio symbol on every row (checked vs unchecked by selection state).
  case radio
  /// Check symbol plus highlighted title.
  case checkAndHighlightedTitle
  /// Radio symbol plus highlighted title.
  case radioAndHighlightedTitle
}

extension FKActionSheetSelectionIndicatorStyle {
  var usesCheck: Bool {
    switch self {
    case .check, .checkAndHighlightedTitle:
      return true
    case .highlightedTitle, .radio, .radioAndHighlightedTitle:
      return false
    }
  }

  var usesRadio: Bool {
    switch self {
    case .radio, .radioAndHighlightedTitle:
      return true
    case .highlightedTitle, .check, .checkAndHighlightedTitle:
      return false
    }
  }

  var usesHighlightedTitle: Bool {
    switch self {
    case .highlightedTitle, .checkAndHighlightedTitle, .radioAndHighlightedTitle:
      return true
    case .check, .radio:
      return false
    }
  }
}
