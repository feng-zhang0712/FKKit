import Foundation

/// Phone-number grouping rule for ``FKPhoneNumberTextFormatter``.
public struct FKPhoneNumberFormattingRule: Sendable, Hashable {
  /// Maximum digits retained in raw text.
  public var maxDigits: Int

  /// Default mainland-China style 11-digit cap.
  public static let `default` = FKPhoneNumberFormattingRule(maxDigits: 11)

  /// Creates a phone formatting rule.
  public init(maxDigits: Int) {
    self.maxDigits = maxDigits
  }
}

/// Groups phone digits as `XXX XXXX XXXX` while keeping raw digits-only text.
public struct FKPhoneNumberTextFormatter: FKTextFormatting {
  /// Associated rule type.
  public typealias Rule = FKPhoneNumberFormattingRule

  /// Creates a formatter instance.
  public init() {}

  /// Formats display text and raw digits for phone entry fields.
  public func format(text: String, rule: FKPhoneNumberFormattingRule) -> FKTextFormattingResult {
    let digits = String(text.filter(\.isNumber).prefix(rule.maxDigits))
    var display = ""
    for (index, character) in digits.enumerated() {
      if index == 3 || index == 7 {
        display.append(" ")
      }
      display.append(character)
    }
    return FKTextFormattingResult(rawText: digits, displayText: display)
  }
}
