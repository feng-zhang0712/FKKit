import FKCoreKit
import UIKit

/// Demonstrates FKLocalizing and FKBusinessI18nManager integration paths.
final class FKI18nIntegrationExampleViewController: FKI18nExampleBaseViewController {

  private let localizingLabel = UILabel()
  private let businessLabel = UILabel()
  private let businessManager: FKBusinessI18nManager = {
    let manager = FKBusinessI18nManager(
      defaultLanguageCode: FKI18nRecommendedLanguages.english,
      storageKey: "com.fkkit.examples.business.i18n"
    )
    manager.coreManager.configure(
      FKI18nConfiguration(
        defaultLanguageCode: FKI18nRecommendedLanguages.english,
        supportedLanguageCodes: FKI18nRecommendedLanguages.languageCodes,
        fallbackLanguageCodes: [FKI18nRecommendedLanguages.english],
        bundle: FKI18nExampleSupport.localizationBundle,
        persistSelection: false,
        storageKey: "com.fkkit.examples.business.i18n",
        enforceSupportedLanguages: true
      )
    )
    return manager
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Integration"

    localizingLabel.font = .preferredFont(forTextStyle: .body)
    localizingLabel.numberOfLines = 0
    businessLabel.font = .preferredFont(forTextStyle: .body)
    businessLabel.numberOfLines = 0

    let labels = UIStackView(arrangedSubviews: [localizingLabel, businessLabel])
    labels.axis = .vertical
    labels.spacing = 8
    stackView.insertArrangedSubview(labels, at: 0)

    addInfoLabel("FKI18nManager conforms to FKLocalizing. FKBusinessI18nManager wraps a dedicated FKI18nManager for BusinessKit.")
    addLanguagePickerButton()
    addActionButton("Resolve via FKLocalizing") { [weak self] in
      self?.logLocalizing()
    }
    addActionButton("Resolve via BusinessKit") { [weak self] in
      self?.logBusinessKit()
    }
    addActionButton("Clear Log") { [weak self] in
      self?.clearOutput()
    }

    _ = businessManager.observeLanguageChange { [weak self] code in
      Task { @MainActor in
        self?.appendOutput("business token → \(code)")
      }
    }

    refreshLocalizedContent()
    logLocalizing()
    logBusinessKit()
  }

  override func refreshLocalizedContent() {
    businessManager.setLanguageCode(FKI18nManager.shared.currentLanguageCode)
    let localizing: FKLocalizing = FKI18nManager.shared
    localizingLabel.text = localizing.localized("i18n.demo.integration.localizing", table: FKI18nExampleSupport.demoTable)
    businessLabel.text = businessManager.localized("i18n.demo.integration.business", table: FKI18nExampleSupport.demoTable)
  }

  private func logLocalizing() {
    let localizing: FKLocalizing = FKI18nManager.shared
    appendOutput("FKLocalizing code=\(localizing.currentLanguageCode)")
    appendOutput(localizing.localized("i18n.demo.integration.localizing", table: FKI18nExampleSupport.demoTable))
  }

  private func logBusinessKit() {
    appendOutput("BusinessKit code=\(businessManager.currentLanguageCode)")
    appendOutput(businessManager.localized("i18n.demo.integration.business", table: FKI18nExampleSupport.demoTable))
  }
}
