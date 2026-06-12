import UIKit

/// Shared switch row rendering for table and collection cells (I-01).
@MainActor
enum FKCellSwitchLayoutRenderer {
  static func apply(
    layout: FKCellStandardRowLayout,
    configuration: FKCellSwitchConfiguration,
    appearance: FKCellAppearanceConfiguration,
    groupConfiguration: FKCellGroupConfiguration?,
    host: FKCellChromeHost
  ) {
    layout.applyAppearance(appearance)
    layout.contentStack.setLeadingContent(nil, width: 0)
    layout.contentStack.setTitle(configuration.title)
    layout.contentStack.setSubtitle(nil)
    layout.contentStack.setDetail(nil)

    layout.accessoryHost.apply(.switchControl(isOn: configuration.isOn), appearance: appearance)
    layout.accessoryHost.switchControl.isEnabled = configuration.isEnabled
    layout.contentStack.setAccessoryViews([layout.accessoryHost])
    layout.accessoryHost.switchControl.isOn = configuration.isOn

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
    layout.accessoryHost.switchControl.accessibilityLabel = configuration.title
  }
}
