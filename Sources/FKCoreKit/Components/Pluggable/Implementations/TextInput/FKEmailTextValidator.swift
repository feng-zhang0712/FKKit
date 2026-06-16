import Foundation

/// Local email validation rule for ``FKEmailTextValidator``.
public struct FKEmailValidationRule: Sendable, Hashable {
  /// Whether empty input is treated as valid.
  public var allowsEmpty: Bool

  /// Default rule requiring non-empty RFC 5322–simplified shape.
  public static let `default` = FKEmailValidationRule(allowsEmpty: false)

  /// Creates an email validation rule.
  public init(allowsEmpty: Bool) {
    self.allowsEmpty = allowsEmpty
  }
}

/// Validates email addresses with a lightweight local pattern (not a full RFC parser).
public struct FKEmailTextValidator: FKTextValidating {
  /// Associated rule type.
  public typealias Rule = FKEmailValidationRule

  /// Creates a validator instance.
  public init() {}

  /// Validates raw/display email text.
  public func validate(
    rawText: String,
    displayText: String,
    rule: FKEmailValidationRule
  ) -> FKTextValidationResult {
    _ = displayText
    if rawText.isEmpty {
      return rule.allowsEmpty ? .valid : .invalid(message: FKI18n.string("fkcore.pluggable.validation.email.required"))
    }
    let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
    let matched = rawText.range(
      of: pattern,
      options: [.regularExpression, .caseInsensitive]
    ) != nil
    if matched {
      return .valid
    }
    return .invalid(message: FKI18n.string("fkcore.pluggable.validation.email.invalid"))
  }
}
