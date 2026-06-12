import UIKit

/// Split country-code and phone-number layout for ``FKFormCellPhoneCell`` (X-06).
@MainActor
final class FKFormPhoneChromeView: UIView {
  var onCountryPickerTapped: (() -> Void)?

  let cardBackground = UIView()
  let rootStack = UIStackView()
  let topLabel = UILabel()
  let splitRow = UIStackView()
  let countryHost = FKFormLeadingAccessoryHostView()
  let verticalDivider = FKDivider()
  let phoneFieldHost = UIView()
  let underline = FKDivider()
  let messageLabel = UILabel()

  private var storedLayout: FKFormCellLayout = .underline
  private var appearance: FKCellAppearanceConfiguration = .default
  private var validation = FKFormFieldValidationPresentation()
  private var focusState: FKFormFieldFocusState = .unfocused
  private var countryWidthConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func install(phoneField: FKTextField) {
    phoneFieldHost.subviews.forEach { $0.removeFromSuperview() }
    phoneField.translatesAutoresizingMaskIntoConstraints = false
    phoneFieldHost.addSubview(phoneField)
    NSLayoutConstraint.activate([
      phoneField.topAnchor.constraint(equalTo: phoneFieldHost.topAnchor),
      phoneField.leadingAnchor.constraint(equalTo: phoneFieldHost.leadingAnchor),
      phoneField.trailingAnchor.constraint(equalTo: phoneFieldHost.trailingAnchor),
      phoneField.bottomAnchor.constraint(equalTo: phoneFieldHost.bottomAnchor),
      phoneField.heightAnchor.constraint(greaterThanOrEqualToConstant: FKFormLayoutMetrics.minimumFieldRowHeight),
    ])
  }

  func apply(
    layout: FKFormCellLayout,
    label: String?,
    countryPicker: FKFormCountryPickerConfiguration,
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

    countryHost.onCountryPickerTapped = onCountryPickerTapped
    countryHost.apply(.countryPicker(countryPicker))
    applyLabel(label, layout: layout, validation: validation, appearance: appearance)
    applyLayoutStructure(layout)
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
    countryHost.reset()
    topLabel.text = nil
    messageLabel.text = nil
    messageLabel.isHidden = true
    onCountryPickerTapped = nil
    phoneFieldHost.subviews.forEach { $0.removeFromSuperview() }
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

    countryHost.translatesAutoresizingMaskIntoConstraints = false
    verticalDivider.translatesAutoresizingMaskIntoConstraints = false
    phoneFieldHost.translatesAutoresizingMaskIntoConstraints = false
    phoneFieldHost.setContentHuggingPriority(.defaultLow, for: .horizontal)
    phoneFieldHost.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    underline.translatesAutoresizingMaskIntoConstraints = false
    var dividerConfig = FKDivider.defaultConfiguration
    dividerConfig.isPixelPerfect = false
    underline.configuration = dividerConfig

    messageLabel.numberOfLines = 0
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.font = .preferredFont(forTextStyle: .footnote)
    messageLabel.isHidden = true

    splitRow.addArrangedSubview(countryHost)
    splitRow.addArrangedSubview(verticalDivider)
    splitRow.addArrangedSubview(phoneFieldHost)

    rootStack.addArrangedSubview(topLabel)
    rootStack.addArrangedSubview(splitRow)
    rootStack.addArrangedSubview(underline)
    rootStack.addArrangedSubview(messageLabel)

    addSubview(cardBackground)
    addSubview(rootStack)

    countryWidthConstraint = countryHost.widthAnchor.constraint(
      equalTo: splitRow.widthAnchor,
      multiplier: FKFormLayoutMetrics.phoneCountryWidthRatio
    )
    countryWidthConstraint?.isActive = true

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

    switch layout {
    case .underline, .cardStacked:
      topLabel.text = baseLabel
      topLabel.isHidden = baseLabel == nil
      if requiredSuffix, let baseLabel {
        topLabel.text = baseLabel + " *"
        topLabel.textColor = appearance.destructiveColor
      } else {
        topLabel.textColor = .secondaryLabel
      }
    case .cardSplit, .groupedInset:
      topLabel.text = baseLabel
      topLabel.isHidden = baseLabel == nil
      if requiredSuffix, let baseLabel {
        topLabel.text = baseLabel + " *"
        topLabel.textColor = appearance.destructiveColor
      } else {
        topLabel.textColor = .secondaryLabel
      }
    default:
      topLabel.isHidden = true
      topLabel.text = nil
    }

    splitRow.layoutMargins = layout == .cardSplit || layout == .groupedInset
      ? FKFormLayoutMetrics.cardContentInsets
      : .zero
    splitRow.isLayoutMarginsRelativeArrangement = layout == .cardSplit || layout == .groupedInset
  }

  private func applyLayoutStructure(_ layout: FKFormCellLayout) {
    _ = layout
  }
}
