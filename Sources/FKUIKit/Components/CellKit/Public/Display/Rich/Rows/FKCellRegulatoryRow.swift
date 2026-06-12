import Foundation

/// ListKit-friendly row model for ``FKCellRegulatoryCell``.
public struct FKCellRegulatoryRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellRegulatoryConfiguration

  /// Creates a regulatory row model.
  public init(id: String, configuration: FKCellRegulatoryConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
