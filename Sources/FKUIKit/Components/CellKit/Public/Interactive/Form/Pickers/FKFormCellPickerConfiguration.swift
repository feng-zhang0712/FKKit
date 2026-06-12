import Foundation

/// Configuration for ``FKFormCellPickerCell`` (X-11, X-12).
public struct FKFormCellPickerConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var presentation: FKFormPickerPresentation
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a picker field configuration.
  public init(
    layout: FKFormCellLayout = .inlineLabel,
    label: String? = nil,
    placeholder: String? = nil,
    presentation: FKFormPickerPresentation = .dropdown,
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.presentation = presentation
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }

  /// Trailing accessory implied by the presentation style.
  public var trailingAccessory: FKFormTrailingAccessory {
    switch presentation {
    case .dropdown:
      return .chevronDown
    case .navigation:
      return .chevronForward
    }
  }
}
