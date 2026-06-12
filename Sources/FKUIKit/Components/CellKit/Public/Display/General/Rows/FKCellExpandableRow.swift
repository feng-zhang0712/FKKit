import Foundation

/// ListKit-friendly row model for ``FKCellExpandableCell`` (D-64, D-65).
public struct FKCellExpandableRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellExpandableConfiguration

  public init(id: String, configuration: FKCellExpandableConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
