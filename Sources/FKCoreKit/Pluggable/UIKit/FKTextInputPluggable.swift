import Foundation

// MARK: - Text formatting & validation

/// Formats display text for pluggable text fields (phone grouping, card masking, etc.).
public protocol FKTextFormatting: Sendable {
  associatedtype Rule: Sendable

  /// Returns raw (storage) and formatted (display) representations.
  func format(text: String, rule: Rule) -> FKTextFormattingResult
}

/// Result of a formatting pass.
public struct FKTextFormattingResult: Sendable, Equatable {
  /// Value persisted or sent to APIs (often digits only).
  public var rawText: String
  /// Value shown in the control.
  public var displayText: String

  /// Creates a formatting result.
  public init(rawText: String, displayText: String) {
    self.rawText = rawText
    self.displayText = displayText
  }
}

/// Validates text for pluggable text fields.
public protocol FKTextValidating: Sendable {
  associatedtype Rule: Sendable

  /// Validates user input.
  func validate(rawText: String, displayText: String, rule: Rule) -> FKTextValidationResult
}

/// Validation outcome.
public enum FKTextValidationResult: Sendable, Equatable {
  case valid
  case invalid(message: String)
}

/// Async validation (server-side uniqueness, blacklist checks, etc.).
public protocol FKTextAsyncValidating: AnyObject, Sendable {
  associatedtype Rule: Sendable

  /// Performs async validation.
  func validate(rawText: String, displayText: String, rule: Rule) async throws -> FKTextValidationResult
}
