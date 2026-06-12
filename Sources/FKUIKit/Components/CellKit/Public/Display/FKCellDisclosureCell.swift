import FKCoreKit
import UIKit

/// Standard settings navigation row with a trailing chevron (D-01).
@MainActor
public final class FKCellDisclosureCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellDisclosureRow

  private let layout = FKCellStandardRowLayout()
  private var appearance: FKCellAppearanceConfiguration = .default

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a disclosure configuration using default appearance.
  public func apply(_ configuration: FKCellDisclosureConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies a disclosure configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellDisclosureConfiguration,
    appearance: FKCellAppearanceConfiguration
  ) {
    apply(configuration, appearance: appearance, groupConfiguration: nil)
  }

  /// Applies configuration, appearance, and optional inset grouped background metadata.
  public func apply(
    _ configuration: FKCellDisclosureConfiguration,
    appearance: FKCellAppearanceConfiguration,
    groupConfiguration: FKCellGroupConfiguration?
  ) {
    self.appearance = appearance
    FKCellDisclosureLayoutRenderer.apply(
      layout: layout,
      configuration: configuration,
      appearance: appearance,
      groupConfiguration: groupConfiguration,
      host: self
    )
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.title
    accessibilityTraits = configuration.showsDisclosure ? [.button] : []
  }

  /// Binds a row model using default appearance.
  public func configure(with viewModel: FKCellDisclosureRow) {
    apply(viewModel.configuration)
  }

  /// Binds a row model with explicit appearance tokens.
  public func configure(with viewModel: FKCellDisclosureRow, appearance: FKCellAppearanceConfiguration) {
    apply(viewModel.configuration, appearance: appearance)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    layout.resetForReuse()
    alpha = 1
    isUserInteractionEnabled = true
    selectionStyle = .default
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    preservesSuperviewLayoutMargins = true
    contentView.preservesSuperviewLayoutMargins = true
    layout.install(in: contentView)
  }
}
