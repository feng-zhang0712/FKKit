import Foundation

/// Recommended BCP-47 language codes for FKKit products and demo apps.
///
/// The list prioritizes global App Store reach, aligns with built-in
/// ``FKEmptyStateLocale`` coverage (`en`, `zh-CN` → `zh-Hans`, `ja`, `es`, `ar`),
/// and adds other high-traffic locales. Trim or extend for your market.
public enum FKI18nRecommendedLanguages {
  /// English — base language and ultimate fallback.
  public static let english = "en"

  /// Simplified Chinese. Maps to EmptyState ``FKEmptyStateLocale/zhCN`` (`zh-CN`).
  public static let simplifiedChinese = "zh-Hans"

  /// Traditional Chinese (Taiwan, Hong Kong, Macau).
  public static let traditionalChinese = "zh-Hant"

  /// Japanese.
  public static let japanese = "ja"

  /// Korean.
  public static let korean = "ko"

  /// Spanish.
  public static let spanish = "es"

  /// French.
  public static let french = "fr"

  /// German.
  public static let german = "de"

  /// Portuguese (Brazil).
  public static let portugueseBrazil = "pt-BR"

  /// Arabic — primary RTL locale for layout validation.
  public static let arabic = "ar"

  /// Russian.
  public static let russian = "ru"

  /// Ordered recommended language codes for in-app pickers and demo coverage.
  public static let languageCodes: [String] = [
    english,
    simplifiedChinese,
    traditionalChinese,
    japanese,
    korean,
    spanish,
    french,
    german,
    portugueseBrazil,
    arabic,
    russian,
  ]

  /// Recommended languages as ``FKI18nLanguage`` values.
  public static let languages: [FKI18nLanguage] = languageCodes.map { FKI18nLanguage(code: $0) }

  /// Whether `code` uses right-to-left layout in the recommended set.
  public static func isRightToLeft(code: String) -> Bool {
    code == arabic
  }
}
