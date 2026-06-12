import Foundation

/// ListKit-friendly row model for ``FKCellFileCell`` (D-45).
public struct FKCellFileRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellFileConfiguration

  public init(id: String, configuration: FKCellFileConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
