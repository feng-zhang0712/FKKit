import Foundation

/// Configuration for ``FKFormCellSMSCodeCell`` (X-17, F-03).
public struct FKFormCellSMSCodeConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var codeLength: Int
  public var smsButton: FKFormSMSCodeButtonConfiguration
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates an SMS verification code configuration.
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    placeholder: String? = nil,
    codeLength: Int = 6,
    smsButton: FKFormSMSCodeButtonConfiguration = FKFormSMSCodeButtonConfiguration(),
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.codeLength = max(1, codeLength)
    self.smsButton = smsButton
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-03)

public extension FKFormCellSMSCodeConfiguration {
  /// SMS verification code field preset (F-03).
  @MainActor
  static func smsCode(
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    codeLength: Int = 6,
    isRequired: Bool = true
  ) -> FKFormCellSMSCodeConfiguration {
    FKFormCellSMSCodeConfiguration(
      layout: layout,
      label: label,
      placeholder: placeholder,
      codeLength: codeLength,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
  }
}
