import Foundation

/// ListKit-friendly row model for ``FKFormCellSystemPickerCell``.
public struct FKFormCellSystemPickerRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellSystemPickerConfiguration
  public var summary: String

  public init(
    id: String,
    configuration: FKFormCellSystemPickerConfiguration,
    summary: String = ""
  ) {
    self.id = id
    self.configuration = configuration
    self.summary = summary
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
