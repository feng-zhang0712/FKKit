import Foundation

/// ListKit-friendly row model for ``FKCellZeroResultsCell`` (D-88).
public struct FKCellZeroResultsRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellZeroResultsConfiguration

  public init(id: String, configuration: FKCellZeroResultsConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
