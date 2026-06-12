import FKCoreKit
import UIKit

/// Collection variant of ``FKCellSwitchCell`` sharing the same layout renderer (I-01).
@MainActor
public final class FKCellSwitchCollectionCell: UICollectionViewCell, FKCellCollectionReusable {
  public typealias ViewModel = FKCellSwitchRow

  /// Called on the main actor when the user toggles the switch.
  public var onValueChanged: ((Bool) -> Void)?

  private let contentHost = FKCellCollectionContentHost()
  private var isApplyingConfiguration = false

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellSwitchConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellSwitchConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    isApplyingConfiguration = true
    FKCellSwitchLayoutRenderer.apply(
      layout: contentHost.layout,
      configuration: configuration,
      appearance: appearance,
      groupConfiguration: groupConfiguration,
      host: self
    )
    wireSwitchControl()
    isApplyingConfiguration = false
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellSwitchRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onValueChanged = nil
    contentHost.resetForReuse()
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    contentHost.install(in: contentView)
  }

  private func wireSwitchControl() {
    contentHost.layout.switchControl.removeTarget(nil, action: nil, for: .valueChanged)
    contentHost.layout.switchControl.addTarget(
      self,
      action: #selector(handleSwitchValueChanged(_:)),
      for: .valueChanged
    )
  }

  @objc private func handleSwitchValueChanged(_ sender: UISwitch) {
    guard !isApplyingConfiguration else { return }
    onValueChanged?(sender.isOn)
  }
}
