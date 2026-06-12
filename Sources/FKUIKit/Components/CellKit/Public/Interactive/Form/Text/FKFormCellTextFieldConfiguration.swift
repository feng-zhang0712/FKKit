import Foundation

/// Configuration for ``FKFormCellTextFieldCell`` (X-01–X-05, F-01/F-02).
public struct FKFormCellTextFieldConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var textFieldConfiguration: FKTextFieldConfiguration
  public var leadingAccessory: FKFormLeadingAccessory
  public var trailingAccessory: FKFormTrailingAccessory
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a form text field configuration.
  @MainActor
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    placeholder: String? = nil,
    textFieldConfiguration: FKTextFieldConfiguration? = nil,
    leadingAccessory: FKFormLeadingAccessory = .none,
    trailingAccessory: FKFormTrailingAccessory = .none,
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.textFieldConfiguration = textFieldConfiguration
      ?? FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(
          formatType: .alphaNumeric,
          allowsWhitespace: true,
          allowsSpecialCharacters: true
        ),
        style: FKTextFieldManager.shared.defaultStyle,
        placeholder: placeholder
      )
    self.leadingAccessory = leadingAccessory
    self.trailingAccessory = trailingAccessory
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

extension FKFormCellTextFieldConfiguration {
  public static func == (
    lhs: FKFormCellTextFieldConfiguration,
    rhs: FKFormCellTextFieldConfiguration
  ) -> Bool {
    lhs.layout == rhs.layout
      && lhs.label == rhs.label
      && lhs.placeholder == rhs.placeholder
      && lhs.leadingAccessory == rhs.leadingAccessory
      && lhs.trailingAccessory == rhs.trailingAccessory
      && lhs.validation == rhs.validation
      && lhs.linkageID == rhs.linkageID
      && lhs.isEnabled == rhs.isEnabled
      && lhs.textFieldConfiguration.placeholder == rhs.textFieldConfiguration.placeholder
      && lhs.textFieldConfiguration.inputRule.formatType == rhs.textFieldConfiguration.inputRule.formatType
  }
}

// MARK: - Semantic presets (F-01, F-02)

public extension FKFormCellTextFieldConfiguration {
  /// Single-line text field preset (F-01).
  @MainActor
  static func textField(
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    isRequired: Bool = false
  ) -> FKFormCellTextFieldConfiguration {
    FKFormCellTextFieldConfiguration(
      layout: layout,
      label: label,
      placeholder: placeholder,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
  }

  /// Secure password field preset with visibility toggle (F-02, X-08).
  @MainActor
  static func password(
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    isRequired: Bool = true
  ) -> FKFormCellTextFieldConfiguration {
    var configuration = FKFormCellTextFieldConfiguration(
      layout: layout,
      label: label,
      placeholder: placeholder,
      textFieldConfiguration: FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(
          formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true),
          maxLength: 20,
          minLength: 8
        ),
        style: FKTextFieldManager.shared.defaultStyle,
        placeholder: placeholder
      ),
      trailingAccessory: .visibilityToggle,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
    if layout == .iconUnderline {
      configuration.leadingAccessory = .icon(FKCellIconContent(symbolName: "lock.fill"))
    }
    return configuration
  }
}
