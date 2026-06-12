import FKCoreKit
import UIKit

/// Capsule control that displays an ID or token and copies full text to the pasteboard on tap.
@MainActor
public final class FKCopyChip: UIControl {
  public static var defaultConfiguration: FKCopyChipConfiguration {
    get { FKCopyChipDefaults.configuration }
    set { FKCopyChipDefaults.configuration = newValue }
  }

  public var configuration: FKCopyChipConfiguration = FKCopyChip.defaultConfiguration {
    didSet { applyConfiguration() }
  }

  /// Visible text (may be truncated for display; see ``copyText``).
  public var text: String = "" {
    didSet {
      guard oldValue != text else { return }
      refreshDisplayText()
      invalidateIntrinsicContentSize()
      setNeedsLayout()
      updateAccessibility()
    }
  }

  /// Full string copied to the pasteboard; `nil` uses ``text``.
  public var copyText: String?

  /// Called on the main actor after a successful pasteboard write.
  public var onCopy: ((String) -> Void)?

  private let backgroundView = UIView()
  private let textLabel = UILabel()
  private let iconView = UIImageView()
  private var naturalWidthConstraint: NSLayoutConstraint?
  private var latestMetrics = FKCopyChipLayoutEngine.Metrics(
    size: .zero,
    cornerRadius: 0,
    textFrame: .zero,
    iconFrame: .zero
  )
  private var impactGenerator: UIImpactFeedbackGenerator?
  private var cachedHapticStyle: UIImpactFeedbackGenerator.FeedbackStyle?

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKCopyChipConfiguration = FKCopyChip.defaultConfiguration,
    text: String = "",
    copyText: String? = nil
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.text = text
    self.copyText = copyText
  }

  public override var intrinsicContentSize: CGSize {
    latestMetrics.size
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    relayoutMetrics()
    syncNaturalWidthConstraintIfNeeded()
    applySubviewFrames()
  }

  public override var semanticContentAttribute: UISemanticContentAttribute {
    didSet {
      guard oldValue != semanticContentAttribute else { return }
      setNeedsLayout()
    }
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      applyConfiguration()
    } else if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      setNeedsLayout()
    } else if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      updateAppearance()
    }
  }

  public override var isHighlighted: Bool {
    didSet { applyHighlightFeedback() }
  }

  public override var isEnabled: Bool {
    didSet { updateAppearance() }
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard configuration.interaction.expandsHitAreaToMinimumSize else {
      return super.point(inside: point, with: event)
    }
    let minSize = configuration.interaction.minimumHitAreaSize
    let w = max(bounds.width, minSize.width)
    let h = max(bounds.height, minSize.height)
    let hit = CGRect(x: bounds.midX - w / 2, y: bounds.midY - h / 2, width: w, height: h)
    return hit.contains(point)
  }

  public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    super.endTracking(touch, with: event)
    guard let touch, isEnabled else { return }
    let location = touch.location(in: self)
    guard point(inside: location, with: event) else { return }
    performCopy()
  }

  public override func accessibilityActivate() -> Bool {
    guard isEnabled else { return false }
    performCopy()
    return true
  }

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .button
    clipsToBounds = false

    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)

    backgroundView.isUserInteractionEnabled = false
    textLabel.isUserInteractionEnabled = false
    textLabel.lineBreakMode = .byTruncatingTail
    textLabel.textAlignment = .natural
    textLabel.adjustsFontForContentSizeCategory = false

    iconView.contentMode = .center
    iconView.isUserInteractionEnabled = false

    addSubview(backgroundView)
    addSubview(textLabel)
    addSubview(iconView)

    applyConfiguration()
  }

  private func applyConfiguration() {
    refreshDisplayText()
    syncImpactGenerator()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    updateAppearance()
    updateAccessibility()
  }

  private var needsHapticFeedback: Bool {
    switch configuration.feedback.mode {
    case .hapticOnly:
      true
    case .toast:
      configuration.feedback.playsHapticWithToast
    case .none:
      false
    }
  }

  /// Creates or releases the haptic generator based on ``FKCopyChipFeedbackConfiguration/mode``.
  private func syncImpactGenerator() {
    guard needsHapticFeedback else {
      impactGenerator = nil
      cachedHapticStyle = nil
      return
    }
    let style = configuration.feedback.hapticStyle
    if impactGenerator == nil || cachedHapticStyle != style {
      impactGenerator = UIImpactFeedbackGenerator(style: style)
      cachedHapticStyle = style
    }
    impactGenerator?.prepare()
  }

  private func relayoutMetrics() {
    latestMetrics = FKCopyChipLayoutEngine.layout(
      .init(
        displayText: textLabel.text ?? "",
        font: resolvedTitleFont(),
        height: configuration.layout.size.height,
        horizontalPadding: configuration.layout.horizontalPadding,
        iconSpacing: configuration.layout.iconSpacing,
        iconPointSize: configuration.layout.size.height * 0.38
      ),
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
    invalidateIntrinsicContentSize()
  }

  private func applySubviewFrames() {
    let pill = FKCopyChipLayoutEngine.pillFrame(
      metrics: latestMetrics,
      in: bounds,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
    backgroundView.frame = pill
    applyCornerRadius()
    textLabel.frame = latestMetrics.textFrame.offsetBy(dx: pill.minX, dy: pill.minY)
    iconView.frame = latestMetrics.iconFrame.offsetBy(dx: pill.minX, dy: pill.minY)
  }

  private func syncNaturalWidthConstraintIfNeeded() {
    FKCapsuleIntrinsicWidthConstraint.sync(
      on: self,
      width: latestMetrics.size.width,
      storage: &naturalWidthConstraint
    )
  }

  private func resolvedTitleFont() -> UIFont {
    let base = configuration.appearance.titleFont
    let scaled = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: base)
    if configuration.appearance.usesMonospacedFont {
      let monoDescriptor = scaled.fontDescriptor.withDesign(.monospaced) ?? scaled.fontDescriptor
      return UIFont(descriptor: monoDescriptor, size: scaled.pointSize)
    }
    return scaled
  }

  private func refreshDisplayText() {
    textLabel.text = FKCopyChipTextFormatter.displayString(text: text, layout: configuration.layout)
    textLabel.font = resolvedTitleFont()
  }

  private func refreshIcon() {
    let pointSize = configuration.layout.size.height * 0.38
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
    iconView.tintColor = configuration.appearance.iconColor
    iconView.image = UIImage(systemName: configuration.appearance.copySymbolName, withConfiguration: symbolConfig)?
      .withRenderingMode(.alwaysTemplate)
  }

  private func applyCornerRadius() {
    switch configuration.appearance.cornerStyle {
    case .capsule:
      backgroundView.layer.cornerRadius = latestMetrics.cornerRadius
      backgroundView.layer.cornerCurve = .continuous
    case .fixed(let radius):
      backgroundView.layer.cornerRadius = radius
      backgroundView.layer.cornerCurve = .circular
    }
  }

  private func updateAppearance() {
    backgroundView.backgroundColor = configuration.appearance.backgroundColor
    textLabel.textColor = configuration.appearance.foregroundColor
    alpha = isEnabled ? 1 : configuration.appearance.disabledAlpha
    refreshIcon()
  }

  private func applyHighlightFeedback() {
    guard configuration.interaction.highlightsOnPress, isEnabled else { return }
    let reduceMotion = UIAccessibility.isReduceMotionEnabled
    let scale = isHighlighted ? configuration.interaction.highlightScale : 1
    let animations = {
      self.transform = reduceMotion ? .identity : CGAffineTransform(scaleX: scale, y: scale)
    }
    if reduceMotion {
      animations()
    } else {
      UIView.animate(withDuration: 0.16, animations: animations)
    }
  }

  private func performCopy() {
    guard isEnabled else { return }
    let payload = (copyText?.fk_nilIfBlank ?? text).fk_trimmed
    guard !payload.isEmpty else { return }

    FKCopyChipPasteboardWriter.copy(payload, expiration: configuration.interaction.pasteboardExpirationDate)
    deliverFeedback()
    playSuccessFlashIfNeeded()
    onCopy?(payload)
    NotificationCenter.default.post(
      name: .fk_copyChipDidCopy,
      object: self,
      userInfo: [FKCopyChipNotificationKeys.copiedText: payload]
    )
    sendActions(for: .primaryActionTriggered)
  }

  private func deliverFeedback() {
    switch configuration.feedback.mode {
    case .none:
      break
    case .hapticOnly:
      triggerHaptic()
    case .toast:
      if configuration.feedback.playsHapticWithToast {
        triggerHaptic()
      }
      let message = configuration.feedback.toastMessage ?? FKCopyChipI18n.toastSuccess
      FKToast.show(message, style: .success)
    }

    if configuration.feedback.postsAccessibilityAnnouncement, configuration.feedback.mode != .none {
      UIAccessibility.post(notification: .announcement, argument: FKCopyChipI18n.copiedAnnouncement)
    }
  }

  private func triggerHaptic() {
    syncImpactGenerator()
    guard let impactGenerator else { return }
    impactGenerator.impactOccurred()
    impactGenerator.prepare()
  }

  private func playSuccessFlashIfNeeded() {
    guard configuration.feedback.mode != .none,
          configuration.feedback.playsSuccessFlash,
          !UIAccessibility.isReduceMotionEnabled else { return }
    let original = configuration.appearance.backgroundColor
    let flash = configuration.appearance.successFlashColor ?? original.withAlphaComponent(0.55)
    UIView.animate(withDuration: 0.1, animations: {
      self.backgroundView.backgroundColor = flash
    }, completion: { _ in
      UIView.animate(withDuration: 0.18) {
        self.backgroundView.backgroundColor = original
      }
    })
  }

  private func updateAccessibility() {
    let summary = FKCopyChipTextFormatter.accessibilitySummary(text: text, layout: configuration.layout)
    accessibilityLabel = configuration.accessibility.customLabel ?? FKCopyChipI18n.accessibilityLabel(summary: summary)
    accessibilityHint = configuration.accessibility.customHint ?? FKCopyChipI18n.accessibilityHint
  }
}
