//
// FKTextFieldConfiguration.swift
//
// Configuration model for FKTextField.
//

import Foundation
import UIKit

/// Rule set that controls filtering and formatting behavior.
public struct FKTextFieldInputRule {
  /// Built-in format type.
  public var formatType: FKTextFieldFormatType
  /// Maximum raw text length override.
  public var maxLength: Int?
  /// Whether whitespace is allowed.
  public var allowsWhitespace: Bool
  /// Whether emoji is allowed.
  public var allowsEmoji: Bool
  /// Whether special characters are allowed.
  public var allowsSpecialCharacters: Bool
  /// Whether the text field should resign first responder automatically when completed.
  public var autoDismissKeyboardOnComplete: Bool
  /// Debounce duration for callback notifications.
  public var debounceInterval: TimeInterval
  /// Minimum interval for accepting consecutive edits.
  public var minimumInputInterval: TimeInterval

  /// Creates an input rule.
  public init(
    formatType: FKTextFieldFormatType,
    maxLength: Int? = nil,
    allowsWhitespace: Bool = false,
    allowsEmoji: Bool = false,
    allowsSpecialCharacters: Bool = false,
    autoDismissKeyboardOnComplete: Bool = false,
    debounceInterval: TimeInterval = 0,
    minimumInputInterval: TimeInterval = 0
  ) {
    self.formatType = formatType
    self.maxLength = maxLength
    self.allowsWhitespace = allowsWhitespace
    self.allowsEmoji = allowsEmoji
    self.allowsSpecialCharacters = allowsSpecialCharacters
    self.autoDismissKeyboardOnComplete = autoDismissKeyboardOnComplete
    self.debounceInterval = max(0, debounceInterval)
    self.minimumInputInterval = max(0, minimumInputInterval)
  }
}

/// Full configuration for a text field instance.
public struct FKTextFieldConfiguration {
  /// Input rule.
  public var inputRule: FKTextFieldInputRule
  /// Visual style.
  public var style: FKTextFieldStyle
  /// Optional attributed placeholder that has highest priority.
  public var attributedPlaceholder: NSAttributedString?
  /// Placeholder plain text.
  public var placeholder: String?

  /// Creates a full configuration object.
  public init(
    inputRule: FKTextFieldInputRule,
    style: FKTextFieldStyle = .default,
    attributedPlaceholder: NSAttributedString? = nil,
    placeholder: String? = nil
  ) {
    self.inputRule = inputRule
    self.style = style
    self.attributedPlaceholder = attributedPlaceholder
    self.placeholder = placeholder
  }
}

