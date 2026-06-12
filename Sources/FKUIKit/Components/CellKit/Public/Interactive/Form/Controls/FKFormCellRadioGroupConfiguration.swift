import Foundation

/// Single option in a radio group row.
public struct FKFormRadioOption: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String

  /// Creates a radio option.
  public init(id: String, title: String) {
    self.id = id
    self.title = title
  }
}

/// Configuration for ``FKFormCellRadioGroupCell`` (X-37, F-06).
public struct FKFormCellRadioGroupConfiguration: Sendable, Equatable {
  public var label: String?
  public var options: [FKFormRadioOption]
  public var selectedOptionID: String?
  public var isEnabled: Bool

  /// Creates a radio group configuration.
  public init(
    label: String? = nil,
    options: [FKFormRadioOption],
    selectedOptionID: String? = nil,
    isEnabled: Bool = true
  ) {
    self.label = label
    self.options = options
    self.selectedOptionID = selectedOptionID
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-06)

public extension FKFormCellRadioGroupConfiguration {
  /// Radio group preset (F-06).
  static func radioGroup(
    label: String? = nil,
    options: [FKFormRadioOption],
    selectedOptionID: String? = nil
  ) -> FKFormCellRadioGroupConfiguration {
    FKFormCellRadioGroupConfiguration(
      label: label,
      options: options,
      selectedOptionID: selectedOptionID
    )
  }
}
