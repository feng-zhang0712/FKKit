import UIKit

/// Multi-select checkbox control with optional title, subtitle, rich-text links, and indeterminate state.
///
/// Use ``setCheckState(_:animated:sendActions:)`` for programmatic updates. Global defaults: ``FKSelectionControlDefaults/checkbox``.
///
/// - Note: Named ``checkState`` (not `state`) to avoid colliding with ``UIControl/state``.
@MainActor
public final class FKCheckbox: UIControl {
  /// Style and behavior; assigning refreshes layout and appearance.
  public var configuration: FKCheckboxConfiguration {
    didSet { applyConfiguration() }
  }

  /// Title content; assigning refreshes labels and accessibility.
  public var content: FKCheckboxContentConfiguration {
    didSet { refreshContent(); setNeedsLayout(); invalidateIntrinsicContentSize(); updateAccessibility() }
  }

  /// Current three-state value. Setting syncs ``isSelected`` (`true` only when ``FKCheckboxState/checked``).
  public var checkState: FKCheckboxState {
    get { _checkState }
    set { setCheckState(newValue, animated: false, sendActions: false) }
  }

  /// Convenience for ``checkState`` == ``FKCheckboxState/checked``.
  public var isChecked: Bool { checkState == .checked }

  /// When `true`, draws an error border on unchecked / indeterminate indicators.
  public var showsError: Bool = false {
    didSet {
      guard oldValue != showsError else { return }
      refreshIndicator(animated: false)
      updateAccessibility()
    }
  }

  /// Mirrors ``FKCheckboxInteractionConfiguration/mode`` for quick overrides.
  public var interactionMode: FKSelectionControlInteractionMode {
    get { configuration.interaction.mode }
    set { configuration.interaction.mode = newValue }
  }

  /// Invoked when ``checkState`` changes via user or programmatic `sendActions: true`.
  public var onStateChanged: ((FKCheckboxState) -> Void)?

  /// Invoked when the user activates a link in ``FKCheckboxContentConfiguration/attributedTitle``.
  public var onLinkActivated: ((URL) -> Void)?

  private var _checkState: FKCheckboxState = .unchecked
  private let indicator = FKSelectionIndicatorView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let attributedTitleView = FKSelectionAttributedTextView()
  private var latestMetrics = FKSelectionRowLayout.Metrics(
    indicatorFrame: .zero,
    imageFrame: nil,
    titleFrame: nil,
    subtitleFrame: nil,
    contentHeight: FKSelectionControlMetrics.rowMinHeight
  )
  private var isApplyingHighlight = false
  private var lastTouchLocationInSelf: CGPoint?

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    configuration = FKSelectionControlDefaults.checkbox
    content = .init()
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    configuration = FKSelectionControlDefaults.checkbox
    content = .init()
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a checkbox with configuration and content.
  public init(
    configuration: FKCheckboxConfiguration = FKSelectionControlDefaults.checkbox,
    content: FKCheckboxContentConfiguration = .init()
  ) {
    self.configuration = configuration
    self.content = content
    super.init(frame: .zero)
    commonInit()
  }

  /// Convenience for a titled checkbox.
  public convenience init(title: String?, checkState: FKCheckboxState = .unchecked) {
    self.init(configuration: FKSelectionControlDefaults.checkbox, content: .init(title: title))
    setCheckState(checkState, animated: false, sendActions: false)
  }

  private func commonInit() {
    isAccessibilityElement = true
    backgroundColor = .clear
    clipsToBounds = false

    titleLabel.numberOfLines = 0
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.isAccessibilityElement = false

    subtitleLabel.numberOfLines = 2
    subtitleLabel.lineBreakMode = .byTruncatingTail
    subtitleLabel.isAccessibilityElement = false

    attributedTitleView.isHidden = true
    attributedTitleView.isAccessibilityElement = false
    // Touches are owned by the control so non-link title taps toggle (design §6.5).
    attributedTitleView.isUserInteractionEnabled = false

    addSubview(indicator)
    addSubview(titleLabel)
    addSubview(subtitleLabel)
    addSubview(attributedTitleView)

    applyConfiguration()
    refreshContent()
    refreshIndicator(animated: false)
    updateAccessibility()

    addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
  }

  // MARK: - Public API

  /// Replaces ``configuration`` and refreshes presentation.
  public func apply(_ configuration: FKCheckboxConfiguration) {
    self.configuration = configuration
  }

