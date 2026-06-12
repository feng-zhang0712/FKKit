import Foundation

/// ListKit-friendly row model for ``FKCellStepListCell`` (D-50).
public struct FKCellStepListRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellStepListConfiguration

  public init(id: String, configuration: FKCellStepListConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
