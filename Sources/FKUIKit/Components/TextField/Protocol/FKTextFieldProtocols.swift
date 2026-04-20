//
// FKTextFieldProtocols.swift
//
// Protocol abstractions for formatter and validator.
//

import Foundation

/// Formatter protocol used by `FKTextField`.
public protocol FKTextFieldFormatting {
  /// Formats the provided text using the rule.
  ///
  /// - Parameters:
  ///   - text: Source text in current display form.
  ///   - rule: Active input rule.
  /// - Returns: A formatting result that includes raw and display text.
  func format(text: String, rule: FKTextFieldInputRule) -> FKTextFieldFormattingResult
}

/// Validator protocol used by `FKTextField`.
public protocol FKTextFieldValidating {
  /// Validates the text under the active rule.
  ///
  /// - Parameters:
  ///   - rawText: Text without separators.
  ///   - formattedText: Text displayed in UI.
  ///   - rule: Active input rule.
  /// - Returns: Validation result.
  func validate(
    rawText: String,
    formattedText: String,
    rule: FKTextFieldInputRule
  ) -> FKTextFieldValidationResult
}

/// API contract for configurable custom text fields.
@MainActor
public protocol FKTextFieldConfigurable: AnyObject {
  /// Applies a full configuration.
  func configure(_ configuration: FKTextFieldConfiguration)
}

