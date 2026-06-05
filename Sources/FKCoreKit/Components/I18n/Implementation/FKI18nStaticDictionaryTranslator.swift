import Foundation

/// Static dictionary translator used with ``FKI18nManager/setDictionaryTranslator(_:)``.
public struct FKI18nStaticDictionaryTranslator: FKI18nDictionaryTranslating, Sendable {
  /// Nested dictionary: languageCode -> table -> key -> value.
  public let dictionary: [String: [String: [String: String]]]

  /// Secondary language used when a key is missing.
  public let fallbackLanguageCode: String

  /// Creates a static dictionary translator.
  ///
  /// - Parameters:
  ///   - dictionary: Nested translation table keyed by language, table, and localization key.
  ///   - fallbackLanguageCode: Secondary language used when a key is missing.
  public init(
    dictionary: [String: [String: [String: String]]],
    fallbackLanguageCode: String
  ) {
    self.dictionary = dictionary
    self.fallbackLanguageCode = fallbackLanguageCode
  }

  /// Convenience initializer using the default table name.
  ///
  /// - Parameters:
  ///   - flatDictionary: Map of language code to key/value pairs in `Localizable`.
  ///   - fallbackLanguageCode: Secondary language used when a key is missing.
  public init(
    flatDictionary: [String: [String: String]],
    fallbackLanguageCode: String
  ) {
    self.dictionary = flatDictionary.mapValues { ["Localizable": $0] }
    self.fallbackLanguageCode = fallbackLanguageCode
  }

  /// Translates localized text for `key` in `languageCode`.
  public func translate(_ key: String, languageCode: String, table: String?) -> String? {
    let tableName = table ?? "Localizable"
    return dictionary[languageCode]?[tableName]?[key]
      ?? dictionary[fallbackLanguageCode]?[tableName]?[key]
  }
}
