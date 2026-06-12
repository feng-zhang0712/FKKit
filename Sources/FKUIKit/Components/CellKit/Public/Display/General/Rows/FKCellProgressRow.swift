import Foundation

/// ListKit-friendly row model for ``FKCellProgressCell`` (D-35).
public struct FKCellProgressRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellProgressConfiguration

  public init(id: String, configuration: FKCellProgressConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
