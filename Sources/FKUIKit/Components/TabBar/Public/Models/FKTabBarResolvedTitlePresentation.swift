import UIKit

/// Effective title layout after ``FKTabBar`` resolves overflow, Dynamic Type, and non-scrollable policies.
///
/// Read via ``FKTabBar/resolvedTitlePresentationForCurrentEnvironment()`` when debugging why tabs truncate,
/// wrap, or increase bar height.
public struct FKTabBarResolvedTitlePresentation: Equatable, Sendable {
  /// Overflow mode applied to visible tab titles.
  public var overflowMode: FKTabBarTitleOverflowMode
  /// Maximum number of title lines rendered in each tab cell.
  public var maximumTitleLines: Int
  /// When `true`, ``FKTabBar/intrinsicContentSize`` may grow taller for accessibility categories.
  public var shouldIncreaseBarHeight: Bool

  /// Creates a resolved title presentation snapshot.
  public init(
    overflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int,
    shouldIncreaseBarHeight: Bool
  ) {
    self.overflowMode = overflowMode
    self.maximumTitleLines = max(1, maximumTitleLines)
    self.shouldIncreaseBarHeight = shouldIncreaseBarHeight
  }
}
