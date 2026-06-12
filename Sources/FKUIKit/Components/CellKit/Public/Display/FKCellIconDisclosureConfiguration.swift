import Foundation

/// Configuration for ``FKCellIconDisclosureCell`` (D-04).
public struct FKCellIconDisclosureConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent
  public var title: String
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an icon + title + chevron row configuration.
  public init(
    icon: FKCellIconContent,
    title: String,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .insetFromLeadingContent,
    isLastInSection: Bool = false
  ) {
    self.icon = icon
    self.title = title
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
