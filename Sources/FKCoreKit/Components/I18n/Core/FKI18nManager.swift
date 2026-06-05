import Foundation

/// Main in-app localization manager for FKCoreKit.
///
/// `FKI18nManager` resolves strings from language-specific bundles, persists user language
/// selection, and broadcasts changes to observers and `NotificationCenter`.
public final class FKI18nManager: FKI18nLocalizing, @unchecked Sendable {
  /// Shared singleton for app-wide localization.
  public static let shared = FKI18nManager()

  /// Posted after the active language changes successfully.
  ///
  /// User info contains ``FKI18nNotificationKey/languageCode`` and
  /// ``FKI18nNotificationKey/previousLanguageCode``.
  public static let languageDidChangeNotification = Notification.Name("com.fkkit.i18n.languageDidChange")

  /// Lock protecting mutable configuration, language state, caches, and observers.
  private let lock = NSLock()

  /// Active runtime configuration.
  private var configuration: FKI18nConfiguration

  /// Current selected language code.
  private var languageCode: String

  /// Cached language bundles keyed by normalized language code.
  private var bundleCache: [String: Bundle] = [:]

  /// Registered language change observers.
  private var observers: [UUID: @Sendable (FKI18nLanguage) -> Void] = [:]

  /// Optional dictionary backend used before bundle lookup.
  private var dictionaryTranslator: FKI18nDictionaryTranslating?

  /// Storage backend for persisted language code.
  private let userDefaults: UserDefaults

  /// Creates a manager with explicit configuration.
  ///
  /// - Parameters:
  ///   - configuration: Initial runtime configuration.
  ///   - userDefaults: Persistence backend for selected language code.
  public init(
    configuration: FKI18nConfiguration = FKI18nSettings.defaultConfiguration,
    userDefaults: UserDefaults = .standard
  ) {
    self.configuration = configuration
    self.userDefaults = userDefaults
    self.languageCode = Self.resolveInitialLanguageCode(
      using: configuration,
      userDefaults: userDefaults
    )
  }

  /// Replaces runtime configuration and clears bundle caches.
  ///
  /// Re-applies persisted or system-preferred language using the new ``FKI18nConfiguration/storageKey``.
  ///
  /// - Parameter configuration: New configuration values.
  public func configure(_ configuration: FKI18nConfiguration) {
    let resolved = Self.resolveInitialLanguageCode(
      using: configuration,
      userDefaults: userDefaults
    )
    lock.lock()
    self.configuration = configuration
    bundleCache.removeAll()
    lock.unlock()
    setLanguageCode(resolved)
  }

  /// Installs an optional dictionary backend consulted before bundle lookup.
  ///
  /// - Parameter translator: Dictionary or remote translation provider.
  public func setDictionaryTranslator(_ translator: FKI18nDictionaryTranslating?) {
    lock.lock()
    dictionaryTranslator = translator
    lock.unlock()
  }

  /// Supported languages derived from ``FKI18nConfiguration/supportedLanguageCodes``.
  public var supportedLanguages: [FKI18nLanguage] {
    lock.lock()
    let codes = configuration.supportedLanguageCodes
    lock.unlock()
    return codes.map { FKI18nLanguage(code: $0) }
  }

  /// Currently selected language descriptor.
  public var currentLanguage: FKI18nLanguage {
    FKI18nLanguage(code: currentLanguageCode)
  }

  /// Currently selected BCP-47 language code.
  public var currentLanguageCode: String {
    lock.lock()
    let value = languageCode
    lock.unlock()
    return value
  }

  /// Foundation locale for the active in-app language.
  public var currentLocale: Locale {
    Locale(identifier: currentLanguageCode)
  }

  /// Whether the active language uses right-to-left layout direction.
  public var isRightToLeft: Bool {
    NSLocale.characterDirection(forLanguage: currentLanguageCode) == .rightToLeft
  }

  /// Locale-aware formatter factory bound to ``currentLocale``.
  public var formatters: FKI18nFormatterProvider {
    FKI18nFormatterProvider(locale: currentLocale)
  }

  /// Updates the active language and notifies observers when the code changes.
  public func setLanguageCode(_ code: String) {
    let normalized = code
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "_", with: "-")
    let canonical = FKI18nLocaleMatcher.canonicalize(normalized)

    lock.lock()

    guard !canonical.isEmpty, languageCode != canonical else {
      lock.unlock()
      return
    }

    if configuration.enforceSupportedLanguages,
       !configuration.supportedLanguageCodes.isEmpty,
       !configuration.supportedLanguageCodes.contains(canonical) {
      lock.unlock()
      return
    }

    let previous = languageCode
    languageCode = canonical

    if configuration.persistSelection {
      userDefaults.set(canonical, forKey: configuration.storageKey)
    }

    bundleCache.removeAll()
    let handlers = observers.values
    lock.unlock()

