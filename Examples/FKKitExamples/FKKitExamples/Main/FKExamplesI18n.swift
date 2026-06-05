import FKCoreKit
import Foundation

/// Resolves localized copy for the FKKitExamples app from `Resources/Localization`.
enum FKExamplesI18n {
  /// Shared localization provider configured at launch.
  nonisolated(unsafe) static var provider: FKI18nLocalizing = FKI18nManager.shared

  /// Resolves a localized string from the app bundle.
  public static func string(_ key: String, table: String? = nil) -> String {
    provider.localized(key, table: table, bundle: .main)
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
