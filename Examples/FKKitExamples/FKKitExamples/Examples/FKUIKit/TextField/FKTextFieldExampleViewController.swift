//
// FKTextFieldExampleViewController.swift
//
// Complete copy-ready demo for FKTextField scenarios.
//

import UIKit
import FKUIKit

/// Shared setup helpers for FKTextField demos.
enum FKTextFieldDemoSupport {
  private static var didConfigureGlobalStyle = false

  /// Configures a global text field style once.
  static func configureGlobalStyleIfNeeded() {
    guard !didConfigureGlobalStyle else { return }
    didConfigureGlobalStyle = true
    FKTextFieldManager.shared.configureDefaultStyle { style in
      style.normal.cornerRadius = 10
      style.normal.borderColor = .systemGray4
      style.normal.backgroundColor = .secondarySystemBackground
      style.focused.borderColor = .systemBlue
      style.error.borderColor = .systemRed
      style.placeholderColor = .tertiaryLabel
    }
  }
}

/// End-to-end examples covering formatting, validation, callbacks, and styling.
final class FKTextFieldExampleViewController: UIViewController {

  private let scrollView = UIScrollView()
  private let contentStack = UIStackView()
  private let callbackLogLabel = UILabel()
  private var errorLabels: [ObjectIdentifier: UILabel] = [:]

  override func viewDidLoad() {
    super.viewDidLoad()
    FKTextFieldDemoSupport.configureGlobalStyleIfNeeded()
    title = "FKTextField"
    view.backgroundColor = .systemGroupedBackground
    setupLayout()
    buildExamples()
  }
}

private extension FKTextFieldExampleViewController {
  func setupLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.alwaysBounceVertical = true
    view.addSubview(scrollView)

    contentStack.axis = .vertical
    contentStack.spacing = 18
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(contentStack)

