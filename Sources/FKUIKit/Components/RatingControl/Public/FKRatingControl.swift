import UIKit

/// Interactive or read-only star-style rating control with configurable icons, steps, caption, and accessibility.
///
/// Assign ``configuration`` to change layout and appearance. Use ``setValue(_:animated:sendsControlEvents:)`` for programmatic updates.
/// Global defaults: ``FKRating/defaultConfiguration`` or ``FKRatingDefaults/configuration``.
@MainActor
public final class FKRatingControl: UIControl {
  /// Baseline copied by `init(frame:)` until you replace ``configuration``.
  public static var defaultConfiguration: FKRatingConfiguration {
    get { FKRatingDefaults.configuration }
    set { FKRatingDefaults.configuration = newValue }
  }

  /// Style and behavior; assigning triggers layout and appearance refresh.
  public var configuration: FKRatingConfiguration = FKRatingControl.defaultConfiguration {
    didSet {
      reconcileItemViews()
      applyAppearance()
      applyInteractionMode()
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      refreshLabel()
      updateAccessibility()
    }
  }

  /// Lower bound of the rating scale.
  public var minimumValue: Double = 0

  /// Upper bound of the rating scale (defaults to the layout item count).
  public var maximumValue: Double = 5

  /// Current snapped rating value.
  public private(set) var value: Double = 0

  /// Optional delegate for value change callbacks.
  public weak var delegate: FKRatingControlDelegate?

  /// Closure alternative to ``FKRatingControlDelegate``.
  public var onValueChanged: ((Double) -> Void)?

  private var itemViews: [FKRatingItemView] = []
  private let valueLabel = UILabel()
  private var latestMetrics = FKRatingLayoutEngine.Metrics(itemFrames: [], iconsRect: .zero, labelFrame: nil)
  private var isDragging = false
  private var previousFillSignature: [CGFloat] = []

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a control with an explicit configuration and initial value.
  public convenience init(
    configuration: FKRatingConfiguration = FKRatingControl.defaultConfiguration,
    value: Double = 0,
    minimumValue: Double = 0,
    maximumValue: Double = 5
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
    setValue(value, animated: false, sendsControlEvents: false)
  }

  private func commonInit() {
    isAccessibilityElement = true
    backgroundColor = .clear
    clipsToBounds = false

    valueLabel.numberOfLines = 1
    valueLabel.lineBreakMode = .byTruncatingTail
    valueLabel.isAccessibilityElement = false
    valueLabel.isUserInteractionEnabled = false
    addSubview(valueLabel)

    reconcileItemViews()
    applyAppearance()
    applyInteractionMode()
    refreshLabel()
    updateAccessibility()

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    addGestureRecognizer(tap)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.maximumNumberOfTouches = 1
    addGestureRecognizer(pan)
  }

  // MARK: - Public API

  /// Sets the rating after snapping to ``FKRatingInteractionConfiguration/step``; values are clamped to ``minimumValue``…``maximumValue``.
  public func setValue(_ newValue: Double, animated: Bool, sendsControlEvents: Bool) {
    let snapped = snap(newValue)
    guard snapped != value || sendsControlEvents else {
      refreshPresentation(animated: animated)
      return
    }

    if sendsControlEvents {
      delegate?.ratingControl(self, willChangeValue: snapped)
    }

    value = snapped
    refreshPresentation(animated: animated)

    if sendsControlEvents {
      fireTouchHapticIfNeeded()
      sendActions(for: .valueChanged)
      onValueChanged?(snapped)
      delegate?.ratingControl(self, didChangeValue: snapped)
    }

    updateAccessibility()
  }

  public override var intrinsicContentSize: CGSize {
    let labelSize = FKRatingLabelFormatting.labelSize(value: value, configuration: configuration)
    return FKRatingLayoutEngine.intrinsicContentSize(configuration: configuration, labelSize: labelSize)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    let labelSize = FKRatingLabelFormatting.labelSize(value: value, configuration: configuration)
    latestMetrics = FKRatingLayoutEngine.metrics(
      in: bounds,
      configuration: configuration,
      labelSize: labelSize,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )

    zip(itemViews, latestMetrics.itemFrames).forEach { view, frame in
      view.frame = frame
    }

    if let labelFrame = latestMetrics.labelFrame {
      valueLabel.frame = labelFrame
      valueLabel.isHidden = false
    } else {
      valueLabel.isHidden = true
    }
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard configuration.interaction.mode == .interactive, isEnabled else {
      return super.point(inside: point, with: event)
    }
    for frame in latestMetrics.itemFrames {
      let hit = FKRatingLayoutEngine.expandedHitFrame(
        for: frame,
        minimumSize: configuration.interaction.minimumTouchTargetSize
      )
      if hit.contains(point) { return true }
    }
    return latestMetrics.iconsRect.contains(point)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyAppearance()
    refreshLabel()
    setNeedsLayout()
  }

  public override func accessibilityIncrement() {
    guard configuration.interaction.mode == .interactive else { return }
    setValue(value + configuration.interaction.step.increment, animated: true, sendsControlEvents: true)
  }

  public override func accessibilityDecrement() {
    guard configuration.interaction.mode == .interactive else { return }
    setValue(value - configuration.interaction.step.increment, animated: true, sendsControlEvents: true)
  }

