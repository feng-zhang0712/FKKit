import FKCoreKit
import UIKit

/// Collection variant of ``FKCellProfileCell`` sharing the same layout renderer (D-17).
@MainActor
public final class FKCellProfileCollectionCell: UICollectionViewCell, FKCellCollectionReusable {
  public typealias ViewModel = FKCellProfileRow

  private let contentHost = FKCellCollectionContentHost()
  private let avatarSlot = FKCellAvatarSlotView()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellProfileConfiguration) {
    apply(configuration, appearance: .default, imageURL: nil, image: nil, displayName: configuration.title)
  }

  public func apply(
    _ configuration: FKCellProfileConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    imageURL: URL? = nil,
    image: UIImage? = nil,
    displayName: String? = nil
  ) {
    FKCellProfileLayoutRenderer.apply(
      layout: contentHost.layout,
      avatarSlot: avatarSlot,
      configuration: configuration,
      appearance: appearance,
      imageURL: imageURL,
      image: image,
      displayName: displayName,
      host: self
    )
    accessibilityLabel = configuration.title
  }

  public func configure(with viewModel: FKCellProfileRow) {
    apply(
      viewModel.configuration,
      imageURL: viewModel.imageURL,
      image: viewModel.image,
      displayName: viewModel.displayName
    )
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    avatarSlot.resetForReuse()
    contentHost.resetForReuse()
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    contentHost.install(in: contentView)
  }
}
