import UIKit

/// Layout engine for read-only tappable value form rows (picker, date, time).
@MainActor
final class FKFormTappableValueChromeView: UIView {
  var onTap: (() -> Void)?

  let cardBackground = UIView()
  let rootStack = UIStackView()
  let topLabel = UILabel()
  let inlineLabel = UILabel()
  let fieldRow = UIStackView()
  let valueLabel = UILabel()
  let trailingHost = FKFormTrailingAccessoryHostView()
  let underline = FKDivider()
  let messageLabel = UILabel()

  private var inlineLabelWidthConstraint: NSLayoutConstraint?
  private var storedLayout: FKFormCellLayout = .underline
  private var appearance: FKCellAppearanceConfiguration = .default
  private var validation = FKFormFieldValidationPresentation()
  private var focusState: FKFormFieldFocusState = .unfocused

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    layout: FKFormCellLayout,
    label: String?,
    value: String?,
    placeholder: String?,
    validation: FKFormFieldValidationPresentation,
    trailingAccessory: FKFormTrailingAccessory,
    appearance: FKCellAppearanceConfiguration,
    focusState: FKFormFieldFocusState,
    isEnabled: Bool
  ) {
    storedLayout = layout
    self.appearance = appearance
    self.validation = validation
    self.focusState = focusState

    trailingHost.apply(trailingAccessory)
    applyLabel(label, layout: layout, validation: validation, appearance: appearance)
    applyValue(value: value, placeholder: placeholder, isEnabled: isEnabled)
    applyLayoutStructure(layout)
    refreshChrome(isEnabled: isEnabled)
  }

  func refreshChrome(isEnabled: Bool) {
    let resolved = FKFormFieldChromeStateResolver.resolve(
      layout: storedLayout,
      validation: validation,
      focusState: focusState,
      isFieldFocused: false,
      appearance: appearance
    )

    cardBackground.isHidden = !resolved.showsCard
    cardBackground.backgroundColor = appearance.cellBackgroundColor
    cardBackground.layer.cornerRadius = FKFormLayoutMetrics.cardCornerRadius
    cardBackground.layer.cornerCurve = .continuous
    cardBackground.layer.borderWidth = resolved.showsCard ? resolved.underlineThickness : 0
    cardBackground.layer.borderColor = resolved.cardBorderColor.cgColor

    let showsUnderline = storedLayout == .underline || storedLayout == .inlineLabel
    underline.isHidden = !showsUnderline || resolved.showsCard
    var dividerConfig = underline.configuration
    dividerConfig.color = resolved.underlineColor
    dividerConfig.thickness = resolved.underlineThickness
    dividerConfig.isPixelPerfect = false
    underline.configuration = dividerConfig

    if let text = resolved.messageText, !text.isEmpty {
      messageLabel.isHidden = false
      messageLabel.text = text
      messageLabel.textColor = resolved.messageColor
    } else {
      messageLabel.isHidden = true
      messageLabel.text = nil
    }

    isUserInteractionEnabled = isEnabled
    alpha = isEnabled ? 1 : 0.5
  }

  func reset() {
    trailingHost.reset()
    topLabel.text = nil
    inlineLabel.text = nil
    valueLabel.text = nil
    messageLabel.text = nil
    messageLabel.isHidden = true
    onTap = nil
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

    inlineLabel.numberOfLines = 0
    inlineLabel.adjustsFontForContentSizeCategory = true
    inlineLabel.font = .preferredFont(forTextStyle: .body)
    inlineLabel.textColor = .label
    inlineLabel.isHidden = true
    inlineLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    inlineLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

    fieldRow.axis = .horizontal
    fieldRow.alignment = .center
    fieldRow.spacing = FKFormLayoutMetrics.prefixTextSpacing
    fieldRow.translatesAutoresizingMaskIntoConstraints = false

    valueLabel.numberOfLines = 1
    valueLabel.adjustsFontForContentSizeCategory = true
    valueLabel.font = .preferredFont(forTextStyle: .body)
    valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    trailingHost.translatesAutoresizingMaskIntoConstraints = false

    underline.translatesAutoresizingMaskIntoConstraints = false
    var dividerConfig = FKDivider.defaultConfiguration
    dividerConfig.isPixelPerfect = false
    underline.configuration = dividerConfig

    messageLabel.numberOfLines = 0
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.font = .preferredFont(forTextStyle: .footnote)
    messageLabel.isHidden = true

    fieldRow.addArrangedSubview(inlineLabel)
    fieldRow.addArrangedSubview(valueLabel)
    fieldRow.addArrangedSubview(trailingHost)

    rootStack.addArrangedSubview(topLabel)
    rootStack.addArrangedSubview(fieldRow)
    rootStack.addArrangedSubview(underline)
    rootStack.addArrangedSubview(messageLabel)

    addSubview(cardBackground)
    addSubview(rootStack)

    inlineLabelWidthConstraint = inlineLabel.widthAnchor.constraint(equalToConstant: 96)
    inlineLabelWidthConstraint?.isActive = false

    NSLayoutConstraint.activate([
      cardBackground.topAnchor.constraint(equalTo: fieldRow.topAnchor, constant: -FKFormLayoutMetrics.cardContentInsets.top),
      cardBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
      cardBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
      cardBackground.bottomAnchor.constraint(equalTo: fieldRow.bottomAnchor, constant: FKFormLayoutMetrics.cardContentInsets.bottom),

      rootStack.topAnchor.constraint(equalTo: topAnchor),
      rootStack.leadingAnchor.constraint(equalTo: leadingAnchor),
      rootStack.trailingAnchor.constraint(equalTo: trailingAnchor),
      rootStack.bottomAnchor.constraint(equalTo: bottomAnchor),

      underline.heightAnchor.constraint(equalToConstant: FKFormLayoutMetrics.underlineFocusedThickness),
      fieldRow.heightAnchor.constraint(greaterThanOrEqualToConstant: FKFormLayoutMetrics.minimumFieldRowHeight),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
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
      inlineLabel.isHidden = true
      inlineLabel.text = nil
    case .cardInline:
      topLabel.isHidden = true
      topLabel.text = nil
      inlineLabel.isHidden = true
      inlineLabel.text = nil
    case .inlineLabel, .groupedInset:
      topLabel.isHidden = true
      topLabel.text = nil
      if let baseLabel {
        inlineLabel.text = requiredSuffix ? baseLabel + " *" : baseLabel
        inlineLabel.textColor = requiredSuffix ? appearance.destructiveColor : .label
        inlineLabel.isHidden = false
      } else {
        inlineLabel.isHidden = true
        inlineLabel.text = nil
      }
    case .iconUnderline, .cardSplit:
      topLabel.isHidden = true
      topLabel.text = nil
      inlineLabel.isHidden = true
      inlineLabel.text = nil
    }
  }

  private func applyValue(value: String?, placeholder: String?, isEnabled: Bool) {
    if let value, !value.isEmpty {
      valueLabel.text = value
      valueLabel.textColor = .label
    } else if let placeholder, !placeholder.isEmpty {
      valueLabel.text = placeholder
      valueLabel.textColor = .placeholderText
    } else {
      valueLabel.text = nil
      valueLabel.textColor = .label
    }
    valueLabel.isEnabled = isEnabled
  }

  private func applyLayoutStructure(_ layout: FKFormCellLayout) {
    let usesInlineLabelColumn = layout == .inlineLabel || layout == .groupedInset
    inlineLabelWidthConstraint?.isActive = usesInlineLabelColumn

    fieldRow.layoutMargins = FKFormLayoutMetrics.cardContentInsets
    fieldRow.isLayoutMarginsRelativeArrangement = layout == .cardStacked
      || layout == .cardInline
      || layout == .groupedInset
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if inlineLabelWidthConstraint?.isActive == true {
      let available = bounds.width
      inlineLabelWidthConstraint?.constant = max(72, available * FKFormLayoutMetrics.inlineLabelWidthRatio)
    }
  }

  @objc private func handleTap() {
    onTap?()
  }
}
