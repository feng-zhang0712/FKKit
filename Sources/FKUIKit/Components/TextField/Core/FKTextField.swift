//
// FKTextField.swift
//
// Highly customizable formatted text field.
//

import UIKit

/// A native, protocol-driven, zero-dependency formatted text field for UIKit.
@MainActor
public final class FKTextField: UITextField, FKTextFieldConfigurable {
  /// Current full configuration.
  public private(set) var configuration: FKTextFieldConfiguration

  /// Current validation result.
  public private(set) var validationResult: FKTextFieldValidationResult = .valid

  /// Closure called when raw and formatted text changes.
  public var onTextDidChange: ((String, String) -> Void)?
  /// Closure called when formatter output is produced.
  public var onFormattedResult: ((FKTextFieldFormattingResult) -> Void)?
  /// Closure called when validation result changes.
  public var onValidationResult: ((FKTextFieldValidationResult) -> Void)?
  /// Closure called when error message changes.
  public var onErrorMessage: ((String?) -> Void)?
  /// Closure called when fixed-length input is completed.
  public var onInputCompleted: ((String) -> Void)?

  /// Raw text value without visual separators.
  public var rawText: String {
    textState.rawText
  }

  /// Controls whether password text is visible.
  public var isPasswordVisible: Bool = false {
    didSet { applySecureTextEntry() }
  }

  /// External delegate receiver for app-level behaviors.
  public weak var forwardingDelegate: UITextFieldDelegate?

  private let formatter: FKTextFieldFormatting
  private let validator: FKTextFieldValidating
  private var debounceTask: DispatchWorkItem?
  private var lastInputTime: CFAbsoluteTime = 0
  private var textState = FKTextFieldState()
  private lazy var passwordToggleButton = UIButton(type: .system)

  /// Creates a text field with custom formatter and validator.
  public init(
    configuration: FKTextFieldConfiguration,
    formatter: FKTextFieldFormatting = FKTextFieldDefaultFormatter(),
    validator: FKTextFieldValidating = FKTextFieldDefaultValidator()
  ) {
    self.configuration = configuration
    self.formatter = formatter
    self.validator = validator
    super.init(frame: .zero)
    commonInit()
  }

  /// Creates a text field using global style defaults.
  public convenience init(inputRule: FKTextFieldInputRule) {
    let configuration = FKTextFieldConfiguration(
      inputRule: inputRule,
      style: FKTextFieldManager.shared.defaultStyle
    )
    self.init(configuration: configuration)
  }

  /// Interface Builder initializer.
  public required init?(coder: NSCoder) {
    configuration = FKTextFieldConfiguration(
      inputRule: FKTextFieldInputRule(formatType: .alphaNumeric),
      style: FKTextFieldManager.shared.defaultStyle
    )
    formatter = FKTextFieldDefaultFormatter()
    validator = FKTextFieldDefaultValidator()
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a full configuration.
  public func configure(_ configuration: FKTextFieldConfiguration) {
    self.configuration = configuration
    applyConfiguration()
    reformatCurrentText()
  }

  /// Updates input rule only.
  public func updateInputRule(_ rule: FKTextFieldInputRule) {
    configuration.inputRule = rule
    applyConfiguration()
    reformatCurrentText()
  }

  /// Sets an explicit error state and message.
  public func setError(message: String?) {
    textState.errorMessage = message
    applyStateStyle()
    onErrorMessage?(message)
  }

  /// Clears current text and state.
  public func clear() {
    textState = FKTextFieldState()
    text = nil
    validationResult = .valid
    onTextDidChange?("", "")
    onValidationResult?(.valid)
    applyStateStyle()
  }
}

private extension FKTextField {
  func commonInit() {
    delegate = self
    addTarget(self, action: #selector(editingChanged), for: .editingChanged)
    addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
    addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
    autocorrectionType = .no
    spellCheckingType = .no
    smartDashesType = .no
    smartQuotesType = .no
    smartInsertDeleteType = .no
    clearButtonMode = .whileEditing
    applyConfiguration()
  }

  func applyConfiguration() {
    keyboardType = configuration.inputRule.formatType.keyboardType
    font = configuration.style.font
    textColor = configuration.style.textColor
    borderStyle = .none
    applyPlaceholder()
    configurePasswordToggleIfNeeded()
    applySecureTextEntry()
    applyStateStyle()
  }

  func applyPlaceholder() {
    if let attributedPlaceholder = configuration.attributedPlaceholder {
      self.attributedPlaceholder = attributedPlaceholder
      return
    }
    placeholder = configuration.placeholder
    guard let placeholder else { return }
    attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: [
        .foregroundColor: configuration.style.placeholderColor,
        .font: configuration.style.placeholderFont,
      ]
    )
  }

