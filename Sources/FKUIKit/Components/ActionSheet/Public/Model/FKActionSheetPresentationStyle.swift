import Foundation

/// Visual placement of an action sheet, aligned with common UIKit presentation patterns.
public enum FKActionSheetPresentationStyle: String, Sendable, Equatable, CaseIterable {
  /// Bottom-anchored sheet (default HIG action sheet).
  case bottom
  /// Centered card on a dimmed full-screen backdrop (home-panel / context-menu style).
  case centered
  /// Popover anchored to a source view or bar button (typical on iPad).
  case popover
}
