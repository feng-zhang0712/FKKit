import Foundation

/// Interactive selection progress emitted by ``FKTabBar`` during paging-style transitions.
public struct FKTabBarSelectionProgress: Equatable, Sendable {
  /// Origin visible index.
  public var fromIndex: Int
  /// Destination visible index.
  public var toIndex: Int
  /// Normalized progress in `0...1`.
  public var progress: CGFloat

  /// Creates a progress snapshot.
  public init(fromIndex: Int, toIndex: Int, progress: CGFloat) {
    self.fromIndex = fromIndex
    self.toIndex = toIndex
    self.progress = progress
  }
}
