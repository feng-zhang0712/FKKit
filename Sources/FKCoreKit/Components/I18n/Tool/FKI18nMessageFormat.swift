import Foundation

/// String interpolation and formatting helpers for localization templates.
public enum FKI18nMessageFormat {
  /// Replaces `{token}` placeholders with `variables` values. Unknown tokens remain unchanged.
  ///
  /// - Parameters:
  ///   - template: Localized template containing `{name}` placeholders.
  ///   - variables: Replacement map keyed by token name without braces.
  /// - Returns: Interpolated string.
  public static func interpolate(template: String, variables: [String: String]) -> String {
    guard template.contains("{"), !variables.isEmpty else { return template }

    var result = template
    for (key, value) in variables {
      result = result.replacingOccurrences(of: "{\(key)}", with: value)
    }
    return result
  }

  /// Applies `String(format:)` using an explicit locale.
  ///
  /// Floating-point values are boxed as ``NSNumber`` so `%@` specifiers receive Foundation objects.
  /// Integer types are passed through for `%d` / `%ld` templates.
  ///
  /// - Parameters:
  ///   - format: Format template stored in strings files.
  ///   - locale: Locale used for formatting.
  ///   - arguments: Format arguments.
  /// - Returns: Formatted string.
  public static func format(_ format: String, locale: Locale, arguments: [CVarArg]) -> String {
    guard !arguments.isEmpty else { return format }
    let normalized = normalizedFormatArguments(arguments)
    return withVaList(normalized) { pointer in
      NSString(format: format, locale: locale, arguments: pointer) as String
    }
  }

  /// Applies plural `.stringsdict` formatting when the template expects a count argument.
  ///
  /// - Parameters:
  ///   - format: Plural rule format string.
  ///   - locale: Locale used for pluralization.
  ///   - count: Cardinal count.
  /// - Returns: Pluralized string.
  public static func plural(format: String, locale: Locale, count: Int) -> String {
    String(format: format, locale: locale, count)
  }

  /// Normalizes common Swift bridged values for `NSString` format templates.
  private static func normalizedFormatArguments(_ arguments: [CVarArg]) -> [CVarArg] {
    arguments.map { value in
      switch value {
      case let number as NSNumber:
        return number
      case let string as String:
        return string as NSString
      case let double as Double:
        return NSNumber(value: double)
      case let float as Float:
        return NSNumber(value: float)
      case let bool as Bool:
        return NSNumber(value: bool)
      default:
        return value
      }
    }
  }
}
