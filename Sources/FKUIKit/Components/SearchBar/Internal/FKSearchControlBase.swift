import UIKit

/// Shared runtime configuration consumed by the internal search control implementation.
struct FKSearchRuntimeConfiguration: Equatable {
  var layout: FKSearchLayoutConfiguration
  var appearance: FKSearchAppearanceConfiguration
  var textInput: FKSearchTextInputTraitsConfiguration
  var debounce: FKSearchDebounceConfiguration
  var clearButton: FKSearchClearButtonConfiguration
  var cancelButton: FKSearchCancelButtonConfiguration?
  var loading: FKSearchLoadingConfiguration
  var submit: FKSearchSubmitConfiguration
  var accessibility: FKSearchAccessibilityConfiguration

  init(barConfiguration: FKSearchBarConfiguration) {
    layout = barConfiguration.layout
    appearance = barConfiguration.appearance
    textInput = barConfiguration.textInput
    debounce = barConfiguration.debounce
    clearButton = barConfiguration.clearButton
    cancelButton = barConfiguration.cancelButton
    loading = barConfiguration.loading
    submit = barConfiguration.submit
    accessibility = barConfiguration.accessibility
  }

  init(fieldConfiguration: FKSearchFieldConfiguration) {
    layout = fieldConfiguration.layout
    appearance = fieldConfiguration.appearance
    textInput = fieldConfiguration.textInput
    debounce = fieldConfiguration.debounce
    clearButton = fieldConfiguration.clearButton
    cancelButton = nil
    loading = fieldConfiguration.loading
    submit = fieldConfiguration.submit
    accessibility = fieldConfiguration.accessibility
  }
}

/// Shared `UIControl` implementation for ``FKSearchBar`` and ``FKSearchField``.
///
/// Do not instantiate directly — use ``FKSearchBar`` or ``FKSearchField``.
@MainActor
public class FKSearchControlBase: UIControl, UITextFieldDelegate, UIGestureRecognizerDelegate {
  var runtimeConfiguration: FKSearchRuntimeConfiguration {
    didSet {
      coordinator.configuration = .init(
        debounce: runtimeConfiguration.debounce,
        textInput: runtimeConfiguration.textInput
      )
      applyConfiguration()
      refreshAccessoryVisibility(animated: false)
      invalidateIntrinsicContentSize()
      setNeedsLayout()
    }
  }

  public var callbacks = FKSearchCallbacks()
  public var placeholder: String? {
    didSet { refreshPlaceholder() }
  }

  public var text: String {
    get { _textField.text ?? "" }
    set { setText(newValue, options: .silent) }
  }

  public var isEditing: Bool { _textField.isFirstResponder }
  public private(set) var isLoading = false

  /// Underlying text input for advanced customization (`inputAccessoryView`, keyboard toolbar, etc.).
  ///
  /// - Important: Do not set ``UITextField/isSecureTextEntry`` — search controls reject secure entry.
  public var textField: UITextField { _textField }

  private let _textField = UITextField()
  private let chromeView = FKSearchChromeView()
  private let searchIconView = UIImageView()
  private var clearButton: UIButton?
  private var cancelButton: UIButton?
  private var loadingIndicator: UIActivityIndicatorView?

  private let coordinator: FKSearchInputCoordinator
  private var textAtEditingBegin = ""
  private var isCancelVisible = false
  private var latestMetrics = FKSearchLayoutEngine.Metrics(
    chromeFrame: .zero,
    searchIconFrame: .zero,
    textFieldFrame: .zero,
    loadingIndicatorFrame: .zero,
    clearButtonFrame: .zero,
    cancelButtonFrame: .zero,
    underlineFrame: nil,
    barHeight: 44
  )

