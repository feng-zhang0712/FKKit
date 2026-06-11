import Foundation

/// Overrides automatic visibility (for example global “do not disturb” or marketing overlays).
public enum FKBadgeVisibilityPolicy: Sendable, Equatable {
  /// Hide when content is empty, count ≤ 0, or invalid numeric input.
  case automatic
  /// Always hidden regardless of content.
  case forcedHidden
  /// Always visible when drawable content is set. A numeric payload of `0` renders `"0"`; empty payload (`.clear`) still hides.
  case forcedVisible
}
