import Foundation

/// ListKit-friendly row model for ``FKFormCellCheckboxGroupCell``.
public struct FKFormCheckboxGroupRow: Sendable, Equatable, Hashable {
  public var id: String
  public var options: [FKFormCheckboxOption]
  public var configuration: FKFormCellCheckboxGroupConfiguration

  /// Creates a checkbox group row model.
  public init(
    id: String,
    options: [FKFormCheckboxOption],
    configuration: FKFormCellCheckboxGroupConfiguration
  ) {
    self.id = id
    self.options = options
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
