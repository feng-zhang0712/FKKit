import Foundation

/// ListKit-friendly row model for ``FKFormCellPhoneCell`` (F-12).
public struct FKFormPhoneRow: Sendable, Equatable, Hashable {
  public var id: String
  public var phoneNumber: String
  public var configuration: FKFormCellPhoneConfiguration

  /// Creates a phone row model.
  public init(
    id: String,
    phoneNumber: String = "",
    configuration: FKFormCellPhoneConfiguration
  ) {
    self.id = id
    self.phoneNumber = phoneNumber
    self.configuration = configuration
  }

  /// Convenience builder for F-12.
  @MainActor
  public init(
    id: String,
    phoneNumber: String = "",
    layout: FKFormCellLayout = .underline,
    label: String?,
    placeholder: String? = nil,
    countryPicker: FKFormCountryPickerConfiguration = FKFormCountryPickerConfiguration(dialCode: "+1", flagEmoji: "🇺🇸", countryName: "United States"),
    isRequired: Bool = true
  ) {
    self.id = id
    self.phoneNumber = phoneNumber
    self.configuration = .phone(
      layout: layout,
      label: label,
      placeholder: placeholder,
      countryPicker: countryPicker,
      isRequired: isRequired
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
