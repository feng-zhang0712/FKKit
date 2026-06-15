import UIKit

/// Composes icon, title, message, optional text field, confirmation switch, and buttons.
@MainActor
final class FKAlertContentView: UIView {
  var onActionSelected: ((FKAlertResolvedAction) -> Void)?
  var onPreferredContentSizeInvalidated: (() -> Void)?

  private let contentStack = UIStackView()
  private let iconImageView = UIImageView()
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let messageScrollView = UIScrollView()
  private let confirmationRow = UIStackView()
  private let confirmationLabel = UILabel()
  private let confirmationSwitch = UISwitch()
  private let buttonStackView = FKAlertButtonStackView()
  private var textField: FKTextField?
  private var messageHeightConstraint: NSLayoutConstraint?
  private var iconHeightConstraint: NSLayoutConstraint?
  private var actionSectionTopConstraint: NSLayoutConstraint?
  private var messageLabelScrollConstraints: [NSLayoutConstraint] = []
  private let bodyButtonSpacer = UIView()
  private var lastReportedPreferredHeight: CGFloat = 0
  private enum MessageLayoutMode: Equatable {
    case none
    case inline
    case scrolling(viewportHeight: CGFloat)
  }

  private var messageLayoutMode: MessageLayoutMode = .none

  private var content = FKAlertContent()
  private var configuration = FKAlertConfiguration()
  private var resolvedActions: [FKAlertResolvedAction] = []
  private var isConfirmationChecked = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    configureHierarchy()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    content: FKAlertContent,
    configuration: FKAlertConfiguration,
    resolvedActions: [FKAlertResolvedAction],
    isLoading: Bool
  ) {
    self.content = content
    self.configuration = configuration
    self.resolvedActions = resolvedActions
    backgroundColor = configuration.appearance.backgroundColor
    directionalLayoutMargins = configuration.appearance.contentInsets
    contentStack.spacing = configuration.appearance.bodyItemSpacing
    actionSectionTopConstraint?.constant = configuration.appearance.actionSectionSpacing

    applyIcon(content.icon)
    applyTitle(content.title)
    applyMessage(content)
    applyTextField(content.textInput)
    applyConfirmationRow(content.dangerousAction)
    applyButtons(isLoading: isLoading)
    invalidatePreferredContentSizeIfNeeded(forWidth: resolvedContentWidth())
  }

  /// Returns the alert body height for sheet fit-content sizing at the given width.
  func preferredContentHeight(forWidth width: CGFloat) -> CGFloat {
    let fittingWidth = max(1, width)
    let insets = configuration.appearance.contentInsets
    let contentWidth = max(1, fittingWidth - insets.leading - insets.trailing)
    applyLabelPreferredMaxWidths(contentWidth: contentWidth)
    updateMessageLayout(forContentWidth: contentWidth)

    var height = insets.top + insets.bottom
    var blockHeights: [CGFloat] = []

    if !iconImageView.isHidden {
      blockHeights.append(configuration.appearance.iconSize)
    }
    if !titleLabel.isHidden {
      blockHeights.append(measuredTitleHeight(forWidth: contentWidth))
    }
    if messageHasVisibleContent {
      blockHeights.append(resolvedMessageBlockHeight(forWidth: contentWidth))
    }
    if let textField, textField.superview != nil {
      blockHeights.append(measuredTextFieldHeight(forWidth: contentWidth))
    }
    if confirmationRow.superview != nil, !confirmationRow.isHidden {
      blockHeights.append(measuredConfirmationRowHeight(forWidth: contentWidth))
    }

    if !blockHeights.isEmpty {
      height += blockHeights.reduce(0, +)
      height += CGFloat(max(0, blockHeights.count - 1)) * configuration.appearance.bodyItemSpacing
    }

    height += configuration.appearance.actionSectionSpacing
    height += buttonStackView.measuredHeight(forWidth: contentWidth)
    return max(44, ceil(height))
  }

  private var messageHasVisibleContent: Bool {
    if messageLabel.attributedText.map({ !$0.string.isEmpty }) == true { return true }
    return !(messageLabel.text?.isEmpty ?? true)
  }

  private func measuredTitleHeight(forWidth contentWidth: CGFloat) -> CGFloat {
    guard !titleLabel.isHidden, let font = titleLabel.font else { return 0 }
    let text = titleLabel.text ?? ""
    guard !text.isEmpty else { return 0 }
    let rect = (text as NSString).boundingRect(
      with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    return ceil(rect.height)
  }

  private func measuredMessageHeight(forWidth contentWidth: CGFloat) -> CGFloat {
    if let attributed = messageLabel.attributedText, attributed.length > 0 {
      let rect = attributed.boundingRect(
        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
      )
      return ceil(rect.height)
    }
    guard let font = messageLabel.font else { return 0 }
    let text = messageLabel.text ?? ""
    guard !text.isEmpty else { return 0 }
    let rect = (text as NSString).boundingRect(
      with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )
    return ceil(rect.height)
  }

  private func measuredTextFieldHeight(forWidth contentWidth: CGFloat) -> CGFloat {
    guard let textField else { return resolvedTextFieldMinimumHeight() }
    let fittingSize = textField.sizeThatFits(
      CGSize(width: max(1, contentWidth), height: UIView.layoutFittingCompressedSize.height)
    )
    return max(resolvedTextFieldMinimumHeight(), fittingSize.height.rounded(.up))
  }

  private func resolvedTextFieldMinimumHeight() -> CGFloat {
    configuration.textField.usesCompactPreset ? 40 : 44
  }

  private func measuredConfirmationRowHeight(forWidth contentWidth: CGFloat) -> CGFloat {
    let switchWidth = confirmationSwitch.intrinsicContentSize.width
    let labelWidth = max(1, contentWidth - switchWidth - confirmationRow.spacing)
    let labelHeight = confirmationLabel.sizeThatFits(
      CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
    ).height
    let switchHeight = confirmationSwitch.intrinsicContentSize.height
    return max(labelHeight, switchHeight > 0 ? switchHeight : 31).rounded(.up)
  }

  private func applyLabelPreferredMaxWidths(contentWidth: CGFloat) {
    titleLabel.preferredMaxLayoutWidth = contentWidth
    messageLabel.preferredMaxLayoutWidth = contentWidth
  }

  func currentTextValue() -> String? {
    textField?.rawText
  }

  func focusPreferredElement() {
    if let textField {
      textField.becomeFirstResponder()
    } else if !titleLabel.isHidden {
      UIAccessibility.post(notification: .layoutChanged, argument: titleLabel)
    }
  }

  func validateTextInput() -> Bool {
    guard let textInput = content.textInput else { return true }
    let value = trimmedTextInputValue()
    if textInput.requiresNonEmptyInput, value.isEmpty {
      textField?.setError(
        message: textInput.nonEmptyFailureMessage
          ?? FKUIKitI18n.string("fkuikit.alert.text_input_required")
      )
      return false
    }
    guard let validation = textInput.validation else { return true }
    let isValid = validation.validate(value)
    if !isValid {
      textField?.setError(message: validation.failureMessage)
    }
    return isValid
  }

  func setLoading(_ isLoading: Bool) {
    buttonStackView.setLoading(isLoading)
    updateButtonStates(isLoading: isLoading)
  }

  private func applyButtons(isLoading: Bool) {
    buttonStackView.apply(
      resolvedActions: resolvedActions,
      configuration: configuration,
      isPrimaryEnabled: isPrimaryEnabled,
      destructiveEnabledProvider: { [weak self] action in
        self?.isDestructiveEnabled(for: action) ?? false
      }
    )
    if content.dangerousAction?.requiresConfirmationCheckbox == true {
      buttonStackView.refreshDestructiveAccessibility(
        isConfirmationRequired: true,
        isConfirmationChecked: isConfirmationChecked
      )
    }
    setLoading(isLoading)
  }

  private func updateButtonStates(isLoading: Bool = false) {
    buttonStackView.setPrimaryEnabled(!isLoading && isPrimaryEnabled)
    buttonStackView.updateDestructiveEnabled { [weak self] action in
      guard let self else { return false }
      return !isLoading && self.isDestructiveEnabled(for: action)
    }
  }

  private var isPrimaryEnabled: Bool {
    validateTextSilently()
  }

  private func isDestructiveEnabled(for action: FKAlertResolvedAction) -> Bool {
    guard action.role == .destructive else { return true }
    guard isPrimaryEnabled else { return false }
    guard let options = content.dangerousAction, options.requiresConfirmationCheckbox else { return true }
    if let index = options.destructiveActionIndex, action.sourceIndex != index {
      return true
    }
    return isConfirmationChecked
  }

  private func validateTextSilently() -> Bool {
    guard satisfiesNonEmptyInputRequirement() else { return false }
    guard let validation = content.textInput?.validation else { return true }
    let value = trimmedTextInputValue()
    let isValid = validation.validate(value)
    if isValid {
      textField?.setError(message: nil)
    }
    return isValid
  }

  private func trimmedTextInputValue() -> String {
    currentTextValue()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  private func satisfiesNonEmptyInputRequirement() -> Bool {
    guard content.textInput?.requiresNonEmptyInput == true else { return true }
    return !trimmedTextInputValue().isEmpty
  }

  private func configureHierarchy() {
    contentStack.axis = .vertical
    contentStack.alignment = .fill
    contentStack.translatesAutoresizingMaskIntoConstraints = false
    contentStack.setContentHuggingPriority(.required, for: .vertical)
    contentStack.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    bodyButtonSpacer.translatesAutoresizingMaskIntoConstraints = false
    bodyButtonSpacer.setContentHuggingPriority(.defaultLow, for: .vertical)
    bodyButtonSpacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    bodyButtonSpacer.isAccessibilityElement = false
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    iconImageView.isHidden = true
    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentHuggingPriority(.required, for: .vertical)
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.setContentHuggingPriority(.required, for: .vertical)
    messageLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    messageScrollView.translatesAutoresizingMaskIntoConstraints = false
    messageScrollView.showsVerticalScrollIndicator = true
    messageScrollView.isHidden = true
    messageScrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
    messageScrollView.setContentCompressionResistancePriority(.required, for: .vertical)
    confirmationRow.axis = .horizontal
    confirmationRow.spacing = 12
    confirmationRow.alignment = .center
    confirmationRow.translatesAutoresizingMaskIntoConstraints = false
    confirmationRow.isHidden = true
    confirmationLabel.numberOfLines = 0
    confirmationLabel.translatesAutoresizingMaskIntoConstraints = false
    confirmationLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    confirmationSwitch.translatesAutoresizingMaskIntoConstraints = false
    confirmationSwitch.setContentHuggingPriority(.required, for: .horizontal)
    confirmationSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.isConfirmationChecked = self.confirmationSwitch.isOn
      self.updateButtonStates()
      self.buttonStackView.refreshDestructiveAccessibility(
        isConfirmationRequired: self.content.dangerousAction?.requiresConfirmationCheckbox == true,
        isConfirmationChecked: self.isConfirmationChecked
      )
      UIAccessibility.post(notification: .announcement, argument: self.confirmationAccessibilityAnnouncement())
    }, for: .valueChanged)
    buttonStackView.translatesAutoresizingMaskIntoConstraints = false
    buttonStackView.setContentHuggingPriority(.required, for: .vertical)
    buttonStackView.setContentCompressionResistancePriority(.required, for: .vertical)
    buttonStackView.onActionSelected = { [weak self] action in
      self?.onActionSelected?(action)
    }

    addSubview(contentStack)
    addSubview(bodyButtonSpacer)
    addSubview(buttonStackView)
    contentStack.addArrangedSubview(iconImageView)
    contentStack.addArrangedSubview(titleLabel)
    contentStack.addArrangedSubview(messageScrollView)
    messageScrollView.addSubview(messageLabel)
    confirmationRow.addArrangedSubview(confirmationLabel)
    confirmationRow.addArrangedSubview(confirmationSwitch)

    messageLabelScrollConstraints = [
      messageLabel.topAnchor.constraint(equalTo: messageScrollView.contentLayoutGuide.topAnchor),
      messageLabel.leadingAnchor.constraint(equalTo: messageScrollView.contentLayoutGuide.leadingAnchor),
      messageLabel.trailingAnchor.constraint(equalTo: messageScrollView.contentLayoutGuide.trailingAnchor),
      messageLabel.bottomAnchor.constraint(equalTo: messageScrollView.contentLayoutGuide.bottomAnchor),
      messageLabel.widthAnchor.constraint(equalTo: messageScrollView.frameLayoutGuide.widthAnchor),
    ]

    let actionSectionTop = buttonStackView.topAnchor.constraint(
      equalTo: bodyButtonSpacer.bottomAnchor,
      constant: FKAlertAppearanceConfiguration().actionSectionSpacing
    )
    actionSectionTopConstraint = actionSectionTop

    NSLayoutConstraint.activate([
      contentStack.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
      contentStack.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      contentStack.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

      bodyButtonSpacer.topAnchor.constraint(equalTo: contentStack.bottomAnchor),
      bodyButtonSpacer.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      bodyButtonSpacer.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      bodyButtonSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),

      actionSectionTop,
      buttonStackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
      buttonStackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
      buttonStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
    ])
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    applyLabelPreferredMaxWidths(contentWidth: resolvedContentWidth())
    updateMessageLayout(forContentWidth: resolvedContentWidth())
    invalidatePreferredContentSizeIfNeeded(forWidth: bounds.width)
  }

  private func invalidatePreferredContentSizeIfNeeded(forWidth width: CGFloat) {
    let fittingWidth = width > 1 ? width : 320
    let nextHeight = preferredContentHeight(forWidth: fittingWidth)
    guard abs(nextHeight - lastReportedPreferredHeight) > 0.5 else { return }
    lastReportedPreferredHeight = nextHeight
    onPreferredContentSizeInvalidated?()
  }

  private func applyIcon(_ icon: FKAlertIcon?) {
    iconHeightConstraint?.isActive = false
    guard let icon else {
      iconImageView.isHidden = true
      iconImageView.image = nil
      return
    }
    switch icon {
    case .none:
      iconImageView.isHidden = true
      iconImageView.image = nil
    case .systemName(let name, let tint):
      iconImageView.isHidden = false
      iconImageView.isAccessibilityElement = false
      iconImageView.image = UIImage(systemName: name)
      iconImageView.tintColor = resolvedTint(tint)
      iconHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: configuration.appearance.iconSize)
      iconHeightConstraint?.isActive = true
    case .asset(let name, let bundle):
      iconImageView.isHidden = false
      iconImageView.isAccessibilityElement = false
      iconImageView.image = UIImage(named: name, in: bundle, compatibleWith: traitCollection)
      iconImageView.tintColor = nil
      iconHeightConstraint = iconImageView.heightAnchor.constraint(equalToConstant: configuration.appearance.iconSize)
      iconHeightConstraint?.isActive = true
    }
  }

  private func applyTitle(_ title: String?) {
    if let title, !title.isEmpty {
      titleLabel.isHidden = false
      titleLabel.text = title
      titleLabel.font = UIFont.preferredFont(forTextStyle: configuration.appearance.titleTextStyle)
      titleLabel.adjustsFontForContentSizeCategory = true
      titleLabel.textColor = configuration.appearance.titleColor
      titleLabel.accessibilityTraits = .header
    } else {
      titleLabel.isHidden = true
      titleLabel.text = nil
    }
  }

  private func applyMessage(_ content: FKAlertContent) {
    let font = UIFont.preferredFont(forTextStyle: configuration.appearance.messageTextStyle)
    messageLabel.font = font
    messageLabel.adjustsFontForContentSizeCategory = true
    messageLabel.textColor = configuration.appearance.messageColor

    if let attributed = FKAlertActionResolver.resolvedAttributedMessage(from: content.attributedMessage) {
      messageLabel.attributedText = attributed
      messageLabel.text = nil
    } else if let message = content.message, !message.isEmpty {
      messageLabel.text = message
      messageLabel.attributedText = nil
    } else {
      messageLabel.text = nil
      messageLabel.attributedText = nil
      applyMessageLayoutMode(.none)
    }
    updateMessageLayout(forContentWidth: resolvedContentWidth() > 1 ? resolvedContentWidth() : 280)
    setNeedsLayout()
  }

  private func updateMessageLayout(forContentWidth width: CGFloat) {
    guard messageHasVisibleContent else {
      applyMessageLayoutMode(.none)
      return
    }

    messageLabel.isHidden = false
    guard width > 1 else { return }

    let measured = measuredMessageHeight(forWidth: width)
    let maxHeight = configuration.appearance.maxMessageHeight ?? estimatedMessageScrollViewportHeight()
    let nextMode: MessageLayoutMode = measured <= maxHeight
      ? .inline
      : .scrolling(viewportHeight: maxHeight)
    applyMessageLayoutMode(nextMode)
  }

  private func resolvedMessageBlockHeight(forWidth contentWidth: CGFloat) -> CGFloat {
    switch messageLayoutMode {
    case .none:
      return 0
    case .inline:
      return measuredMessageHeight(forWidth: contentWidth)
    case let .scrolling(viewportHeight):
      return ceil(viewportHeight)
    }
  }

  private func applyMessageLayoutMode(_ mode: MessageLayoutMode) {
    guard messageLayoutMode != mode else { return }
    tearDownMessageLayout()
    messageLayoutMode = mode

    switch mode {
    case .none:
      messageScrollView.isHidden = true
      messageLabel.isHidden = true
      removeMessageLabelFromBodyStackIfNeeded()
    case .inline:
      presentInlineMessage()
    case let .scrolling(viewportHeight):
      presentScrollingMessage(viewportHeight: viewportHeight)
    }
  }

  private func tearDownMessageLayout() {
    messageHeightConstraint?.isActive = false
    messageHeightConstraint = nil
    NSLayoutConstraint.deactivate(messageLabelScrollConstraints)
  }

  private func presentInlineMessage() {
    messageScrollView.isHidden = true
    if messageLabel.superview !== contentStack {
      messageLabel.removeFromSuperview()
      contentStack.insertArrangedSubview(messageLabel, at: messageInsertionIndex())
    }
  }

  private func presentScrollingMessage(viewportHeight: CGFloat) {
    removeMessageLabelFromBodyStackIfNeeded()
    messageScrollView.isHidden = false
    if messageLabel.superview !== messageScrollView {
      messageLabel.removeFromSuperview()
      messageScrollView.addSubview(messageLabel)
    }
    NSLayoutConstraint.activate(messageLabelScrollConstraints)
    messageHeightConstraint = messageScrollView.heightAnchor.constraint(equalToConstant: viewportHeight)
    messageHeightConstraint?.isActive = true
  }

  private func messageInsertionIndex() -> Int {
    if let titleIndex = contentStack.arrangedSubviews.firstIndex(of: titleLabel) {
      return titleIndex + 1
    }
    return contentStack.arrangedSubviews.count
  }

  private func removeMessageLabelFromBodyStackIfNeeded() {
    guard contentStack.arrangedSubviews.contains(messageLabel) else { return }
    contentStack.removeArrangedSubview(messageLabel)
    messageLabel.removeFromSuperview()
  }

  private func resolvedContentWidth() -> CGFloat {
    guard bounds.width > 1 else { return 0 }
    return bounds.width - layoutMargins.left - layoutMargins.right
  }

  private func estimatedMessageScrollViewportHeight() -> CGFloat {
    let font = UIFont.preferredFont(forTextStyle: configuration.appearance.messageTextStyle)
    let lineHeight = font.lineHeight
    // Reserve a taller scroll viewport so long legal copy remains easy to read and scroll.
    let minimumViewport = lineHeight * 12
    let screenHeight = window?.windowScene?.screen.bounds.height ?? UIScreen.main.bounds.height
    let maximumViewport = max(minimumViewport, screenHeight * 0.42)
    return min(maximumViewport, 360)
  }

  private func applyTextField(_ textInput: FKAlertTextInput?) {
    textField?.removeFromSuperview()
    textField = nil
    guard let textInput else { return }

    let formatType: FKTextFieldFormatType = textInput.isSecure
      ? .password(minLength: 0, maxLength: textInput.maxLength ?? 256, validatesStrength: false)
      : .custom(regex: ".", maxLength: textInput.maxLength, separator: nil, groupPattern: [])
    var rule = FKTextFieldInputRule(formatType: formatType, maxLength: textInput.maxLength)
    rule.allowsWhitespace = true
    rule.allowsSpecialCharacters = true
    var fieldConfiguration = FKTextFieldConfiguration(inputRule: rule, placeholder: textInput.placeholder)
    applyAlertTextFieldConfiguration(&fieldConfiguration)
    fieldConfiguration.textInputTraits.textContentType = textInput.textContentType
    fieldConfiguration.textInputTraits.returnKeyType = textInput.returnKeyType
    fieldConfiguration.textInputTraits.autocapitalizationType = textInput.autocapitalization

    let field = FKTextField(configuration: fieldConfiguration)
    field.text = textInput.initialText
    field.keyboardType = textInput.keyboardType
    field.translatesAutoresizingMaskIntoConstraints = false
    field.setContentHuggingPriority(.required, for: .vertical)
    field.setContentCompressionResistancePriority(.required, for: .vertical)
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: resolvedTextFieldMinimumHeight()).isActive = true
    field.onEditingChanged = { [weak self] _, _ in
      self?.updateButtonStates()
    }
    field.onDidSubmit = { [weak self] _ in
      guard let self, let primary = self.resolvedActions.first(where: { $0.role == .primary }) else { return }
      guard self.validateTextInput() else { return }
      self.onActionSelected?(primary)
    }
    textField = field

    if let index = contentStack.arrangedSubviews.firstIndex(of: confirmationRow) {
      contentStack.insertArrangedSubview(field, at: index)
    } else {
      contentStack.addArrangedSubview(field)
    }
  }

  private func applyAlertTextFieldConfiguration(_ fieldConfiguration: inout FKTextFieldConfiguration) {
    fieldConfiguration.inlineMessage.showsErrorMessage = true
    guard configuration.textField.usesCompactPreset else { return }
    fieldConfiguration.layout.textAreaHeight = 40
  }

  private func applyConfirmationRow(_ options: FKAlertDangerousActionOptions?) {
    guard let options, options.requiresConfirmationCheckbox else {
      removeConfirmationRowIfNeeded()
      isConfirmationChecked = true
      return
    }

    if confirmationRow.superview == nil {
      contentStack.addArrangedSubview(confirmationRow)
    }

    confirmationRow.isHidden = false
    confirmationLabel.text = options.checkboxTitle
    confirmationLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    confirmationSwitch.isOn = false
    isConfirmationChecked = false
    confirmationSwitch.accessibilityLabel = options.checkboxTitle
  }

  private func removeConfirmationRowIfNeeded() {
    guard confirmationRow.superview != nil else { return }
    contentStack.removeArrangedSubview(confirmationRow)
    confirmationRow.removeFromSuperview()
    confirmationRow.isHidden = true
    confirmationLabel.text = nil
    confirmationSwitch.isOn = false
    confirmationSwitch.accessibilityLabel = nil
  }

  private func resolvedTint(_ tint: FKAlertIconTint?) -> UIColor {
    switch tint {
    case .warning:
      return .systemOrange
    case .destructive:
      return .systemRed
    case .primary, nil:
      return .label
    }
  }

  private func confirmationAccessibilityAnnouncement() -> String {
    if isConfirmationChecked {
      return FKUIKitI18n.string("fkuikit.alert.confirmation_enabled")
    }
    return FKUIKitI18n.string("fkuikit.alert.confirmation_disabled")
  }
}
