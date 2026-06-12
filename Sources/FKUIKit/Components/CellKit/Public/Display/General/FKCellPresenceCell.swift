import FKCoreKit
import UIKit

/// IM friend row with avatar presence dot and status text (D-19).
@MainActor
public final class FKCellPresenceCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellPresenceRow

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

  public func apply(_ configuration: FKCellPresenceConfiguration) {
    apply(configuration, appearance: .default, imageURL: nil, image: nil)
  }

  public func apply(
    _ configuration: FKCellPresenceConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    imageURL: URL? = nil,
    image: UIImage? = nil
  ) {
    layout.applyAppearance(appearance)
    var avatarConfig = configuration.avatarConfiguration
    avatarConfig.showsPresenceIndicator = true
    avatarConfig.presenceState = configuration.presenceState
    avatarSlot.apply(
      configuration: avatarConfig,
      displayName: configuration.name,
      imageURL: imageURL,
      image: image
    )
    layout.contentStack.setLeadingContent(avatarSlot, width: FKCellLayoutMetrics.compactAvatarSize)
    layout.contentStack.setTitle(configuration.name)
    layout.contentStack.setSubtitle(configuration.statusText)
    layout.contentStack.setDetail(configuration.timestamp)

    layout.contentStack.setAccessoryViews([])

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

  public func configure(with viewModel: FKCellPresenceRow) {
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