  // MARK: - Gestures

  @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
    guard configuration.interaction.mode == .interactive, isEnabled else { return }
    let location = recognizer.location(in: self)
    updateValue(at: location, sendsControlEvents: true)
  }

  @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.interaction.mode == .interactive,
          configuration.interaction.allowsDragSelection,
          isEnabled else { return }

    switch recognizer.state {
    case .began:
      isDragging = true
      updateValue(at: recognizer.location(in: self), sendsControlEvents: true)
    case .changed:
      updateValue(at: recognizer.location(in: self), sendsControlEvents: true)
    case .ended, .cancelled, .failed:
      isDragging = false
    default:
      break
    }
  }

  // MARK: - Private

  private func updateValue(at point: CGPoint, sendsControlEvents: Bool) {
    let raw = FKRatingLayoutEngine.value(
      at: point,
      in: latestMetrics,
      minimumValue: minimumValue,
      maximumValue: maximumValue,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
    setValue(raw, animated: !isDragging, sendsControlEvents: sendsControlEvents)
  }

  private func snap(_ raw: Double) -> Double {
    let clamped = min(max(raw, minimumValue), maximumValue)
    let step = configuration.interaction.step.increment
    guard step > 0 else { return clamped }
    let offset = clamped - minimumValue
    let steps = (offset / step).rounded()
    let snapped = minimumValue + steps * step
    return min(max(snapped, minimumValue), maximumValue)
  }

  private func reconcileItemViews() {
    let targetCount = configuration.layout.itemCount
    while itemViews.count < targetCount {
      let view = FKRatingItemView()
      addSubview(view)
      itemViews.append(view)
    }
    while itemViews.count > targetCount {
      itemViews.popLast()?.removeFromSuperview()
    }
    previousFillSignature = Array(repeating: -1, count: targetCount)
  }

  private func applyAppearance() {
    let empty = FKRatingIconResolver.emptyImage(for: configuration.appearance)
    let filled = FKRatingIconResolver.filledImage(for: configuration.appearance)
    itemViews.forEach { view in
      view.applyImages(empty: empty, filled: filled)
      view.applyColors(
        empty: configuration.appearance.emptyColor,
        filled: configuration.appearance.filledColor
      )
    }
    valueLabel.font = configuration.appearance.labelFont
    valueLabel.textColor = configuration.appearance.labelColor
  }

  private func applyInteractionMode() {
    let interactive = configuration.interaction.mode == .interactive
    isUserInteractionEnabled = interactive
    gestureRecognizers?.forEach { $0.isEnabled = interactive }
    alpha = isEnabled ? 1 : configuration.interaction.disabledAlpha
    updateAccessibility()
  }

  public override var isEnabled: Bool {
    didSet {
      applyInteractionMode()
    }
  }

  private func refreshPresentation(animated: Bool) {
    let duration = resolvedAnimationDuration(animated: animated)
    let signatures = (0 ..< itemViews.count).map { index in
      FKRatingLayoutEngine.fillFraction(
        forItemAt: index,
        value: value,
        minimumValue: minimumValue,
        maximumValue: maximumValue,
        itemCount: configuration.layout.itemCount
      )
    }

    for (index, view) in itemViews.enumerated() {
      let fraction = signatures[index]
      view.setFillFraction(
        fraction,
        animated: animated,
        duration: duration,
        timing: configuration.motion.timing
      )

      if animated,
         index < previousFillSignature.count,
         abs(previousFillSignature[index] - fraction) > 0.001,
         !UIAccessibility.isReduceMotionEnabled || !configuration.motion.respectsReducedMotion {
        view.performSelectionAnimation(configuration.motion.selectionAnimation)
      }
    }

    previousFillSignature = signatures
    refreshLabel()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
  }

  private func resolvedAnimationDuration(animated: Bool) -> TimeInterval {
    guard animated else { return 0 }
    if configuration.motion.respectsReducedMotion, UIAccessibility.isReduceMotionEnabled { return 0 }
    return configuration.motion.animationDuration
  }

  private func refreshLabel() {
    valueLabel.text = FKRatingLabelFormatting.labelText(value: value, configuration: configuration)
  }

  private func updateAccessibility() {
    if let label = configuration.accessibility.customLabel, !label.isEmpty {
      accessibilityLabel = label
    } else {
      accessibilityLabel = "Rating"
    }

    if let hint = configuration.accessibility.customHint, !hint.isEmpty {
      accessibilityHint = hint
    } else if configuration.interaction.mode == .interactive {
      accessibilityHint = "Adjustable"
    } else {
      accessibilityHint = nil
    }

    accessibilityValue = FKRatingLabelFormatting.accessibilityValue(
      value: value,
      maximumValue: maximumValue,
      configuration: configuration
    )

    if configuration.interaction.mode == .interactive, isEnabled {
      accessibilityTraits.insert(.adjustable)
    } else {
      accessibilityTraits.remove(.adjustable)
    }
  }

  private func fireTouchHapticIfNeeded() {
    switch configuration.interaction.touchHaptic {
    case .none:
      break
    case .light:
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .selection:
      UISelectionFeedbackGenerator().selectionChanged()
    }
  }
}