  init(runtimeConfiguration: FKSearchRuntimeConfiguration) {
    self.runtimeConfiguration = runtimeConfiguration
    coordinator = FKSearchInputCoordinator(
      configuration: .init(
        debounce: runtimeConfiguration.debounce,
        textInput: runtimeConfiguration.textInput
      )
    )
    super.init(frame: .zero)
    commonInit()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  public func setText(_ text: String, options: FKSearchTextUpdateOptions) {
    let previous = _textField.text ?? ""
    guard previous != text else {
      if options.triggerSearchQueryChanged, !options.suppressEvents {
        emitSearchQueryChanged(coordinator.normalizedQuery(from: text))
      }
      return
    }

    _textField.text = text
    refreshAccessoryVisibility(animated: false)

    guard !options.suppressEvents else {
      if options.triggerSearchQueryChanged {
        emitSearchQueryChanged(coordinator.normalizedQuery(from: text))
      }
      return
    }

    emitTextChanged(text)
    if options.triggerSearchQueryChanged {
      emitSearchQueryChanged(coordinator.normalizedQuery(from: text))
    } else {
      scheduleSearchQuery(for: text)
    }
  }

  public func setLoading(_ isLoading: Bool, animated: Bool) {
    guard self.isLoading != isLoading else { return }
    self.isLoading = isLoading
    applyInputEnabledState()
    applyLayoutMetrics(animated: animated)

    if runtimeConfiguration.loading.announcesLoadingToVoiceOver {
      let message = isLoading
        ? FKUIKitI18n.string("fkuikit.common.loading")
        : FKUIKitI18n.string("fkuikit.search.loading_finished")
      UIAccessibility.post(notification: .announcement, argument: message)
    }
  }

  @discardableResult
  public override func becomeFirstResponder() -> Bool {
    _textField.becomeFirstResponder()
  }

  @discardableResult
  public override func resignFirstResponder() -> Bool {
    _textField.resignFirstResponder()
  }

  public override var isEnabled: Bool {
    didSet {
      _textField.isEnabled = isEnabled
      applyInputEnabledState()
      refreshVisualState()
    }
  }

  public override var intrinsicContentSize: CGSize {
    FKSearchLayoutEngine.intrinsicContentSize(
      layout: runtimeConfiguration.layout,
      appearance: runtimeConfiguration.appearance,
      showsCancelButton: showsCancelButton,
      isCancelVisible: isCancelVisible,
      cancelTitleSize: cancelTitleSize(),
      proposedWidth: bounds.width > 0 ? bounds.width : 320
    )
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    let width = size.width > 0 ? size.width : 320
    let height = FKSearchLayoutEngine.metrics(
      for: layoutInput(proposedWidth: width)
    ).barHeight
    return CGSize(width: width, height: height)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    applyLayoutMetrics(animated: false)
  }

  /// Applies computed layout metrics. Accessory views snap to their final frames and fade; only the text field width animates.
  private func applyLayoutMetrics(animated: Bool) {
    let metrics = FKSearchLayoutEngine.metrics(for: layoutInput(proposedWidth: bounds.width))
    let duration = runtimeConfiguration.cancelButton?.animationDuration ?? 0.25
    let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled

    let showsCancel = showsCancelButton && isCancelVisible
    let showsClear = shouldShowClearButton(for: _textField.text ?? "")
    let showsLoading = shouldShowLoadingIndicator()

    latestMetrics = metrics
    chromeView.frame = metrics.chromeFrame
    searchIconView.frame = metrics.searchIconFrame

    if showsCancel {
      let cancelButton = ensureCancelButton()
      cancelButton.isHidden = false
      cancelButton.frame = metrics.cancelButtonFrame
    }
    if showsClear {
      let clearButton = ensureClearButton()
      clearButton.isHidden = false
      clearButton.frame = metrics.clearButtonFrame
    }
    if showsLoading {
      let loadingIndicator = ensureLoadingIndicator()
      loadingIndicator.isHidden = false
      loadingIndicator.frame = metrics.loadingIndicatorFrame
      loadingIndicator.startAnimating()
    }

    refreshVisualState()

    let targetCancelAlpha: CGFloat = showsCancel ? 1 : 0
    let targetClearAlpha: CGFloat = showsClear ? 1 : 0
    let targetLoadingAlpha: CGFloat = showsLoading ? 1 : 0

    let finish = { [self] in
      self.finishAccessoryVisibility(
        showsCancel: showsCancel,
        showsClear: showsClear,
        showsLoading: showsLoading
      )
    }

    if shouldAnimate {
      if showsCancel, let cancelButton, cancelButton.alpha < 1 { cancelButton.alpha = 0 }
      if showsClear, let clearButton, clearButton.alpha < 1 { clearButton.alpha = 0 }
      if showsLoading, let loadingIndicator, loadingIndicator.alpha < 1 { loadingIndicator.alpha = 0 }

      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
        self._textField.frame = metrics.textFieldFrame
        self.cancelButton?.alpha = targetCancelAlpha
        self.clearButton?.alpha = targetClearAlpha
        self.loadingIndicator?.alpha = targetLoadingAlpha
      } completion: { _ in
        finish()
      }
    } else {
      _textField.frame = metrics.textFieldFrame
      cancelButton?.alpha = targetCancelAlpha
      clearButton?.alpha = targetClearAlpha
      loadingIndicator?.alpha = targetLoadingAlpha
      finish()
    }
  }

