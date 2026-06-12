import Foundation

/// Configuration for ``FKCellContactCell`` (D-18).
public struct FKCellContactConfiguration: @unchecked Sendable, Equatable {
  public var avatarConfiguration: FKAvatarConfiguration
  public var name: String
  public var detail: String?
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a contact row configuration.
  @MainActor
  public init(
    avatarConfiguration: FKAvatarConfiguration = FKAvatarConfiguration(
      layout: .init(size: .m, shape: .circle)
    ),
    name: String,
    detail: String? = nil,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.avatarConfiguration = avatarConfiguration
    self.name = name
    self.detail = detail
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellContactConfiguration {
  public static func == (lhs: FKCellContactConfiguration, rhs: FKCellContactConfiguration) -> Bool {
    lhs.name == rhs.name
      && lhs.detail == rhs.detail
      && lhs.showsDisclosure == rhs.showsDisclosure
      && lhs.isEnabled == rhs.isEnabled
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
      && lhs.avatarConfiguration.layout == rhs.avatarConfiguration.layout
  }
}
