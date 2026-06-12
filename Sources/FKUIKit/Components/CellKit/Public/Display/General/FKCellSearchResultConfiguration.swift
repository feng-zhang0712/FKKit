import Foundation

/// Configuration for ``FKCellSearchResultCell`` (D-66).
public struct FKCellSearchResultConfiguration: Sendable, Equatable {
  public var title: String
  public var subtitle: String?
  public var query: String
  public var leadingIcon: FKCellIconContent?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    title: String,
    subtitle: String? = nil,
    query: String = "",
    leadingIcon: FKCellIconContent? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    self.query = query
    self.leadingIcon = leadingIcon
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
