import UIKit

@MainActor
final class FKTimelineRowView: UIView {
  let nodeView = FKFlowNodeView()
  let titleLabel = UILabel()
  private(set) var subtitleLabel: UILabel?
  private(set) var timestampLabel: UILabel?
  private(set) var captionLabel: UILabel?
  private(set) var chevronView: UIImageView?

  var itemID: String = ""
  var onTap: ((String) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    item: FKFlowStepItem,
    stepIndex: Int,
    configuration: FKTimelineConfiguration,
    isExpanded: Bool,
    showsChevron: Bool,
    isInteractive: Bool = false
  ) {
    itemID = item.id
    let appearanceConfig = configuration.appearance
    let nodeAppearance = appearanceConfig.appearance(for: item.state)
    let icon = FKFlowIconResolver.image(for: item.icon, state: item.state, stepIndex: stepIndex)
    let number = FKFlowIconResolver.numberLabel(for: item.icon, state: item.state, stepIndex: stepIndex)
    let alpha: CGFloat = item.state == .disabled ? configuration.interaction.disabledAlpha : 1

    nodeView.nodeShape = appearanceConfig.nodeShape
    nodeView.apply(
      appearance: nodeAppearance,
      icon: icon,
      numberText: number,
      iconTint: nodeAppearance.iconTint,
      alphaMultiplier: alpha
    )

    titleLabel.font = titleFont(for: item, configuration: configuration)
    titleLabel.textColor = appearanceConfig.titleColor
    titleLabel.text = item.title
    titleLabel.numberOfLines = configuration.layout.titleNumberOfLines

    if let subtitle = item.subtitle, !subtitle.isEmpty {
      let label = ensureSubtitleLabel()
      label.font = appearanceConfig.subtitleFont
      label.textColor = appearanceConfig.subtitleColor
      label.text = subtitle
      label.numberOfLines = configuration.layout.subtitleNumberOfLines
    } else {
      removeSubtitleLabel()
    }

    let timestamp = FKTimelineTimestampFormatter.string(for: item, style: configuration.layout.timestampStyle)
    if let timestamp {
      let label = ensureTimestampLabel()
      label.font = appearanceConfig.timestampFont
      label.textColor = appearanceConfig.timestampColor
      label.text = timestamp
    } else {
      removeTimestampLabel()
    }

    let hasCaption = !(item.caption?.isEmpty ?? true)
    if isExpanded && hasCaption {
      let label = ensureCaptionLabel()
      label.font = appearanceConfig.captionFont
      label.textColor = appearanceConfig.captionColor
      label.text = item.caption
      label.numberOfLines = configuration.layout.captionNumberOfLines
    } else {
      removeCaptionLabel()
    }

    if showsChevron {
      let view = ensureChevronView()
      view.transform = isExpanded ? CGAffineTransform(rotationAngle: .pi * 0.5) : .identity
    } else {
      removeChevronView()
    }

    let shouldPulse = item.state == .current
      && configuration.motion.pulsesCurrentNode
      && configuration.motion.shouldAnimate
    nodeView.setPulsing(shouldPulse)

    isAccessibilityElement = true
    accessibilityTraits = isInteractive ? .button : .staticText
    accessibilityLabel = FKFlowAccessibilityFormatter.timelineLabel(
      item: item,
      timestamp: timestamp,
      configuration: configuration.accessibility
    )
    if isInteractive, let hint = item.accessibilityHint ?? configuration.accessibility.selectableHint {
      accessibilityHint = hint
    } else {
      accessibilityHint = nil
    }
  }

  private func titleFont(for item: FKFlowStepItem, configuration: FKTimelineConfiguration) -> UIFont {
    guard configuration.appearance.emphasizesCurrentTitle, item.state == .current else {
      return configuration.appearance.titleFont
    }
    return UIFont.systemFont(ofSize: configuration.appearance.titleFont.pointSize, weight: .semibold)
  }

  private func commonInit() {
    titleLabel.numberOfLines = 0
    addSubview(nodeView)
    addSubview(titleLabel)
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
  }

  private func ensureSubtitleLabel() -> UILabel {
    if let subtitleLabel { return subtitleLabel }
    let label = UILabel()
    label.numberOfLines = 0
    addSubview(label)
    self.subtitleLabel = label
    return label
  }

  private func ensureTimestampLabel() -> UILabel {
    if let timestampLabel { return timestampLabel }
    let label = UILabel()
    label.numberOfLines = 0
    addSubview(label)
    self.timestampLabel = label
    return label
  }

  private func ensureCaptionLabel() -> UILabel {
    if let captionLabel { return captionLabel }
    let label = UILabel()
    label.numberOfLines = 0
    addSubview(label)
    self.captionLabel = label
    return label
  }

  private func ensureChevronView() -> UIImageView {
    if let chevronView { return chevronView }
    let view = UIImageView(image: UIImage(systemName: "chevron.right"))
    view.tintColor = .tertiaryLabel
    view.contentMode = .scaleAspectFit
    addSubview(view)
    self.chevronView = view
    return view
  }

  private func removeSubtitleLabel() {
    subtitleLabel?.removeFromSuperview()
    subtitleLabel = nil
  }

  private func removeTimestampLabel() {
    timestampLabel?.removeFromSuperview()
    timestampLabel = nil
  }

  private func removeCaptionLabel() {
    captionLabel?.removeFromSuperview()
    captionLabel = nil
  }

  private func removeChevronView() {
    chevronView?.removeFromSuperview()
    chevronView = nil
  }

  @objc private func handleTap() {
    onTap?(itemID)
  }
}
