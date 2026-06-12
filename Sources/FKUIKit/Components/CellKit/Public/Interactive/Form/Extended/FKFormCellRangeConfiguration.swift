import Foundation

/// Configuration for ``FKFormCellRangeCell`` (X-56, F-15).
public struct FKFormCellRangeConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var minLabel: String
  public var maxLabel: String
  public var minPlaceholder: String?
  public var maxPlaceholder: String?
  public var minText: String
  public var maxText: String
  public var validation: FKFormFieldValidationPresentation
  public var isEnabled: Bool

  /// Creates a dual amount range field configuration.
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    minLabel: String = "Minimum",
    maxLabel: String = "Maximum",
    minPlaceholder: String? = nil,
    maxPlaceholder: String? = nil,
    minText: String = "",
    maxText: String = "",
    validation: FKFormFieldValidationPresentation = .init(),
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.minLabel = minLabel
    self.maxLabel = maxLabel
    self.minPlaceholder = minPlaceholder
    self.maxPlaceholder = maxPlaceholder
    self.minText = minText
    self.maxText = maxText
    self.validation = validation
    self.isEnabled = isEnabled
  }
}
