import Foundation

/// ListKit-friendly row model for ``FKFormCellPickerCell``.
public struct FKFormPickerRow: Sendable, Equatable, Hashable {
  public var id: String
  public var value: String?
  public var configuration: FKFormCellPickerConfiguration

  /// Creates a picker row model.
  public init(
    id: String,
    value: String? = nil,
    configuration: FKFormCellPickerConfiguration
  ) {
    self.id = id
    self.value = value
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
