import FKCoreKit
import UIKit

/// Demonstrates `FKTextFormatting`, `FKTextValidating`, and `FKTextAsyncValidating`.
final class FKPluggableTextInputExampleViewController: FKPluggableExampleBaseViewController {

  private let phoneField = UITextField()
  private let usernameField = UITextField()
  private let statusLabel = UILabel()

  private let phoneRule = DemoPhoneFormatRule()
  private let phoneFormatter = DemoPhoneFormatter()
  private let phoneValidator = DemoPhoneValidator()
  private let asyncValidator = DemoUsernameAsyncValidator()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Text Input"
    setupFields()

    addActionButton("1) Format phone as you type (FKTextFormatting)") { [weak self] in
      self?.appendOutput("Type in the phone field — formatting runs on .editingChanged")
    }
    addActionButton("2) Validate phone (FKTextValidating)") { [weak self] in
      self?.validatePhone()
    }
    addActionButton("3) Async validate username (FKTextAsyncValidating)") { [weak self] in
      Task { await self?.validateUsernameAsync() }
    }
    addActionButton("4) Try reserved username 'admin'") { [weak self] in
      self?.usernameField.text = "admin"
      Task { await self?.validateUsernameAsync() }
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func setupFields() {
    phoneField.placeholder = "Phone (11 digits)"
    phoneField.borderStyle = .roundedRect
    phoneField.keyboardType = .numberPad
    phoneField.addTarget(self, action: #selector(phoneEditingChanged), for: .editingChanged)

    usernameField.placeholder = "Username (async check)"
    usernameField.borderStyle = .roundedRect
    usernameField.autocapitalizationType = .none

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Status: —"

    let fieldStack = UIStackView(arrangedSubviews: [phoneField, usernameField, statusLabel])
    fieldStack.axis = .vertical
    fieldStack.spacing = 8
    stackView.insertArrangedSubview(fieldStack, at: 0)
  }

  @objc private func phoneEditingChanged() {
    let text = phoneField.text ?? ""
    let result = phoneFormatter.format(text: text, rule: phoneRule)
    if phoneField.text != result.displayText {
      phoneField.text = result.displayText
    }
    statusLabel.text = "raw=\(result.rawText) display=\(result.displayText)"
  }

  private func validatePhone() {
    let display = phoneField.text ?? ""
    let digits = String(display.filter(\.isNumber))
    let result = phoneValidator.validate(rawText: digits, displayText: display, rule: phoneRule)
    switch result {
    case .valid:
      appendOutput("Phone validation: valid")
    case .invalid(let message):
      appendOutput("Phone validation: \(message)")
    }
  }

  private func validateUsernameAsync() async {
    let name = usernameField.text ?? ""
    appendOutput("Async validating '\(name)'…")
    let result = try? await asyncValidator.validate(
      rawText: name,
      displayText: name,
      rule: DemoAsyncValidationRule()
    )
    switch result {
    case .valid:
      appendOutput("Username validation: valid")
    case .invalid(let message):
      appendOutput("Username validation: \(message)")
    case .none:
      appendOutput("Username validation failed with error")
    }
  }
}