  /// Updates check state with optional animation and control events.
  public func setCheckState(_ checkState: FKCheckboxState, animated: Bool, sendActions: Bool) {
    let resolved = clampState(checkState)
    let changed = resolved != _checkState
    _checkState = resolved
    syncIsSelectedFlag()
    refreshIndicator(animated: animated)
    updateAccessibility()

    guard changed, sendActions else { return }
    FKSelectionControlHaptics.fire(configuration.interaction.haptic)
    self.sendActions(for: .valueChanged)
    onStateChanged?(resolved)
  }

  /// Toggles according to ``FKCheckboxInteractionConfiguration/indeterminateTapBehavior``.
  public func toggle(animated: Bool = true, sendActions: Bool = true) {
    let next: FKCheckboxState
    switch _checkState {
    case .unchecked:
      next = .checked
    case .checked:
      if configuration.interaction.indeterminateTapBehavior == .cycle {
        next = configuration.interaction.allowsIndeterminate ? .indeterminate : .unchecked
      } else {
        next = .unchecked
      }
    case .indeterminate:
      switch configuration.interaction.indeterminateTapBehavior {
      case .promoteToChecked:
        next = .checked
      case .promoteToUnchecked:
        next = .unchecked
      case .cycle:
        next = .unchecked
      }
    }
    setCheckState(next, animated: animated, sendActions: sendActions)
  }

  /// Applies an aggregate parent state from child checked flags without requiring a group type.
  public func applyAggregate(fromChildCheckedFlags flags: [Bool], sendActions: Bool = false) {
    setCheckState(FKCheckboxStateAggregator.aggregate(checkedFlags: flags), animated: true, sendActions: sendActions)
  }

  // MARK: - UIControl

  public override var isEnabled: Bool {
    didSet {
      guard oldValue != isEnabled else { return }
      refreshIndicator(animated: false)
      refreshContentColors()
      applyPressedVisual(false)
      updateAccessibility()
    }
  }

  public override var isHighlighted: Bool {
    didSet {
      guard oldValue != isHighlighted else { return }
      applyPressedVisual(isHighlighted && isEnabled && configuration.interaction.mode == .interactive)
    }
  }

  public override var isSelected: Bool {
    get { _checkState == .checked }
    set { setCheckState(newValue ? .checked : .unchecked, animated: false, sendActions: false) }
  }

  public override var intrinsicContentSize: CGSize {
    let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    let measured = measure(in: CGSize(width: width, height: .greatestFiniteMagnitude))
    return CGSize(width: UIView.noIntrinsicMetric, height: measured.contentHeight)
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    let measured = measure(in: size)
    let width = size.width > 0 ? size.width : UIView.noIntrinsicMetric
    return CGSize(width: width, height: measured.contentHeight)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    latestMetrics = measure(in: bounds.size)
    indicator.frame = latestMetrics.indicatorFrame

    let usesAttributed = content.attributedTitle != nil
    attributedTitleView.isHidden = !usesAttributed || configuration.layout.labelPlacement == .hidden
    titleLabel.isHidden = usesAttributed || configuration.layout.labelPlacement == .hidden || latestMetrics.titleFrame == nil

    if let titleFrame = latestMetrics.titleFrame {
      if usesAttributed {
        attributedTitleView.frame = titleFrame
      } else {
        titleLabel.frame = titleFrame
      }
    }

    if let subtitleFrame = latestMetrics.subtitleFrame {
      subtitleLabel.frame = subtitleFrame
      subtitleLabel.isHidden = configuration.layout.labelPlacement == .hidden
    } else {
      subtitleLabel.isHidden = true
    }
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    if configuration.layout.expandsHitTargetToMinimum {
      let hit = FKSelectionControlMetrics.expandedHitFrame(for: bounds)
      if hit.contains(point) { return true }
    }
    return super.point(inside: point, with: event)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    refreshIndicator(animated: false)
    refreshContentColors()
    setNeedsLayout()
  }

  // MARK: - Private

  @objc private func touchUpInside() {
    if let location = lastTouchLocationInSelf,
       content.attributedTitle != nil,
       !attributedTitleView.isHidden {
      let pointInText = attributedTitleView.convert(location, from: self)
      if attributedTitleView.bounds.contains(pointInText),
         let url = attributedTitleView.linkURL(at: pointInText) {
        handleLink(url)
        return
      }
    }
    guard canToggle else { return }
    guard configuration.interaction.togglesOnTouch else { return }
    toggle(animated: true, sendActions: true)
  }

  private var canToggle: Bool {
    isEnabled && configuration.interaction.mode == .interactive
  }

  private func handleLink(_ url: URL) {
    onLinkActivated?(url)
    if configuration.interaction.linkTapTogglesCheckbox, canToggle {
      toggle(animated: true, sendActions: true)
    }
  }

  private func clampState(_ state: FKCheckboxState) -> FKCheckboxState {
    if state == .indeterminate, !configuration.interaction.allowsIndeterminate {
      return .unchecked
    }
    return state
  }

