//
// FKTextFieldDefaultValidator.swift
//
// Default validation implementation for FKTextField.
//

import Foundation

/// Default validator used by `FKTextField`.
public struct FKTextFieldDefaultValidator: FKTextFieldValidating {
  /// Creates a validator.
  public init() {}

  /// Validates text under the active rule.
  public func validate(
    rawText: String,
    formattedText _: String,
    rule: FKTextFieldInputRule
  ) -> FKTextFieldValidationResult {
    if let maxLength = rule.maxLength, rawText.count > maxLength {
      return .init(isValid: false, message: "Input exceeds max length.")
    }

    switch rule.formatType {
    case .phoneNumber:
      let valid = rawText.count == 11
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Phone number must be 11 digits.")
    case .idCard:
      let valid = validateIDCard(rawText)
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid ID card format.")
    case .bankCard:
      let valid = (12 ... 24).contains(rawText.count)
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Bank card length is invalid.")
    case let .verificationCode(length, _):
      let valid = rawText.count == length
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Verification code is incomplete.")
    case let .password(minLength, _, validatesStrength):
      let lengthValid = rawText.count >= minLength
      if !lengthValid {
        return .init(isValid: false, message: rawText.isEmpty ? nil : "Password is too short.")
      }
      if validatesStrength {
        let strong = rawText.range(of: "(?=.*[A-Z])(?=.*[a-z])(?=.*\\d).{8,}", options: .regularExpression) != nil
        return .init(isValid: strong, message: strong ? nil : "Password must include uppercase, lowercase and number.")
      }
      return .valid
    case let .amount(_, decimalDigits):
      let expression = "^\\d+(\\.\\d{0,\(max(0, decimalDigits))})?$"
      let valid = rawText.range(of: expression, options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid amount format.")
    case .email:
      let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
      let valid = rawText.range(of: regex, options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid email address.")
    case .numeric:
      let valid = rawText.allSatisfy(\.isNumber)
      return .init(isValid: valid, message: valid ? nil : "Only numbers are allowed.")
    case .alphabetic:
      let valid = rawText.allSatisfy(\.isLetter)
      return .init(isValid: valid, message: valid ? nil : "Only letters are allowed.")
    case .alphaNumeric:
      let valid = rawText.allSatisfy { $0.isNumber || $0.isLetter }
      return .init(isValid: valid, message: valid ? nil : "Only letters and numbers are allowed.")
    case let .custom(regex, _, _, _):
      let valid = rawText.range(of: "^\(regex)*$", options: .regularExpression) != nil
      return .init(isValid: valid, message: valid || rawText.isEmpty ? nil : "Invalid custom input.")
    }
  }
}

private extension FKTextFieldDefaultValidator {
  func validateIDCard(_ id: String) -> Bool {
    if id.count == 15 {
      return id.allSatisfy(\.isNumber)
    }
    guard id.count == 18 else { return false }
    let body = id.prefix(17)
    let check = id.suffix(1).uppercased()
    guard body.allSatisfy(\.isNumber) else { return false }
    let factors = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
    let parity = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]
    let sum = zip(body, factors).reduce(0) { partial, item in
      partial + (Int(String(item.0)) ?? 0) * item.1
    }
    return parity[sum % 11] == check
  }
}

