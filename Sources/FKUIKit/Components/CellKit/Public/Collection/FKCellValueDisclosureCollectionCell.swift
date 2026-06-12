import FKCoreKit
import UIKit

/// Collection variant of ``FKCellValueDisclosureCell`` sharing the same layout renderer (D-03).
@MainActor
public final class FKCellValueDisclosureCollectionCell: UICollectionViewCell, FKCellCollectionReusable {
  public typealias ViewModel = FKCellValueDisclosureRow

  private let contentHost = FKCellCollectionContentHost()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellValueDisclosureConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKCellValueDisclosureConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    groupConfiguration: FKCellGroupConfiguration? = nil
  ) {
    FKCellValueDisclosureLayoutRenderer.apply(
      layout: contentHost.layout,
      configuration: configuration,
      appearance: appearance,
      groupConfiguration: groupConfiguration,
      host: self
    )
    accessibilityLabel = "\(configuration.title), \(configuration.value)"
    accessibilityTraits = configuration.showsDisclosure ? [.button] : []
  }

  public func configure(with viewModel: FKCellValueDisclosureRow) {
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
