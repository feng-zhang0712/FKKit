import FKCoreKit
import UIKit

/// Collection variant of ``FKCellDisclosureCell`` sharing the same layout renderer (D-01).
@MainActor
public final class FKCellDisclosureCollectionCell: UICollectionViewCell, FKCellCollectionReusable {
  public typealias ViewModel = FKCellDisclosureRow

  private let contentHost = FKCellCollectionContentHost()

  public override init(frame: CGRect) {
    super.init(frame: frame)
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
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    FKCellDisclosureLayoutRenderer.apply(
      layout: contentHost.layout,
      configuration: configuration,
      appearance: appearance,
      groupConfiguration: groupConfiguration,
      host: self
    )
    accessibilityLabel = configuration.title
    accessibilityTraits = configuration.showsDisclosure ? [.button] : []
  }

  public func configure(with viewModel: FKCellDisclosureRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    contentHost.resetForReuse()
    accessibilityLabel = nil
    accessibilityTraits = []
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    contentHost.install(in: contentView)
  }
}