    let language = FKI18nLanguage(code: canonical)
    NotificationCenter.default.post(
      name: Self.languageDidChangeNotification,
      object: self,
      userInfo: [
        FKI18nNotificationKey.languageCode: canonical,
        FKI18nNotificationKey.previousLanguageCode: previous,
      ]
    )
    handlers.forEach { $0(language) }
  }

  /// Resets language selection to ``FKI18nConfiguration/defaultLanguageCode`` and clears persistence.
  public func resetLanguageSelection() {
    lock.lock()
    userDefaults.removeObject(forKey: configuration.storageKey)
    let defaultCode = configuration.defaultLanguageCode
    lock.unlock()
    setLanguageCode(defaultCode)
  }

  /// Resolves a localized string for `key`.
  public func localized(_ key: String, table: String?, bundle: Bundle?) -> String {
    if let dictionaryValue = dictionaryValue(for: key, table: table) {
      return dictionaryValue
    }

    let resolvedBundle = bundle ?? resolvedBundle(for: currentLanguageCode)
    let value = resolvedBundle.localizedString(forKey: key, value: nil, table: table)
    if value != key {
      return value
    }

    return fallbackLocalizedValue(for: key, table: table, excluding: resolvedBundle)
  }

  /// Resolves a localized string for a typed key.
  public func localized(_ key: FKI18nKey, table: String?, bundle: Bundle?) -> String {
    localized(key.rawValue, table: table, bundle: bundle)
  }

  /// Resolves a template and interpolates `{token}` placeholders.
  public func localized(_ key: String, table: String?, variables: [String: String]) -> String {
    let template = localized(key, table: table, bundle: nil)
    return FKI18nMessageFormat.interpolate(template: template, variables: variables)
  }

  /// Resolves a format string and applies format arguments.
  public func localizedFormat(_ key: String, table: String?, arguments: [CVarArg]) -> String {
    let format = localized(key, table: table, bundle: nil)
    return FKI18nMessageFormat.format(format, locale: currentLocale, arguments: arguments)
  }

  /// Resolves pluralized copy backed by `.stringsdict` rules when available.
  public func localizedPlural(_ key: String, count: Int, table: String?) -> String {
    let format = localized(key, table: table, bundle: nil)
    return FKI18nMessageFormat.plural(format: format, locale: currentLocale, count: count)
  }

  /// Adds a language change observer.
  @discardableResult
  public func observeLanguageChange(_ handler: @escaping @Sendable (FKI18nLanguage) -> Void) -> FKI18nObservationToken {
    let id = UUID()
    lock.lock()
    observers[id] = handler
    let current = FKI18nLanguage(code: languageCode)
    lock.unlock()

    handler(current)

    return FKI18nObservationToken { [weak self] in
      guard let self else { return }
      self.lock.lock()
      self.observers[id] = nil
      self.lock.unlock()
    }
  }

  /// Resolves the best bundle for `languageCode`, using an internal cache.
  private func resolvedBundle(for languageCode: String) -> Bundle {
    lock.lock()
    if let cached = bundleCache[languageCode] {
      lock.unlock()
      return cached
    }

    let config = configuration
    lock.unlock()

    let bundle = FKI18nBundleResolver.bundle(
      for: languageCode,
      in: config.bundle,
      fallbackLanguageCodes: config.fallbackLanguageCodes + [config.defaultLanguageCode]
    )

    lock.lock()
    bundleCache[languageCode] = bundle
    lock.unlock()
    return bundle
  }

  /// Attempts dictionary lookup before bundle resolution.
  private func dictionaryValue(for key: String, table: String?) -> String? {
    lock.lock()
    let translator = dictionaryTranslator
    let code = languageCode
    lock.unlock()

    guard let translator else { return nil }
    return translator.translate(key, languageCode: code, table: table)
  }

  /// Falls back through locale candidates when the primary bundle returns the key unchanged.
  private func fallbackLocalizedValue(for key: String, table: String?, excluding excludedBundle: Bundle) -> String {
    lock.lock()
    let config = configuration
    let code = languageCode
    lock.unlock()

    let candidates = FKI18nLocaleMatcher.fallbackCandidates(
      for: code,
      additionalFallbacks: config.fallbackLanguageCodes + [config.defaultLanguageCode]
    )

    for candidate in candidates {
      let bundle = resolvedBundle(for: candidate)
      guard bundle != excludedBundle else { continue }
      let value = bundle.localizedString(forKey: key, value: nil, table: table)
      if value != key {
        return value
      }
    }

    return key
  }

  /// Resolves launch language: persisted in-app selection, then device preferred locales.
  private static func resolveInitialLanguageCode(
    using configuration: FKI18nConfiguration,
    userDefaults: UserDefaults
  ) -> String {
    if configuration.persistSelection,
       let stored = userDefaults.string(forKey: configuration.storageKey),
       !stored.isEmpty {
      let canonical = FKI18nLocaleMatcher.canonicalize(stored)
      if !configuration.enforceSupportedLanguages
        || configuration.supportedLanguageCodes.isEmpty
        || configuration.supportedLanguageCodes.contains(canonical) {
        return canonical
      }
    }

    let preferredLanguageCodes = FKI18nLocaleMatcher.uniqueLanguageCodes(
      Locale.preferredLanguages + configuration.bundle.preferredLocalizations
    )

    return FKI18nLocaleMatcher.bestSupportedLanguage(
      preferredLanguageCodes: preferredLanguageCodes,
      supportedLanguageCodes: configuration.supportedLanguageCodes,
      fallback: configuration.defaultLanguageCode
    )
  }
}
