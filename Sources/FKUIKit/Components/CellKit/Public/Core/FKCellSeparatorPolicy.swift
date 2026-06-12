import Foundation

/// Controls how list separators are inset and displayed for a CellKit row.
public enum FKCellSeparatorPolicy: Sendable, Equatable {
  /// Shows a separator for non-last rows; inset follows leading content when applicable.
  case automatic

  /// Separator leading edge aligns with the title leading anchor (after icon column).
  case insetFromLeadingContent

  /// Full-width separator inside grouped cards (rich text and feature cards).
  case fullWidth

  /// Hides the separator entirely.
  case none
}
