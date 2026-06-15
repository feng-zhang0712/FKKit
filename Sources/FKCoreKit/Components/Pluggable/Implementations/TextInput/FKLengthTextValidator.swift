import Foundation

/// Length validation rule for ``FKLengthTextValidator``.
public struct FKLengthValidationRule: Sendable, Hashable {
  /// Minimum inclusive raw length.
  public var minimum: Int
  /// Maximum inclusive raw length.
  public var maximum: Int

  /// Creates a length rule.
  public init(minimum: Int, maximum: Int) {
    self.minimum = minimum
    self.maximum = maximum
  }
}

/// Validates raw text length against inclusive bounds.
public struct FKLengthTextValidator: FKTextValidating {
  /// Associated rule type.
  public typealias Rule = FKLengthValidationRule

  /// Creates a validator instance.
  public init() {}

  /// Validates raw text length.
  public func validate(
    rawText: String,
    displayText: String,
    rule: FKLengthValidationRule
  ) -> FKTextValidationResult {
    _ = displayText
    let count = rawText.count
    if count < rule.minimum {
      return .invalid(message: FKI18n.format("fkcore.pluggable.validation.length.minimum", rule.minimum))
    }
    if count > rule.maximum {
      return .invalid(message: FKI18n.format("fkcore.pluggable.validation.length.maximum", rule.maximum))
    }
    return .valid
  }
}
