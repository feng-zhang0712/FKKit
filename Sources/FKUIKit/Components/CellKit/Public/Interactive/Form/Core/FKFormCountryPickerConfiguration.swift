import Foundation

/// Display payload for the country-code leading zone in phone form rows (X-06).
public struct FKFormCountryPickerConfiguration: Sendable, Equatable {
  /// International dialing prefix, for example `+1`.
  public var dialCode: String
  /// Optional flag emoji shown before the dial code.
  public var flagEmoji: String?
  /// Optional country name used for accessibility.
  public var countryName: String?

  /// Creates a country picker configuration.
  public init(
    dialCode: String,
    flagEmoji: String? = nil,
    countryName: String? = nil
  ) {
    self.dialCode = dialCode
    self.flagEmoji = flagEmoji
    self.countryName = countryName
  }
}
