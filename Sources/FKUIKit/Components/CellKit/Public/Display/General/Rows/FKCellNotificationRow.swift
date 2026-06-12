import Foundation

/// ListKit-friendly row model for ``FKCellNotificationCell`` (D-21).
public struct FKCellNotificationRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellNotificationConfiguration

  public init(id: String, configuration: FKCellNotificationConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
