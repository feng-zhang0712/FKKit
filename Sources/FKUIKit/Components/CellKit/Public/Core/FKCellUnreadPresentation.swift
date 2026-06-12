import UIKit

/// Shared unread styling for message and notification feed rows (D-20, D-21).
public struct FKCellUnreadPresentation: @unchecked Sendable, Equatable {
  public var isUnread: Bool
  public var usesBoldTitle: Bool
  public var showsBadge: Bool
  public var badgeCount: Int
  public var backgroundTint: UIColor?

  /// Creates unread presentation settings.
  public init(
    isUnread: Bool = false,
    usesBoldTitle: Bool = true,
    showsBadge: Bool = true,
    badgeCount: Int = 0,
    backgroundTint: UIColor? = nil
  ) {
    self.isUnread = isUnread
    self.usesBoldTitle = usesBoldTitle
    self.showsBadge = showsBadge
    self.badgeCount = max(0, badgeCount)
    self.backgroundTint = backgroundTint
  }
}

extension FKCellUnreadPresentation {
  public static func == (lhs: FKCellUnreadPresentation, rhs: FKCellUnreadPresentation) -> Bool {
    lhs.isUnread == rhs.isUnread
      && lhs.usesBoldTitle == rhs.usesBoldTitle
      && lhs.showsBadge == rhs.showsBadge
      && lhs.badgeCount == rhs.badgeCount
      && lhs.backgroundTint == rhs.backgroundTint
  }
}
