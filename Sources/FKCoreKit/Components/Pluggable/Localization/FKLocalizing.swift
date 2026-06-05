import Foundation

/// In-app localization boundary independent of `NSLocalizedString` call sites.
///
/// Production implementations may read `Bundle`, custom tables, or downloaded string packs.
public protocol FKLocalizing: AnyObject, Sendable {
  /// BCP-47 style language code (for example `en`, `zh-Hans`).
  var currentLanguageCode: String { get }

  /// Switches active language and notifies observers.
  func setLanguageCode(_ code: String)

  /// Resolves a localized string.
  ///
  /// - Parameters:
  ///   - key: Localization key.
  ///   - table: Optional `.strings` table name. Pass `nil` for `Localizable`.
  /// - Returns: Localized value or `key` as fallback.
  func localized(_ key: String, table: String?) -> String

  /// Observes language changes for UI refresh.
  @discardableResult
  func observeLanguageChange(
    _ handler: @escaping @Sendable (String) -> Void
  ) -> FKPluggableObservationToken
}

/// Typed translation with placeholder interpolation (CMS, experiments, empty states).
public protocol FKTranslating: Sendable {
  associatedtype Key: Hashable & Sendable

  /// Translates `key` for `locale`, substituting `variables` into the template.
  func translate(
    _ key: Key,
    locale: String,
    variables: [String: String]
  ) -> String
}
