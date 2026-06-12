import Foundation

/// ListKit-friendly row model for ``FKCellRecentSearchCell`` (D-67).
public struct FKCellRecentSearchRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellRecentSearchConfiguration

  public init(id: String, configuration: FKCellRecentSearchConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
