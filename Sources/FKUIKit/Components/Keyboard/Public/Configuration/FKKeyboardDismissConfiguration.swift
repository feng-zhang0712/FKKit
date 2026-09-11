import Foundation

/// Configuration for ``FKKeyboardDismissController``.
public struct FKKeyboardDismissConfiguration: Equatable, Sendable {
  /// When `true`, the tap gesture cancels touches delivered to the hit view.
  ///
  /// Defaults to `false` so buttons and controls keep receiving taps.
  public var cancelsTouchesInView: Bool

  /// When `true`, taps inside the current first responder do not dismiss the keyboard.
  public var ignoresTapsInsideFirstResponder: Bool

  /// Creates a dismiss configuration.
  public init(
    cancelsTouchesInView: Bool = false,
    ignoresTapsInsideFirstResponder: Bool = true
  ) {
    self.cancelsTouchesInView = cancelsTouchesInView
    self.ignoresTapsInsideFirstResponder = ignoresTapsInsideFirstResponder
  }
}
