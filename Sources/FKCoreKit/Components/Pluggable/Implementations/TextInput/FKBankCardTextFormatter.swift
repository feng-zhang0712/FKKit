import Foundation

/// Bank-card grouping rule for ``FKBankCardTextFormatter``.
public struct FKBankCardFormattingRule: Sendable, Hashable {
  /// Maximum digits retained in raw text.
  public var maxDigits: Int

  /// Default 16-digit card grouping.
  public static let `default` = FKBankCardFormattingRule(maxDigits: 16)

  /// Creates a bank-card formatting rule.
  public init(maxDigits: Int) {
    self.maxDigits = maxDigits
  }
}

/// Groups card digits in blocks of four separated by spaces.
public struct FKBankCardTextFormatter: FKTextFormatting {
  /// Associated rule type.
  public typealias Rule = FKBankCardFormattingRule

  /// Creates a formatter instance.
  public init() {}

  /// Formats card display text while preserving digits-only raw text.
  public func format(text: String, rule: FKBankCardFormattingRule) -> FKTextFormattingResult {
    let digits = String(text.filter(\.isNumber).prefix(rule.maxDigits))
    var display = ""
    for (index, character) in digits.enumerated() {
      if index > 0, index % 4 == 0 {
        display.append(" ")
      }
      display.append(character)
    }
    return FKTextFormattingResult(rawText: digits, displayText: display)
  }
}
