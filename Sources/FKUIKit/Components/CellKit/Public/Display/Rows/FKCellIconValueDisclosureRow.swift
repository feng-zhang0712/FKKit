import Foundation

/// ListKit-friendly row model for ``FKCellIconValueDisclosureCell``.
public struct FKCellIconValueDisclosureRow: Sendable, Equatable, Hashable {
  public var id: String
  public var icon: FKCellIconContent
  public var title: String
  public var subtitle: String?
  public var value: String
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an icon value disclosure row model.
  public init(
    id: String,
    icon: FKCellIconContent,
    title: String,
    subtitle: String? = nil,
    value: String,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .insetFromLeadingContent,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.value = value
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellIconValueDisclosureConfiguration {
    FKCellIconValueDisclosureConfiguration(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: value,
      showsDisclosure: showsDisclosure,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
