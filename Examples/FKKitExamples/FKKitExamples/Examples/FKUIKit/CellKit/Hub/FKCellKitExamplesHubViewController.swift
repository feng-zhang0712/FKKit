import FKUIKit
import UIKit

@MainActor
private func cellKitHubItem(
  _ title: String,
  _ subtitle: String,
  _ factory: @escaping @MainActor () -> UIViewController
) -> FKCellKitExampleHubItem {
  FKCellKitExampleHubItem(title: title, subtitle: subtitle, factory: factory)
}

/// Top-level CellKit examples hub grouped by domain.
final class FKCellKitExamplesHubViewController: FKCellKitExamplesListViewController {
  init() {
    super.init(title: "CellKit", sections: Self.sections)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static let sections: [FKCellKitExampleHubSection] = [
    FKCellKitExampleHubSection(title: "Getting Started", items: [
      cellKitHubItem(
        "Standalone Table",
        "Disclosure rows with S-01/S-02 section header and footer — no FKListKit.",
        { FKCellKitExampleStandaloneTableViewController() }
      ),
      cellKitHubItem(
        "ListKit Preset Mapping",
        "FKListPresetItem cases applied through FKListPresetCellConfigurator.",
        { FKCellKitExampleListPresetViewController() }
      ),
      cellKitHubItem(
        "Collection Parity",
        "UICollectionView list layout sharing Internal renderers with table cells.",
        { FKCellKitExampleCollectionParityViewController() }
      ),
    ]),
    FKCellKitExampleHubSection(title: "Composed Flows", items: [
      cellKitHubItem(
        "Settings Scenarios",
        "Design-doc settings flows #1–#9: General, About, AirDrop, Storage, Legal, …",
        { FKCellKitSettingsExamplesHubViewController() }
      ),
      cellKitHubItem(
        "Form Scenarios",
        "Login, profile, layout archetypes, enterprise inline, inline search (#10–#18).",
        { FKCellKitFormsExamplesHubViewController() }
      ),
      cellKitHubItem(
        "Feed & Commerce",
        "Inbox, checkout, FAQ, sort/filter (#19–#24).",
        { FKCellKitDisplayExamplesHubViewController() }
      ),
      cellKitHubItem(
        "Phase 6 Flows",
        "Wallet, playlist, tasks, extended fields, NPS survey (#22–#27).",
        { FKCellKitPhase6ExamplesHubViewController() }
      ),
    ]),
    FKCellKitExampleHubSection(title: "Full Coverage", items: [
      cellKitHubItem(
        "Cell Type Galleries",
        "Every FKCellReusable table cell, grouped by Settings / Display / Form.",
        { FKCellKitCellGalleriesHubViewController() }
      ),
      cellKitHubItem(
        "Stress Scroll",
        "200-row disclosure list for scroll performance spot checks.",
        { FKCellKitExampleStressScrollViewController() }
      ),
    ]),
  ]
}

/// Settings-style composed scenarios (#1–#9).
final class FKCellKitSettingsExamplesHubViewController: FKCellKitExamplesListViewController {
  init() {
    super.init(title: "CellKit — Settings", sections: [
      FKCellKitExampleHubSection(title: "Settings", items: [
        cellKitHubItem("General", "D-04, D-06 Hero, D-11, section chrome.", FKCellKitExampleScenarios.settingsGeneral),
        cellKitHubItem("About", "D-02, D-03, D-05, D-16 key-value and info rows.", FKCellKitExampleScenarios.settingsAbout),
        cellKitHubItem("Software Update", "D-07–D-09, app update and alert action.", FKCellKitExampleScenarios.settingsSoftwareUpdate),
        cellKitHubItem("AirDrop", "I-01 selection, I-03 switch, S-01/S-02 structure.", FKCellKitExampleScenarios.settingsAirDrop),
        cellKitHubItem("Language & Region", "I-04 language, I-06 reorder, D-10 picker.", FKCellKitExampleScenarios.settingsLanguageRegion),
        cellKitHubItem("AutoFill", "I-02 checkbox, I-05 picker, password autofill.", FKCellKitExampleScenarios.settingsAutoFill),
        cellKitHubItem("Storage", "D-13 segments, D-14 summary, recommendations.", FKCellKitExampleScenarios.settingsStorage),
        cellKitHubItem("Legal & Regulatory", "D-15 regulatory block, D-01 disclosure.", FKCellKitExampleScenarios.settingsLegal),
        cellKitHubItem("Transfer or Reset", "D-12 feature card, prepare flow.", FKCellKitExampleScenarios.settingsTransferReset),
      ]),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

/// Form layout and flow scenarios (#10–#18).
final class FKCellKitFormsExamplesHubViewController: FKCellKitExamplesListViewController {
  init() {
    super.init(title: "CellKit — Forms", sections: [
      FKCellKitExampleHubSection(title: "Flows", items: [
        cellKitHubItem("Login & Register", "F-01/02, agreement, primary button, social.", FKCellKitExampleScenarios.formLoginRegister),
        cellKitHubItem("Profile Edit", "Stacked fields, media picker, date.", FKCellKitExampleScenarios.formProfileEdit),
        cellKitHubItem("Contact & Social", "Phone, platform picker, website.", FKCellKitExampleScenarios.formContactSocial),
        cellKitHubItem("Enterprise Inline", "Inline label layout, picker, SMS code.", FKCellKitExampleScenarios.formEnterpriseInline),
        cellKitHubItem("Inline Search", "Search styles, filter chips, suggestions.", FKCellKitExampleScenarios.formInlineSearch),
      ]),
      FKCellKitExampleHubSection(title: "Layout Archetypes", items: [
        cellKitHubItem("Material Underline", "R-01 underline text, password, pickers.", FKCellKitExampleScenarios.formMaterialUnderline),
        cellKitHubItem("Card Stacked", "R-04 stacked card labels.", FKCellKitExampleScenarios.formCardStacked),
        cellKitHubItem("Card Inline", "R-02 inline card labels.", FKCellKitExampleScenarios.formCardInline),
      ]),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static func hub(
    _ title: String,
    _ subtitle: String,
    _ factory: @escaping @MainActor () -> UIViewController
  ) -> FKCellKitExampleHubItem {
    FKCellKitExampleHubItem(title: title, subtitle: subtitle, factory: factory)
  }
}

/// Feed, commerce, and list UI scenarios (#19–#24).
final class FKCellKitDisplayExamplesHubViewController: FKCellKitExamplesListViewController {
  init() {
    super.init(title: "CellKit — Display", sections: [
      FKCellKitExampleHubSection(title: "Lists", items: [
        cellKitHubItem("Messages Inbox", "D-20 conversation rows.", FKCellKitExampleScenarios.messagesInbox),
        cellKitHubItem("Commerce Checkout", "D-28 product, D-30 payment method.", FKCellKitExampleScenarios.commerceCheckout),
        cellKitHubItem("FAQ Expandable", "D-64 expandable FAQ rows.", FKCellKitExampleScenarios.faqExpandable),
        cellKitHubItem("Sort & Filter", "D-78 sort bar, D-55 filter summary.", FKCellKitExampleScenarios.listSortFilter),
      ]),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static func hub(
    _ title: String,
    _ subtitle: String,
    _ factory: @escaping @MainActor () -> UIViewController
  ) -> FKCellKitExampleHubItem {
    FKCellKitExampleHubItem(title: title, subtitle: subtitle, factory: factory)
  }
}

/// Phase 6 long-tail composed scenarios (#22–#27).
final class FKCellKitPhase6ExamplesHubViewController: FKCellKitExamplesListViewController {
  init() {
    super.init(title: "CellKit — Phase 6", sections: [
      FKCellKitExampleHubSection(title: "Mixed Flows", items: [
        cellKitHubItem("Wallet Transactions", "D-69 transactions, payment methods.", FKCellKitExampleScenarios.walletTransactions),
        cellKitHubItem("Media Playlist", "D-73 now playing, D-86 playable media.", FKCellKitExampleScenarios.mediaPlaylist),
        cellKitHubItem("Tasks & Checkbox", "D-70 tasks, I-08 slider, M-04 compose.", FKCellKitExampleScenarios.taskAndCheckbox),
        cellKitHubItem("Extended Form Fields", "F-14–F-20, X-54–X-56 advanced inputs.", FKCellKitExampleScenarios.formExtendedFields),
        cellKitHubItem("NPS Survey", "X-65 NPS scale, D-71 poll results.", FKCellKitExampleScenarios.surveyNPS),
      ]),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static func hub(
    _ title: String,
    _ subtitle: String,
    _ factory: @escaping @MainActor () -> UIViewController
  ) -> FKCellKitExampleHubItem {
    FKCellKitExampleHubItem(title: title, subtitle: subtitle, factory: factory)
  }
}

/// Per-domain cell type galleries for full API coverage.
final class FKCellKitCellGalleriesHubViewController: FKCellKitExamplesListViewController {
  init() {
    super.init(title: "CellKit — Galleries", sections: [
      FKCellKitExampleHubSection(title: "Table Cells", items: [
        cellKitHubItem(
          "Settings Controls",
          "I-01–I-15 inline controls: switch, checkbox, picker, slider, …",
          FKCellKitExampleGalleries.settingsControlsGallery
        ),
        cellKitHubItem(
          "General Display",
          "Feed, commerce, search, and list utility rows (D-17–D-88).",
          FKCellKitExampleGalleries.generalDisplayGallery
        ),
        cellKitHubItem(
          "Rich Display",
          "Hero cards, storage summary, regulatory blocks (D-06–D-15).",
          FKCellKitExampleGalleries.richDisplayGallery
        ),
        cellKitHubItem(
          "Long-Tail Display",
          "Phase 6 specialty rows: tasks, transactions, playlists, …",
          FKCellKitExampleGalleries.longTailDisplayGallery
        ),
        cellKitHubItem(
          "Form Cells",
          "All FKFormCell* field and action rows (X-01–X-72, F-01–F-20).",
          FKCellKitExampleGalleries.formCellsGallery
        ),
      ]),
      FKCellKitExampleHubSection(title: "Combined", items: [
        cellKitHubItem(
          "All Cell Types (Single Screen)",
          "Scroll through every table cell type in one long list.",
          FKCellKitExampleGalleries.allCellsGallery
        ),
      ]),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
