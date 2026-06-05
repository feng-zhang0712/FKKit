import Foundation

/// Default validator used by `FKTextField`.
///
/// The default validator mirrors the built-in `FKTextFieldFormatType` cases and provides
/// pragmatic validation rules commonly used in production apps.
public struct FKTextFieldDefaultValidator: FKTextFieldValidating {
  /// Creates a validator.
  public init() {}

  /// Validates text under the active rule.
  ///
  /// - Parameters:
  ///   - rawText: Text without separators (the canonical value for validation).
  ///   - formattedText: UI display text. Not used by the default implementation.
  ///   - rule: Active input rule.
  /// - Returns: A validation result describing validity and an optional error message.
  public func validate(
    rawText: String,
    formattedText _: String,
    rule: FKTextFieldInputRule
  ) -> FKTextFieldValidationResult {
    if let minLength = rule.minLength, rawText.count < minLength, !rawText.isEmpty {
      return .init(isValid: false, message: FKUIKitI18n.string("fkuikit.textfield.validation.shorter_than_min"))
    }
    if let maxLength = rule.maxLength, rawText.count > maxLength {
      return .init(isValid: false, message: FKUIKitI18n.string("fkuikit.textfield.validation.too_long"))
    }

    switch rule.formatType {
    case .phoneNumber:
      let valid = rawText.count == 11
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.phone_11_digits"))
    case .idCard:
      let valid = validateIDCard(rawText)
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.id_card"))
    case .bankCard:
      let valid = (12 ... 24).contains(rawText.count)
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.bank_card"))
    case let .verificationCode(length, _):
      let valid = rawText.count == length
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.verification_code"))
    case let .password(minLength, _, validatesStrength):
      let lengthValid = rawText.count >= minLength
      if !lengthValid {
        return .init(isValid: false, message: rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.password_short"))
      }
      if validatesStrength {
        let strong = rawText.range(of: "(?=.*[A-Z])(?=.*[a-z])(?=.*\\d).{8,}", options: .regularExpression) != nil
        return .init(isValid: strong, message: strong ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.password_strength"))
      }
      return .valid
    case let .amount(_, decimalDigits):
      let expression = "^\\d+(\\.\\d{0,\(max(0, decimalDigits))})?$"
      let valid = rawText.range(of: expression, options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.amount"))
    case .email:
      let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
      let valid = rawText.range(of: regex, options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.email"))
    case .numeric:
      let valid = rawText.allSatisfy(\.isNumber)
      return .init(isValid: valid, message: valid ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.numeric_only"))
    case .alphabetic:
      let valid = rawText.allSatisfy(\.isLetter)
      return .init(isValid: valid, message: valid ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.letters_only"))
    case .alphaNumeric:
      let valid = rawText.allSatisfy { $0.isNumber || $0.isLetter }
      return .init(isValid: valid, message: valid ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.alphanumeric_only"))
    case let .custom(regex, _, _, _):
      let valid = rawText.range(of: "^\(regex)*$", options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : FKUIKitI18n.string("fkuikit.textfield.validation.custom"))
    }
  }
}

private extension FKTextFieldDefaultValidator {
  /// Validates Chinese Resident Identity Card numbers (15 or 18 characters).
  ///
  /// - Parameter id: Raw ID string (digits plus optional `X` for 18-digit checksum).
  /// - Returns: `true` if the ID is structurally valid.
  func validateIDCard(_ id: String) -> Bool {
    if id.count == 15 {
      // 15-digit IDs are validated as numeric-only.
      return id.allSatisfy(\.isNumber)
    }
    guard id.count == 18 else { return false }
    let body = id.prefix(17)
    let check = id.suffix(1).uppercased()
    guard body.allSatisfy(\.isNumber) else { return false }
    // 18-digit checksum: weighted sum modulo 11 mapped to parity table.
    let factors = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
    let parity = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]
    let sum = zip(body, factors).reduce(0) { partial, item in
      partial + (Int(String(item.0)) ?? 0) * item.1
    }
    return parity[sum % 11] == check
  }
}

