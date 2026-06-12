import Foundation

/// ListKit-friendly row model for ``FKCellStackedKeyValueCell`` (D-29).
public struct FKCellStackedKeyValueRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellStackedKeyValueConfiguration

  public init(id: String, configuration: FKCellStackedKeyValueConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
