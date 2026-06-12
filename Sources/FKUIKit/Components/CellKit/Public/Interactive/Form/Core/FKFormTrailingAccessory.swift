import Foundation

/// Trailing accessory slot for form field rows (§6.8).
public enum FKFormTrailingAccessory: Sendable, Equatable {
  case none
  case visibilityToggle
  case clearButton
  case chevronDown
  case chevronForward
  case calendar
  case clock
  case smsCodeButton(FKFormSMSCodeButtonConfiguration)
  case custom(id: String)
}
