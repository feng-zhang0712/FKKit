import Foundation

/// ListKit-friendly row model for ``FKCellStatusCell`` (D-33).
public struct FKCellStatusRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellStatusConfiguration

  public init(id: String, configuration: FKCellStatusConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
