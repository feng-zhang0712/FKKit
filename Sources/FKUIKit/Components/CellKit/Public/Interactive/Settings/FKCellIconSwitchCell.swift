import FKCoreKit
import UIKit

/// Settings row with leading icon, optional subtitle, and trailing switch (I-02).
@MainActor
public final class FKCellIconSwitchCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellIconSwitchRow

  /// Called on the main actor when the user toggles the switch.
  public var onValueChanged: ((Bool) -> Void)?

  private let layout = FKCellStandardRowLayout()
  private let iconSlot = FKCellIconSlotView()
  private var isApplyingConfiguration = false

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies an icon switch configuration with default appearance.
  public func apply(_ configuration: FKCellIconSwitchConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies an icon switch configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellIconSwitchConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    layout.applyAppearance(appearance)
    iconSlot.apply(configuration.icon)
    layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)
    layout.contentStack.setDetail(nil)

    layout.accessoryHost.apply(.switchControl(isOn: configuration.isOn), appearance: appearance)
    layout.accessoryHost.switchControl.isEnabled = configuration.isEnabled
    layout.contentStack.setAccessoryViews([layout.accessoryHost])

    isApplyingConfiguration = true
    layout.accessoryHost.switchControl.isOn = configuration.isOn
    isApplyingConfiguration = false

    layout.applyChrome(
      .init(
        groupConfiguration: groupConfiguration,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    layout.contentStack.titleLabel.textColor = configuration.isEnabled ? .label : .tertiaryLabel
    selectionStyle = .none
    accessibilityLabel = [configuration.title, configuration.subtitle]
      .compactMap { value in
        guard let value, !value.isEmpty else { return nil }
        return value
      }
      .joined(separator: ", ")
    layout.accessoryHost.switchControl.accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellIconSwitchRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onValueChanged = nil
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)
    layout.accessoryHost.switchControl.addTarget(self, action: #selector(handleSwitchValueChanged(_:)), for: .valueChanged)
  }

  @objc private func handleSwitchValueChanged(_ sender: UISwitch) {
    guard !isApplyingConfiguration else { return }
    onValueChanged?(sender.isOn)
  }
}
