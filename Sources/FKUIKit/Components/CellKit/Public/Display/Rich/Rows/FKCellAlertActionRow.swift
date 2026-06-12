import Foundation

/// ListKit-friendly row model for ``FKCellAlertActionCell``.
public struct FKCellAlertActionRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellAlertActionConfiguration

  public init(id: String, configuration: FKCellAlertActionConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
