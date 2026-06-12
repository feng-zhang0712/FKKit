import FKCoreKit
import UIKit

/// Profile header row with avatar, name, and optional edit/disclosure accessory (D-17).
@MainActor
public final class FKCellProfileCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellProfileRow

  private let layout = FKCellStandardRowLayout()
  private let avatarSlot = FKCellAvatarSlotView()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Applies a profile configuration with default appearance.
  public func apply(_ configuration: FKCellProfileConfiguration) {
    apply(configuration, appearance: .default, imageURL: nil, image: nil, displayName: configuration.title)
  }

  /// Applies a profile configuration with explicit appearance and avatar payload.
  public func apply(
    _ configuration: FKCellProfileConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    imageURL: URL? = nil,
    image: UIImage? = nil,
    displayName: String? = nil
  ) {
    FKCellProfileLayoutRenderer.apply(
      layout: layout,
      avatarSlot: avatarSlot,
      configuration: configuration,
      appearance: appearance,
      imageURL: imageURL,
      image: image,
      displayName: displayName,
      host: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
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
    layout.resetForReuse()
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    layout.install(in: contentView)
  }
}