    callbackLogLabel.font = .preferredFont(forTextStyle: .footnote)
    callbackLogLabel.textColor = .secondaryLabel
    callbackLogLabel.numberOfLines = 0
    callbackLogLabel.text = "Callback log will be shown here."
    contentStack.addArrangedSubview(makeSectionTitle("Live Callback Log"))
    contentStack.addArrangedSubview(callbackLogLabel)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
      contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
      contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
      contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
      contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
    ])
  }

  func buildExamples() {
    makePhoneExample()
    makeIDCardExample()
    makeBankCardExample()
    makeVerificationCodeExample()
    makePasswordExample()
    makeAmountExample()
    makeEmailExample()
    makeCustomLimitExample()
    makeCustomStyleExample()
    makeValidationErrorTipExample()
    makeClearAndRightViewExample()
  }

  func makePhoneExample() {
    let field = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone number (138 1234 5678)")
    bindCommonCallbacks(field, scenario: "Phone")
    addFieldSection(
      title: "Phone Number Formatted Input",
      subtitle: "Automatically groups digits into 3-4-4 format.",
      field: field
    )
  }

  func makeIDCardExample() {
    let field = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .idCard,
        maxLength: 18
      )
    )
    field.placeholder = "ID card (15/18)"
    bindCommonCallbacks(field, scenario: "IDCard")
    addFieldSection(
      title: "ID Card Input with Validation",
      subtitle: "Supports 15/18 format and built-in checksum validation for 18-digit IDs.",
      field: field
    )
  }

  func makeBankCardExample() {
    let field = FKTextField.make(formatType: .bankCard, placeholder: "Bank card number")
    bindCommonCallbacks(field, scenario: "BankCard")
    addFieldSection(
      title: "Bank Card Number Formatted Input",
      subtitle: "Automatically groups card digits by 4.",
      field: field
    )
  }

  func makeVerificationCodeExample() {
    let field = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .verificationCode(length: 6, allowsAlphabet: false),
        autoDismissKeyboardOnComplete: true
      )
    )
    field.placeholder = "6-digit verification code"
    bindCommonCallbacks(field, scenario: "OTP")
    field.onInputCompleted = { [weak self] code in
      self?.appendLog("OTP completed: \(code)")
    }
    addFieldSection(
      title: "Verification Code Input",
      subtitle: "Numeric-only fixed-length input with completion callback.",
      field: field
    )
  }

  func makePasswordExample() {
    let field = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .password(minLength: 8, maxLength: 20, validatesStrength: true)
      )
    )
    field.placeholder = "Password (8+ with strength check)"
    bindCommonCallbacks(field, scenario: "Password")
    addFieldSection(
      title: "Password Input with Show/Hide Toggle",
      subtitle: "Includes built-in secure/plain toggle and strength validation.",
      field: field
    )
  }

  func makeAmountExample() {
    let field = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .amount(maxIntegerDigits: 10, decimalDigits: 2)
      )
    )
    field.placeholder = "Amount (thousands separated)"
    bindCommonCallbacks(field, scenario: "Amount")
    addFieldSection(
      title: "Amount Input with Thousands Separator",
      subtitle: "Automatically formats integer part and limits decimal precision.",
      field: field
    )
  }

  func makeEmailExample() {
    let field = FKTextField.make(formatType: .email, placeholder: "Email address")
    bindCommonCallbacks(field, scenario: "Email")
    addFieldSection(
      title: "Email Input with Format Validation",
      subtitle: "Realtime email format validation with clear error message callback.",
      field: field
    )
  }

  func makeCustomLimitExample() {
    let field = FKTextField(
      inputRule: FKTextFieldInputRule(
        formatType: .alphaNumeric,
        maxLength: 12,
        allowsWhitespace: false,
        allowsEmoji: false,
        allowsSpecialCharacters: false,
        debounceInterval: 0.12,
        minimumInputInterval: 0.03
      )
    )
    field.placeholder = "Max 12 chars, no emoji/special/space"
    bindCommonCallbacks(field, scenario: "CustomLimit")
    addFieldSection(
      title: "Custom Input Limit (Length, No Emoji/Special)",
      subtitle: "Demonstrates strict filtering, length limit, debounce, and anti-burst input interval.",
      field: field
    )
  }

  func makeCustomStyleExample() {
    var style = FKTextFieldStyle.default
    style.normal.cornerRadius = 14
    style.normal.borderColor = .systemTeal
    style.focused.borderColor = .systemIndigo
    style.error.borderColor = .systemRed
    style.normal.backgroundColor = .systemBackground
    style.textColor = .label
    style.placeholderColor = .systemTeal

    let attributedPlaceholder = NSAttributedString(
      string: "Styled placeholder",
      attributes: [
        .font: UIFont.italicSystemFont(ofSize: 14),
        .foregroundColor: UIColor.systemTeal.withAlphaComponent(0.8),
      ]
    )

    let field = FKTextField(
      configuration: FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, maxLength: 16),
        style: style,
        attributedPlaceholder: attributedPlaceholder
      )
    )
    bindCommonCallbacks(field, scenario: "CustomStyle")
    addFieldSection(
      title: "Custom UI Style (Border, Corner, Placeholder)",
      subtitle: "Demonstrates per-instance style override from global defaults.",
      field: field
    )
  }

  func makeValidationErrorTipExample() {
    let field = FKTextField.make(formatType: .email, placeholder: "Type invalid email to see error")
      .chain { $0.clearButtonMode = .whileEditing }
    bindCommonCallbacks(field, scenario: "ValidationTip")
    addFieldSection(
      title: "Input Validation & Error Message Display",
      subtitle: "Error label updates in realtime through validation callbacks.",
      field: field
    )
  }

  func makeClearAndRightViewExample() {
    let field = FKTextField.make(formatType: .phoneNumber, placeholder: "Phone with actions")
    field.clearButtonMode = .whileEditing

    let rightButton = UIButton(type: .system)
    rightButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    rightButton.tintColor = .systemBlue
    rightButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
    rightButton.addAction(UIAction { [weak self, weak field] _ in
      guard let self, let field else { return }
      self.appendLog("Right icon tapped -> raw value: \(field.rawText)")
    }, for: .touchUpInside)
    field.rightView = rightButton
    field.rightViewMode = .always

    bindCommonCallbacks(field, scenario: "Clear+RightView")
    addFieldSection(
      title: "Clear Button & Right Icon View",
      subtitle: "Shows clear button usage and a custom right action icon.",
      field: field
    )
  }

  func addFieldSection(title: String, subtitle: String, field: FKTextField) {
    let container = UIStackView()
    container.axis = .vertical
    container.spacing = 8

    container.addArrangedSubview(makeSectionTitle(title))
    container.addArrangedSubview(makeSectionSubtitle(subtitle))

    field.translatesAutoresizingMaskIntoConstraints = false
    field.heightAnchor.constraint(equalToConstant: 44).isActive = true
    container.addArrangedSubview(field)

    let errorLabel = UILabel()
    errorLabel.font = .preferredFont(forTextStyle: .caption1)
    errorLabel.textColor = .systemRed
    errorLabel.numberOfLines = 0
    errorLabel.text = " "
    errorLabels[ObjectIdentifier(field)] = errorLabel
    container.addArrangedSubview(errorLabel)

    contentStack.addArrangedSubview(container)
  }

  func bindCommonCallbacks(_ field: FKTextField, scenario: String) {
    field.onFormattedResult = { [weak self] result in
      self?.appendLog("\(scenario) formatted -> \(result.formattedText)")
    }
    field.onTextDidChange = { [weak self] raw, _ in
      self?.appendLog("\(scenario) raw -> \(raw)")
    }
    field.onValidationResult = { [weak self] validation in
      self?.appendLog("\(scenario) valid -> \(validation.isValid)")
    }
    field.onErrorMessage = { [weak self, weak field] message in
      guard let self, let field else { return }
      self.errorLabels[ObjectIdentifier(field)]?.text = message ?? " "
    }
  }

  func appendLog(_ text: String) {
    callbackLogLabel.text = text
  }

  func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .headline)
    label.numberOfLines = 0
    label.text = text
    return label
  }

  func makeSectionSubtitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }
}

private extension FKTextField {
  /// Lightweight chain helper used for demo readability.
  @discardableResult
  func chain(_ block: (FKTextField) -> Void) -> FKTextField {
    block(self)
    return self
  }
}

