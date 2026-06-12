import Foundation

/// Configuration for ``FKCellBadgeCell`` (D-34).
public struct FKCellBadgeConfiguration: @unchecked Sendable, Equatable {
  public var leadingIcon: FKCellIconContent?
  public var title: String
  public var subtitle: String?
  public var badgeConfiguration: FKBadgeConfiguration
  public var badgeCount: Int
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    leadingIcon: FKCellIconContent? = nil,
    title: String,
    subtitle: String? = nil,
    badgeConfiguration: FKBadgeConfiguration = FKBadgeConfiguration(),
    badgeCount: Int = 0,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.leadingIcon = leadingIcon
    self.title = title
    self.subtitle = subtitle
    self.badgeConfiguration = badgeConfiguration
    self.badgeCount = badgeCount
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
