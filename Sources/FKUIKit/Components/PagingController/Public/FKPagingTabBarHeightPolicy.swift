import UIKit

/// Tab strip height policy for the embedded ``FKTabBar`` in ``FKPagingController``.
public enum FKPagingTabBarHeightPolicy: Equatable {
  /// Fixed height in points (minimum 36).
  case fixed(CGFloat)
  /// Uses ``FKTabBar/intrinsicContentSize`` height, including Dynamic Type growth.
  case automatic
}
