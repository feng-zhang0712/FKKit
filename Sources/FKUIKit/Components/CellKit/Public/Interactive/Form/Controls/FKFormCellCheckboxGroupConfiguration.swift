import Foundation

/// Single option in a checkbox group row.
public struct FKFormCheckboxOption: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var isChecked: Bool

  /// Creates a checkbox option.
  public init(id: String, title: String, isChecked: Bool = false) {
    self.id = id
    self.title = title
    self.isChecked = isChecked
  }
}

/// Configuration for ``FKFormCellCheckboxGroupCell`` (X-36, F-06 partial).
public struct FKFormCellCheckboxGroupConfiguration: Sendable, Equatable {
  public var label: String?
  public var options: [FKFormCheckboxOption]
  public var isEnabled: Bool

  /// Creates a checkbox group configuration.
  public init(
    label: String? = nil,
    options: [FKFormCheckboxOption],
    isEnabled: Bool = true
  ) {
    self.label = label
    self.options = options
    self.isEnabled = isEnabled
  }
}
