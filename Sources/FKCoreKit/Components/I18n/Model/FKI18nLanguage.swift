import Foundation

/// Describes one selectable in-app language.
public struct FKI18nLanguage: Equatable, Sendable, Codable, Hashable {
  /// BCP-47 language code such as `en`, `zh-Hans`, or `pt-BR`.
  public let code: String

  /// Optional user-facing display name. When `nil`, ``displayName(using:)`` derives one from ``code``.
  public let displayNameOverride: String?

  /// Creates a language descriptor.
  ///
  /// - Parameters:
  ///   - code: BCP-47 language code.
  ///   - displayNameOverride: Optional fixed display label shown in language pickers.
  public init(code: String, displayNameOverride: String? = nil) {
    self.code = code
    self.displayNameOverride = displayNameOverride
  }

  /// Foundation locale derived from ``code``.
  public var locale: Locale {
    Locale(identifier: code)
  }

  /// Resolves a user-facing label for language pickers.
  ///
  /// - Parameter locale: Locale used to localize the display name. Defaults to the language itself.
  /// - Returns: Human-readable language name.
  public func displayName(using locale: Locale? = nil) -> String {
    if let displayNameOverride, !displayNameOverride.isEmpty {
      return displayNameOverride
    }
    let targetLocale = locale ?? self.locale
    return targetLocale.localizedString(forLanguageCode: code) ?? code
  }
}
