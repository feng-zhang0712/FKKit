import Foundation

/// Layout style for ``FKCellProfileCell`` (D-17).
public enum FKCellProfileLayout: Sendable, Equatable {
  case horizontal
  case centered
}

/// Trailing accessory for profile rows.
public enum FKCellProfileAccessory: Sendable, Equatable {
  case none
  case disclosure
  case text(String)
}

/// Configuration for ``FKCellProfileCell`` (D-17).
public struct FKCellProfileConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKCellProfileLayout
  public var avatarConfiguration: FKAvatarConfiguration
  public var title: String
  public var subtitle: String?
  public var accessory: FKCellProfileAccessory
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a profile row configuration.
  @MainActor
  public init(
    layout: FKCellProfileLayout = .horizontal,
    avatarConfiguration: FKAvatarConfiguration = FKAvatarConfiguration(
      layout: .init(size: .l, shape: .circle)
    ),
    title: String,
    subtitle: String? = nil,
    accessory: FKCellProfileAccessory = .disclosure,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.layout = layout
    self.avatarConfiguration = avatarConfiguration
    self.title = title
    self.subtitle = subtitle
    self.accessory = accessory
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellProfileConfiguration {
  public static func == (lhs: FKCellProfileConfiguration, rhs: FKCellProfileConfiguration) -> Bool {
    lhs.layout == rhs.layout
      && lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle
      && lhs.accessory == rhs.accessory
      && lhs.isEnabled == rhs.isEnabled
      && lhs.separatorPolicy == rhs.separatorPolicy
      && lhs.isLastInSection == rhs.isLastInSection
      && lhs.avatarConfiguration.layout == rhs.avatarConfiguration.layout
  }
}
