import FKCoreKit
import UIKit

/// SMS verification code field with resend countdown button (X-17, F-03).
@MainActor
public final class FKFormCellSMSCodeCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormSMSCodeRow

  /// Called on the main actor when the user taps the send-code button.
  public var onSendSMS: (() -> Void)?
  /// Called on the main actor when the code text changes.
  public var onCodeChanged: ((String) -> Void)?

  private let chromeView = FKFormFieldChromeView()
  private let codeField = FKTextField(configuration: FKTextFieldConfiguration(
    inputRule: FKTextFieldInputRule(
      formatType: .verificationCode(length: 6, allowsAlphabet: false),
      maxLength: 6
    ),
    style: FKTextFieldManager.shared.defaultStyle
  ))
  private let countdown = FKFormSMSCountdown()
  private var storedConfiguration = FKFormCellSMSCodeConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies an SMS code configuration with default appearance.
  public func apply(_ configuration: FKFormCellSMSCodeConfiguration) {
    apply(configuration, appearance: .default, code: codeField.rawText)
  }

  /// Applies an SMS code configuration with explicit appearance and code value.
  public func apply(
    _ configuration: FKFormCellSMSCodeConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    code: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    var embeddedConfiguration = FKFormTextFieldEmbedding.prepare(
      FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(
          formatType: .verificationCode(length: configuration.codeLength, allowsAlphabet: false),
          maxLength: configuration.codeLength
        ),
        style: FKTextFieldManager.shared.defaultStyle,
        placeholder: configuration.placeholder
      ),
      trailingAccessory: .smsCodeButton(configuration.smsButton)
    )
    if let placeholder = configuration.placeholder {
      embeddedConfiguration.placeholder = placeholder
    }
    codeField.configure(embeddedConfiguration)
    codeField.isEnabled = configuration.isEnabled
    codeField.text = code

    chromeView.install(textField: codeField)
    chromeView.trailingHost.onSMSCodeTapped = { [weak self] in
      self?.onSendSMS?()
    }
    chromeView.trailingHost.updateSMSCountdown(remainingSeconds: countdown.remainingSeconds)
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      validation: configuration.validation,
      leadingAccessory: .none,
      trailingAccessory: .smsCodeButton(configuration.smsButton),
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isFieldFocused: codeField.isFirstResponder
    )

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormSMSCodeRow) {
    apply(viewModel.configuration, code: viewModel.code)
  }

  /// Starts the SMS resend countdown after a successful send.
  public func startCountdown() {
    startCountdown(seconds: storedConfiguration.smsButton.countdownSeconds)
  }

  /// Starts the SMS resend countdown with an explicit duration.
  public func startCountdown(seconds: Int) {
    countdown.start(seconds: seconds)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onSendSMS = nil
    onCodeChanged = nil
    countdown.invalidate()
    codeField.onEditingChanged = nil
    codeField.onDidBeginEditing = nil
    codeField.onDidEndEditing = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    wireCodeFieldCallbacks()
    wireCountdownCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    chromeView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(chromeView)
    NSLayoutConstraint.activate([
      chromeView.topAnchor.constraint(equalTo: contentView.topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      chromeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    chromeView.install(textField: codeField)
    wireCodeFieldCallbacks()
    wireCountdownCallbacks()
  }

  private func wireCodeFieldCallbacks() {
    codeField.onEditingChanged = { [weak self] (raw: String, _: String) in
      guard let self else { return }
      self.onCodeChanged?(raw)
    }
    codeField.onDidBeginEditing = { [weak self] in
      guard let self else { return }
      self.refreshChrome(focusState: .focused, isFieldFocused: true)
    }
    codeField.onDidEndEditing = { [weak self] in
      guard let self else { return }
      let state: FKFormFieldFocusState = self.storedConfiguration.isEnabled ? .unfocused : .disabled
      self.refreshChrome(focusState: state, isFieldFocused: false)
    }
  }

  private func wireCountdownCallbacks() {
    countdown.onTick = { [weak self] remaining in
      guard let self else { return }
      self.chromeView.trailingHost.updateSMSCountdown(remainingSeconds: remaining)
    }
    countdown.onFinished = { [weak self] in
      guard let self else { return }
      self.chromeView.trailingHost.resetSMSCountdown()
    }
  }

  private func refreshChrome(focusState: FKFormFieldFocusState, isFieldFocused: Bool) {
    chromeView.apply(
      layout: storedConfiguration.layout,
      label: storedConfiguration.label,
      validation: storedConfiguration.validation,
      leadingAccessory: .none,
      trailingAccessory: .smsCodeButton(storedConfiguration.smsButton),
      appearance: appearance,
      focusState: focusState,
      isFieldFocused: isFieldFocused
    )
    chromeView.trailingHost.updateSMSCountdown(remainingSeconds: countdown.remainingSeconds)
  }
}
