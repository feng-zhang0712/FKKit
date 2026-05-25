import Foundation

/// Horizontal layout for action row content.
public enum FKActionSheetRowAlignment: Sendable, Equatable {
  /// Centers title, icon, and accessories (system action-sheet style).
  case center
  /// Leading icon with left-aligned text (common for icon menus).
  case leading
}
