import Foundation

/// Configuration for ``FKCellConversationCell`` (D-20).
public struct FKCellConversationConfiguration: @unchecked Sendable, Equatable {
  public var avatarConfiguration: FKAvatarConfiguration
  public var title: String
  public var preview: String?
  public var timestamp: String?
  public var unread: FKCellUnreadPresentation
  public var isPinned: Bool
  public var isMuted: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a conversation preview row configuration.
  @MainActor
  public init(
    avatarConfiguration: FKAvatarConfiguration = FKAvatarConfiguration(
      layout: .init(size: .l, shape: .circle)
    ),
    title: String,
    preview: String? = nil,
    timestamp: String? = nil,
    unread: FKCellUnreadPresentation = FKCellUnreadPresentation(),
    isPinned: Bool = false,
    isMuted: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.avatarConfiguration = avatarConfiguration
    self.title = title
    self.preview = preview
    self.timestamp = timestamp
    self.unread = unread
    self.isPinned = isPinned
    self.isMuted = isMuted
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellConversationConfiguration {
  public static func == (lhs: FKCellConversationConfiguration, rhs: FKCellConversationConfiguration) -> Bool {
    lhs.title == rhs.title
      && lhs.preview == rhs.preview
      && lhs.timestamp == rhs.timestamp
      && lhs.unread == rhs.unread
      && lhs.isPinned == rhs.isPinned
      && lhs.isMuted == rhs.isMuted
      && lhs.isEnabled == rhs.isEnabled
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
      && lhs.avatarConfiguration.layout == rhs.avatarConfiguration.layout
  }
}
