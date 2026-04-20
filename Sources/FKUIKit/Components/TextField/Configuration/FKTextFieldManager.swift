//
// FKTextFieldManager.swift
//
// Global style manager for FKTextField.
//

import UIKit

/// Global manager for default `FKTextField` configuration.
@MainActor
public final class FKTextFieldManager {
  /// Shared singleton instance.
  public static let shared = FKTextFieldManager()

  /// Global default style.
  public var defaultStyle: FKTextFieldStyle = .default

  private init() {}

  /// Updates global style in place.
  ///
  /// - Parameter block: Style mutation block.
  public func configureDefaultStyle(_ block: (inout FKTextFieldStyle) -> Void) {
    var style = defaultStyle
    block(&style)
    defaultStyle = style
  }

  /// Restores the global default style.
  public func resetDefaultStyle() {
    defaultStyle = .default
  }
}

