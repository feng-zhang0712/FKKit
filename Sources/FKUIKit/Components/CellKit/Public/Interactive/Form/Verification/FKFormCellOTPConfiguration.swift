import UIKit

/// Configuration for ``FKFormCellOTPCell`` (X-18, F-03).
public struct FKFormCellOTPConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var codeConfiguration: FKCodeTextField.Configuration
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates an OTP field configuration.
  @MainActor
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    codeConfiguration: FKCodeTextField.Configuration = FKCodeTextField.Configuration(length: 6),
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.codeConfiguration = codeConfiguration
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

extension FKFormCellOTPConfiguration {
  public static func == (lhs: FKFormCellOTPConfiguration, rhs: FKFormCellOTPConfiguration) -> Bool {
    lhs.layout == rhs.layout
      && lhs.label == rhs.label
      && lhs.codeConfiguration.length == rhs.codeConfiguration.length
      && lhs.codeConfiguration.slotStyle == rhs.codeConfiguration.slotStyle
      && lhs.validation == rhs.validation
      && lhs.linkageID == rhs.linkageID
      && lhs.isEnabled == rhs.isEnabled
  }
}

// MARK: - Semantic preset (F-03)

public extension FKFormCellOTPConfiguration {
  /// OTP slot field preset (F-03).
  @MainActor
  static func otp(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    length: Int = 6,
    linkageID: FKFormCellLinkageID? = nil,
    isRequired: Bool = true
  ) -> FKFormCellOTPConfiguration {
    FKFormCellOTPConfiguration(
      layout: layout,
      label: label,
      codeConfiguration: FKCodeTextField.Configuration(length: length),
      validation: FKFormFieldValidationPresentation(isRequired: isRequired),
      linkageID: linkageID
    )
  }
}
