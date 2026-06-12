import FKCoreKit
import UIKit

/// Read-only metadata capsule for categories, promotions, and roles (v1 non-interactive).
///
/// For workflow/order status words use ``FKStatusPill``; for numeric badges use ``FKBadge``.
@MainActor
public final class FKTag: UIView {
  public static var defaultConfiguration: FKTagConfiguration {
    get { FKTagDefaults.configuration }
    set { FKTagDefaults.configuration = newValue }
  }

  public var configuration: FKTagConfiguration = FKTag.defaultConfiguration {
    didSet { applyConfiguration() }
  }

  public var title: String = "" {
    didSet {
      guard oldValue != title else { return }
      applyConfiguration()
    }
  }

  public var variant: FKTagVariant = .neutral {
    didSet {
      guard oldValue != variant else { return }
      applyConfiguration()
    }
  }

  public var leadingIcon: FKTagIcon? {
    didSet {
      guard oldValue != leadingIcon else { return }
      applyConfiguration()
    }
  }

  private let backgroundView = UIView()
  private let titleLabel = UILabel()
  var leadingIconView: UIImageView?
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
    configuration: FKTagConfiguration = FKTag.defaultConfiguration,
    title: String = "",
    variant: FKTagVariant = .neutral
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.title = title
    self.variant = variant
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
    syncTitleText()
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
    titleLabel.frame = layoutMetrics.titleFrame.offsetBy(dx: pill.minX, dy: pill.minY)
    titleLabel.isHidden = false
    bringSubviewToFront(titleLabel)
    if let leadingIconView {
      bringSubviewToFront(leadingIconView)
    }
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil else { return }
    refreshMetricsIfNeeded()
    setNeedsLayout()
    superview?.setNeedsLayout()
    updateAppearance()
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

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .staticText
    isUserInteractionEnabled = false

    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)

    backgroundView.translatesAutoresizingMaskIntoConstraints = true
    backgroundView.autoresizingMask = []
    titleLabel.translatesAutoresizingMaskIntoConstraints = true
    titleLabel.autoresizingMask = []

    backgroundView.isUserInteractionEnabled = false
    titleLabel.isUserInteractionEnabled = false
    titleLabel.isAccessibilityElement = false
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.numberOfLines = 1
    titleLabel.adjustsFontForContentSizeCategory = false

    addSubview(backgroundView)
    addSubview(titleLabel)

    applyConfiguration()
  }

  private func applyConfiguration() {
    syncTitleText()
    titleLabel.font = scaledTitleFont()
    syncLeadingIconSubview()
    refreshMetricsIfNeeded()
    setNeedsLayout()
    updateAppearance()
    updateAccessibility()
  }

  private var displayTitle: String {
    title.fk_limitedPrefix(48)
  }

  private func syncTitleText() {
    titleLabel.text = displayTitle
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
        leadingIconPointSize: height * 0.4,
        hasLeadingIcon: leadingIcon != nil,
        showsRemoveButton: false,
        removeSymbolPointSize: 0,
        removeHitSide: 0,
        maxWidth: maxWidth
      )
    )
  }

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

  /// Caps width only when ``FKTagLayoutConfiguration/maxWidth`` is set (never from transient ``bounds``).
  private func resolvedMaxWidth(forProposedWidth proposedWidth: CGFloat) -> CGFloat? {
    guard let cap = configuration.layout.maxWidth else { return nil }
    guard proposedWidth > 0, proposedWidth != UIView.noIntrinsicMetric else { return cap }
    return min(cap, proposedWidth)
  }

  private func refreshMetricsIfNeeded() {
    updateIntrinsicMetrics()
    invalidateIntrinsicContentSize()
  }

  private func scaledTitleFont() -> UIFont {
    FKTagRenderer.scaledFont(base: configuration.appearance.titleFont, size: configuration.layout.size)
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

  private func syncLeadingIconSubview() {
    guard let leadingIcon else {
      releaseLeadingIconView()
      return
    }
    let colors = FKTagRenderer.colors(for: variant, tintColor: tintColor)
    let view = ensureLeadingIconView()
    view.tintColor = colors.foreground
    view.image = leadingIcon.resolvedTemplateImage(
      pointSize: configuration.layout.size.height * 0.4
    )
  }

  private func updateAppearance() {
    let colors = FKTagRenderer.colors(for: variant, tintColor: tintColor)
    backgroundView.backgroundColor = colors.background
    titleLabel.textColor = colors.foreground
    if colors.borderWidth > 0, let border = colors.border {
      backgroundView.layer.borderWidth = colors.borderWidth
      backgroundView.layer.borderColor = border.cgColor
    } else {
      backgroundView.layer.borderWidth = 0
      backgroundView.layer.borderColor = nil
    }
    syncLeadingIconSubview()
  }

  private func updateAccessibility() {
    accessibilityLabel = configuration.accessibility.customLabel ?? title
  }
}
