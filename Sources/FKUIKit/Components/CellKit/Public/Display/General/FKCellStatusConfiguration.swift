import Foundation

/// Configuration for ``FKCellStatusCell`` (D-33).
public struct FKCellStatusConfiguration: Sendable, Equatable {
  public var leadingIcon: FKCellIconContent?
  public var title: String
  public var trailing: FKCellTrailingContent
  public var badgeCount: Int
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    leadingIcon: FKCellIconContent? = nil,
    title: String,
    trailing: FKCellTrailingContent = .none,
    badgeCount: Int = 0,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.leadingIcon = leadingIcon
    self.title = title
    self.trailing = trailing
    self.badgeCount = badgeCount
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
