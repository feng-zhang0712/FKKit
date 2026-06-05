import Foundation

/// BusinessKit adapter over ``FKI18nManager`` that conforms to ``FKBusinessLocalizing``.
public final class FKBusinessI18nManager: FKBusinessLocalizing, @unchecked Sendable {
  /// Posted after the active language changes. Mirrors ``FKI18nManager/languageDidChangeNotification``.
  public static let languageDidChangeNotification = FKI18nManager.languageDidChangeNotification

  private let manager: FKI18nManager

  /// Creates a manager backed by ``FKI18nManager``.
  ///
  /// - Parameters:
  ///   - defaultLanguageCode: Fallback language code when no user selection exists.
  ///   - userDefaults: Storage for selected language.
  ///   - storageKey: Key used to persist language code.
  public init(
    defaultLanguageCode: String,
    userDefaults: UserDefaults = .standard,
    storageKey: String = "com.fkkit.business.i18n.language"
  ) {
    var configuration = FKI18nConfiguration(
      defaultLanguageCode: defaultLanguageCode,
      supportedLanguageCodes: [defaultLanguageCode],
      fallbackLanguageCodes: [],
      bundle: .main,
      persistSelection: true,
      storageKey: storageKey,
      enforceSupportedLanguages: false
    )
    manager = FKI18nManager(configuration: configuration, userDefaults: userDefaults)
  }

  /// Underlying localization manager for advanced APIs (formatters, plural rules, bundle overrides).
  public var coreManager: FKI18nManager { manager }

  /// Current selected language code.
  public var currentLanguageCode: String {
    manager.currentLanguageCode
  }

  /// Updates current language and notifies all observers.
  public func setLanguageCode(_ code: String) {
    manager.setLanguageCode(code)
  }

  /// Resolves localized text from the active language bundle.
  public func localized(_ key: String, table: String? = nil) -> String {
    manager.localized(key, table: table)
  }

  /// Adds language change observer and emits current language immediately.
  @discardableResult
  public func observeLanguageChange(_ handler: @escaping @Sendable (String) -> Void) -> FKBusinessObservationToken {
    let token = manager.observeLanguageChange { language in
      handler(language.code)
    }
    return FKBusinessObservationToken {
      token.invalidate()
    }
  }
}
