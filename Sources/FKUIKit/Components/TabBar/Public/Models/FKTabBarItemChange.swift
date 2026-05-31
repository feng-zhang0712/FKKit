import Foundation

/// A single structural or content mutation for ``FKTabBar/applyChanges(_:updatePolicy:animated:completion:)``.
public struct FKTabBarItemChange: @unchecked Sendable, Equatable {
  /// Mutation kind applied to the visible strip (`visibleItems` indices).
  public enum Kind: Equatable {
    /// Inserts a tab at a visible index. Hidden items in ``FKTabBar/items`` are preserved.
    case insert(FKTabBarItem, atVisibleIndex: Int)
    /// Removes the tab at a visible index. The backing item is marked `isHidden = true`.
    case delete(visibleIndex: Int)
    /// Reorders the visible strip.
    case move(fromVisibleIndex: Int, toVisibleIndex: Int)
    /// Replaces the model at a visible index (stable `id` required).
    case update(FKTabBarItem, atVisibleIndex: Int)
  }

  /// Mutation to apply.
  public var kind: Kind

  /// Creates a change record.
  public init(kind: Kind) {
    self.kind = kind
  }
}
