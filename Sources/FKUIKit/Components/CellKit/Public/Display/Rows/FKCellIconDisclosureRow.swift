import Foundation

/// ListKit-friendly row model for ``FKCellIconDisclosureCell``.
public struct FKCellIconDisclosureRow: Sendable, Equatable, Hashable {
  public var id: String
  public var icon: FKCellIconContent
  public var title: String
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an icon disclosure row model.
  public init(
    id: String,
    icon: FKCellIconContent,
    title: String,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .insetFromLeadingContent,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.icon = icon
    self.title = title
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellIconDisclosureConfiguration {
    FKCellIconDisclosureConfiguration(
      icon: icon,
      title: title,
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
