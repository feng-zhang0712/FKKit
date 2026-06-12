import Foundation

/// Configuration for ``FKFormCellInlineExpandCell`` (X-64).
public struct FKFormCellInlineExpandConfiguration: Sendable, Equatable {
  public var toggleTitle: String
  public var fieldLabel: String?
  public var fieldPlaceholder: String?
  public var isExpanded: Bool
  public var fieldText: String
  public var isEnabled: Bool

  /// Creates an inline expandable sub-field configuration.
  public init(
    toggleTitle: String,
    fieldLabel: String? = nil,
    fieldPlaceholder: String? = nil,
    isExpanded: Bool = false,
    fieldText: String = "",
    isEnabled: Bool = true
  ) {
    self.toggleTitle = toggleTitle
    self.fieldLabel = fieldLabel
    self.fieldPlaceholder = fieldPlaceholder
    self.isExpanded = isExpanded
    self.fieldText = fieldText
    self.isEnabled = isEnabled
  }
}