  private func finishAccessoryVisibility(showsCancel: Bool, showsClear: Bool, showsLoading: Bool) {
    if showsCancel {
      cancelButton?.isHidden = false
    } else {
      cancelButton?.isHidden = true
      cancelButton?.frame = .zero
    }

    if showsClear {
      clearButton?.isHidden = false
    } else {
      clearButton?.isHidden = true
      clearButton?.frame = .zero
    }

    if showsLoading {
      loadingIndicator?.isHidden = false
      loadingIndicator?.startAnimating()
    } else {
      releaseLoadingIndicator()
    }
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyConfiguration()
  }

  // MARK: - UITextFieldDelegate

  public func textFieldDidBeginEditing(_ textField: UITextField) {
    textAtEditingBegin = textField.text ?? ""
    syncCancelVisibilityForEditingState()
    refreshAccessoryVisibility(animated: true)
    emitEditingDidBegin()
  }

  public func textFieldDidEndEditing(_ textField: UITextField) {
    syncCancelVisibilityForEditingState()
    refreshAccessoryVisibility(animated: true)
    emitEditingDidEnd()
  }

  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    let raw = textField.text ?? ""
    let normalized = coordinator.normalizedQuery(from: raw)
    guard !normalized.isEmpty || runtimeConfiguration.submit.allowsEmptySubmit else {
      return true
    }
    emitSubmit(normalized)
    coordinator.flushSearchQuery(rawText: raw) { [weak self] query in
      self?.emitSearchQueryChanged(query)
    }
    if runtimeConfiguration.submit.submitResignsFirstResponder {
      _textField.resignFirstResponder()
    }
    return true
  }

  // MARK: - Event hooks (subclasses override for delegate)

  open func emitTextChanged(_ text: String) {
    callbacks.onTextChanged?(text)
  }

  open func emitSearchQueryChanged(_ query: String) {
    callbacks.onSearchQueryChanged?(query)
  }

  open func emitSubmit(_ query: String) {
    callbacks.onSubmit?(query)
  }

  open func emitClear() {
    callbacks.onClear?()
  }

  open func emitCancel() {
    callbacks.onCancel?()
  }

  open func emitEditingDidBegin() {
    callbacks.onEditingDidBegin?()
  }

  open func emitEditingDidEnd() {
    callbacks.onEditingDidEnd?()
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let touchedView = touch.view else { return true }
    if let clearButton, touchedView.isDescendant(of: clearButton) { return false }
    if let cancelButton, touchedView.isDescendant(of: cancelButton) { return false }
    return true
  }

  // MARK: - Private

  private var showsCancelButton: Bool {
    guard let cancel = runtimeConfiguration.cancelButton else { return false }
    return cancel.visibility != .never
  }

  private var needsClearButtonHost: Bool {
    runtimeConfiguration.clearButton.visibility != .never
  }

  private func syncAccessoryHosts() {
    if needsClearButtonHost {
      _ = ensureClearButton()
    } else {
      clearButton?.removeFromSuperview()
      clearButton = nil
    }

    if showsCancelButton {
      _ = ensureCancelButton()
    } else {
      cancelButton?.removeFromSuperview()
      cancelButton = nil
      isCancelVisible = false
    }

    if !shouldShowLoadingIndicator() {
      releaseLoadingIndicator()
    }
  }

  @discardableResult
  private func ensureClearButton() -> UIButton {
    if let clearButton { return clearButton }
    let button = UIButton(type: .system)
    button.addTarget(self, action: #selector(handleClearTapped), for: .touchUpInside)
    insertAccessorySubview(button)
    clearButton = button
    return button
  }

  @discardableResult
  private func ensureCancelButton() -> UIButton {
    if let cancelButton { return cancelButton }
    let button = UIButton(type: .system)
    button.addTarget(self, action: #selector(handleCancelTapped), for: .touchUpInside)
    button.setContentCompressionResistancePriority(.required, for: .horizontal)
    insertAccessorySubview(button)
    cancelButton = button
    return button
  }

  @discardableResult
  private func ensureLoadingIndicator() -> UIActivityIndicatorView {
    if let loadingIndicator { return loadingIndicator }
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = false
    insertAccessorySubview(indicator)
    loadingIndicator = indicator
    return indicator
  }

  private func releaseLoadingIndicator() {
    loadingIndicator?.stopAnimating()
    loadingIndicator?.removeFromSuperview()
    loadingIndicator = nil
  }

  private func insertAccessorySubview(_ view: UIView) {
    let anchor = loadingIndicator ?? cancelButton ?? clearButton ?? _textField
    insertSubview(view, aboveSubview: anchor)
  }

  private func commonInit() {
    backgroundColor = .clear
    clipsToBounds = false

    addSubview(chromeView)
    addSubview(searchIconView)
    addSubview(_textField)

    searchIconView.contentMode = .scaleAspectFit
    searchIconView.isAccessibilityElement = false

    _textField.borderStyle = .none
    _textField.backgroundColor = .clear
    _textField.clearButtonMode = .never
    _textField.delegate = self
    _textField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
    _textField.adjustsFontForContentSizeCategory = runtimeConfiguration.layout.growsWithDynamicType
    assert(_textField.isSecureTextEntry == false, "FKSearch controls do not support secure text entry.")

    let focusTap = UITapGestureRecognizer(target: self, action: #selector(handleFocusTap(_:)))
    focusTap.cancelsTouchesInView = false
    focusTap.delegate = self
    addGestureRecognizer(focusTap)

    applyConfiguration()
    refreshAccessoryVisibility(animated: false)
    updateAccessibility()
  }

  private func applyConfiguration() {
    let appearance = runtimeConfiguration.appearance
    let textInput = runtimeConfiguration.textInput
    let clear = runtimeConfiguration.clearButton
    let cancel = runtimeConfiguration.cancelButton

    let scaledFont = FKSearchLayoutEngine.scaledFont(
      for: appearance,
      layout: runtimeConfiguration.layout
    )
    _textField.font = scaledFont
    _textField.textColor = appearance.textStyle.textColor
    _textField.autocorrectionType = textInput.autocorrectionType
    _textField.autocapitalizationType = textInput.autocapitalizationType
    _textField.spellCheckingType = textInput.spellCheckingType
    _textField.smartQuotesType = textInput.smartQuotesType
    _textField.smartDashesType = textInput.smartDashesType
    _textField.returnKeyType = textInput.returnKeyType
    _textField.keyboardType = textInput.keyboardType
    _textField.textContentType = textInput.textContentType

    let symbolConfig = UIImage.SymbolConfiguration(pointSize: appearance.leadingIcon.pointSize, weight: .medium)
    let searchImage = appearance.leadingIcon.image
      ?? UIImage(systemName: "magnifyingglass", withConfiguration: symbolConfig)
    searchIconView.image = searchImage
    searchIconView.isHidden = appearance.leadingIcon.isHidden

    syncCancelVisibilityForEditingState()
    syncAccessoryHosts()

    let clearImage = clear.image
      ?? UIImage(systemName: "xmark.circle.fill", withConfiguration: symbolConfig)
    if let clearButton {
      clearButton.setImage(clearImage, for: .normal)
      clearButton.accessibilityLabel = clear.accessibilityLabel
    }

    if let cancel, let cancelButton {
      let title = cancel.title ?? FKUIKitI18n.string("fkuikit.common.cancel")
      cancelButton.setTitle(title, for: .normal)
      cancelButton.titleLabel?.font = appearance.cancelTitleStyle.font
      cancelButton.setTitleColor(appearance.cancelTitleStyle.textColor, for: .normal)
      cancelButton.accessibilityLabel = cancel.accessibilityLabel
    }

    refreshPlaceholder()
    applyInputEnabledState()
    refreshVisualState()
    updateAccessibility()
  }

  private func refreshVisualState() {
    let appearance = runtimeConfiguration.appearance
    let tint = resolvedTintColor()
    _textField.tintColor = tint
    searchIconView.tintColor = tint
    clearButton?.tintColor = tint
    alpha = isEnabled ? 1 : 0.6

    chromeView.apply(
      appearance: appearance,
      layout: runtimeConfiguration.layout,
      barHeight: latestMetrics.barHeight,
      isFocused: isEditing,
      isEnabled: isEnabled,
      underlineFrame: latestMetrics.underlineFrame
    )
  }

  private func resolvedTintColor() -> UIColor {
    let appearance = runtimeConfiguration.appearance
    let state: FKSearchBarStateAppearance
    if !isEnabled {
      state = appearance.stateAppearances.disabled
    } else if isEditing {
      state = appearance.stateAppearances.focused
    } else {
      state = appearance.stateAppearances.normal
    }
    return state.tintColor ?? appearance.tintColor
  }

  private func refreshPlaceholder() {
    guard let placeholder else {
      _textField.attributedPlaceholder = nil
      _textField.placeholder = nil
      return
    }
    let style = runtimeConfiguration.appearance.placeholderStyle
    let font = style.font
      ?? FKSearchLayoutEngine.scaledFont(for: runtimeConfiguration.appearance, layout: runtimeConfiguration.layout)
    _textField.attributedPlaceholder = NSAttributedString(
      string: placeholder,
      attributes: [
        .foregroundColor: style.textColor,
        .font: font,
      ]
    )
  }

  private func applyInputEnabledState() {
    let disabledByLoading = isLoading && runtimeConfiguration.loading.presentation == .disabledInput
    _textField.isUserInteractionEnabled = isEnabled && !disabledByLoading
  }

  @objc private func handleFocusTap(_ gesture: UITapGestureRecognizer) {
    guard isEnabled, gesture.state == .ended else { return }
    let location = gesture.location(in: self)
    if let clearButton, clearButton.frame.contains(location) { return }
    if let cancelButton, cancelButton.frame.contains(location) { return }
    if let loadingIndicator, loadingIndicator.frame.contains(location), shouldShowLoadingIndicator() { return }
    _ = _textField.becomeFirstResponder()
  }

  @objc private func handleEditingChanged() {
    let raw = _textField.text ?? ""
    refreshAccessoryVisibility(animated: true)
    emitTextChanged(raw)
    scheduleSearchQuery(for: raw)
  }

  @objc private func handleClearTapped() {
    _textField.text = ""
    refreshAccessoryVisibility(animated: true)
    emitClear()
    emitTextChanged("")

    if runtimeConfiguration.debounce.flushDebounceOnClear {
      coordinator.flushSearchQuery(rawText: "") { [weak self] query in
        self?.emitSearchQueryChanged(query)
      }
    } else {
      scheduleSearchQuery(for: "")
    }

    if runtimeConfiguration.clearButton.clearResignsFirstResponder {
      _textField.resignFirstResponder()
    }

    if runtimeConfiguration.clearButton.announcesClearToVoiceOver {
      UIAccessibility.post(
        notification: .announcement,
        argument: FKUIKitI18n.string("fkuikit.search.cleared")
      )
    }
  }

  @objc private func handleCancelTapped() {
    guard let cancel = runtimeConfiguration.cancelButton else { return }
    emitCancel()
    coordinator.cancelPending()

    switch cancel.policy {
    case .clearAndResign:
      _textField.text = ""
      emitTextChanged("")
      if runtimeConfiguration.debounce.flushDebounceOnClear {
        coordinator.flushSearchQuery(rawText: "") { [weak self] query in
          self?.emitSearchQueryChanged(query)
        }
      }
    case .resignOnly:
      break
    case .revertAndResign:
      _textField.text = textAtEditingBegin
      emitTextChanged(textAtEditingBegin)
      scheduleSearchQuery(for: textAtEditingBegin)
    }

    _textField.resignFirstResponder()
    refreshAccessoryVisibility(animated: true)
  }

  private func scheduleSearchQuery(for raw: String) {
    coordinator.scheduleSearchQuery(rawText: raw) { [weak self] query in
      self?.emitSearchQueryChanged(query)
    }
  }

  private func syncCancelVisibilityForEditingState() {
    guard runtimeConfiguration.cancelButton != nil else {
      isCancelVisible = false
      return
    }
    switch runtimeConfiguration.cancelButton!.visibility {
    case .whileEditing:
      isCancelVisible = isEditing
    case .always:
      isCancelVisible = true
    case .never:
      isCancelVisible = false
    }
  }

  private func refreshAccessoryVisibility(animated: Bool) {
    applyLayoutMetrics(animated: animated)
  }

  private func shouldShowClearButton(for text: String) -> Bool {
    switch runtimeConfiguration.clearButton.visibility {
    case .whileEditingNonEmpty:
      return isEditing && !text.isEmpty && !(isLoading && runtimeConfiguration.loading.hidesClearWhileLoading)
    case .whileNonEmpty:
      return !text.isEmpty && !(isLoading && runtimeConfiguration.loading.hidesClearWhileLoading)
    case .never:
      return false
    }
  }

  private func shouldShowLoadingIndicator() -> Bool {
    guard isLoading else { return false }
    switch runtimeConfiguration.loading.presentation {
    case .none:
      return false
    case .activityIndicator, .disabledInput:
      return true
    }
  }

  private func layoutInput(proposedWidth: CGFloat) -> FKSearchLayoutEngine.Input {
    FKSearchLayoutEngine.Input(
      bounds: CGRect(x: 0, y: 0, width: proposedWidth, height: 0),
      layout: runtimeConfiguration.layout,
      appearance: runtimeConfiguration.appearance,
      showsCancelButton: showsCancelButton,
      isCancelVisible: isCancelVisible,
      showsClearButton: shouldShowClearButton(for: _textField.text ?? ""),
      showsLoadingIndicator: shouldShowLoadingIndicator(),
      cancelTitleSize: cancelTitleSize(),
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      scaledTextFont: FKSearchLayoutEngine.scaledFont(
        for: runtimeConfiguration.appearance,
        layout: runtimeConfiguration.layout
      )
    )
  }

  private func cancelTitleSize() -> CGSize {
    guard showsCancelButton, let cancel = runtimeConfiguration.cancelButton else { return .zero }
    let title = cancel.title ?? FKUIKitI18n.string("fkuikit.common.cancel")
    let font = runtimeConfiguration.appearance.cancelTitleStyle.font
    return (title as NSString).size(withAttributes: [.font: font])
  }

  private func updateAccessibility() {
    let a11y = runtimeConfiguration.accessibility
    _textField.isAccessibilityElement = true
    _textField.accessibilityTraits.insert(.searchField)
    _textField.accessibilityLabel = a11y.textFieldLabel ?? placeholder
    _textField.accessibilityHint = a11y.textFieldHint
    searchIconView.isHiddenFromAccessibility = a11y.hidesDecorativeSearchIcon
  }
}

private extension UIView {
  var isHiddenFromAccessibility: Bool {
    get { accessibilityElementsHidden }
    set { accessibilityElementsHidden = newValue }
  }
}
