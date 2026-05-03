import UIKit

/// A highly configurable determinate / indeterminate progress indicator (linear or ring) with optional buffer, labels, and accessibility.
///
/// Assign ``configuration`` to change appearance. Use ``setProgress(_:animated:)`` and ``setBufferProgress(_:animated:)`` for animated updates.
/// Set ``isIndeterminate`` to `true` and choose ``FKProgressBarConfiguration/indeterminateStyle`` for activity modes.
///
/// Global defaults: set ``defaultConfiguration`` at launch or use ``FKProgressBarDefaults/configuration``.
@IBDesignable
@MainActor
public final class FKProgressBar: UIView {
  /// Baseline copied by `init(frame:)` until you replace ``configuration``.
  public static var defaultConfiguration: FKProgressBarConfiguration {
    get { FKProgressBarDefaults.configuration }
    set { FKProgressBarDefaults.configuration = newValue }
  }

  /// Style and behavior; assigning invalidates layout and refreshes dynamic colors on the next layout pass.
  public var configuration: FKProgressBarConfiguration = FKProgressBar.defaultConfiguration {
    didSet {
      applyConfigurationToLabel()
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      updateAccessibility()
    }
  }

  /// Normalized primary progress in `0...1`.
  public private(set) var progress: CGFloat = 0

  /// Normalized buffer progress in `0...1` (shown when ``FKProgressBarConfiguration/showsBuffer`` is `true`).
  public private(set) var bufferProgress: CGFloat = 0

  /// When `true`, determinate fills are de-emphasized and ``FKProgressBarConfiguration/indeterminateStyle`` drives motion.
  public var isIndeterminate: Bool = false {
    didSet {
      guard isIndeterminate != oldValue else { return }
      updateAccessibility()
      delegate?.progressBar(self, didChangeIndeterminate: isIndeterminate)
      setNeedsLayout()
    }
  }

  public weak var delegate: FKProgressBarDelegate?

