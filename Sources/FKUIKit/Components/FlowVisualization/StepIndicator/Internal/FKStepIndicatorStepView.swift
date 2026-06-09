import UIKit

@MainActor
final class FKStepIndicatorStepView: UIView {
  let nodeView = FKFlowNodeView()
  let titleLabel = UILabel()
  private(set) var subtitleLabel: UILabel?

  var index: Int = 0
  var onTap: ((Int) -> Void)?

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
    totalCount: Int,
    configuration: FKStepIndicatorConfiguration,
    isLoading: Bool = false,
    isSelectable: Bool = false
  ) {
    index = stepIndex
    let appearanceConfig = configuration.appearance
    let nodeAppearance = appearanceConfig.appearance(for: item.state)
    let alpha: CGFloat = item.state == .disabled ? configuration.interaction.disabledAlpha : 1

    nodeView.nodeShape = appearanceConfig.nodeShape

    if isLoading {
      nodeView.setLoading(true, tint: nodeAppearance.iconTint)
      nodeView.apply(
        appearance: nodeAppearance,
        icon: nil,
        numberText: nil,
        iconTint: nodeAppearance.iconTint,
        alphaMultiplier: alpha
      )
    } else {
      nodeView.setLoading(false)
      let icon = FKFlowIconResolver.image(for: item.icon, state: item.state, stepIndex: stepIndex)
      let number = FKFlowIconResolver.numberLabel(for: item.icon, state: item.state, stepIndex: stepIndex)
      nodeView.apply(
        appearance: nodeAppearance,
        icon: icon,
        numberText: number,
        iconTint: nodeAppearance.iconTint,
        alphaMultiplier: alpha
      )
    }

    let titleFont = titleFont(for: item, configuration: configuration)
    titleLabel.font = titleFont
    titleLabel.textColor = appearanceConfig.titleColor
    titleLabel.numberOfLines = configuration.layout.titleNumberOfLines
    let isInline = configuration.layout.layout == .horizontalInline
    titleLabel.textAlignment = isInline ? .left : .center
    if appearanceConfig.strikethroughSkippedTitles, item.state == .skipped {
      titleLabel.attributedText = NSAttributedString(
        string: item.title,
        attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
      )
    } else {
      titleLabel.text = item.title
    }

    if let subtitle = item.subtitle, !subtitle.isEmpty {
      let label = ensureSubtitleLabel()
      label.font = appearanceConfig.subtitleFont
      label.textColor = appearanceConfig.subtitleColor
      label.text = subtitle
      label.numberOfLines = configuration.layout.subtitleNumberOfLines
      label.textAlignment = isInline ? .left : .center
    } else {
      removeSubtitleLabel()
    }

    let shouldPulse = item.state == .current
      && !isLoading
      && configuration.motion.pulsesCurrentNode
      && configuration.motion.shouldAnimate
    nodeView.setPulsing(shouldPulse)

    isAccessibilityElement = true
    accessibilityTraits = isSelectable ? .button : .staticText
    accessibilityLabel = FKFlowAccessibilityFormatter.stepLabel(
      index: stepIndex,
      count: totalCount,
      item: item,
      configuration: configuration.accessibility
    )
    if isSelectable, let hint = item.accessibilityHint ?? configuration.accessibility.selectableHint {
      accessibilityHint = hint
    } else {
      accessibilityHint = nil
    }
  }

  private func titleFont(for item: FKFlowStepItem, configuration: FKStepIndicatorConfiguration) -> UIFont {
    guard configuration.appearance.emphasizesCurrentTitle, item.state == .current else {
      return configuration.appearance.titleFont
    }
    return UIFont.systemFont(ofSize: configuration.appearance.titleFont.pointSize, weight: .semibold)
  }

  private func commonInit() {
    isUserInteractionEnabled = true
    isMultipleTouchEnabled = false
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.clipsToBounds = true
    addSubview(nodeView)
    addSubview(titleLabel)
    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
  }

  private func ensureSubtitleLabel() -> UILabel {
    if let subtitleLabel { return subtitleLabel }
    let label = UILabel()
    label.lineBreakMode = .byTruncatingTail
    label.clipsToBounds = true
    addSubview(label)
    self.subtitleLabel = label
    return label
  }

  private func removeSubtitleLabel() {
    subtitleLabel?.removeFromSuperview()
    subtitleLabel = nil
  }

  @objc private func handleTap() {
    onTap?(index)
  }
}
