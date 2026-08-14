import UIKit

/// Single circular radio indicator with optional title, subtitle, and image.
///
/// Standalone instances do **not** enforce mutual exclusion — use ``FKRadioGroup`` or host logic.
@MainActor
public final class FKRadioButton: UIControl {
  public var configuration: FKRadioButtonConfiguration {
    didSet { applyConfiguration() }
  }

  public var content: FKRadioButtonContentConfiguration {
    didSet { refreshContent(); setNeedsLayout(); invalidateIntrinsicContentSize(); updateAccessibility() }
  }

  public var showsError: Bool = false {
    didSet {
      guard oldValue != showsError else { return }
      refreshIndicator(animated: false)
      updateAccessibility()
    }
  }

  public var interactionMode: FKSelectionControlInteractionMode {
    get { configuration.interaction.mode }
    set {
      configuration.interaction.mode = newValue
    }
  }

  public var onSelectionChanged: ((Bool) -> Void)?
  public var onLinkActivated: ((URL) -> Void)?

  /// When `true`, the group owns selection and ignores standalone tap deselection rules.
  var selectionManagedExternally: Bool = false

  private let indicator = FKSelectionIndicatorView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let imageView = UIImageView()
  private let attributedTitleView = FKSelectionAttributedTextView()
  private var latestMetrics = FKSelectionRowLayout.Metrics(
    indicatorFrame: .zero,
    imageFrame: nil,
    titleFrame: nil,
    subtitleFrame: nil,
    contentHeight: FKSelectionControlMetrics.rowMinHeight
  )
  private var _selected: Bool = false
  private var lastTouchLocationInSelf: CGPoint?

  public override init(frame: CGRect) {
    configuration = FKSelectionControlDefaults.radioButton
    content = .init()
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    configuration = FKSelectionControlDefaults.radioButton
    content = .init()
    super.init(coder: coder)
    commonInit()
  }

  public init(
    configuration: FKRadioButtonConfiguration = FKSelectionControlDefaults.radioButton,
    content: FKRadioButtonContentConfiguration = .init()
  ) {
    self.configuration = configuration
    self.content = content
    super.init(frame: .zero)
    commonInit()
  }

  public convenience init(title: String?, isSelected: Bool = false) {
    self.init(content: .init(title: title))
    setSelected(isSelected, animated: false, sendActions: false)
  }

  private func commonInit() {
    isAccessibilityElement = true
    backgroundColor = .clear

    titleLabel.numberOfLines = 0
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.isAccessibilityElement = false

    subtitleLabel.numberOfLines = 2
    subtitleLabel.lineBreakMode = .byTruncatingTail
    subtitleLabel.isAccessibilityElement = false

    imageView.contentMode = .scaleAspectFit
    imageView.isAccessibilityElement = false
    imageView.isUserInteractionEnabled = false

    attributedTitleView.isHidden = true
    attributedTitleView.isAccessibilityElement = false
    attributedTitleView.isUserInteractionEnabled = false

    addSubview(indicator)
    addSubview(imageView)
    addSubview(titleLabel)
    addSubview(subtitleLabel)
    addSubview(attributedTitleView)

    applyConfiguration()
    refreshContent()
    refreshIndicator(animated: false)
    updateAccessibility()
    addTarget(self, action: #selector(touchUpInside), for: .touchUpInside)
  }

  public func apply(_ configuration: FKRadioButtonConfiguration) {
    self.configuration = configuration
  }

  public func setSelected(_ selected: Bool, animated: Bool, sendActions: Bool) {
    let changed = selected != _selected
    _selected = selected
    super.isSelected = selected
    refreshIndicator(animated: animated)
    updateAccessibility()

    guard changed, sendActions else { return }
    FKSelectionControlHaptics.fire(configuration.interaction.haptic)
    self.sendActions(for: .valueChanged)
    onSelectionChanged?(selected)
  }

  public override var isSelected: Bool {
    get { _selected }
    set { setSelected(newValue, animated: false, sendActions: false) }
  }

  public override var isEnabled: Bool {
    didSet {
      guard oldValue != isEnabled else { return }
      refreshIndicator(animated: false)
      refreshContentColors()
      updateAccessibility()
    }
  }

  public override var isHighlighted: Bool {
    didSet {
      guard oldValue != isHighlighted else { return }
      let pressed = isHighlighted && isEnabled && configuration.interaction.mode == .interactive
      let alpha = pressed ? configuration.appearance.pressedAlpha : 1
      let scale = pressed ? configuration.appearance.pressedScale : 1
      UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
        self.alpha = self.isEnabled ? alpha : 1
        self.transform = CGAffineTransform(scaleX: scale, y: scale)
      }
    }
  }

