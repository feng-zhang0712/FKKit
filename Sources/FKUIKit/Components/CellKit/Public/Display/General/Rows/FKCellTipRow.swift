import Foundation

/// ListKit-friendly row model for ``FKCellTipCell`` (D-57).
public struct FKCellTipRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellTipConfiguration

  public init(id: String, configuration: FKCellTipConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
