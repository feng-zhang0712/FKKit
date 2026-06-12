import UIKit

/// Leading accessory host for form field rows.
@MainActor
final class FKFormLeadingAccessoryHostView: UIView {
  var onCountryPickerTapped: (() -> Void)?

  private let iconSlot = FKCellIconSlotView()
  private let prefixLabel = UILabel()

  private lazy var countryButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(handleCountryTap), for: .touchUpInside)
    button.titleLabel?.font = .preferredFont(forTextStyle: .body)
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.setContentHuggingPriority(.required, for: .horizontal)
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
    return button
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(_ accessory: FKFormLeadingAccessory) {
    subviews.forEach { $0.removeFromSuperview() }
    isHidden = true

    switch accessory {
    case .none:
      break
    case let .icon(content):
      isHidden = false
      iconSlot.apply(content)
      embed(iconSlot)
    case let .prefixText(text):
      isHidden = false
      prefixLabel.text = text
      prefixLabel.font = .preferredFont(forTextStyle: .body)
      prefixLabel.textColor = .secondaryLabel
      embed(prefixLabel)
    case let .countryPicker(configuration):
      isHidden = false
      applyCountryPicker(configuration)
      embed(countryButton)
    case .custom:
      break
    }
  }

  func reset() {
    iconSlot.reset()
    prefixLabel.text = nil
    onCountryPickerTapped = nil
    apply(.none)
  }

  private func commonInit() {
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    prefixLabel.translatesAutoresizingMaskIntoConstraints = false
    prefixLabel.adjustsFontForContentSizeCategory = true
  }

  private func applyCountryPicker(_ configuration: FKFormCountryPickerConfiguration) {
    var title = configuration.dialCode
    if let flag = configuration.flagEmoji, !flag.isEmpty {
      title = "\(flag) \(title)"
    }
    var buttonConfig = UIButton.Configuration.plain()
    buttonConfig.title = title
    buttonConfig.image = UIImage(systemName: "chevron.down")
    buttonConfig.imagePlacement = .trailing
    buttonConfig.imagePadding = 4
    buttonConfig.baseForegroundColor = .label
    countryButton.configuration = buttonConfig
    countryButton.accessibilityLabel = configuration.countryName ?? "Country code \(configuration.dialCode)"
    countryButton.accessibilityTraits = [.button]
  }

  private func embed(_ view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @objc private func handleCountryTap() {
    onCountryPickerTapped?()
  }
}

/// Trailing accessory host for form field rows.
@MainActor
final class FKFormTrailingAccessoryHostView: UIView {
  var onSMSCodeTapped: (() -> Void)?

  private weak var textField: FKTextField?
  private var smsConfiguration = FKFormSMSCodeButtonConfiguration()
  private var smsRemainingSeconds = 0

  private lazy var visibilityButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
    button.accessibilityLabel = "Toggle password visibility"
    return button
  }()

  private lazy var clearButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
    button.addTarget(self, action: #selector(clearText), for: .touchUpInside)
    button.accessibilityLabel = "Clear text"
    return button
  }()

  private lazy var symbolButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.isUserInteractionEnabled = false
    return button
  }()

  private lazy var smsButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.addTarget(self, action: #selector(handleSMSTap), for: .touchUpInside)
    button.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.accessibilityTraits = [.button]
    return button
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func bind(textField: FKTextField) {
    self.textField = textField
  }

  func apply(_ accessory: FKFormTrailingAccessory) {
    subviews.forEach { $0.removeFromSuperview() }
    isHidden = true

    switch accessory {
    case .none:
      break
    case .visibilityToggle:
      isHidden = false
      refreshVisibilityButton()
      embed(visibilityButton)
    case .clearButton:
      isHidden = false
      embed(clearButton)
    case .chevronDown:
      isHidden = false
      symbolButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
      symbolButton.accessibilityLabel = "Open picker"
      embed(symbolButton)
    case .chevronForward:
      isHidden = false
      symbolButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
      symbolButton.accessibilityLabel = "Open selection"
      embed(symbolButton)
    case .calendar:
      isHidden = false
      symbolButton.setImage(UIImage(systemName: "calendar"), for: .normal)
      symbolButton.accessibilityLabel = "Choose date"
      embed(symbolButton)
    case .clock:
      isHidden = false
      symbolButton.setImage(UIImage(systemName: "clock"), for: .normal)
      symbolButton.accessibilityLabel = "Choose time"
      embed(symbolButton)
    case let .smsCodeButton(configuration):
      isHidden = false
      smsConfiguration = configuration
      refreshSMSButton()
      embed(smsButton)
    case .custom:
      break
    }
  }

  func updateSMSCountdown(remainingSeconds: Int) {
    smsRemainingSeconds = remainingSeconds
    refreshSMSButton()
  }

  func resetSMSCountdown() {
    smsRemainingSeconds = 0
    refreshSMSButton()
  }

  func reset() {
    textField = nil
    onSMSCodeTapped = nil
    smsRemainingSeconds = 0
    apply(.none)
  }

  private func commonInit() {
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  private func embed(_ view: UIView) {
    addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
      view.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
      view.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),
    ])
  }

  private func refreshVisibilityButton() {
    let isVisible = textField?.isPasswordVisible ?? false
    let symbol = isVisible ? "eye" : "eye.slash"
    visibilityButton.setImage(UIImage(systemName: symbol), for: .normal)
  }

  private func refreshSMSButton() {
    if smsRemainingSeconds > 0 {
      let title = String(format: smsConfiguration.countdownTitleFormat, smsRemainingSeconds)
      smsButton.setTitle(title, for: .normal)
      smsButton.isEnabled = false
      smsButton.accessibilityLabel = "Resend code in \(smsRemainingSeconds) seconds"
    } else {
      smsButton.setTitle(smsConfiguration.title, for: .normal)
      smsButton.isEnabled = true
      smsButton.accessibilityLabel = smsConfiguration.title
    }
  }

  @objc private func togglePasswordVisibility() {
    guard let textField else { return }
    textField.isPasswordVisible.toggle()
    refreshVisibilityButton()
    textField.onPasswordVisibilityToggled?(textField.isPasswordVisible)
  }

  @objc private func clearText() {
    textField?.text = ""
    textField?.onDidClear?()
  }

  @objc private func handleSMSTap() {
    onSMSCodeTapped?()
  }
}
