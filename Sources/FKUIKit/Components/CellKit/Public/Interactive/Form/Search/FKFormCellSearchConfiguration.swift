import Foundation

/// Configuration for ``FKFormCellSearchCell`` (X-26–X-29).
public struct FKFormCellSearchConfiguration: Sendable, Equatable {
  public var style: FKFormSearchCellStyle
  public var placeholder: String?
  public var searchFieldConfiguration: FKSearchFieldConfiguration
  public var isEnabled: Bool

  /// Creates an embedded search row configuration.
  public init(
    style: FKFormSearchCellStyle = .capsule,
    placeholder: String? = "Search",
    searchFieldConfiguration: FKSearchFieldConfiguration? = nil,
    isEnabled: Bool = true
  ) {
    self.style = style
    self.placeholder = placeholder
    self.searchFieldConfiguration = searchFieldConfiguration ?? FKFormSearchCellStyle.searchFieldConfiguration(for: style)
    self.isEnabled = isEnabled
  }
}