  func configurePasswordToggleIfNeeded() {
    guard case .password = configuration.inputRule.formatType else {
      if rightView == passwordToggleButton {
        rightView = nil
      }
      return
    }
    passwordToggleButton.setTitle("Show", for: .normal)
    passwordToggleButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
    passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisible), for: .touchUpInside)
    rightView = passwordToggleButton
    rightViewMode = .always
  }

  func applySecureTextEntry() {
    guard case .password = configuration.inputRule.formatType else {
      isSecureTextEntry = false
      return
    }
    isSecureTextEntry = !isPasswordVisible
    passwordToggleButton.setTitle(isPasswordVisible ? "Hide" : "Show", for: .normal)
  }

  func applyStateStyle() {
    let stateStyle: FKTextFieldStateStyle
    if textState.errorMessage != nil || !validationResult.isValid {
      stateStyle = configuration.style.error
    } else if isFirstResponder {
      stateStyle = configuration.style.focused
    } else {
      stateStyle = configuration.style.normal
    }

    layer.cornerRadius = stateStyle.cornerRadius
    layer.borderWidth = stateStyle.borderWidth
    layer.borderColor = stateStyle.borderColor.cgColor
    layer.backgroundColor = stateStyle.backgroundColor.cgColor
    layer.shadowColor = stateStyle.shadowColor?.cgColor
    layer.shadowOpacity = stateStyle.shadowOpacity
    layer.shadowOffset = stateStyle.shadowOffset
    layer.shadowRadius = stateStyle.shadowRadius
  }

  func processIncomingText(_ candidateText: String) {
    let result = formatter.format(text: candidateText, rule: configuration.inputRule)
    textState.rawText = result.rawText
    textState.formattedText = result.formattedText
    text = result.formattedText
    validationResult = validator.validate(rawText: result.rawText, formattedText: result.formattedText, rule: configuration.inputRule)

    if validationResult.isValid {
      textState.errorMessage = nil
    } else {
      textState.errorMessage = validationResult.message
    }

    applyStateStyle()
    dispatchCallbacks(result: result, validationResult: validationResult)
    onErrorMessage?(textState.errorMessage)
    checkCompletion()
  }

  func dispatchCallbacks(
    result: FKTextFieldFormattingResult,
    validationResult: FKTextFieldValidationResult
  ) {
    debounceTask?.cancel()
    let callback = { [weak self] in
      guard let self else { return }
      self.onFormattedResult?(result)
      self.onTextDidChange?(result.rawText, result.formattedText)
      self.onValidationResult?(validationResult)
    }
    let delay = configuration.inputRule.debounceInterval
    if delay > 0 {
      let task = DispatchWorkItem(block: callback)
      debounceTask = task
      DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
    } else {
      callback()
    }
  }

  func checkCompletion() {
    guard let fixedLength = configuration.inputRule.formatType.fixedLength else { return }
    guard textState.rawText.count == fixedLength else { return }
    onInputCompleted?(textState.rawText)
    if configuration.inputRule.autoDismissKeyboardOnComplete {
      resignFirstResponder()
    }
  }

  func reformatCurrentText() {
    processIncomingText(text ?? "")
  }

  @objc func editingChanged() {
    processIncomingText(text ?? "")
  }

  @objc func editingDidBegin() {
    applyStateStyle()
  }

  @objc func editingDidEnd() {
    validationResult = validator.validate(rawText: textState.rawText, formattedText: textState.formattedText, rule: configuration.inputRule)
    if !validationResult.isValid {
      textState.errorMessage = validationResult.message
      onErrorMessage?(textState.errorMessage)
    }
    applyStateStyle()
    forwardingDelegate?.textFieldDidEndEditing?(self)
  }

  @objc func togglePasswordVisible() {
    isPasswordVisible.toggle()
  }
}

extension FKTextField: UITextFieldDelegate {
  public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let currentTime = CFAbsoluteTimeGetCurrent()
    let minimumInterval = configuration.inputRule.minimumInputInterval
    if minimumInterval > 0, currentTime - lastInputTime < minimumInterval {
      return false
    }
    lastInputTime = currentTime

    guard let text = textField.text, let textRange = Range(range, in: text) else {
      return forwardingDelegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    let candidate = text.replacingCharacters(in: textRange, with: string)
    processIncomingText(candidate)
    return false
  }

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if configuration.inputRule.autoDismissKeyboardOnComplete {
      textField.resignFirstResponder()
    }
    return forwardingDelegate?.textFieldShouldReturn?(textField) ?? true
  }

  public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    forwardingDelegate?.textFieldShouldBeginEditing?(textField) ?? true
  }

  public func textFieldDidBeginEditing(_ textField: UITextField) {
    forwardingDelegate?.textFieldDidBeginEditing?(textField)
  }
}

private struct FKTextFieldState {
  var rawText: String = ""
  var formattedText: String = ""
  var errorMessage: String?
}

