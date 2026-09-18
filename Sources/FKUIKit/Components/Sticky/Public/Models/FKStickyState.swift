import Foundation

/// Lifecycle phase of a sticky target relative to the pin line.
public enum FKStickyState: String, Sendable, Equatable, CaseIterable {
  /// Target remains in its original hierarchy and scrolls with content.
  case idle
  /// Target is crossing the pin threshold; ``FKStickyProgress/value`` is between `0` and `1`.
  case sticking
  /// Target is hosted in the sticky overlay at (or push-offset from) the pin line.
  case stuck
  /// Target is leaving the stuck phase; progress decreases toward `0`.
  case unsticking
}
