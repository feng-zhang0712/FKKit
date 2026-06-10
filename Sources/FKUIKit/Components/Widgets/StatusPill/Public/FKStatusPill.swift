import FKCoreKit
import UIKit

/// Read-only workflow status capsule for orders, tickets, and logistics rows.
///
/// For marketing/metadata labels use ``FKTag``; for user presence use ``FKPresenceIndicator``.
@MainActor
public final class FKStatusPill: UIView {
  public static var defaultConfiguration: FKStatusPillConfiguration {
    get { FKStatusPillDefaults.configuration }
    set { FKStatusPillDefaults.configuration = newValue }
  }

  public var configuration: FKStatusPillConfiguration = FKStatusPill.defaultConfiguration {
    didSet { applyConfiguration() }
  }

  /// Status word displayed inside the pill (for example, “Shipped”, “Pending review”).
  public var title: String = "" {
    didSet {
      guard oldValue != title else { return }
      applyConfiguration()
    }
  }

  /// Workflow semantic styling.
  public var style: FKStatusPillStyle = .neutral {
    didSet {
      guard oldValue != style else { return }
      updateAppearance()
      updatePulseState()
    }
  }

  /// When `true`, shows an 8 pt leading dot spaced before the title.
  public var showsDot: Bool = false {
    didSet {
      guard oldValue != showsDot else { return }
      refreshMetricsIfNeeded()
      updatePulseState()
      setNeedsLayout()
    }
  }

  private let backgroundView = UIView()
  private let dotView = UIView()
  private let pulseLayer = FKPresencePulseLayer()
  private let titleLabel = UILabel()
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
    configuration: FKStatusPillConfiguration = FKStatusPill.defaultConfiguration,
    title: String = "",
    style: FKStatusPillStyle = .neutral,
    showsDot: Bool = false
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.title = title
    self.style = style
    self.showsDot = showsDot
    applyConfiguration()
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

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil else { return }
    refreshMetricsIfNeeded()
    setNeedsLayout()
    superview?.setNeedsLayout()
    updateAppearance()
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

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .staticText
    isUserInteractionEnabled = false
    clipsToBounds = false

    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.defaultHigh, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)

    backgroundView.translatesAutoresizingMaskIntoConstraints = true
    backgroundView.autoresizingMask = []
    dotView.translatesAutoresizingMaskIntoConstraints = true
    dotView.autoresizingMask = []
    titleLabel.translatesAutoresizingMaskIntoConstraints = true
    titleLabel.autoresizingMask = []

    backgroundView.isUserInteractionEnabled = false
    dotView.isUserInteractionEnabled = false
    dotView.isHidden = true
    dotView.layer.cornerCurve = .continuous

    titleLabel.isUserInteractionEnabled = false
    titleLabel.isAccessibilityElement = false
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.numberOfLines = 1
    titleLabel.adjustsFontForContentSizeCategory = false

    pulseLayer.onReduceMotionStatusChange = { [weak self] in
      self?.updatePulseState()
    }

    addSubview(backgroundView)
    addSubview(dotView)
    addSubview(titleLabel)

    applyConfiguration()
  }

  private func applyConfiguration() {
    titleLabel.text = title.fk_limitedPrefix(32)
    titleLabel.font = FKStatusPillRenderer.scaledTitleFont(configuration: configuration)
    dotView.isHidden = !showsDot
    refreshMetricsIfNeeded()
    setNeedsLayout()
    updateAppearance()
    updatePulseState()
    updateAccessibility()
  }

  private func computeMetrics(maxWidth: CGFloat?) -> FKCapsuleLayoutEngine.Metrics {
    let layout = configuration.layout
    return FKCapsuleLayoutEngine.layout(
      .init(
        title: titleLabel.text ?? title,
        font: FKStatusPillRenderer.scaledTitleFont(configuration: configuration),
        height: layout.size.height,
        horizontalPadding: layout.horizontalPadding,
        iconSpacing: layout.dotSpacing,
        leadingIconPointSize: layout.dotDiameter,
        hasLeadingIcon: showsDot,
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

  /// Caps width only when ``FKStatusPillLayoutConfiguration/maxWidth`` is set (never from transient ``bounds``).
  private func resolvedMaxWidth(forProposedWidth proposedWidth: CGFloat) -> CGFloat? {
    guard let cap = configuration.layout.maxWidth else { return nil }
    guard proposedWidth > 0, proposedWidth != UIView.noIntrinsicMetric else { return cap }
    return min(cap, proposedWidth)
  }

  private func refreshMetricsIfNeeded() {
    updateIntrinsicMetrics()
    invalidateIntrinsicContentSize()
  }

  private func applySubviewFrames() {
    let pill = FKCapsuleLayoutEngine.pillFrame(
      metrics: layoutMetrics,
      in: bounds,
      layoutDirection: effectiveUserInterfaceLayoutDirection
    )
    backgroundView.frame = pill
    applyCornerRadius(using: layoutMetrics)

    if let dotFrame = layoutMetrics.leadingIconFrame, showsDot {
      dotView.isHidden = false
      dotView.frame = dotFrame.offsetBy(dx: pill.minX, dy: pill.minY)
      dotView.layer.cornerRadius = dotFrame.width / 2
      layoutPulseLayer()
    } else {
      dotView.isHidden = true
    }

    titleLabel.frame = layoutMetrics.titleFrame.offsetBy(dx: pill.minX, dy: pill.minY)
    bringSubviewToFront(dotView)
    bringSubviewToFront(titleLabel)
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

  private func layoutPulseLayer() {
    if pulseLayer.superlayer !== dotView.layer {
      dotView.layer.insertSublayer(pulseLayer, at: 0)
    }
    let side = dotView.bounds.width
    guard side > 0 else { return }
    let pulseSide = side * 2.2
    pulseLayer.frame = CGRect(
      x: (side - pulseSide) / 2,
      y: (side - pulseSide) / 2,
      width: pulseSide,
      height: pulseSide
    )
  }

  private func updateAppearance() {
    let colors = FKStatusPillRenderer.colors(
      for: style,
      dotColorOverride: configuration.appearance.dotColorOverride
    )
    backgroundView.backgroundColor = colors.background
    titleLabel.textColor = colors.foreground
    dotView.backgroundColor = colors.dot
    pulseLayer.pulseColor = colors.dot
  }

  private func updatePulseState() {
    let shouldPulse = showsDot && FKStatusPillRenderer.shouldPulseDot(style: style, configuration: configuration)
    pulseLayer.isHidden = !shouldPulse
    if shouldPulse {
      pulseLayer.startAnimatingIfNeeded()
    } else {
      pulseLayer.stopAnimating()
    }
  }

  private func updateAccessibility() {
    if let custom = configuration.accessibility.customLabel {
      accessibilityLabel = custom
      return
    }
    if configuration.accessibility.includesStatusSuffix {
      accessibilityLabel = FKStatusPillI18n.accessibilityLabel(title: title)
    } else {
      accessibilityLabel = title
    }
  }
}
