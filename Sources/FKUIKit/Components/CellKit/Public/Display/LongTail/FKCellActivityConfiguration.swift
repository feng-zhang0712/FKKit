import Foundation

/// Configuration for ``FKCellActivityCell`` (D-49).
public struct FKCellActivityConfiguration: Sendable, Equatable {
  public var actorName: String
  public var actionText: String
  public var targetPreview: String?
  public var timestamp: String?
  public var avatarConfiguration: FKAvatarConfiguration
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    actorName: String,
    actionText: String,
    targetPreview: String? = nil,
    timestamp: String? = nil,
    avatarConfiguration: FKAvatarConfiguration = .init(),
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.actorName = actorName
    self.actionText = actionText
    self.targetPreview = targetPreview
    self.timestamp = timestamp
    self.avatarConfiguration = avatarConfiguration
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