  private let layerStack = FKProgressBarLayerStack()
  private let valueLabel = UILabel()
  private var animateNextLayout = false

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a bar with an explicit configuration.
  public convenience init(configuration: FKProgressBarConfiguration) {
    self.init(frame: .zero)
    self.configuration = configuration
  }

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits.insert(.updatesFrequently)
    backgroundColor = .clear
    clipsToBounds = false
    layerStack.install()
    layer.insertSublayer(layerStack.container, at: 0)
    valueLabel.textAlignment = .center
    valueLabel.numberOfLines = 1
    valueLabel.lineBreakMode = .byTruncatingTail
    valueLabel.isAccessibilityElement = false
    valueLabel.isUserInteractionEnabled = false
    addSubview(valueLabel)
    applyConfigurationToLabel()
    updateAccessibility()
  }

  // MARK: - Public API

  /// Sets normalized progress; values are clamped to `0...1`.
  public func setProgress(_ value: CGFloat, animated: Bool) {
    let clamped = min(max(value, 0), 1)
    let from = progress
    progress = clamped
    let duration = resolvedAnimationDuration(animated: animated)
    if animated, duration > 0 {
      delegate?.progressBar(self, willAnimateProgress: from, to: clamped, duration: duration)
    }
    animateNextLayout = animated
    fireCompletionHapticIfNeeded(from: from, to: clamped)
    setNeedsLayout()
    layoutIfNeeded()
    delegate?.progressBar(self, didAnimateProgressTo: clamped)
    updateLabelText()
    updateAccessibility()
  }

  /// Sets normalized buffer progress; clamped to `0...1`.
  public func setBufferProgress(_ value: CGFloat, animated: Bool) {
    bufferProgress = min(max(value, 0), 1)
    animateNextLayout = animateNextLayout || animated
    delegate?.progressBar(self, didUpdateBufferProgress: bufferProgress)
    setNeedsLayout()
    updateAccessibility()
  }

  /// Convenience: sets both primary and buffer in one layout pass.
  public func setProgress(_ progress: CGFloat, buffer: CGFloat, animated: Bool) {
    let p = min(max(progress, 0), 1)
    let b = min(max(buffer, 0), 1)
    let from = self.progress
    self.progress = p
    self.bufferProgress = b
    let duration = resolvedAnimationDuration(animated: animated)
    if animated, duration > 0 {
      delegate?.progressBar(self, willAnimateProgress: from, to: p, duration: duration)
    }
    animateNextLayout = animated
    fireCompletionHapticIfNeeded(from: from, to: p)
    setNeedsLayout()
    layoutIfNeeded()
    delegate?.progressBar(self, didUpdateBufferProgress: b)
    delegate?.progressBar(self, didAnimateProgressTo: p)
    updateLabelText()
    updateAccessibility()
  }

  /// Begins indeterminate presentation according to ``FKProgressBarConfiguration/indeterminateStyle``.
  public func startIndeterminate() {
    isIndeterminate = true
  }

  /// Stops indeterminate presentation and restores determinate fills.
  public func stopIndeterminate() {
    isIndeterminate = false
    layerStack.animator.stopAll()
    setNeedsLayout()
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    let reduced = UIAccessibility.isReduceMotionEnabled
    let animated = animateNextLayout
    animateNextLayout = false
    layerStack.layout(
      in: bounds,
      configuration: configuration,
      progress: progress,
      buffer: bufferProgress,
      isIndeterminate: isIndeterminate,
      layoutDirection: effectiveUserInterfaceLayoutDirection,
      traitCollection: traitCollection,
      reducedMotion: reduced,
      animated: animated,
      animationDuration: configuration.animationDuration,
      timing: configuration.timing,
      prefersSpring: configuration.prefersSpringAnimation,
      springDamping: configuration.springDampingRatio,
      springVelocity: configuration.springVelocity
    )
    layoutValueLabel()
  }

  public override var intrinsicContentSize: CGSize {
    let c = configuration
    let insets = c.contentInsets
    let labelBlock = labelIntrinsicAxisContribution()

    switch c.variant {
    case .linear:
      switch c.axis {
      case .horizontal:
        let h = insets.top + insets.bottom + c.trackThickness + labelBlock.vertical
        return CGSize(width: UIView.noIntrinsicMetric, height: h)
      case .vertical:
        let w = insets.left + insets.right + c.trackThickness + labelBlock.horizontal
        return CGSize(width: w, height: UIView.noIntrinsicMetric)
      }
    case .ring:
      let d = (c.ringDiameter ?? 36) + labelBlock.bothAxes
      return CGSize(width: d + insets.left + insets.right, height: d + insets.top + insets.bottom)
    }
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setNeedsLayout()
  }

  // MARK: - Private

  private func resolvedAnimationDuration(animated: Bool) -> TimeInterval {
    guard animated else { return 0 }
    if configuration.respectsReducedMotion, UIAccessibility.isReduceMotionEnabled { return 0 }
    return configuration.animationDuration
  }

  private func fireCompletionHapticIfNeeded(from: CGFloat, to: CGFloat) {
    guard from < 1, to >= 1 else { return }
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    switch configuration.completionHaptic {
    case .none:
      return
    case .light:
      style = .light
    case .medium:
      style = .medium
    case .rigid:
      style = .rigid
    }
    let gen = UIImpactFeedbackGenerator(style: style)
    gen.prepare()
    gen.impactOccurred()
  }

  private func applyConfigurationToLabel() {
    valueLabel.font = configuration.labelFont
    valueLabel.textColor = configuration.labelUsesSemanticLabelColor ? .label : configuration.labelColor
    valueLabel.isHidden = configuration.labelPlacement == .none
    updateLabelText()
  }

  private func updateLabelText() {
    guard configuration.labelPlacement != .none else {
      valueLabel.text = nil
      return
    }
    valueLabel.text = FKProgressBarLabelFormatting.displayString(progress: progress, configuration: configuration)
  }

  private func layoutValueLabel() {
    guard configuration.labelPlacement != .none else {
      valueLabel.frame = .zero
      return
    }
    let pad = configuration.labelPadding
    let c = configuration
    let track = FKProgressBarLayoutEngine.trackRect(in: bounds, contentInsets: c.contentInsets)
    let size = valueLabel.sizeThatFits(CGSize(width: bounds.width - pad * 2, height: bounds.height))
    let w = min(bounds.width - pad * 2, size.width)
    let h = size.height
    var f = CGRect.zero
    let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
    switch c.labelPlacement {
    case .none:
      break
    case .above:
      f = CGRect(x: (bounds.width - w) / 2, y: track.minY - pad - h, width: w, height: h)
    case .below:
      f = CGRect(x: (bounds.width - w) / 2, y: track.maxY + pad, width: w, height: h)
    case .leading:
      let x = rtl ? track.maxX + pad : track.minX - pad - w
      f = CGRect(x: x, y: track.midY - h / 2, width: w, height: h)
    case .trailing:
      let x = rtl ? track.minX - pad - w : track.maxX + pad
      f = CGRect(x: x, y: track.midY - h / 2, width: w, height: h)
    case .centeredOnTrack:
      f = CGRect(x: track.midX - w / 2, y: track.midY - h / 2, width: w, height: h)
    }
    valueLabel.frame = f.integral
  }

  private struct LabelAxisInset {
    var vertical: CGFloat = 0
    var horizontal: CGFloat = 0
    var bothAxes: CGFloat = 0
  }

  private func labelIntrinsicAxisContribution() -> LabelAxisInset {
    guard configuration.labelPlacement != .none else { return LabelAxisInset() }
    let pad = configuration.labelPadding
    let c = configuration
    var o = LabelAxisInset()
    switch c.labelPlacement {
    case .none:
      break
    case .above, .below:
      let h = ceil(valueLabel.font.lineHeight) + pad
      o.vertical = h
    case .leading, .trailing:
      let w = min(120, max(80, bounds.width > 0 ? bounds.width * 0.35 : 80)) + pad
      o.horizontal = w
    case .centeredOnTrack:
      o.bothAxes = ceil(valueLabel.font.lineHeight) + pad
    }
    return o
  }

  private func updateAccessibility() {
    if let label = configuration.accessibilityCustomLabel, !label.isEmpty {
      accessibilityLabel = label
    } else {
      accessibilityLabel = nil
    }
    if let hint = configuration.accessibilityCustomHint, !hint.isEmpty {
      accessibilityHint = hint
    } else {
      accessibilityHint = nil
    }
    accessibilityValue = FKProgressBarLabelFormatting.accessibilityValue(
      progress: progress,
      buffer: bufferProgress,
      configuration: configuration,
      isIndeterminate: isIndeterminate
    )
    if configuration.accessibilityTreatAsFrequentUpdates {
      accessibilityTraits.insert(.updatesFrequently)
    } else {
      accessibilityTraits.remove(.updatesFrequently)
    }
  }
}
