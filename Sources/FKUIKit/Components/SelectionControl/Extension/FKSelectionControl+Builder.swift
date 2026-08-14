import UIKit

public extension FKCheckbox {
  /// Sets the indicator tint and returns `self` for chaining.
  @discardableResult
  func tint(_ tint: FKSelectionControlTint) -> Self {
    configuration.appearance.tint = tint
    return self
  }

  /// Sets the indicator size and returns `self` for chaining.
  @discardableResult
  func size(_ size: FKSelectionControlSize) -> Self {
    configuration.layout.size = size
    return self
  }
}

public extension FKRadioButton {
  /// Sets the indicator tint and returns `self` for chaining.
  @discardableResult
  func tint(_ tint: FKSelectionControlTint) -> Self {
    configuration.appearance.tint = tint
    return self
  }

  /// Sets the indicator size and returns `self` for chaining.
  @discardableResult
  func size(_ size: FKSelectionControlSize) -> Self {
    configuration.layout.size = size
    return self
  }
}
