import FKCoreKit
import UIKit

/// Compact contact row with avatar, name, and optional role line (D-18).
@MainActor
public final class FKCellContactCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellContactRow

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

  public func apply(_ configuration: FKCellContactConfiguration) {
    apply(configuration, appearance: .default, imageURL: nil, image: nil)
  }

  public func apply(
    _ configuration: FKCellContactConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    imageURL: URL? = nil,
    image: UIImage? = nil
  ) {
    layout.applyAppearance(appearance)
    avatarSlot.apply(
      configuration: configuration.avatarConfiguration,
      displayName: configuration.name,
      imageURL: imageURL,
      image: image
    )
    layout.contentStack.setLeadingContent(avatarSlot, width: FKCellLayoutMetrics.compactAvatarSize)
    layout.contentStack.setTitle(configuration.name)
    layout.contentStack.setSubtitle(configuration.detail)

    let accessory: FKCellAccessory = configuration.showsDisclosure ? .disclosureIndicator : .none
    layout.accessoryHost.apply(accessory, appearance: appearance)
    layout.contentStack.setAccessoryViews(configuration.showsDisclosure ? [layout.accessoryHost] : [])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = configuration.name
  }

  public func configure(with viewModel: FKCellContactRow) {
    apply(viewModel.configuration, imageURL: viewModel.imageURL, image: viewModel.image)
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
