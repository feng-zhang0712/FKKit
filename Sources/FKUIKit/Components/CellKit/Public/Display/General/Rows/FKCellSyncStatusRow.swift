import Foundation

/// ListKit-friendly row model for ``FKCellSyncStatusCell`` (D-36).
public struct FKCellSyncStatusRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellSyncStatusConfiguration

  public init(id: String, configuration: FKCellSyncStatusConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
