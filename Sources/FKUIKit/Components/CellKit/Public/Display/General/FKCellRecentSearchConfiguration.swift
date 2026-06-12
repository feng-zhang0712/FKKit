import Foundation

/// Configuration for ``FKCellRecentSearchCell`` (D-67).
public struct FKCellRecentSearchConfiguration: Sendable, Equatable {
  public var query: String
  public var showsDeleteButton: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    query: String,
    showsDeleteButton: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.query = query
    self.showsDeleteButton = showsDeleteButton
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
