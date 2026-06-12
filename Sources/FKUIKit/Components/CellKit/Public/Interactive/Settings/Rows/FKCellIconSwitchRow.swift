import Foundation

/// ListKit-friendly row model for ``FKCellIconSwitchCell``.
public struct FKCellIconSwitchRow: Sendable, Equatable, Hashable {
  public var id: String
  public var icon: FKCellIconContent
  public var title: String
  public var subtitle: String?
  public var isOn: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an icon switch row model.
  public init(
    id: String,
    icon: FKCellIconContent,
    title: String,
    subtitle: String? = nil,
    isOn: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .insetFromLeadingContent,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.isOn = isOn
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellIconSwitchConfiguration {
    FKCellIconSwitchConfiguration(
      icon: icon,
      title: title,
      subtitle: subtitle,
      isOn: isOn,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
