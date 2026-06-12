import Foundation

/// ListKit-friendly row model for ``FKFormCellRadioGroupCell`` (F-06).
public struct FKFormRadioGroupRow: Sendable, Equatable, Hashable {
  public var id: String
  public var selectedOptionID: String?
  public var configuration: FKFormCellRadioGroupConfiguration

  /// Creates a radio group row model.
  public init(
    id: String,
    selectedOptionID: String? = nil,
    configuration: FKFormCellRadioGroupConfiguration
  ) {
    self.id = id
    self.selectedOptionID = selectedOptionID
    self.configuration = configuration
  }

  /// Convenience builder for F-06.
  public init(
    id: String,
    selectedOptionID: String? = nil,
    label: String? = nil,
    options: [FKFormRadioOption]
  ) {
    self.id = id
    self.selectedOptionID = selectedOptionID
    self.configuration = .radioGroup(label: label, options: options, selectedOptionID: selectedOptionID)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
