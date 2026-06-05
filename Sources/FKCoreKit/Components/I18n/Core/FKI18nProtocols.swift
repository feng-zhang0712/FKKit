import Foundation

/// Notification user-info keys posted by ``FKI18nManager``.
public enum FKI18nNotificationKey {
  /// New language code after a successful switch.
  public static let languageCode = "FKI18nLanguageCode"

  /// Previous language code before the switch.
  public static let previousLanguageCode = "FKI18nPreviousLanguageCode"
}

/// In-app localization capabilities independent of the system locale.
public protocol FKI18nLocalizing: AnyObject, Sendable {
  /// Currently selected language descriptor.
  var currentLanguage: FKI18nLanguage { get }

  /// Currently selected BCP-47 language code.
  var currentLanguageCode: String { get }

  /// Foundation locale for the active in-app language.
  var currentLocale: Locale { get }

  /// Whether the active language uses right-to-left layout direction.
  var isRightToLeft: Bool { get }

  /// Locale-aware formatter factory bound to ``currentLocale``.
  var formatters: FKI18nFormatterProvider { get }

  /// Updates the active language and notifies observers when the code changes.
  ///
  /// - Parameter code: BCP-47 language code such as `en` or `zh-Hans`.
  func setLanguageCode(_ code: String)

  /// Resolves a localized string for `key`.
  ///
  /// - Parameters:
  ///   - key: Localization key.
  ///   - table: Optional strings table name. Pass `nil` for `Localizable.strings`.
  ///   - bundle: Optional override bundle. Pass `nil` to use the language-specific bundle.
  /// - Returns: Localized value or `key` fallback.
  func localized(_ key: String, table: String?, bundle: Bundle?) -> String

  /// Resolves a localized string for a typed key.
  ///
  /// - Parameters:
  ///   - key: Typed localization key.
  ///   - table: Optional strings table name.
  ///   - bundle: Optional override bundle.
  /// - Returns: Localized value or key fallback.
  func localized(_ key: FKI18nKey, table: String?, bundle: Bundle?) -> String

  /// Resolves a template and interpolates `{token}` placeholders.
  ///
  /// - Parameters:
  ///   - key: Localization key.
  ///   - table: Optional strings table name.
  ///   - variables: Placeholder map such as `["name": "Alex"]`.
  /// - Returns: Interpolated localized string.
  func localized(_ key: String, table: String?, variables: [String: String]) -> String

  /// Resolves a format string and applies `CVarArg` arguments using ``currentLocale``.
  ///
  /// - Parameters:
  ///   - key: Localization key whose value is a `String(format:)` template.
  ///   - table: Optional strings table name.
  ///   - arguments: Format arguments.
  /// - Returns: Formatted localized string.
  func localizedFormat(_ key: String, table: String?, arguments: [CVarArg]) -> String

  /// Resolves pluralized copy backed by `.stringsdict` rules when available.
  ///
  /// - Parameters:
  ///   - key: Plural rule key.
  ///   - count: Cardinal count passed to plural rules.
  ///   - table: Optional strings table name.
  /// - Returns: Locale-aware pluralized string.
  func localizedPlural(_ key: String, count: Int, table: String?) -> String

  /// Adds an observer invoked immediately with the current language and on every change.
  ///
  /// - Parameter handler: Callback invoked with the active ``FKI18nLanguage``.
  /// - Returns: Token used to cancel observation.
  @discardableResult
  func observeLanguageChange(_ handler: @escaping @Sendable (FKI18nLanguage) -> Void) -> FKI18nObservationToken
}

public extension FKI18nLocalizing {
  /// Resolves a localized string from the default `Localizable.strings` table.
  func localized(_ key: String) -> String {
    localized(key, table: nil, bundle: nil)
  }

  /// Resolves a localized string from an optional table.
  func localized(_ key: String, table: String?) -> String {
    localized(key, table: table, bundle: nil)
  }

  /// Resolves a typed key from the default table.
  func localized(_ key: FKI18nKey) -> String {
    localized(key, table: nil, bundle: nil)
  }

  /// Resolves a typed key from an optional table.
  func localized(_ key: FKI18nKey, table: String?) -> String {
    localized(key, table: table, bundle: nil)
  }

  /// Resolves and interpolates `{token}` placeholders using the default table.
  func localized(_ key: String, variables: [String: String]) -> String {
    localized(key, table: nil, variables: variables)
  }

  /// Resolves and formats using variadic arguments.
  func localizedFormat(_ key: String, table: String? = nil, _ arguments: CVarArg...) -> String {
    localizedFormat(key, table: table, arguments: arguments)
  }

  /// Resolves pluralized copy from the default table.
  func localizedPlural(_ key: String, count: Int) -> String {
    localizedPlural(key, count: count, table: nil)
  }
}

/// Pluggable dictionary backend for tests, previews, or remote copy providers.
public protocol FKI18nDictionaryTranslating: Sendable {
  /// Translates localized text for `key` in `languageCode`.
  ///
  /// - Parameters:
  ///   - key: Localization key.
  ///   - languageCode: Active BCP-47 language code.
  ///   - table: Optional logical table name for multi-table dictionaries.
  /// - Returns: Localized value or `nil` when missing.
  func translate(_ key: String, languageCode: String, table: String?) -> String?
}
