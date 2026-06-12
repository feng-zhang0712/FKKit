import Foundation

/// ListKit-friendly row model for ``FKFormCellDualButtonCell``.
public struct FKFormDualButtonRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellDualButtonConfiguration

  /// Creates a dual button row model.
  public init(id: String, configuration: FKFormCellDualButtonConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
