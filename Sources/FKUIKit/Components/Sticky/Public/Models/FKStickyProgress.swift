import CoreGraphics
import Foundation

/// Snapshot of sticky transition progress for a single target.
public struct FKStickyProgress: Sendable, Equatable {
  /// Normalized progress in `0...1` within ``FKStickyConfiguration/transitionDistance``.
  public var value: CGFloat

  /// Discrete lifecycle state at the time of the snapshot.
  public var state: FKStickyState

  /// Creates a progress snapshot.
  public init(value: CGFloat, state: FKStickyState) {
    self.value = min(max(value, 0), 1)
    self.state = state
  }

  /// Idle progress (`value == 0`, `state == .idle`).
  public static let idle = FKStickyProgress(value: 0, state: .idle)

  /// Fully stuck progress (`value == 1`, `state == .stuck`).
  public static let stuck = FKStickyProgress(value: 1, state: .stuck)
}
