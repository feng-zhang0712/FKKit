import Foundation

/// Localizes built-in ``FKEmptyStateI18nKey`` values via ``FKUIKitI18n``.
public struct FKEmptyStateBundleTranslator: FKEmptyStateTranslating {
  public init() {}

  public func translate(
    _ key: FKEmptyStateI18nKey,
    locale: FKEmptyStateLocale,
    variables: [String: String]
  ) -> String {
    _ = locale
    return FKUIKitI18n.string("fkuikit.\(key.rawValue)", variables: variables)
  }
}