  private func syncIsSelectedFlag() {
    // Keep UIControl selected bit aligned without re-entering `isSelected` setter.
    super.isSelected = (_checkState == .checked)
  }

  private func applyConfiguration() {
    indicator.size = configuration.layout.size
    indicator.tint = configuration.appearance.tint
    indicator.cornerRadiusOverride = configuration.appearance.cornerRadius
    indicator.uncheckedBorderColor = configuration.appearance.uncheckedBorderColor
    indicator.uncheckedBorderWidth = configuration.appearance.uncheckedBorderWidth
    indicator.checkmarkColor = configuration.appearance.checkmarkColor
    indicator.checkmarkImage = configuration.appearance.checkmarkImage
    indicator.indeterminateImage = configuration.appearance.indeterminateImage
    indicator.errorBorderColor = configuration.appearance.errorBorderColor
    indicator.disabledOnAlpha = configuration.appearance.disabledAlpha

    titleLabel.font = configuration.appearance.titleFont
    titleLabel.numberOfLines = configuration.layout.titleNumberOfLines
    subtitleLabel.font = configuration.appearance.subtitleFont
    subtitleLabel.numberOfLines = configuration.layout.subtitleNumberOfLines
    attributedTitleView.font = configuration.appearance.titleFont

    _checkState = clampState(_checkState)
    syncIsSelectedFlag()
    refreshContent()
    refreshIndicator(animated: false)
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    updateAccessibility()
  }

  private func refreshContent() {
    let usesAttributed = content.attributedTitle != nil
    if usesAttributed, let attributed = content.attributedTitle {
      var ns = NSAttributedString(attributed)
      if content.isRequired {
        ns = appendingRequiredAsterisk(to: ns)
      }
      attributedTitleView.attributedText = ns
      titleLabel.text = nil
    } else {
      attributedTitleView.attributedText = nil
      titleLabel.attributedText = nil
      if let title = content.title {
        if content.isRequired {
          titleLabel.attributedText = requiredTitle(title)
        } else {
          titleLabel.text = title
        }
      } else {
        titleLabel.text = nil
      }
    }

    subtitleLabel.text = content.subtitle
    refreshContentColors()
  }

  private func refreshContentColors() {
    let enabled = isEnabled
    titleLabel.textColor = enabled ? configuration.appearance.titleColor : configuration.appearance.disabledTitleColor
    subtitleLabel.textColor = enabled ? configuration.appearance.subtitleColor : configuration.appearance.disabledTitleColor
    attributedTitleView.textColor = enabled ? configuration.appearance.titleColor : configuration.appearance.disabledTitleColor
  }

  private func requiredTitle(_ title: String) -> NSAttributedString {
    let result = NSMutableAttributedString(
      string: title,
      attributes: [
        .font: configuration.appearance.titleFont,
        .foregroundColor: isEnabled ? configuration.appearance.titleColor : configuration.appearance.disabledTitleColor,
      ]
    )
    result.append(NSAttributedString(
      string: " *",
      attributes: [
        .font: configuration.appearance.titleFont,
        .foregroundColor: configuration.appearance.requiredAsteriskColor,
      ]
    ))
    return result
  }

