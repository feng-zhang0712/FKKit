import Foundation

/// Presentation style for ``FKCellRichTextCell`` (D-07, D-22).
public enum FKCellRichTextStyle: Sendable, Equatable {
  /// Bold headline, multi-line body, optional footer link (D-07).
  case standard
  /// Compact announcement with optional icon and timestamp (D-22).
  case compact
}

/// Configuration for ``FKCellRichTextCell`` (D-07, D-22).
public struct FKCellRichTextConfiguration: Sendable, Equatable {
  public var style: FKCellRichTextStyle
  public var leadingIcon: FKCellIconContent?
  public var title: String
  public var body: String
  public var bodyLinkRanges: [FKCellLinkRange]
  public var footerAction: FKCellActionLink?
  public var separatorBeforeFooter: Bool
  public var timestamp: String?
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a rich text card configuration.
  public init(
    style: FKCellRichTextStyle = .standard,
    leadingIcon: FKCellIconContent? = nil,
    title: String,
    body: String,
    bodyLinkRanges: [FKCellLinkRange] = [],
    footerAction: FKCellActionLink? = nil,
    separatorBeforeFooter: Bool = true,
    timestamp: String? = nil,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.style = style
    self.leadingIcon = leadingIcon
    self.title = title
    self.body = body
    self.bodyLinkRanges = bodyLinkRanges
    self.footerAction = footerAction
    self.separatorBeforeFooter = separatorBeforeFooter
    self.timestamp = timestamp
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
