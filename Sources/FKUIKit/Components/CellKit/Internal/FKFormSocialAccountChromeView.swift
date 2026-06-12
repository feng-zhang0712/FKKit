import UIKit

/// Split platform picker and username field layout for ``FKFormCellSocialAccountCell`` (X-07).
@MainActor
final class FKFormSocialAccountChromeView: UIView {
  var onPlatformPickerTapped: (() -> Void)?

  let cardBackground = UIView()
  let rootStack = UIStackView()
  let topLabel = UILabel()
  let splitRow = UIStackView()
  let platformHost = UIView()
  let platformButton = UIButton(type: .system)
  let platformIcon = FKCellIconSlotView()
  let verticalDivider = FKDivider()
  let usernameFieldHost = UIView()
  let underline = FKDivider()
  let messageLabel = UILabel()

  private var storedLayout: FKFormCellLayout = .underline
  private var appearance: FKCellAppearanceConfiguration = .default
  private var validation = FKFormFieldValidationPresentation()
  private var focusState: FKFormFieldFocusState = .unfocused
  private var platformWidthConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func install(usernameField: FKTextField) {
    usernameFieldHost.subviews.forEach { $0.removeFromSuperview() }
    usernameField.translatesAutoresizingMaskIntoConstraints = false
    usernameFieldHost.addSubview(usernameField)
    NSLayoutConstraint.activate([
      usernameField.topAnchor.constraint(equalTo: usernameFieldHost.topAnchor),
      usernameField.leadingAnchor.constraint(equalTo: usernameFieldHost.leadingAnchor),
      usernameField.trailingAnchor.constraint(equalTo: usernameFieldHost.trailingAnchor),
      usernameField.bottomAnchor.constraint(equalTo: usernameFieldHost.bottomAnchor),
      usernameField.heightAnchor.constraint(greaterThanOrEqualToConstant: FKFormLayoutMetrics.minimumFieldRowHeight),
    ])
  }

  func apply(
    layout: FKFormCellLayout,
    label: String?,
    platformPicker: FKFormPlatformPickerConfiguration,
    validation: FKFormFieldValidationPresentation,
    appearance: FKCellAppearanceConfiguration,
    focusState: FKFormFieldFocusState,
    isFieldFocused: Bool,
    isEnabled: Bool
  ) {
    storedLayout = layout
    self.appearance = appearance
    self.validation = validation
    self.focusState = focusState
    applyPlatformPicker(platformPicker)
    applyLabel(label, layout: layout, validation: validation, appearance: appearance)
    refreshChrome(isFieldFocused: isFieldFocused, isEnabled: isEnabled)
  }

  func refreshChrome(isFieldFocused: Bool, isEnabled: Bool) {
    let resolved = FKFormFieldChromeStateResolver.resolve(
      layout: storedLayout,
      validation: validation,
      focusState: focusState,
      isFieldFocused: isFieldFocused,
      appearance: appearance
    )

    let showsCard = storedLayout == .cardSplit || storedLayout == .groupedInset
    cardBackground.isHidden = !showsCard
    cardBackground.backgroundColor = appearance.cellBackgroundColor
    cardBackground.layer.cornerRadius = FKFormLayoutMetrics.cardCornerRadius
    cardBackground.layer.cornerCurve = .continuous
    cardBackground.layer.borderWidth = showsCard ? resolved.underlineThickness : 0
    cardBackground.layer.borderColor = resolved.cardBorderColor.cgColor

    let showsUnderline = storedLayout == .underline
    underline.isHidden = !showsUnderline || showsCard
    var dividerConfig = underline.configuration
    dividerConfig.color = resolved.underlineColor
    dividerConfig.thickness = resolved.underlineThickness
    dividerConfig.isPixelPerfect = false
    underline.configuration = dividerConfig

    var verticalConfig = verticalDivider.configuration
    verticalConfig.direction = .vertical
    verticalConfig.color = .separator
    verticalConfig.thickness = FKFormLayoutMetrics.phoneSplitDividerThickness
    verticalConfig.isPixelPerfect = false
    verticalDivider.configuration = verticalConfig

    if let text = resolved.messageText, !text.isEmpty {
      messageLabel.isHidden = false
      messageLabel.text = text
      messageLabel.textColor = resolved.messageColor
    } else {
      messageLabel.isHidden = true
      messageLabel.text = nil
    }

    alpha = isEnabled ? 1 : 0.5
  }