  private func appendingRequiredAsterisk(to attributed: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: attributed)
    result.append(NSAttributedString(
      string: " *",
      attributes: [
        .font: configuration.appearance.titleFont,
        .foregroundColor: configuration.appearance.requiredAsteriskColor,
      ]
    ))
    return result
  }

  private func refreshIndicator(animated: Bool) {
    indicator.showsError = showsError && (_checkState == .unchecked || _checkState == .indeterminate)
    let presentation = resolvePresentation()
    if animated {
      layer.removeAllAnimations()
      indicator.layer.removeAllAnimations()
      indicator.animatePresentation(
        to: presentation,
        style: configuration.motion.selectionAnimation,
        duration: configuration.motion.animationDuration,
        respectsReducedMotion: configuration.motion.respectsReducedMotion
      )
    } else {
      indicator.presentation = presentation
    }
  }

  private func resolvePresentation() -> FKSelectionIndicatorPresentation {
    if isEnabled {
      switch _checkState {
      case .unchecked: return .checkboxUnchecked
      case .checked: return .checkboxChecked
      case .indeterminate: return .checkboxIndeterminate
      }
    }
    switch _checkState {
    case .unchecked: return .checkboxDisabled
    case .checked: return .checkboxDisabledOn
    case .indeterminate: return .checkboxDisabledIndeterminate
    }
  }

  private func applyPressedVisual(_ pressed: Bool) {
    guard !isApplyingHighlight else { return }
    isApplyingHighlight = true
    defer { isApplyingHighlight = false }
    let alpha = pressed ? configuration.appearance.pressedAlpha : 1
    let scale = pressed ? configuration.appearance.pressedScale : 1
    UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
      self.alpha = self.isEnabled ? alpha : 1
      self.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
  }

  private func measure(in size: CGSize) -> FKSelectionRowLayout.Metrics {
    let insets = configuration.layout.contentInsets
    let side = configuration.layout.size.indicatorSide
    let availableTextWidth: CGFloat = {
      let width = size.width > 0 ? size.width : UIScreen.main.bounds.width
      let occupied = insets.leading + insets.trailing + side + configuration.layout.indicatorTitleSpacing
      return max(0, width - occupied)
    }()

    let titleSize: CGSize
    if configuration.layout.labelPlacement == .hidden {
      titleSize = .zero
    } else if let attributed = content.attributedTitle {
      var ns = NSAttributedString(attributed)
      if content.isRequired { ns = appendingRequiredAsterisk(to: ns) }
      titleSize = FKSelectionRowLayout.measureAttributed(
        ns,
        numberOfLines: configuration.layout.titleNumberOfLines,
        width: availableTextWidth
      )
    } else if let title = content.title {
      let text = content.isRequired ? title + " *" : title
      titleSize = FKSelectionRowLayout.measureText(
        text,
        font: configuration.appearance.titleFont,
        numberOfLines: configuration.layout.titleNumberOfLines,
        width: availableTextWidth
      )
    } else {
      titleSize = .zero
    }

    let subtitleSize: CGSize
    if configuration.layout.labelPlacement == .hidden {
      subtitleSize = .zero
    } else {
      subtitleSize = FKSelectionRowLayout.measureText(
        content.subtitle,
        font: configuration.appearance.subtitleFont,
        numberOfLines: configuration.layout.subtitleNumberOfLines,
        width: availableTextWidth
      )
    }

    return FKSelectionRowLayout.metrics(
      in: CGRect(origin: .zero, size: CGSize(width: size.width > 0 ? size.width : UIScreen.main.bounds.width, height: size.height)),
      size: configuration.layout.size,
      contentInsets: insets,
      indicatorEdge: configuration.layout.indicatorEdge,
      labelPlacement: configuration.layout.labelPlacement,
      indicatorTitleSpacing: configuration.layout.indicatorTitleSpacing,
      titleSubtitleSpacing: configuration.layout.titleSubtitleSpacing,
      imageSize: nil,
      imageTitleSpacing: FKSelectionControlMetrics.imageTitleSpacing,
      titleSize: titleSize,
      subtitleSize: subtitleSize,
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      rowMinHeight: configuration.layout.rowMinHeight
    )
  }

  private func updateAccessibility() {
    if let custom = configuration.accessibility.customLabel, !custom.isEmpty {
      accessibilityLabel = custom
    } else {
      var parts: [String] = []
      if let attributed = content.attributedTitle {
        parts.append(String(attributed.characters))
      } else if let title = content.title {
        parts.append(title)
      }
      if content.isRequired {
        parts.append(FKSelectionControlI18n.requiredSuffix)
      }
      accessibilityLabel = parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    accessibilityHint = configuration.accessibility.customHint ?? FKSelectionControlI18n.checkboxHint

    switch _checkState {
    case .checked:
      accessibilityValue = FKSelectionControlI18n.checkboxChecked
    case .unchecked:
      accessibilityValue = FKSelectionControlI18n.checkboxUnchecked
    case .indeterminate:
      accessibilityValue = FKSelectionControlI18n.checkboxMixed
    }

    var traits: UIAccessibilityTraits = .button
    if _checkState == .checked { traits.insert(.selected) }
    if !isEnabled { traits.insert(.notEnabled) }
    accessibilityTraits = traits

    if showsError {
      accessibilityValue = [accessibilityValue, FKSelectionControlI18n.invalidValue]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
  }

  public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    lastTouchLocationInSelf = touch.location(in: self)
    let began = super.beginTracking(touch, with: event)
    if began { isHighlighted = true }
    return began
  }

  public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    lastTouchLocationInSelf = touch.location(in: self)
    isHighlighted = bounds.contains(touch.location(in: self))
    return super.continueTracking(touch, with: event)
  }

  public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    if let touch {
      lastTouchLocationInSelf = touch.location(in: self)
    }
    isHighlighted = false
    super.endTracking(touch, with: event)
  }

  public override func cancelTracking(with event: UIEvent?) {
    lastTouchLocationInSelf = nil
    isHighlighted = false
    super.cancelTracking(with: event)
  }
}
