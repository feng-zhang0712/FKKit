import Foundation

/// Configuration for ``FKFormCellCharacterCountFooterCell`` (X-69).
public struct FKFormCellCharacterCountFooterConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var maxLength: Int
  public var text: String
  public var validation: FKFormFieldValidationPresentation
  public var isEnabled: Bool

  /// Creates a multiline field with an external character count footer.
  public init(
    layout: FKFormCellLayout = .cardStacked,
    label: String? = nil,
    placeholder: String? = nil,
    maxLength: Int = 280,
    text: String = "",
    validation: FKFormFieldValidationPresentation = .init(),
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.maxLength = maxLength
    self.text = text
    self.validation = validation
    self.isEnabled = isEnabled
  }
}
