import FKCoreKit
import UIKit

/// Settings row with trailing ``UISwitch`` (I-01).
@MainActor
public final class FKCellSwitchCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellSwitchRow

  /// Called on the main actor when the user toggles the switch.
  public var onValueChanged: ((Bool) -> Void)?

  private let layout = FKCellStandardRowLayout()
  private var isApplyingConfiguration = false

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a switch row configuration with default appearance.
  public func apply(_ configuration: FKCellSwitchConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies a switch row configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellSwitchConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    isApplyingConfiguration = true
    FKCellSwitchLayoutRenderer.apply(
      layout: layout,
      configuration: configuration,
      appearance: appearance,
      groupConfiguration: groupConfiguration,
      host: self
    )
    wireSwitchControl()
    isApplyingConfiguration = false

    selectionStyle = .none
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellSwitchRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onValueChanged = nil
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)
  }

  private func wireSwitchControl() {
    layout.switchControl.removeTarget(nil, action: nil, for: .valueChanged)
    layout.switchControl.addTarget(self, action: #selector(handleSwitchValueChanged(_:)), for: .valueChanged)
  }

  @objc private func handleSwitchValueChanged(_ sender: UISwitch) {
    guard !isApplyingConfiguration else { return }
    onValueChanged?(sender.isOn)
  }
}
