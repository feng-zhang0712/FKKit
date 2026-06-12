import FKCoreKit
import UIKit

/// Media picker row supporting avatar, thumbnail, and file variants (X-19, F-11).
@MainActor
public final class FKFormCellMediaPickerCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKFormMediaPickerRow

  /// Called when the user taps the action control.
  public var onPick: (() -> Void)?
  /// Called when the user requests removal (avatar/thumbnail variants).
  public var onRemove: (() -> Void)?

  private let layout = FKCellStandardRowLayout()
  private let avatarView = FKAvatar()
  private let thumbnailView = FKCellImageThumbnailView()
  private let iconSlot = FKCellIconSlotView()
  private let actionButton = UIButton(type: .system)

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKFormCellMediaPickerConfiguration) {
    apply(configuration, appearance: .default)
  }

  public func apply(
    _ configuration: FKFormCellMediaPickerConfiguration,
    appearance: FKCellAppearanceConfiguration = .default
  ) {
    layout.applyAppearance(appearance)
    actionButton.setTitle(configuration.actionTitle, for: .normal)
    actionButton.isEnabled = configuration.isEnabled

    switch configuration.variant {
    case let .avatar(displayName, imageURL, image):
      avatarView.displayName = displayName
      avatarView.imageURL = imageURL
      avatarView.image = image
      layout.contentStack.setLeadingContent(avatarView, width: 56)
      layout.contentStack.setTitle(displayName)
      layout.contentStack.setSubtitle(nil)
      layout.contentStack.setDetail(nil)
    case let .thumbnail(fileName, image):
      thumbnailView.apply(content: image)
      layout.contentStack.setLeadingContent(thumbnailView, width: FKCellLayoutMetrics.thumbnailSize)
      layout.contentStack.setTitle(fileName)
      layout.contentStack.setSubtitle(nil)
      layout.contentStack.setDetail(nil)
    case let .file(fileName, fileSizeText, icon):
      iconSlot.apply(icon)
      layout.contentStack.setLeadingContent(iconSlot, width: FKCellLayoutMetrics.iconColumnWidth)
      layout.contentStack.setTitle(fileName)
      layout.contentStack.setSubtitle(fileSizeText)
      layout.contentStack.setDetail(nil)
    }

    let accessory: FKCellAccessory = configuration.showsDisclosure ? .disclosureIndicator : .none
    layout.accessoryHost.apply(accessory, appearance: appearance)
    layout.contentStack.setAccessoryViews([actionButton, layout.accessoryHost])

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: .automatic,
        isLastInSection: false,
        isEnabled: configuration.isEnabled
      ),
      to: self
    )

    selectionStyle = .none
    accessibilityLabel = configuration.actionTitle
    accessibilityTraits = [.button]
  }

  public func configure(with viewModel: FKFormMediaPickerRow) {
    apply(viewModel.configuration)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    onPick = nil
    onRemove = nil
    avatarView.resetForReuse()
    thumbnailView.resetForReuse()
    iconSlot.reset()
    layout.resetForReuse()
    selectionStyle = .none
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none
    layout.install(in: contentView)

    actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
    actionButton.setContentHuggingPriority(.required, for: .horizontal)
  }

  @objc private func handleActionTap() {
    onPick?()
  }
}
