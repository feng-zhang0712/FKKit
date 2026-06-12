import UIKit

/// Hosts a single trailing accessory slot, creating subviews on demand.
@MainActor
final class FKCellAccessoryHostView: UIView {
  private enum ActiveCoreSlot {
    case disclosure(UIImageView)
    case checkmark(UIImageView)
    case value(UILabel)
    case switchControl(UISwitch)
  }

  private var activeCoreSlot: ActiveCoreSlot?
  private var statusPillView: FKStatusPill?
  private var badgeHostView: UIView?
  private var copyChipView: FKCopyChip?

  /// The embedded switch when the active accessory is ``FKCellAccessory/switchControl``.
  var switchControl: UISwitch {
    if case let .switchControl(control) = activeCoreSlot {
      return control
    }
    let control = makeSwitchControl()
    setCoreSlot(.switchControl(control))
    return control
  }

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

    switch accessory {
    case .none:
      clearCoreSlot()

    case .disclosureIndicator:
      setCoreSlot(.disclosure(makeDisclosureView()))

    case let .checkmark(isSelected):
      let view = makeCheckmarkView()
      view.isHidden = !isSelected
      setCoreSlot(.checkmark(view))

    case let .switchControl(isOn):
      if case let .switchControl(existing) = activeCoreSlot {
        existing.isOn = isOn
      } else {
        let control = makeSwitchControl()
        control.isOn = isOn
        setCoreSlot(.switchControl(control))
      }

    case let .value(text):
      let label = makeValueLabel()
      label.text = text
      label.textColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)
      setCoreSlot(.value(label))

    case let .statusPill(configuration):
      clearCoreSlot()
      embedOptionalHost(FKStatusPill(configuration: configuration))

    case let .badge(configuration):
      clearCoreSlot()
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
      clearCoreSlot()
      embedOptionalHost(FKCopyChip(configuration: configuration))

    case .custom:
      clearCoreSlot()
    }
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard !isHidden, isUserInteractionEnabled, alpha >= 0.01, bounds.contains(point) else { return nil }
    for subview in subviews.reversed() {
      let converted = convert(point, to: subview)
      if let hit = subview.hitTest(converted, with: event) { return hit }
    }
    return nil
  }

  private func clearCoreSlot() {
    guard let slot = activeCoreSlot else { return }
    view(for: slot).removeFromSuperview()
    activeCoreSlot = nil
  }

  private func setCoreSlot(_ slot: ActiveCoreSlot) {
    clearCoreSlot()
    activeCoreSlot = slot
    let view = view(for: slot)
    view.translatesAutoresizingMaskIntoConstraints = false
    addSubview(view)
    activateConstraints(for: slot, view: view)
  }

  private func view(for slot: ActiveCoreSlot) -> UIView {
    switch slot {
    case let .disclosure(view), let .checkmark(view):
      return view
    case let .value(view):
      return view
    case let .switchControl(view):
      return view
    }
  }

  private func activateConstraints(for slot: ActiveCoreSlot, view: UIView) {
    switch slot {
    case .disclosure:
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.centerYAnchor.constraint(equalTo: centerYAnchor),
        view.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.chevronWidth),
        view.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.chevronHeight),
      ])

    case .checkmark, .switchControl:
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.centerYAnchor.constraint(equalTo: centerYAnchor),
      ])

    case .value:
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: leadingAnchor),
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.topAnchor.constraint(equalTo: topAnchor),
        view.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }
  }

  private func makeDisclosureView() -> UIImageView {
    let view = UIImageView(image: FKCellDisclosureChevronImage.make())
    view.contentMode = .scaleAspectFit
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    view.tintColor = .tertiaryLabel
    return view
  }

  private func makeCheckmarkView() -> UIImageView {
    let image = UIImage(
      systemName: "checkmark",
      withConfiguration: UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
    )
    let view = UIImageView(image: image)
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    view.tintColor = .systemBlue
    return view
  }

  private func makeValueLabel() -> UILabel {
    let label = UILabel()
    label.adjustsFontForContentSizeCategory = true
    label.font = .preferredFont(forTextStyle: .body)
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    return label
  }

  private func makeSwitchControl() -> UISwitch {
    let control = UISwitch()
    control.setContentHuggingPriority(.required, for: .horizontal)
    control.setContentCompressionResistancePriority(.required, for: .horizontal)
    return control
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
    guard
      traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory
        || traitCollection.layoutDirection != previousTraitCollection?.layoutDirection
    else { return }
    if case let .disclosure(view) = activeCoreSlot {
      view.image = FKCellDisclosureChevronImage.make()
    }
  }
}
