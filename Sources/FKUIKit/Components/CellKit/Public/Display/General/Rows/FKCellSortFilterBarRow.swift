import Foundation

/// ListKit-friendly row model for ``FKCellSortFilterBarCell`` (D-78).
public struct FKCellSortFilterBarRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellSortFilterBarConfiguration

  public init(id: String, configuration: FKCellSortFilterBarConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
