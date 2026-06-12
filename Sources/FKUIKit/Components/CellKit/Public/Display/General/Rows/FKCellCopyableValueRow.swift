import Foundation

/// ListKit-friendly row model for ``FKCellCopyableValueCell`` (D-39).
public struct FKCellCopyableValueRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellCopyableValueConfiguration

  public init(id: String, configuration: FKCellCopyableValueConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
