//
// FKTextFieldStyle.swift
//
// Visual style descriptors for FKTextField.
//

import UIKit

/// Visual style for a specific `FKTextField` state.
public struct FKTextFieldStateStyle {
  /// Border color.
  public var borderColor: UIColor
  /// Border width.
  public var borderWidth: CGFloat
  /// Corner radius.
  public var cornerRadius: CGFloat
  /// Background color.
  public var backgroundColor: UIColor
  /// Optional shadow color.
  public var shadowColor: UIColor?
  /// Shadow opacity.
  public var shadowOpacity: Float
  /// Shadow offset.
  public var shadowOffset: CGSize
  /// Shadow blur radius.
  public var shadowRadius: CGFloat

  /// Creates a state style.
  public init(
    borderColor: UIColor,
    borderWidth: CGFloat = 1,
    cornerRadius: CGFloat = 10,
    backgroundColor: UIColor = .secondarySystemBackground,
    shadowColor: UIColor? = nil,
    shadowOpacity: Float = 0,
    shadowOffset: CGSize = .zero,
    shadowRadius: CGFloat = 0
  ) {
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
    self.shadowColor = shadowColor
    self.shadowOpacity = shadowOpacity
    self.shadowOffset = shadowOffset
    self.shadowRadius = shadowRadius
  }
}

/// Full style group for normal/focused/error states.
public struct FKTextFieldStyle {
  /// Style used in normal state.
  public var normal: FKTextFieldStateStyle
  /// Style used while editing.
  public var focused: FKTextFieldStateStyle
  /// Style used in invalid/error state.
  public var error: FKTextFieldStateStyle
  /// Text color.
  public var textColor: UIColor
  /// Text font.
  public var font: UIFont
  /// Placeholder color.
  public var placeholderColor: UIColor
  /// Placeholder font.
  public var placeholderFont: UIFont

  /// Creates a style group.
  public init(
    normal: FKTextFieldStateStyle,
    focused: FKTextFieldStateStyle,
    error: FKTextFieldStateStyle,
    textColor: UIColor = .label,
    font: UIFont = .systemFont(ofSize: 16),
    placeholderColor: UIColor = .secondaryLabel,
    placeholderFont: UIFont = .systemFont(ofSize: 16)
  ) {
    self.normal = normal
    self.focused = focused
    self.error = error
    self.textColor = textColor
    self.font = font
    self.placeholderColor = placeholderColor
    self.placeholderFont = placeholderFont
  }
}

public extension FKTextFieldStyle {
  /// Default style.
  static var `default`: FKTextFieldStyle {
    FKTextFieldStyle(
      normal: FKTextFieldStateStyle(borderColor: .separator),
      focused: FKTextFieldStateStyle(borderColor: .systemBlue),
      error: FKTextFieldStateStyle(borderColor: .systemRed)
    )
  }
}

