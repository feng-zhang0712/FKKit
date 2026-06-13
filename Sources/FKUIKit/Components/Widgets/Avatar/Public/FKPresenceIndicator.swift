import UIKit

/// Small presence dot for user online/offline/busy/away status.
///
/// Attach to ``FKAvatar`` via configuration or use standalone. Not for order/workflow status — use ``FKStatusPill`` instead.
@MainActor
public final class FKPresenceIndicator: UIView {
  /// Baseline copied by ``init(frame:)`` until replaced via ``configuration``.
  public static var defaultConfiguration: FKPresenceIndicatorConfiguration {
    get { FKPresenceIndicatorDefaults.configuration }
    set { FKPresenceIndicatorDefaults.configuration = newValue }
  }

  /// Visual and motion settings.
  public var configuration: FKPresenceIndicatorConfiguration = FKPresenceIndicator.defaultConfiguration {
    didSet { applyConfiguration() }
  }

  /// Current presence state.
  public var state: FKPresenceState = .offline {
    didSet {
      guard oldValue != state else { return }
      updateAppearance()
    }
  }

  private let pulseLayer = FKPresencePulseLayer()
  private let dotLayer = CALayer()

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates an indicator with explicit configuration and state.
  public convenience init(
    configuration: FKPresenceIndicatorConfiguration = FKPresenceIndicator.defaultConfiguration,
    state: FKPresenceState = .offline
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.state = state
  }

  public override var intrinsicContentSize: CGSize {
    let diameter = configuration.size.diameter + borderOutset * 2
    return CGSize(width: diameter, height: diameter)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    layoutLayers()
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      updateAppearance()
    }
  }

  // MARK: - Private

  private var borderOutset: CGFloat {
    configuration.showsBorder ? configuration.borderWidth : 0
  }

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .staticText
    clipsToBounds = false
    layer.addSublayer(pulseLayer)
    layer.addSublayer(dotLayer)
    pulseLayer.onReduceMotionStatusChange = { [weak self] in
      self?.updateAppearance()
    }
    applyConfiguration()
    updateAppearance()
  }

  private func applyConfiguration() {
    pulseLayer.pulsePeriod = configuration.pulsePeriod
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    updateAppearance()
  }

  private func layoutLayers() {
    let diameter = configuration.size.diameter
    let dotFrame = CGRect(
      x: (bounds.width - diameter) / 2,
      y: (bounds.height - diameter) / 2,
      width: diameter,
      height: diameter
    )
    pulseLayer.frame = dotFrame
    dotLayer.frame = dotFrame
    dotLayer.cornerRadius = diameter / 2
  }

  private func updateAppearance() {
    let fillColor = resolvedFillColor()
    dotLayer.backgroundColor = fillColor.cgColor

    if configuration.showsBorder {
      dotLayer.borderWidth = configuration.borderWidth
      dotLayer.borderColor = (configuration.borderColor ?? .systemBackground).cgColor
    } else {
      dotLayer.borderWidth = 0
      dotLayer.borderColor = nil
    }

    accessibilityLabel = state.accessibilityLabel

    if shouldPulse {
      pulseLayer.pulseColor = fillColor
      pulseLayer.startAnimatingIfNeeded()
    } else {
      pulseLayer.stopAnimating()
    }
  }

  private var shouldPulse: Bool {
    switch state {
    case .online:
      configuration.pulsesWhenOnline
    case .custom(let custom):
      custom.pulses
    default:
      false
    }
  }

  private func resolvedFillColor() -> UIColor {
    switch state {
    case .online:
      configuration.stateColors.online
    case .offline:
      configuration.stateColors.offline
    case .busy:
      configuration.stateColors.busy
    case .away:
      configuration.stateColors.away
    case .custom(let custom):
      custom.color
    }
  }
}

/// Thread-safe global defaults for ``FKPresenceIndicator``.
public enum FKPresenceIndicatorDefaults {
  /// Baseline configuration copied by ``FKPresenceIndicator/init(frame:)``.
  @MainActor public static var configuration = FKPresenceIndicatorConfiguration()
}

/// Marks whether the indicator is embedded in an avatar (merged accessibility tree).
extension FKPresenceIndicator {
  /// When `true`, the indicator is not individually focusable in VoiceOver.
  public var isEmbeddedInAvatar: Bool {
    get { !isAccessibilityElement }
    set {
      isAccessibilityElement = !newValue
      accessibilityElementsHidden = newValue
    }
  }
}
