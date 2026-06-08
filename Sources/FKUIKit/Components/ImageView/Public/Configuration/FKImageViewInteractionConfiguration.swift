import UIKit

/// Tap, highlight, and retry debounce settings.
public struct FKImageViewInteractionConfiguration: Equatable, Sendable {
  /// When `true`, dims the image using ``FKImageViewAppearanceConfiguration/highlightedAlpha`` on press.
  /// ``FKImageViewAppearanceConfiguration/adjustsImageWhenHighlighted`` enables the same effect.
  public var highlightOnPress: Bool
  /// Minimum interval between retry invocations.
  public var retryDebounceInterval: TimeInterval

  /// Creates interaction defaults.
  public init(
    highlightOnPress: Bool = false,
    retryDebounceInterval: TimeInterval = 0.3
  ) {
    self.highlightOnPress = highlightOnPress
    self.retryDebounceInterval = retryDebounceInterval
  }
}
