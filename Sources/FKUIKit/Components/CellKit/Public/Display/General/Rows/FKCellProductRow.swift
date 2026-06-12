import Foundation

/// ListKit-friendly row model for ``FKCellProductCell`` (D-28).
public struct FKCellProductRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellProductConfiguration

  public init(id: String, configuration: FKCellProductConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
