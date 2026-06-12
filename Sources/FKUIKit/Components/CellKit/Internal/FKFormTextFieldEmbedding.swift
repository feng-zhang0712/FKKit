import UIKit

/// Prepares ``FKTextField`` instances for embedding inside ``FKFormFieldChromeView``.
enum FKFormTextFieldEmbedding {
  static func prepare(
    _ configuration: FKTextFieldConfiguration,
    trailingAccessory: FKFormTrailingAccessory
  ) -> FKTextFieldConfiguration {
    var copy = configuration
    copy.inlineMessage.showsErrorMessage = false
    copy.floatingTitle = nil
    copy.messages.error = nil
    copy.messages.helper = nil
    copy.messages.success = nil

    let clearStyle = FKTextFieldStateStyle(
      borderColor: .clear,
      borderWidth: 0,
      cornerRadius: 0,
      backgroundColor: .clear
    )
    copy.style.normal = clearStyle
    copy.style.focused = clearStyle
    copy.style.error = clearStyle
    copy.style.success = clearStyle
    copy.style.filled = clearStyle
    copy.style.disabled = clearStyle
    copy.style.readOnly = clearStyle
    copy.decoration = FKTextFieldDecorationConfiguration(mode: .border)

    switch trailingAccessory {
    case .visibilityToggle:
      copy.accessories.passwordToggle.isEnabled = false
    case .clearButton:
      copy.accessories.clearButton.isEnabled = false
    case .none, .custom, .chevronDown, .chevronForward, .calendar, .clock, .smsCodeButton:
      break
    }

    return copy
  }
}
