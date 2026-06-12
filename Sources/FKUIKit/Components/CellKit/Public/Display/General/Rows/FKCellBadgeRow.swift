import Foundation

/// ListKit-friendly row model for ``FKCellBadgeCell`` (D-34).
public struct FKCellBadgeRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellBadgeConfiguration

  public init(id: String, configuration: FKCellBadgeConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
