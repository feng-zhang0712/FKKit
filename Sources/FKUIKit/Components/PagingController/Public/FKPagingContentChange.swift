import Foundation

/// A single mutation applied by ``FKPagingController/applyContentChanges(_:updatePolicy:animated:completion:)``.
public enum FKPagingContentChange: Equatable, Sendable {
  /// Forwards a tab-strip mutation to ``FKTabBar/applyChanges(_:updatePolicy:animated:completion:)``.
  case tab(FKTabBarItemChange)
  /// Drops the cached or eager page at `index` and resizes storage when structural tab changes require it.
  case invalidatePage(at: Int)
}