  public override var intrinsicContentSize: CGSize {
    let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    return CGSize(width: UIView.noIntrinsicMetric, height: measure(in: CGSize(width: width, height: 0)).contentHeight)
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    let measured = measure(in: size)
    return CGSize(width: size.width > 0 ? size.width : UIView.noIntrinsicMetric, height: measured.contentHeight)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    latestMetrics = measure(in: bounds.size)
    indicator.frame = latestMetrics.indicatorFrame

    if let imageFrame = latestMetrics.imageFrame {
      imageView.frame = imageFrame
      imageView.isHidden = content.image == nil
    } else {
      imageView.isHidden = true
    }

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
      subtitleLabel.isHidden = false
    } else {
      subtitleLabel.isHidden = true
    }
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    if configuration.layout.expandsHitTargetToMinimum {
      if FKSelectionControlMetrics.expandedHitFrame(for: bounds).contains(point) { return true }
    }
    return super.point(inside: point, with: event)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    refreshIndicator(animated: false)
    refreshContentColors()
  }

  @objc private func touchUpInside() {
    if let location = lastTouchLocationInSelf,
       content.attributedTitle != nil,
       !attributedTitleView.isHidden {
      let pointInText = attributedTitleView.convert(location, from: self)
      if attributedTitleView.bounds.contains(pointInText),
         let url = attributedTitleView.linkURL(at: pointInText) {
        onLinkActivated?(url)
        return
      }
    }
    guard isEnabled, configuration.interaction.mode == .interactive else { return }
    guard configuration.interaction.selectsOnTouch else { return }
    if selectionManagedExternally {
      sendActions(for: .primaryActionTriggered)
      return
    }
    if !_selected {
      setSelected(true, animated: true, sendActions: true)
    }
  }

  private func applyConfiguration() {
    indicator.size = configuration.layout.size
    indicator.tint = configuration.appearance.tint
    indicator.uncheckedBorderColor = configuration.appearance.uncheckedBorderColor
    indicator.ringWidthOverride = configuration.appearance.ringWidth
    indicator.innerDotScale = configuration.appearance.innerDotScale
    indicator.errorBorderColor = configuration.appearance.errorBorderColor
    indicator.disabledOnAlpha = configuration.appearance.disabledAlpha

    titleLabel.font = configuration.appearance.titleFont
    titleLabel.numberOfLines = configuration.layout.titleNumberOfLines
    subtitleLabel.font = configuration.appearance.subtitleFont
    subtitleLabel.numberOfLines = configuration.layout.subtitleNumberOfLines
    attributedTitleView.font = configuration.appearance.titleFont

    refreshContent()
    refreshIndicator(animated: false)
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    updateAccessibility()
  }

  private func refreshContent() {
    imageView.image = content.image
    if let attributed = content.attributedTitle {
      attributedTitleView.attributedText = NSAttributedString(attributed)
      titleLabel.text = nil
    } else {
      attributedTitleView.attributedText = nil
      titleLabel.text = content.title
    }
    subtitleLabel.text = content.subtitle
    refreshContentColors()
  }

  private func refreshContentColors() {
    let enabled = isEnabled
    titleLabel.textColor = enabled ? configuration.appearance.titleColor : configuration.appearance.disabledTitleColor
    subtitleLabel.textColor = enabled ? configuration.appearance.subtitleColor : configuration.appearance.disabledTitleColor
    attributedTitleView.textColor = enabled ? configuration.appearance.titleColor : configuration.appearance.disabledTitleColor
    imageView.alpha = enabled ? 1 : configuration.appearance.disabledAlpha
  }

  private func refreshIndicator(animated: Bool) {
    indicator.showsError = showsError && !_selected
    let presentation: FKSelectionIndicatorPresentation
    if isEnabled {
      presentation = _selected ? .radioSelected : .radioUnchecked
    } else {
      presentation = _selected ? .radioDisabledOn : .radioDisabled
    }
    if animated {
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

  private func measure(in size: CGSize) -> FKSelectionRowLayout.Metrics {
    let insets = configuration.layout.contentInsets
    let side = configuration.layout.size.indicatorSide
    let imageSize: CGSize? = {
      guard content.image != nil else { return nil }
      return content.imageSize ?? FKSelectionControlMetrics.defaultImageSize
    }()
    let imageOccupied = (imageSize?.width ?? 0) + (imageSize != nil ? configuration.layout.imageTitleSpacing : 0)
    let width = size.width > 0 ? size.width : UIScreen.main.bounds.width
    let available = max(0, width - insets.leading - insets.trailing - side - configuration.layout.indicatorTitleSpacing - imageOccupied)

    let titleSize: CGSize
    if configuration.layout.labelPlacement == .hidden {
      titleSize = .zero
    } else if let attributed = content.attributedTitle {
      titleSize = FKSelectionRowLayout.measureAttributed(
        NSAttributedString(attributed),
        numberOfLines: configuration.layout.titleNumberOfLines,
        width: available
      )
    } else {
      titleSize = FKSelectionRowLayout.measureText(
        content.title,
        font: configuration.appearance.titleFont,
        numberOfLines: configuration.layout.titleNumberOfLines,
        width: available
      )
    }

    let subtitleSize = configuration.layout.labelPlacement == .hidden
      ? .zero
      : FKSelectionRowLayout.measureText(
        content.subtitle,
        font: configuration.appearance.subtitleFont,
        numberOfLines: configuration.layout.subtitleNumberOfLines,
        width: available
      )

    return FKSelectionRowLayout.metrics(
      in: CGRect(origin: .zero, size: CGSize(width: width, height: size.height)),
      size: configuration.layout.size,
      contentInsets: insets,
      indicatorEdge: configuration.layout.indicatorEdge,
      labelPlacement: configuration.layout.labelPlacement,
      indicatorTitleSpacing: configuration.layout.indicatorTitleSpacing,
      titleSubtitleSpacing: configuration.layout.titleSubtitleSpacing,
      imageSize: imageSize,
      imageTitleSpacing: configuration.layout.imageTitleSpacing,
      titleSize: titleSize,
      subtitleSize: subtitleSize,
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      rowMinHeight: configuration.layout.rowMinHeight
    )
  }

  private func updateAccessibility() {
    if let custom = configuration.accessibility.customLabel, !custom.isEmpty {
      accessibilityLabel = custom
    } else if let attributed = content.attributedTitle {
      accessibilityLabel = String(attributed.characters)
    } else {
      accessibilityLabel = content.title
    }
    accessibilityHint = configuration.accessibility.customHint ?? FKSelectionControlI18n.radioHint
    accessibilityValue = _selected ? FKSelectionControlI18n.radioSelected : FKSelectionControlI18n.radioNotSelected
    var traits: UIAccessibilityTraits = .button
    if _selected { traits.insert(.selected) }
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
