//
// FKTextFieldFormatType.swift
//
// Built-in formatting and input-limit types for FKTextField.
//

import Foundation
import UIKit

/// Describes the built-in formatting strategy used by `FKTextField`.
public enum FKTextFieldFormatType: Sendable, Equatable {
  /// Phone number formatting. Example: `138 1234 5678`.
  case phoneNumber
  /// Chinese ID card formatting for 15/18 characters.
  case idCard
  /// Bank card formatting with groups of 4.
  case bankCard
  /// Verification code with fixed length and optional alphabet support.
  case verificationCode(length: Int, allowsAlphabet: Bool)
  /// Password mode with optional strength validation.
  case password(minLength: Int, maxLength: Int, validatesStrength: Bool)
  /// Amount formatting with grouping and fixed decimal scale.
  case amount(maxIntegerDigits: Int, decimalDigits: Int)
  /// Email input and validation mode.
  case email
  /// Numeric-only input.
  case numeric
  /// Alphabet-only input.
  case alphabetic
  /// Alphanumeric input.
  case alphaNumeric
  /// Custom regular expression filtering and optional visual grouping.
  case custom(
    regex: String,
    maxLength: Int?,
    separator: Character?,
    groupPattern: [Int]
  )

  /// Returns the suggested keyboard type for the format type.
  public var keyboardType: UIKeyboardType {
    switch self {
    case .phoneNumber, .numeric, .bankCard, .verificationCode:
      return .numberPad
    case .amount:
      return .decimalPad
    case .email:
      return .emailAddress
    case .password:
      return .asciiCapable
    case .alphabetic, .alphaNumeric, .idCard, .custom:
      return .asciiCapable
    }
  }

  /// Returns the fixed completed length when the input type has one.
  public var fixedLength: Int? {
    switch self {
    case let .verificationCode(length, _):
      return max(0, length)
    default:
      return nil
    }
  }
}

