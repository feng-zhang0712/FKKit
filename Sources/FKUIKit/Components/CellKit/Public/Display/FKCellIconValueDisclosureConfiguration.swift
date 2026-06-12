import Foundation

/// Configuration for ``FKCellIconValueDisclosureCell`` (D-14).
public struct FKCellIconValueDisclosureConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent
  public var title: String
  public var subtitle: String?
  public var value: String
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an icon + dual-line + value + chevron row configuration.
  public init(
    icon: FKCellIconContent,
    title: String,
    subtitle: String? = nil,
    value: String,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .insetFromLeadingContent,
    isLastInSection: Bool = false
  ) {
    self.icon = icon
    self.title = title
    self.subtitle = subtitle
    self.value = value
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