  func reset() {
    platformIcon.reset()
    topLabel.text = nil
    messageLabel.text = nil
    messageLabel.isHidden = true
    onPlatformPickerTapped = nil
    usernameFieldHost.subviews.forEach { $0.removeFromSuperview() }
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false

    cardBackground.translatesAutoresizingMaskIntoConstraints = false
    cardBackground.isHidden = true
    cardBackground.isUserInteractionEnabled = false

    rootStack.axis = .vertical
    rootStack.spacing = FKFormLayoutMetrics.labelFieldSpacing
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    topLabel.numberOfLines = 0
    topLabel.adjustsFontForContentSizeCategory = true
    topLabel.font = .preferredFont(forTextStyle: .footnote)
    topLabel.textColor = .secondaryLabel
    topLabel.isHidden = true

    splitRow.axis = .horizontal
    splitRow.alignment = .center
    splitRow.spacing = FKFormLayoutMetrics.phoneSplitDividerSpacing
    splitRow.translatesAutoresizingMaskIntoConstraints = false

    platformHost.translatesAutoresizingMaskIntoConstraints = false
    platformButton.translatesAutoresizingMaskIntoConstraints = false
    platformButton.addTarget(self, action: #selector(handlePlatformTap), for: .touchUpInside)
    platformButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
    platformButton.titleLabel?.adjustsFontForContentSizeCategory = true
    platformIcon.translatesAutoresizingMaskIntoConstraints = false

    verticalDivider.translatesAutoresizingMaskIntoConstraints = false
    usernameFieldHost.translatesAutoresizingMaskIntoConstraints = false
    usernameFieldHost.setContentHuggingPriority(.defaultLow, for: .horizontal)
    usernameFieldHost.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    underline.translatesAutoresizingMaskIntoConstraints = false
    var dividerConfig = FKDivider.defaultConfiguration
    dividerConfig.isPixelPerfect = false
    underline.configuration = dividerConfig

    messageLabel.numberOfLines = 0
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.font = .preferredFont(forTextStyle: .footnote)
    messageLabel.isHidden = true

    let platformRow = UIStackView(arrangedSubviews: [platformIcon, platformButton])
    platformRow.axis = .horizontal
    platformRow.spacing = 6
    platformRow.alignment = .center
    platformHost.addSubview(platformRow)
    NSLayoutConstraint.activate([
      platformRow.topAnchor.constraint(equalTo: platformHost.topAnchor),
      platformRow.leadingAnchor.constraint(equalTo: platformHost.leadingAnchor),
      platformRow.trailingAnchor.constraint(equalTo: platformHost.trailingAnchor),
      platformRow.bottomAnchor.constraint(equalTo: platformHost.bottomAnchor),
      platformIcon.widthAnchor.constraint(equalToConstant: 24),
      platformIcon.heightAnchor.constraint(equalToConstant: 24),
    ])

    splitRow.addArrangedSubview(platformHost)
    splitRow.addArrangedSubview(verticalDivider)
    splitRow.addArrangedSubview(usernameFieldHost)

    rootStack.addArrangedSubview(topLabel)
    rootStack.addArrangedSubview(splitRow)
    rootStack.addArrangedSubview(underline)
    rootStack.addArrangedSubview(messageLabel)

    addSubview(cardBackground)
    addSubview(rootStack)

    platformWidthConstraint = platformHost.widthAnchor.constraint(
      equalTo: splitRow.widthAnchor,
      multiplier: FKFormLayoutMetrics.phoneCountryWidthRatio
    )
    platformWidthConstraint?.isActive = true

    NSLayoutConstraint.activate([
      cardBackground.topAnchor.constraint(equalTo: splitRow.topAnchor, constant: -FKFormLayoutMetrics.cardContentInsets.top),
      cardBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
      cardBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
      cardBackground.bottomAnchor.constraint(equalTo: splitRow.bottomAnchor, constant: FKFormLayoutMetrics.cardContentInsets.bottom),

      rootStack.topAnchor.constraint(equalTo: topAnchor),
      rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
      rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
      rootStack.bottomAnchor.constraint(equalTo: bottomAnchor),

      underline.heightAnchor.constraint(equalToConstant: FKFormLayoutMetrics.underlineFocusedThickness),
      verticalDivider.widthAnchor.constraint(equalToConstant: FKFormLayoutMetrics.phoneSplitDividerThickness),
      splitRow.heightAnchor.constraint(greaterThanOrEqualToConstant: FKFormLayoutMetrics.minimumFieldRowHeight),
    ])
  }

  private func applyPlatformPicker(_ configuration: FKFormPlatformPickerConfiguration) {
    if let icon = configuration.icon {
      platformIcon.apply(icon)
      platformIcon.isHidden = false
    } else {
      platformIcon.isHidden = true
    }
    var buttonConfig = UIButton.Configuration.plain()
    buttonConfig.title = configuration.platformName
    buttonConfig.image = UIImage(systemName: "chevron.down")
    buttonConfig.imagePlacement = .trailing
    buttonConfig.imagePadding = 4
    buttonConfig.baseForegroundColor = .label
    platformButton.configuration = buttonConfig
    platformButton.accessibilityLabel = "Platform \(configuration.platformName)"
    platformButton.accessibilityTraits = [.button]
  }

  private func applyLabel(
    _ label: String?,
    layout: FKFormCellLayout,
    validation: FKFormFieldValidationPresentation,
    appearance: FKCellAppearanceConfiguration
  ) {
    let baseLabel: String?
    if let label, !label.isEmpty {
      baseLabel = label
    } else {
      baseLabel = nil
    }
    let requiredSuffix = validation.isRequired && validation.showsRequiredIndicator
    topLabel.text = baseLabel
    topLabel.isHidden = baseLabel == nil
    if requiredSuffix, let baseLabel {
      topLabel.text = baseLabel + " *"
      topLabel.textColor = appearance.destructiveColor
    } else {
      topLabel.textColor = .secondaryLabel
    }

    splitRow.layoutMargins = layout == .cardSplit || layout == .groupedInset
      ? FKFormLayoutMetrics.cardContentInsets
      : .zero
    splitRow.isLayoutMarginsRelativeArrangement = layout == .cardSplit || layout == .groupedInset
  }

  @objc private func handlePlatformTap() {
    onPlatformPickerTapped?()
  }
}
