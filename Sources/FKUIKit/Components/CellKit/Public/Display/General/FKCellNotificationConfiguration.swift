import Foundation

/// Configuration for ``FKCellNotificationCell`` (D-21).
public struct FKCellNotificationConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent
  public var title: String
  public var body: String?
  public var timestamp: String?
  public var unread: FKCellUnreadPresentation
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a notification row configuration.
  public init(
    icon: FKCellIconContent = FKCellIconContent(symbolName: "bell.fill"),
    title: String,
    body: String? = nil,
    timestamp: String? = nil,
    unread: FKCellUnreadPresentation = FKCellUnreadPresentation(),
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.icon = icon
    self.title = title
    self.body = body
    self.timestamp = timestamp
    self.unread = unread
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
