import Foundation

/// ListKit-friendly row model for ``FKCellAddressCell`` (D-43).
public struct FKCellAddressRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellAddressConfiguration

  public init(id: String, configuration: FKCellAddressConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
