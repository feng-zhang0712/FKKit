import FKCoreKit
import UIKit

/// Compact toggle/filter control with optional remove affordance.
@MainActor
public final class FKChip: UIControl {
  public static var defaultConfiguration: FKChipConfiguration {
    get { FKChipDefaults.configuration }
    set { FKChipDefaults.configuration = newValue }
  }

  public var configuration: FKChipConfiguration = FKChip.defaultConfiguration {
    didSet { applyConfiguration() }
  }

  public var mode: FKChipMode = .filter {
    didSet {
      guard oldValue != mode else { return }
      updateAppearance()
      updateAccessibility()
    }
  }

  public var title: String = "" {
    didSet {
      guard oldValue != title else { return }
      applyConfiguration()
    }
  }

  public override var isSelected: Bool {
    didSet {
      guard oldValue != isSelected else { return }
      updateAppearance()
      updateAccessibility()
    }
  }

  public var leadingIcon: FKChipIcon? {
    didSet {
      guard oldValue != leadingIcon else { return }
      applyConfiguration()
    }
  }

  public var showsRemoveButton: Bool = false {
    didSet {
      guard oldValue != showsRemoveButton else { return }
      syncRemoveSubview()
      refreshMetricsIfNeeded()
      setNeedsLayout()
      updateAccessibility()
    }
  }

  public var onRemove: (() -> Void)?

  /// When `false`, filter/choice taps emit ``UIControl/Event/valueChanged`` without toggling ``isSelected`` (used by ``FKChipGroup``).
  internal var managesSelectionInternally: Bool = true

