import UIKit

/// Shared profile row rendering for table and collection cells (D-17).
@MainActor
enum FKCellProfileLayoutRenderer {
  static func apply(
    layout: FKCellStandardRowLayout,
    avatarSlot: FKCellAvatarSlotView,
    configuration: FKCellProfileConfiguration,
    appearance: FKCellAppearanceConfiguration,
    imageURL: URL?,
    image: UIImage?,
    displayName: String?,
    host: FKCellChromeHost
  ) {
    layout.applyAppearance(appearance)
    avatarSlot.apply(
      configuration: configuration.avatarConfiguration,
      displayName: displayName ?? configuration.title,
      imageURL: imageURL,
      image: image
    )
    layout.contentStack.setLeadingContent(avatarSlot, width: FKCellLayoutMetrics.feedAvatarSize)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(configuration.subtitle)

    switch configuration.accessory {
    case .none:
      layout.contentStack.setAccessoryViews([])
    case .disclosure:
      layout.accessoryHost.apply(.disclosureIndicator, appearance: appearance)
      layout.contentStack.setAccessoryViews([layout.accessoryHost])
    case let .text(text):
      layout.accessoryHost.apply(.value(text), appearance: appearance)
      layout.contentStack.setAccessoryViews([layout.accessoryHost])
    }

    layout.applyChrome(
      .init(
        groupConfiguration: nil,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: host
    )
  }
}
