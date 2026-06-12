import FKCoreKit
import UIKit

/// Captcha text field with trailing image refresh zone (X-16).
@MainActor
public final class FKFormCellCaptchaCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormCaptchaRow

  /// Called when the user taps the captcha image to refresh.
  public var onCaptchaRefresh: (() -> Void)?
  /// Called when the captcha text changes.
  public var onTextChanged: ((String) -> Void)?

  private let chromeView = FKFormFieldChromeView()
  private let captchaImageView = FKImageView(profile: .listCell)
  private let captchaTapButton = UIButton(type: .custom)
  private let textField = FKTextField(configuration: FKTextFieldConfiguration(
    inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, allowsWhitespace: false, allowsSpecialCharacters: false),
    style: FKTextFieldManager.shared.defaultStyle
  ))
  private var storedConfiguration = FKFormCellCaptchaConfiguration()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellCaptchaConfiguration) {
    apply(configuration, appearance: .default, text: textField.rawText)
  }

  public func apply(
    _ configuration: FKFormCellCaptchaConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    text: String = ""
  ) {
    storedConfiguration = configuration
    self.appearance = appearance

    var embeddedConfiguration = FKFormTextFieldEmbedding.prepare(
      FKTextFieldConfiguration(
        inputRule: FKTextFieldInputRule(formatType: .alphaNumeric, allowsWhitespace: false, allowsSpecialCharacters: false),
        style: FKTextFieldManager.shared.defaultStyle,
        placeholder: configuration.placeholder
      ),
      trailingAccessory: .none
    )
    if let placeholder = configuration.placeholder {
      embeddedConfiguration.placeholder = placeholder
    }
    textField.configure(embeddedConfiguration)
    textField.isEnabled = configuration.isEnabled
    textField.text = text

    applyCaptchaImage(configuration.captchaImage)
    chromeView.install(textField: textField)
    chromeView.apply(
      layout: configuration.layout,
      label: configuration.label,
      validation: configuration.validation,
      leadingAccessory: .none,
      trailingAccessory: .custom(id: "captcha"),
      appearance: appearance,
      focusState: configuration.isEnabled ? .unfocused : .disabled,
      isFieldFocused: textField.isFirstResponder
    )
    chromeView.trailingHost.subviews.forEach { $0.removeFromSuperview() }
    embedCaptchaTrailing()

    backgroundColor = appearance.groupedBackgroundColor
    contentView.backgroundColor = appearance.groupedBackgroundColor
    selectionStyle = .none
    accessibilityLabel = configuration.label
  }

  public func configure(with viewModel: FKFormCaptchaRow) {
    apply(viewModel.configuration, text: viewModel.text)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onCaptchaRefresh = nil
    onTextChanged = nil
    captchaImageView.resetForReuse()
    textField.onEditingChanged = nil
    textField.onDidBeginEditing = nil
    textField.onDidEndEditing = nil
    chromeView.reset()
    selectionStyle = .none
    accessibilityLabel = nil
    wireTextFieldCallbacks()
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    captchaImageView.translatesAutoresizingMaskIntoConstraints = false
    captchaImageView.clipsToBounds = true
    captchaImageView.layer.cornerRadius = 4
    captchaTapButton.translatesAutoresizingMaskIntoConstraints = false
    captchaTapButton.addTarget(self, action: #selector(handleCaptchaTap), for: .touchUpInside)
    captchaTapButton.accessibilityLabel = "Refresh captcha"

    chromeView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(chromeView)
    NSLayoutConstraint.activate([
      chromeView.topAnchor.constraint(equalTo: contentView.topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      chromeView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    chromeView.install(textField: textField)
    wireTextFieldCallbacks()
  }

  private func embedCaptchaTrailing() {
    let host = chromeView.trailingHost
    host.isHidden = false
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(captchaImageView)
    container.addSubview(captchaTapButton)
    host.addSubview(container)
    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: host.topAnchor),
      container.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: host.bottomAnchor),
      container.widthAnchor.constraint(equalToConstant: 88),
      container.heightAnchor.constraint(equalToConstant: 32),

      captchaImageView.topAnchor.constraint(equalTo: container.topAnchor),
      captchaImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      captchaImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      captchaImageView.bottomAnchor.constraint(equalTo: container.bottomAnchor),

      captchaTapButton.topAnchor.constraint(equalTo: container.topAnchor),
      captchaTapButton.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      captchaTapButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      captchaTapButton.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  private func applyCaptchaImage(_ content: FKCellImageContent?) {
    guard let content else {
      captchaImageView.resetForReuse()
      return
    }
    if let url = content.url {
      captchaImageView.load(url: url)
    } else if let image = content.image {
      captchaImageView.setImage(image, animated: false)
    } else {
      captchaImageView.resetForReuse()
    }
  }

  private func wireTextFieldCallbacks() {
    textField.onEditingChanged = { [weak self] (raw: String, _: String) in
      self?.onTextChanged?(raw)
    }
    textField.onDidBeginEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        validation: self.storedConfiguration.validation,
        leadingAccessory: .none,
        trailingAccessory: .custom(id: "captcha"),
        appearance: self.appearance,
        focusState: .focused,
        isFieldFocused: true
      )
      self.embedCaptchaTrailing()
    }
    textField.onDidEndEditing = { [weak self] in
      guard let self else { return }
      self.chromeView.apply(
        layout: self.storedConfiguration.layout,
        label: self.storedConfiguration.label,
        validation: self.storedConfiguration.validation,
        leadingAccessory: .none,
        trailingAccessory: .custom(id: "captcha"),
        appearance: self.appearance,
        focusState: self.storedConfiguration.isEnabled ? .unfocused : .disabled,
        isFieldFocused: false
      )
      self.embedCaptchaTrailing()
    }
  }

  @objc private func handleCaptchaTap() {
    onCaptchaRefresh?()
  }
}
