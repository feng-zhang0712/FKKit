import Foundation

/// Configuration for ``FKFormCellPhoneCell`` (X-06, F-12).
public struct FKFormCellPhoneConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var countryPicker: FKFormCountryPickerConfiguration
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
  public var isEnabled: Bool

  /// Creates a phone field configuration.
  public init(
    layout: FKFormCellLayout = .underline,
    label: String? = nil,
    placeholder: String? = nil,
    countryPicker: FKFormCountryPickerConfiguration = FKFormCountryPickerConfiguration(dialCode: "+1", flagEmoji: "🇺🇸", countryName: "United States"),
    validation: FKFormFieldValidationPresentation = FKFormFieldValidationPresentation(),
    linkageID: FKFormCellLinkageID? = nil,
    isEnabled: Bool = true
  ) {
    self.layout = layout
    self.label = label
    self.placeholder = placeholder
    self.countryPicker = countryPicker
    self.validation = validation
    self.linkageID = linkageID
    self.isEnabled = isEnabled
  }
}

// MARK: - Semantic preset (F-12)

public extension FKFormCellPhoneConfiguration {
  /// Phone number field preset with country code split (F-12).
  @MainActor
  static func phone(
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    countryPicker: FKFormCountryPickerConfiguration = FKFormCountryPickerConfiguration(dialCode: "+1", flagEmoji: "🇺🇸", countryName: "United States"),
    isRequired: Bool = true
  ) -> FKFormCellPhoneConfiguration {
    FKFormCellPhoneConfiguration(
      layout: layout,
      label: label,
      placeholder: placeholder,
      countryPicker: countryPicker,
      validation: FKFormFieldValidationPresentation(isRequired: isRequired)
    )
  }
}
