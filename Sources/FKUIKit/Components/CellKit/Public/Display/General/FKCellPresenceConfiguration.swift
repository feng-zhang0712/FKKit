import Foundation

/// Configuration for ``FKCellPresenceCell`` (D-19).
public struct FKCellPresenceConfiguration: @unchecked Sendable, Equatable {
  public var avatarConfiguration: FKAvatarConfiguration
  public var name: String
  public var statusText: String?
  public var presenceState: FKPresenceState
  public var timestamp: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a presence row configuration.
  @MainActor
  public init(
    avatarConfiguration: FKAvatarConfiguration = FKAvatarConfiguration(
      layout: .init(size: .m, shape: .circle)
    ),
    name: String,
    statusText: String? = nil,
    presenceState: FKPresenceState = .offline,
    timestamp: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.avatarConfiguration = avatarConfiguration
    self.name = name
    self.statusText = statusText
    self.presenceState = presenceState
    self.timestamp = timestamp
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellPresenceConfiguration {
  public static func == (lhs: FKCellPresenceConfiguration, rhs: FKCellPresenceConfiguration) -> Bool {
    lhs.name == rhs.name
      && lhs.statusText == rhs.statusText
      && lhs.presenceState == rhs.presenceState
      && lhs.timestamp == rhs.timestamp
      && lhs.isEnabled == rhs.isEnabled
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
      && lhs.avatarConfiguration.layout == rhs.avatarConfiguration.layout
  }
}
