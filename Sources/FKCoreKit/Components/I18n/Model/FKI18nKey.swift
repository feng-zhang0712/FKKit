import Foundation

/// Typed localization key that prevents accidental free-form string drift.
///
/// Use ``FKI18nKey`` in feature modules instead of raw `String` keys when you want compile-time
/// discoverability and consistent naming (for example `FKI18nKey("settings.title")`).
public struct FKI18nKey: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
  /// Raw localization key passed to `Localizable.strings` or custom providers.
  public let rawValue: String

  /// Creates a key from a raw localization identifier.
  ///
  /// - Parameter rawValue: Key used in strings tables.
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  /// Creates a key from a string literal (enables `"settings.title"` syntax).
  public init(stringLiteral value: String) {
    self.rawValue = value
  }

  /// String representation equals ``rawValue``.
  public var description: String { rawValue }
}
