import FKCoreKit
import UIKit

/// Bootstrap and helpers for FKI18n demo scenarios.
enum FKI18nExampleSupport {
  /// Strings table for demo keys in `Resources/Localization/Localizable.strings`.
  static let demoTable: String? = nil

  /// UserDefaults key for persisted in-app language selection in the examples app.
  static let storageKey = "com.fkkit.examples.i18n.demo.language"

  /// Supported languages — mirrors ``FKI18nRecommendedLanguages/languageCodes``.
  static var supportedLanguageCodes: [String] {
    FKI18nRecommendedLanguages.languageCodes
  }

  /// Configures ``FKI18nManager/shared`` for FKI18n demos.
  static func configureAtLaunch() {
    UserDefaults.standard.removeObject(forKey: FKI18nConfiguration().storageKey)

    FKI18nManager.shared.configure(
      FKI18nConfiguration(
        defaultLanguageCode: FKI18nRecommendedLanguages.english,
        supportedLanguageCodes: supportedLanguageCodes,
        fallbackLanguageCodes: [FKI18nRecommendedLanguages.english],
        bundle: localizationBundle,
        persistSelection: false,
        storageKey: storageKey,
        enforceSupportedLanguages: true
      )
    )
    syncWithDeviceLanguage()
  }

  /// Aligns the shared manager with `Locale.preferredLanguages` (simulator / device Settings).
  static func syncWithDeviceLanguage() {
    let preferredLanguageCodes = FKI18nLocaleMatcher.uniqueLanguageCodes(
      Locale.preferredLanguages + Bundle.main.preferredLocalizations
    )
    let code = FKI18nLocaleMatcher.bestSupportedLanguage(
      preferredLanguageCodes: preferredLanguageCodes,
      supportedLanguageCodes: supportedLanguageCodes,
      fallback: FKI18nRecommendedLanguages.english
    )
    FKI18nManager.shared.setLanguageCode(code)
  }

  /// Container bundle hosting demo `.lproj` directories (copied to the app bundle root by Xcode).
  static var localizationBundle: Bundle {
    .main
  }

  /// Resolves a demo string from ``demoTable``.
  static func localized(_ key: String) -> String {
    FKI18nManager.shared.localized(key, table: demoTable)
  }

  /// Resolves a demo string with `{token}` interpolation.
  static func localized(_ key: String, variables: [String: String]) -> String {
    FKI18nManager.shared.localized(key, table: demoTable, variables: variables)
  }

  /// Presents a language picker for all recommended languages.
  static func presentLanguagePicker(
    from viewController: UIViewController,
    sourceView: UIView? = nil,
    barButtonItem: UIBarButtonItem? = nil,
    onSelect: (() -> Void)? = nil
  ) {
    let alert = UIAlertController(
      title: localized("i18n.demo.picker.title"),
      message: nil,
      preferredStyle: .actionSheet
    )

    for code in supportedLanguageCodes {
      let language = FKI18nLanguage(code: code)
      let rtlSuffix = FKI18nRecommendedLanguages.isRightToLeft(code: code) ? " · RTL" : ""
      let isSelected = FKI18nManager.shared.currentLanguageCode == code
      let title = isSelected ? "✓ \(language.displayName())\(rtlSuffix)" : "\(language.displayName())\(rtlSuffix)"
      alert.addAction(UIAlertAction(title: title, style: .default) { _ in
        FKI18nManager.shared.setLanguageCode(code)
        onSelect?()
      })
    }

    alert.addAction(UIAlertAction(title: localized("i18n.demo.picker.cancel"), style: .cancel))
    if let popover = alert.popoverPresentationController {
      if let barButtonItem {
        popover.barButtonItem = barButtonItem
      } else if let sourceView {
        popover.sourceView = sourceView
        popover.sourceRect = CGRect(
          x: sourceView.bounds.midX,
          y: sourceView.bounds.maxY - 1,
          width: 1,
          height: 1
        )
      }
    }
    viewController.present(alert, animated: true)
  }

  /// Registers a language-change observer that refreshes navigation chrome and optional content.
  @discardableResult
  static func observeLanguageChange(
    on viewController: UIViewController,
    titleKey: String? = nil,
    reload: (@MainActor @Sendable () -> Void)? = nil
  ) -> FKI18nObservationToken {
    if let titleKey {
      viewController.title = localized(titleKey)
    }
    return FKI18nManager.shared.observeLanguageChange { _ in
      Task { @MainActor in
        if let titleKey {
          viewController.title = localized(titleKey)
        }
        reload?()
      }
    }
  }
}
