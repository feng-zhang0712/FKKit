import UIKit

/// Shared disclosure row rendering for table and collection cells (D-01).
@MainActor
enum FKCellDisclosureLayoutRenderer {
  static func apply(
    layout: FKCellStandardRowLayout,
    configuration: FKCellDisclosureConfiguration,
    appearance: FKCellAppearanceConfiguration,
    groupConfiguration: FKCellGroupConfiguration?,
    host: FKCellChromeHost
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(nil)

    let accessory: FKCellAccessory = configuration.showsDisclosure ? .disclosureIndicator : .none
    layout.accessoryHost.apply(accessory, appearance: appearance)
    layout.contentStack.setAccessoryViews([layout.accessoryHost])

    layout.applyChrome(
      .init(
        groupConfiguration: groupConfiguration,
        separatorPolicy: configuration.separatorPolicy,
        isLastInSection: configuration.isLastInSection,
        isEnabled: configuration.isEnabled
      ),
      to: host
    )

    layout.contentStack.titleLabel.textColor = configuration.isEnabled ? .label : .tertiaryLabel
  }
}
