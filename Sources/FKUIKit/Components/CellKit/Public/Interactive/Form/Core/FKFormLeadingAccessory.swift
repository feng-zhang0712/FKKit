import Foundation

/// Leading accessory slot for form field rows (§6.8).
public enum FKFormLeadingAccessory: Sendable, Equatable {
  case none
  case icon(FKCellIconContent)
  case prefixText(String)
  case countryPicker(FKFormCountryPickerConfiguration)
  case custom(id: String)
}
