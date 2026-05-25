import Foundation

/// Visual treatment for a selected row when ``FKActionSheetSelectionConfiguration/mode`` is active.
public enum FKActionSheetSelectionIndicatorStyle: Equatable, Sendable {
  /// Emphasizes the title with semibold weight and tint (no accessory image).
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
