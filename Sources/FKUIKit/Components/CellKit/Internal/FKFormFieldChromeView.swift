import UIKit

/// Resolves underline and message colors for form field chrome.
@MainActor
enum FKFormFieldChromeStateResolver {
  struct ResolvedState {
    var underlineColor: UIColor
    var underlineThickness: CGFloat
    var messageText: String?
    var messageColor: UIColor
    var showsCard: Bool
    var cardBorderColor: UIColor
  }

  static func resolve(
    layout: FKFormCellLayout,
    validation: FKFormFieldValidationPresentation,
    focusState: FKFormFieldFocusState,
    isFieldFocused: Bool,
    appearance: FKCellAppearanceConfiguration
  ) -> ResolvedState {
    let showsCard = layout == .cardStacked || layout == .cardInline || layout == .groupedInset || layout == .cardSplit

    let underlineColor: UIColor
    let underlineThickness: CGFloat
    let messageText: String?
    let messageColor: UIColor

    if let error = validation.errorText, !error.isEmpty {
      underlineColor = appearance.destructiveColor
      underlineThickness = FKFormLayoutMetrics.underlineNormalThickness
      messageText = error
      messageColor = appearance.destructiveColor
    } else if let success = validation.successText, !success.isEmpty {
      underlineColor = .systemGreen
      underlineThickness = FKFormLayoutMetrics.underlineNormalThickness
      messageText = success
      messageColor = .systemGreen
    } else if focusState == .disabled {
      underlineColor = .separator
      underlineThickness = FKFormLayoutMetrics.underlineNormalThickness
      messageText = validation.helperText
      messageColor = appearance.secondaryLabelColor
    } else if isFieldFocused {
      underlineColor = appearance.linkColor
      underlineThickness = FKFormLayoutMetrics.underlineFocusedThickness
      messageText = validation.helperText
      messageColor = appearance.secondaryLabelColor
    } else {
      underlineColor = .separator
      underlineThickness = FKFormLayoutMetrics.underlineNormalThickness
      messageText = validation.helperText
      messageColor = appearance.secondaryLabelColor
    }

    return ResolvedState(
      underlineColor: underlineColor,
      underlineThickness: underlineThickness,
      messageText: messageText,
      messageColor: messageColor,
      showsCard: showsCard,
      cardBorderColor: underlineColor
    )
  }
}

/// Layout engine for text form cells across the five primary layouts (§11.5.2).
@MainActor
final class FKFormFieldChromeView: UIView {
  let cardBackground = UIView()
  let rootStack = UIStackView()
  let topLabel = UILabel()
  let inlineLabel = UILabel()
  let fieldRow = UIStackView()
  let leadingHost = FKFormLeadingAccessoryHostView()
  let trailingHost = FKFormTrailingAccessoryHostView()
  let textFieldHost = UIView()
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

  func install(textField: FKTextField) {
    textFieldHost.subviews.forEach { $0.removeFromSuperview() }
    textField.translatesAutoresizingMaskIntoConstraints = false
    textFieldHost.addSubview(textField)
    NSLayoutConstraint.activate([
      textField.topAnchor.constraint(equalTo: textFieldHost.topAnchor),
      textField.leadingAnchor.constraint(equalTo: textFieldHost.leadingAnchor),
      textField.trailingAnchor.constraint(equalTo: textFieldHost.trailingAnchor),
      textField.bottomAnchor.constraint(equalTo: textFieldHost.bottomAnchor),
      textField.heightAnchor.constraint(greaterThanOrEqualToConstant: FKFormLayoutMetrics.minimumFieldRowHeight),
    ])
    trailingHost.bind(textField: textField)
  }

  func apply(
    layout: FKFormCellLayout,
    label: String?,
    validation: FKFormFieldValidationPresentation,
    leadingAccessory: FKFormLeadingAccessory,
    trailingAccessory: FKFormTrailingAccessory,
    appearance: FKCellAppearanceConfiguration,
    focusState: FKFormFieldFocusState,
    isFieldFocused: Bool
  ) {
    storedLayout = layout
    self.appearance = appearance
    self.validation = validation
    self.focusState = focusState

    leadingHost.apply(leadingAccessory)
    trailingHost.apply(trailingAccessory)
    applyLabel(label, layout: layout, validation: validation, appearance: appearance)
    applyLayoutStructure(layout)
    refreshChrome(isFieldFocused: isFieldFocused)
  }

  func refreshChrome(isFieldFocused: Bool) {
    let resolved = FKFormFieldChromeStateResolver.resolve(
      layout: storedLayout,
      validation: validation,
      focusState: focusState,
      isFieldFocused: isFieldFocused,
      appearance: appearance
    )

    cardBackground.isHidden = !resolved.showsCard
    cardBackground.backgroundColor = appearance.cellBackgroundColor
    cardBackground.layer.cornerRadius = FKFormLayoutMetrics.cardCornerRadius
    cardBackground.layer.cornerCurve = .continuous
    cardBackground.layer.borderWidth = resolved.showsCard ? resolved.underlineThickness : 0
    cardBackground.layer.borderColor = resolved.cardBorderColor.cgColor

    let showsUnderline = storedLayout == .underline
      || storedLayout == .iconUnderline
      || storedLayout == .inlineLabel
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
  }

  func reset() {
    leadingHost.reset()
    trailingHost.reset()
    topLabel.text = nil
    inlineLabel.text = nil
    messageLabel.text = nil
    messageLabel.isHidden = true
    textFieldHost.subviews.forEach { $0.removeFromSuperview() }
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

    textFieldHost.translatesAutoresizingMaskIntoConstraints = false
    textFieldHost.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textFieldHost.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    leadingHost.translatesAutoresizingMaskIntoConstraints = false
    trailingHost.translatesAutoresizingMaskIntoConstraints = false

    underline.translatesAutoresizingMaskIntoConstraints = false
    var dividerConfig = FKDivider.defaultConfiguration
    dividerConfig.isPixelPerfect = false
    underline.configuration = dividerConfig

    messageLabel.numberOfLines = 0
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.font = .preferredFont(forTextStyle: .footnote)
    messageLabel.isHidden = true

    fieldRow.addArrangedSubview(leadingHost)
    fieldRow.addArrangedSubview(inlineLabel)
    fieldRow.addArrangedSubview(textFieldHost)
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
      inlineLabel.isHidden = true
      inlineLabel.text = nil
    case .cardInline, .iconUnderline:
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
    case .cardSplit:
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
    }
  }

  private func applyLayoutStructure(_ layout: FKFormCellLayout) {
    let usesInlineLabelColumn = layout == .inlineLabel || layout == .groupedInset
    inlineLabelWidthConstraint?.isActive = usesInlineLabelColumn

    let cardPadding = layout == .cardInline
      ? FKFormLayoutMetrics.cardContentInsets
      : FKFormLayoutMetrics.cardContentInsets
    fieldRow.layoutMargins = cardPadding
    fieldRow.isLayoutMarginsRelativeArrangement = layout == .cardStacked
      || layout == .cardInline
      || layout == .groupedInset
      || layout == .cardSplit
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if inlineLabelWidthConstraint?.isActive == true {
      let available = bounds.width
      inlineLabelWidthConstraint?.constant = max(72, available * FKFormLayoutMetrics.inlineLabelWidthRatio)
    }
  }
}
