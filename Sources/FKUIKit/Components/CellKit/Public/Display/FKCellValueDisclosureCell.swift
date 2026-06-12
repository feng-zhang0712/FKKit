import FKCoreKit
import UIKit

/// Settings row with trailing detail text and chevron (D-03, I-04, I-07).
@MainActor
public final class FKCellValueDisclosureCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellValueDisclosureRow

  private let layout = FKCellStandardRowLayout()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a value disclosure configuration with default appearance.
  public func apply(_ configuration: FKCellValueDisclosureConfiguration) {
    apply(configuration, appearance: .default)
  }

  /// Applies a value disclosure configuration with explicit appearance tokens.
  public func apply(
    _ configuration: FKCellValueDisclosureConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    FKCellValueDisclosureLayoutRenderer.apply(
      layout: layout,
      configuration: configuration,
      appearance: appearance,
      groupConfiguration: groupConfiguration,
      host: self
    )
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = "\(configuration.title), \(configuration.value)"
    accessibilityTraits = configuration.showsDisclosure ? [.button] : []
  }

  public func configure(with viewModel: FKCellValueDisclosureRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
