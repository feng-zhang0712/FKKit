import Foundation

/// ListKit-friendly row model for ``FKCellSearchResultCell`` (D-66).
public struct FKCellSearchResultRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellSearchResultConfiguration

  public init(id: String, configuration: FKCellSearchResultConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
