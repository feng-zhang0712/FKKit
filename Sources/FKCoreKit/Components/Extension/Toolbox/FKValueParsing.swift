import Foundation

/// Loose-typed value parsing helpers for JSON payloads and dynamic dictionaries.
public enum FKValueParsing {
  /// Returns whether `value` is `nil` or empty-like (`String`, collection, or `NSNull`).
  public static func isNilOrEmpty(_ value: Any?) -> Bool {
    switch value {
    case nil:
      return true
    case let text as String:
      return text.fk_isBlank
    case let array as any Collection:
      return array.isEmpty
    case _ as NSNull:
      return true
    default:
      return false
    }
  }

  /// Safely converts `value` to `String`.
  public static func string(from value: Any?) -> String? {
    guard let value else { return nil }
    if let string = value as? String { return string }
    if let number = value as? NSNumber { return number.stringValue }
    return "\(value)"
  }

  /// Safely converts `value` to `Int`.
  public static func int(from value: Any?) -> Int? {
    switch value {
    case let int as Int:
      return int
    case let string as String:
      return Int(string)
    case let number as NSNumber:
      return number.intValue
    default:
      return nil
    }
  }

  /// Safely converts `value` to `Double`.
  public static func double(from value: Any?) -> Double? {
    switch value {
    case let double as Double:
      return double
    case let float as Float:
      return Double(float)
    case let string as String:
      return Double(string)
    case let number as NSNumber:
      return number.doubleValue
    default:
      return nil
    }
  }

  /// Executes `action` and wraps the result or thrown error.
  public static func catching<T>(_ action: () throws -> T) -> Result<T, Error> {
    do { return .success(try action()) }
    catch { return .failure(error) }
  }
}
