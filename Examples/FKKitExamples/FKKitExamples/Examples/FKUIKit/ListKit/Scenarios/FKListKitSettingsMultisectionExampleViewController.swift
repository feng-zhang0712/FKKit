import FKUIKit
import UIKit

/// Demonstrates all preset row types, section headers/footers, and toggle handler registries.
final class FKListKitSettingsMultisectionExampleViewController: FKDiffableTableViewController {
  private var wifiOn = true
  private var notificationsOn = false
  private var agreeTerms = false

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    config.selection.playsHapticOnSelect = true
    super.init(configuration: config, style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings · Presets"
    registerHandlers()
    registerSectionViewProvider(id: "custom-badge") { [weak self] in
      let label = UILabel()
      label.text = "  Custom header provider"
      label.font = self?.configuration.appearance.sectionHeaderFont
      label.textColor = self?.configuration.appearance.sectionHeaderColor
      return label
    }
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func registerHandlers() {
    switchHandlerRegistry.register(id: "wifi") { [weak self] _, isOn in
      self?.wifiOn = isOn
      self?.reloadSnapshot()
    }
    switchHandlerRegistry.register(id: "notifications") { [weak self] _, isOn in
      self?.notificationsOn = isOn
      self?.reloadSnapshot()
    }
    checkboxHandlerRegistry.register(id: "terms") { [weak self] _, isChecked in
      self?.agreeTerms = isChecked
      self?.reloadSnapshot()
    }
  }

  private func reloadSnapshot() {
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  private func buildSnapshot() -> FKListSnapshot {
    FKListSnapshot(sections: [
      FKListSection(
        id: "account",
        items: [
          FKListItem(id: "profile", kind: .preset(.disclosure(FKListDisclosureRow(
            leading: .symbol(name: "person.circle"),
            title: "Profile",
            subtitle: "Name, email, avatar"
          )))),
          FKListItem(id: "selected", kind: .preset(.disclosure(FKListDisclosureRow(
            leading: .symbol(name: "star.fill"),
            title: "Symbol leading row",
            subtitle: "FKListLeadingContent.symbol (SF Symbol)",
            accessory: .checkmark
          )))),
          FKListItem(
            id: "metadata-disabled",
            kind: .preset(.text(FKListTextRow(title: "Disabled via metadata", isEnabled: true, isSelectable: true))),
            metadata: FKListItemMetadata(isEnabled: false, isSelectable: false)
          ),
          FKListItem(id: "disabled", kind: .preset(.text(FKListTextRow(
            title: "Disabled row",
            isEnabled: false,
            isSelectable: false
          )))),
        ],
        header: .subtitle(title: "Account", subtitle: "Manage your identity"),
        footer: .title("Footer copy for the account section.")
      ),
      FKListSection(
        id: "preferences",
        items: [
          FKListItem(id: "wifi", kind: .preset(.switch(FKListSwitchRow(
            leading: .symbol(name: "wifi"),
            title: "Wi‑Fi",
            subtitle: "Auto-connect",
            isOn: wifiOn,
            handlerID: "wifi"
          )))),
          FKListItem(id: "notifications", kind: .preset(.switch(FKListSwitchRow(
            title: "Notifications",
            isOn: notificationsOn,
            handlerID: "notifications"
          )))),
          FKListItem(id: "terms", kind: .preset(.checkbox(FKListCheckboxRow(
            title: "Agree to terms",
            subtitle: "Tap row to toggle",
            isChecked: agreeTerms,
            handlerID: "terms"
          )))),
        ],
        header: .title("Preferences")
      ),
      FKListSection(
        id: "custom",
        items: [
          FKListItem.text(id: "custom-row", title: "Row under custom header"),
        ],
        header: .custom(viewProviderID: "custom-badge")
      ),
      FKListSection(
        id: "about",
        items: [
          FKListItem(id: "icon", kind: .preset(.icon(FKListIconRow(
            leading: .symbol(name: "star.fill"),
            title: "Icon preset row",
            subtitle: "All preset kinds in this demo"
          )))),
          FKListItem(id: "version", kind: .preset(.customValue(FKListValueRow(
            title: "Version",
            value: "1.0.0 (demo)"
          )))),
          FKListItem(id: "plain", kind: .preset(.text(FKListTextRow(title: "Plain text row")))),
          FKListItem(id: "subtitle", kind: .preset(.subtitle(FKListSubtitleRow(
            title: "Subtitle row",
            subtitle: "Secondary label"
          )))),
        ],
        header: .title("About")
      ),
    ])
  }
}