  private let backgroundView = UIView()
  /// Caption label — named distinctly from ``UIControl/titleLabel`` to avoid UIKit layout conflicts.
  private let captionLabel = UILabel()
  var leadingIconView: UIImageView?
  var removeImageView: UIImageView?
  private var naturalWidthConstraint: NSLayoutConstraint?
  private var intrinsicMetrics = FKCapsuleLayoutEngine.Metrics(
    size: .zero,
    cornerRadius: 0,
    leadingIconFrame: nil,
    titleFrame: .zero,
    removeButtonFrame: nil,
    removeHitAreaFrame: nil
  )
  private var layoutMetrics = FKCapsuleLayoutEngine.Metrics(
    size: .zero,
    cornerRadius: 0,
    leadingIconFrame: nil,
    titleFrame: .zero,
    removeButtonFrame: nil,
    removeHitAreaFrame: nil
  )

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKChipConfiguration = FKChip.defaultConfiguration,
    mode: FKChipMode = .filter,
    title: String = ""
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.mode = mode
    self.title = title
  }

  public override var intrinsicContentSize: CGSize {
    computeMetrics(maxWidth: configuration.layout.maxWidth).size
  }

  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    computeMetrics(maxWidth: resolvedMaxWidth(forProposedWidth: size.width)).size
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    guard superview != nil else { return }
    refreshMetricsIfNeeded()
    superview?.setNeedsLayout()
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil else { return }
    refreshMetricsIfNeeded()
    setNeedsLayout()
    superview?.setNeedsLayout()
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

  private func applySubviewFrames() {
    syncCaptionText()
    let pill = FKCapsuleLayoutEngine.pillFrame(
      metrics: layoutMetrics,
      in: bounds,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
    backgroundView.frame = pill
    applyCornerRadius(using: layoutMetrics)
    if let frame = layoutMetrics.leadingIconFrame {
      leadingIconView?.frame = frame.offsetBy(dx: pill.minX, dy: pill.minY)
    }
    captionLabel.frame = layoutMetrics.titleFrame.offsetBy(dx: pill.minX, dy: pill.minY)
    captionLabel.isHidden = false
    if let frame = layoutMetrics.removeButtonFrame {
      removeImageView?.frame = frame.offsetBy(dx: pill.minX, dy: pill.minY)
    }
    bringSubviewToFront(captionLabel)
    if let removeImageView {
      bringSubviewToFront(removeImageView)
    }
  }

  private func removeHitAreaInBoundsCoordinates() -> CGRect? {
    guard let hit = layoutMetrics.removeHitAreaFrame else { return nil }
    let pill = FKCapsuleLayoutEngine.pillFrame(
      metrics: layoutMetrics,
      in: bounds,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
    return hit.offsetBy(dx: pill.minX, dy: pill.minY)
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

  public override var isEnabled: Bool {
    didSet {
      guard oldValue != isEnabled else { return }
      updateAppearance()
      updateAccessibility()
    }
  }

  public override var isHighlighted: Bool {
    didSet { applyHighlightFeedback() }
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    if showsRemoveButton, let hit = removeHitAreaInBoundsCoordinates(), hit.contains(point) {
      return true
    }
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
    guard let touch, bounds.contains(touch.location(in: self)) else { return }
    if showsRemoveButton, let hit = removeHitAreaInBoundsCoordinates(), hit.contains(touch.location(in: self)) {
      onRemove?()
      return
    }
    handlePrimaryTap()
  }

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .button
    clipsToBounds = false

    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)

    backgroundView.translatesAutoresizingMaskIntoConstraints = true
    backgroundView.autoresizingMask = []
    captionLabel.translatesAutoresizingMaskIntoConstraints = true
    captionLabel.autoresizingMask = []

    backgroundView.isUserInteractionEnabled = false
    captionLabel.isUserInteractionEnabled = false
    captionLabel.isAccessibilityElement = false
    captionLabel.lineBreakMode = .byTruncatingTail
    captionLabel.numberOfLines = 1
    captionLabel.adjustsFontForContentSizeCategory = false

    addSubview(backgroundView)
    addSubview(captionLabel)

    applyConfiguration()
  }

  private func applyConfiguration() {
    syncCaptionText()
    captionLabel.font = scaledTitleFont()
    syncLeadingIconSubview()
    syncRemoveSubview()
    refreshMetricsIfNeeded()
    setNeedsLayout()
    updateAppearance()
    updateAccessibility()
  }

  private var displayTitle: String {
    title.fk_limitedPrefix(48)
  }

  private func syncCaptionText() {
    captionLabel.text = displayTitle
  }

  private func computeMetrics(maxWidth: CGFloat?) -> FKCapsuleLayoutEngine.Metrics {
    let height = configuration.layout.size.height
    return FKCapsuleLayoutEngine.layout(
      .init(
        title: displayTitle,
        font: scaledTitleFont(),
        height: height,
        horizontalPadding: configuration.layout.horizontalPadding,
        iconSpacing: configuration.layout.iconSpacing,
        leadingIconPointSize: height * 0.42,
        hasLeadingIcon: leadingIcon != nil,
        showsRemoveButton: showsRemoveButton,
        removeSymbolPointSize: height * 0.34,
        removeHitSide: configuration.interaction.removeButtonHitSide,
        maxWidth: maxWidth
      )
    )
  }

  /// Natural width for Auto Layout — unconstrained by the current ``bounds``.
  private func updateIntrinsicMetrics() {
    intrinsicMetrics = computeMetrics(maxWidth: configuration.layout.maxWidth)
    layoutMetrics = intrinsicMetrics
  }

  private func relayoutMetrics() {
    layoutMetrics = computeMetrics(maxWidth: configuration.layout.maxWidth)
    if layoutMetrics != intrinsicMetrics {
      intrinsicMetrics = layoutMetrics
      invalidateIntrinsicContentSize()
    }
  }

  /// Prevents vertical ``UIStackView`` fill alignment from stretching the view wider than the pill.
  private func syncNaturalWidthConstraintIfNeeded() {
    FKCapsuleIntrinsicWidthConstraint.sync(
      on: self,
      width: layoutMetrics.size.width,
      storage: &naturalWidthConstraint
    )
  }

  /// Caps width only when ``FKChipLayoutConfiguration/maxWidth`` is set (never from transient ``bounds``).
  private func resolvedMaxWidth(forProposedWidth proposedWidth: CGFloat) -> CGFloat? {
    guard let cap = configuration.layout.maxWidth else { return nil }
    guard proposedWidth > 0, proposedWidth != UIView.noIntrinsicMetric else { return cap }
    return min(cap, proposedWidth)
  }

  private func refreshMetricsIfNeeded() {
    updateIntrinsicMetrics()
    invalidateIntrinsicContentSize()
  }

  private func applyCornerRadius(using metrics: FKCapsuleLayoutEngine.Metrics) {
    switch configuration.appearance.cornerStyle {
    case .capsule:
      backgroundView.layer.cornerRadius = metrics.cornerRadius
      backgroundView.layer.cornerCurve = .continuous
    case .fixed(let radius):
      backgroundView.layer.cornerRadius = radius
      backgroundView.layer.cornerCurve = .circular
    }
  }

  private func scaledTitleFont() -> UIFont {
    UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: configuration.appearance.titleFont)
  }

  private func syncLeadingIconSubview() {
    guard let leadingIcon else {
      releaseLeadingIconView()
      return
    }
    let colors = resolvedColors()
    let view = ensureLeadingIconView()
    view.tintColor = colors.foreground
    view.image = leadingIcon.resolvedTemplateImage(
      pointSize: configuration.layout.size.height * 0.42
    )
  }

  private func syncRemoveSubview() {
    guard showsRemoveButton else {
      releaseRemoveImageView()
      return
    }
    let view = ensureRemoveImageView()
    view.tintColor = configuration.appearance.normalForegroundColor
    view.image = FKChipRemoveIcon.image(
      pointSize: configuration.layout.size.height * 0.34,
      fallbackSymbolName: configuration.appearance.removeSymbolName
    )
  }

  private func updateAppearance() {
    let colors = resolvedColors()
    backgroundView.backgroundColor = colors.background
    if colors.borderWidth > 0 {
      backgroundView.layer.borderWidth = colors.borderWidth
      backgroundView.layer.borderColor = colors.border?.cgColor
    } else {
      backgroundView.layer.borderWidth = 0
      backgroundView.layer.borderColor = nil
    }
    captionLabel.textColor = colors.foreground
    alpha = isEnabled ? 1 : configuration.appearance.disabledAlpha
    syncLeadingIconSubview()
  }

  private struct ResolvedColors {
    var background: UIColor
    var foreground: UIColor
    var border: UIColor?
    var borderWidth: CGFloat
  }

  private func resolvedColors() -> ResolvedColors {
    let appearance = configuration.appearance
    switch mode {
    case .input, .suggestion:
      return ResolvedColors(
        background: appearance.normalBackgroundColor,
        foreground: appearance.normalForegroundColor,
        border: nil,
        borderWidth: 0
      )
    case .filter, .choice:
      if isSelected {
        if appearance.usesBorderWhenSelected {
          return ResolvedColors(
            background: appearance.selectedBackgroundColor.withAlphaComponent(0.12),
            foreground: appearance.selectedBorderColor,
            border: appearance.selectedBorderColor,
            borderWidth: appearance.selectedBorderWidth
          )
        }
        return ResolvedColors(
          background: appearance.selectedBackgroundColor,
          foreground: appearance.selectedForegroundColor,
          border: nil,
          borderWidth: 0
        )
      }
      return ResolvedColors(
        background: appearance.normalBackgroundColor,
        foreground: appearance.normalForegroundColor,
        border: nil,
        borderWidth: 0
      )
    }
  }

  private func handlePrimaryTap() {
    guard isEnabled else { return }
    switch mode {
    case .suggestion:
      sendActions(for: .primaryActionTriggered)
    case .input:
      sendActions(for: .primaryActionTriggered)
    case .filter, .choice:
      if managesSelectionInternally {
        isSelected.toggle()
      }
      if configuration.interaction.hapticFeedbackOnSelection {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      }
      sendActions(for: .valueChanged)
    }
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

  private func updateAccessibility() {
    if let custom = configuration.accessibility.customLabel {
      accessibilityLabel = custom
    } else if mode == .filter || mode == .choice {
      accessibilityLabel = FKChipI18n.filterLabel(
        title: title,
        selected: isSelected,
        roleDescription: configuration.accessibility.filterRoleDescription
      )
    } else {
      accessibilityLabel = title
    }
    accessibilityHint = configuration.accessibility.customHint
    var traits: UIAccessibilityTraits = .button
    if isSelected, mode != .input, mode != .suggestion {
      traits.insert(.selected)
    }
    accessibilityTraits = traits

    if showsRemoveButton {
      let removeName = FKChipI18n.removeLabel(title: title)
      accessibilityCustomActions = [
        UIAccessibilityCustomAction(name: removeName) { [weak self] _ in
          self?.onRemove?()
          return true
        },
      ]
    } else {
      accessibilityCustomActions = nil
    }
  }

  /// Applies chip content without triggering control events (for group sync).
  func applyContent(title: String, icon: FKChipIcon?, selected: Bool, enabled: Bool, showsRemove: Bool) {
    let limited = title.fk_limitedPrefix(48)
    captionLabel.text = limited
    if self.title != title {
      self.title = title
    } else {
      refreshMetricsIfNeeded()
      setNeedsLayout()
    }
    leadingIcon = icon
    showsRemoveButton = showsRemove
    isEnabled = enabled
    if isSelected != selected {
      isSelected = selected
    } else {
      updateAppearance()
    }
  }
}
