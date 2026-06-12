import Foundation

/// Configuration for ``FKFormCellSocialAccountCell`` (X-07).
public struct FKFormCellSocialAccountConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var platformPicker: FKFormPlatformPickerConfiguration
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a social account field configuration.
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    placeholder: String? = "@username",
    platformPicker: FKFormPlatformPickerConfiguration = FKFormPlatformPickerConfiguration(platformName: "Skype"),
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.platformPicker = platformPicker
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}
