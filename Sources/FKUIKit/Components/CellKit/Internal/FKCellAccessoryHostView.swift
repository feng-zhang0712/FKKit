import UIKit

/// Lazily hosts trailing accessories without removing subviews on reuse.
@MainActor
final class FKCellAccessoryHostView: UIView {
  private lazy var disclosureView: UIImageView = {
    let image = UIImage(systemName: "chevron.forward", withConfiguration: chevronConfiguration())
    let view = UIImageView(image: image)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    view.tintColor = .tertiaryLabel
    return view
  }()

  private lazy var checkmarkView: UIImageView = {
    let image = UIImage(
      systemName: "checkmark",
      withConfiguration: UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
    )
    let view = UIImageView(image: image)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    view.tintColor = .systemBlue
    view.isHidden = true
    return view
  }()

  private lazy var valueLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.adjustsFontForContentSizeCategory = true
    label.font = .preferredFont(forTextStyle: .body)
    label.textColor = .secondaryLabel
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    label.isHidden = true
    return label
  }()

  private(set) lazy var switchControl: UISwitch = {
    let control = UISwitch()
    control.translatesAutoresizingMaskIntoConstraints = false
    control.setContentHuggingPriority(.required, for: .horizontal)
    control.setContentCompressionResistancePriority(.required, for: .horizontal)
    control.isHidden = true
    return control
  }()

  private var statusPillView: FKStatusPill?
  private var badgeHostView: UIView?
  private var copyChipView: FKCopyChip?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    _ accessory: FKCellAccessory,
    appearance: FKCellAppearanceConfiguration,
    badgeCount: Int? = nil
  ) {
    resetOptionalHosts()
    switchControl.isHidden = true

    switch accessory {
    case .none:
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = true

    case .disclosureIndicator:
      disclosureView.isHidden = false
      checkmarkView.isHidden = true
      valueLabel.isHidden = true

    case let .checkmark(isSelected):
      disclosureView.isHidden = true
      checkmarkView.isHidden = !isSelected
      valueLabel.isHidden = true

    case let .switchControl(isOn):
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = true
      switchControl.isHidden = false
      switchControl.isOn = isOn

    case let .value(text):
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = false
      valueLabel.text = text
      valueLabel.textColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)

    case let .statusPill(configuration):
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = true
      embedOptionalHost(FKStatusPill(configuration: configuration))

    case let .badge(configuration):
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = true
      let host = UIView()
      host.translatesAutoresizingMaskIntoConstraints = false
      host.fk_badge.configuration = configuration
      let count = max(0, badgeCount ?? 1)
      if count > 0 {
        host.fk_showBadgeCount(count)
      } else {
        host.fk_showBadgeDot()
      }
      embedOptionalHost(host)
      badgeHostView = host

    case let .copy(configuration):
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = true
      embedOptionalHost(FKCopyChip(configuration: configuration))

    case .custom:
      disclosureView.isHidden = true
      checkmarkView.isHidden = true
      valueLabel.isHidden = true
    }
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)

    addSubview(disclosureView)
    addSubview(checkmarkView)
    addSubview(valueLabel)
    addSubview(switchControl)

    NSLayoutConstraint.activate([
      disclosureView.leadingAnchor.constraint(equalTo: leadingAnchor),
      disclosureView.trailingAnchor.constraint(equalTo: trailingAnchor),
      disclosureView.centerYAnchor.constraint(equalTo: centerYAnchor),
      disclosureView.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.chevronWidth),

      checkmarkView.leadingAnchor.constraint(equalTo: leadingAnchor),
      checkmarkView.trailingAnchor.constraint(equalTo: trailingAnchor),
      checkmarkView.centerYAnchor.constraint(equalTo: centerYAnchor),

      valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      valueLabel.topAnchor.constraint(equalTo: topAnchor),
      valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

      switchControl.leadingAnchor.constraint(equalTo: leadingAnchor),
      switchControl.trailingAnchor.constraint(equalTo: trailingAnchor),
      switchControl.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  private func chevronConfiguration() -> UIImage.SymbolConfiguration {
    UIImage.SymbolConfiguration(textStyle: .footnote, scale: .medium)
      .applying(UIImage.SymbolConfiguration(weight: .semibold))
  }

  private func resetOptionalHosts() {
    statusPillView?.removeFromSuperview()
    statusPillView = nil
    badgeHostView?.removeFromSuperview()
    badgeHostView = nil
    copyChipView?.removeFromSuperview()
    copyChipView = nil
  }

  private func embedOptionalHost(_ view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: leadingAnchor),
      view.trailingAnchor.constraint(equalTo: trailingAnchor),
      view.topAnchor.constraint(equalTo: topAnchor),
      view.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    if let pill = view as? FKStatusPill { statusPillView = pill }
    if view !== statusPillView && badgeHostView == nil { badgeHostView = view }
    if let chip = view as? FKCopyChip { copyChipView = chip }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      disclosureView.image = UIImage(systemName: "chevron.forward", withConfiguration: chevronConfiguration())
    }
  }
}
