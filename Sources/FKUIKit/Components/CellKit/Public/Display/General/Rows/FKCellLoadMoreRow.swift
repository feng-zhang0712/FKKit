import Foundation

/// ListKit-friendly row model for ``FKCellLoadMoreCell`` (D-79).
public struct FKCellLoadMoreRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellLoadMoreConfiguration

  public init(id: String, configuration: FKCellLoadMoreConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
