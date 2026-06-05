import Foundation

// MARK: - Locale & keys

/// Supported locale identifiers for built-in EmptyState copy.
///
/// Inject your own ``FKEmptyStateTranslating`` for production; this enum scopes built-in tables.
public enum FKEmptyStateLocale: String, CaseIterable, Equatable, Sendable {
  case en
  case zhCN = "zh-CN"
  case ja
  case es
  case ar
}

/// Typed i18n key (avoids accidental free-form string drift in large codebases).
///
/// Built-in keys follow `empty.<segment>.title|description` and `empty.action.<name>`.
public struct FKEmptyStateI18nKey: Hashable, Sendable {
  public var rawValue: String
  public init(_ rawValue: String) { self.rawValue = rawValue }
}

// MARK: - Translation

/// Pluggable translation backend (dictionary, remote CMS, feature-flag copy, etc.).
public protocol FKEmptyStateTranslating: Sendable {
  func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String
}

public struct FKEmptyStateDictionaryTranslator: FKEmptyStateTranslating {
  public typealias Dictionary = [FKEmptyStateLocale: [FKEmptyStateI18nKey: String]]

  public var dictionary: Dictionary
  public var fallbackLocale: FKEmptyStateLocale

  public init(dictionary: Dictionary, fallbackLocale: FKEmptyStateLocale = .en) {
    self.dictionary = dictionary
    self.fallbackLocale = fallbackLocale
  }

  public func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String {
    let template =
      dictionary[locale]?[key]
      ?? dictionary[fallbackLocale]?[key]
      ?? key.rawValue
    return FKEmptyStateMessageFormat.interpolate(template: template, variables: variables)
  }
}

// MARK: - Placeholders

public enum FKEmptyStateMessageFormat {
  /// Replaces `{token}` placeholders with `variables` values. Unknown `{tokens}` are left unchanged.
  ///
  /// No ICU plural rules—wrap advanced formatting behind ``FKEmptyStateTranslating``.
  public static func interpolate(template: String, variables: [String: String]) -> String {
    guard template.contains("{"), !variables.isEmpty else { return template }
    var result = template
    for (k, v) in variables {
      result = result.replacingOccurrences(of: "{\(k)}", with: v)
    }
    return result
  }
}

// MARK: - Built-in dictionary

public enum FKEmptyStateBuiltInMessages {
  public static let `default` = FKEmptyStateBundleTranslator()
}
