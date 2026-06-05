import Foundation

/// Resolves localized strings from the FKCoreKit resource bundle via ``FKI18nManager``.
public enum FKI18n {
  /// Shared localization provider.
  nonisolated(unsafe) public static var provider: FKI18nLocalizing = FKI18nManager.shared

  /// Resolves a localized string for `key` from the FKCoreKit bundle.
  ///
  /// - Parameters:
  ///   - key: Localization key in `Localizable.strings`.
  ///   - table: Optional strings table name.
  /// - Returns: Localized value or `key` fallback.
  public static func string(_ key: String, table: String? = nil) -> String {
    let bundle = FKCoreKitResourceBundle.localizedBundle(for: provider.currentLanguageCode)
    return provider.localized(key, table: table, bundle: bundle)
  }

  /// Resolves a typed localization key from the FKCoreKit bundle.
  public static func string(_ key: FKI18nKey, table: String? = nil) -> String {
    string(key.rawValue, table: table)
  }

  /// Resolves a format template and applies `CVarArg` arguments using the active locale.
  public static func format(_ key: String, table: String? = nil, _ arguments: CVarArg...) -> String {
    let template = string(key, table: table)
    guard !arguments.isEmpty else { return template }
    return String(format: template, locale: provider.currentLocale, arguments: arguments)
  }

  /// Resolves a template and interpolates `{token}` placeholders.
  public static func string(_ key: String, variables: [String: String], table: String? = nil) -> String {
    let template = string(key, table: table)
    return FKI18nMessageFormat.interpolate(template: template, variables: variables)
  }
}
