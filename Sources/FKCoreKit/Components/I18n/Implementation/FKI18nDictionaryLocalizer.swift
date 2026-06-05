import Foundation

/// Dictionary-backed localization provider for tests, previews, and remote copy tables.
public final class FKI18nDictionaryLocalizer: FKI18nLocalizing, @unchecked Sendable {
  /// Lock protecting mutable language state and observer list.
  private let lock = NSLock()

  /// Fallback language code used when a translation is missing.
  private let fallbackLanguageCode: String

  /// Current selected language code.
  private var languageCode: String

  /// Nested dictionary: languageCode -> table -> key -> value.
  private let dictionary: [String: [String: [String: String]]]

  /// Registered language change observers.
  private var observers: [UUID: @Sendable (FKI18nLanguage) -> Void] = [:]

  /// Creates a dictionary localizer.
  ///
  /// - Parameters:
  ///   - dictionary: Nested translation table keyed by language, table, and localization key.
  ///   - initialLanguageCode: Starting language code.
  ///   - fallbackLanguageCode: Secondary language used when a key is missing.
  public init(
    dictionary: [String: [String: [String: String]]],
    initialLanguageCode: String,
    fallbackLanguageCode: String
  ) {
    self.dictionary = dictionary
    self.languageCode = initialLanguageCode
    self.fallbackLanguageCode = fallbackLanguageCode
  }

  /// Convenience initializer using the default table name.
  ///
  /// - Parameters:
  ///   - flatDictionary: Map of language code to key/value pairs in `Localizable`.
  ///   - initialLanguageCode: Starting language code.
  ///   - fallbackLanguageCode: Secondary language used when a key is missing.
  public convenience init(
    flatDictionary: [String: [String: String]],
    initialLanguageCode: String,
    fallbackLanguageCode: String
  ) {
    let nested = flatDictionary.mapValues { ["Localizable": $0] }
    self.init(
      dictionary: nested,
      initialLanguageCode: initialLanguageCode,
      fallbackLanguageCode: fallbackLanguageCode
    )
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
    lock.lock()
    guard languageCode != code, !code.isEmpty else {
      lock.unlock()
      return
    }
    languageCode = code
    let handlers = observers.values
    lock.unlock()

    let language = FKI18nLanguage(code: code)
    handlers.forEach { $0(language) }
  }

  /// Resolves a localized string for `key`.
  public func localized(_ key: String, table: String?, bundle: Bundle?) -> String {
    _ = bundle
    let tableName = table ?? "Localizable"
    let code = currentLanguageCode
    let value =
      dictionary[code]?[tableName]?[key]
      ?? dictionary[fallbackLanguageCode]?[tableName]?[key]
    return value ?? key
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

  /// Resolves pluralized copy using format templates stored in the dictionary.
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
}
