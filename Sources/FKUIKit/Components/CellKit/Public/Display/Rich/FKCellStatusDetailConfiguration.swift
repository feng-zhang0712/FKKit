import UIKit

/// Configuration for ``FKCellStatusDetailCell`` (D-08).
public struct FKCellStatusDetailConfiguration: Sendable, Equatable {
  public var leadingIcon: FKCellIconContent?
  public var title: String
  public var statusText: String?
  public var statusColor: UIColor
  public var body: String
  public var bodyLinkRanges: [FKCellLinkRange]
  public var footerAction: FKCellActionLink?
  public var separatorBeforeFooter: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a status detail card configuration.
  public init(
    leadingIcon: FKCellIconContent? = nil,
    title: String,
    statusText: String? = nil,
    statusColor: UIColor = .systemRed,
    body: String,
    bodyLinkRanges: [FKCellLinkRange] = [],
    footerAction: FKCellActionLink? = nil,
    separatorBeforeFooter: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.leadingIcon = leadingIcon
    self.title = title
    self.statusText = statusText
    self.statusColor = statusColor
    self.body = body
    self.bodyLinkRanges = bodyLinkRanges
    self.footerAction = footerAction
    self.separatorBeforeFooter = separatorBeforeFooter
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellStatusDetailConfiguration {
  public static func == (lhs: FKCellStatusDetailConfiguration, rhs: FKCellStatusDetailConfiguration) -> Bool {
    lhs.leadingIcon == rhs.leadingIcon
      && lhs.title == rhs.title
      && lhs.statusText == rhs.statusText
      && lhs.statusColor.isEqual(rhs.statusColor)
      && lhs.body == rhs.body
      && lhs.bodyLinkRanges == rhs.bodyLinkRanges
      && lhs.footerAction == rhs.footerAction
      && lhs.separatorBeforeFooter == rhs.separatorBeforeFooter
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
  }
}
