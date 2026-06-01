import UIKit

/// Brief post-action feedback shown on ``FKButton`` (checkmark, failure, or custom message).
public enum FKButtonTransientResult: Equatable, Sendable {
  /// Green checkmark with optional message styling from ``FKButton/showTransientResult(_:duration:options:)``.
  case success
  /// Red cross with optional message styling.
  case failure
  /// Custom symbol name and tint (SF Symbol or asset resolved by the button).
  case custom(systemName: String, tintColor: UIColor, message: String?)
}

/// Optional copy and timing for ``FKButton/showTransientResult(_:duration:options:)``.
public struct FKButtonTransientResultOptions: Equatable, Sendable {
  /// Shown beside the result icon when non-empty. When `nil`, a default label is used for `.success` / `.failure`.
  public var message: String?
  public var messageFont: UIFont
  public var messageColor: UIColor
  /// When `true`, interaction is blocked until the transient state clears.
  public var blocksInteraction: Bool

  /// Creates transient-result options.
  public init(
    message: String? = nil,
    messageFont: UIFont = .preferredFont(forTextStyle: .subheadline),
    messageColor: UIColor = .label,
    blocksInteraction: Bool = true
  ) {
    self.message = message
    self.messageFont = messageFont
    self.messageColor = messageColor
    self.blocksInteraction = blocksInteraction
  }

  /// Default options.
  public static let `default` = FKButtonTransientResultOptions()
}
