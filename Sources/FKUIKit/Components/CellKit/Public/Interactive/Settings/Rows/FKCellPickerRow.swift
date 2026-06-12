import Foundation

/// ListKit-friendly row model for ``FKCellPickerCell``.
public struct FKCellPickerRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellPickerConfiguration

  /// Creates a picker row model.
  public init(id: String, configuration: FKCellPickerConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
