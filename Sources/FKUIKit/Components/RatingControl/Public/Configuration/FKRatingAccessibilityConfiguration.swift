import UIKit

/// VoiceOver label, hint, and value formatting for ``FKRatingControl``.
public struct FKRatingAccessibilityConfiguration: Sendable, Equatable {
  /// When non-empty, overrides the default `accessibilityLabel`.
  public var customLabel: String?
  /// When non-empty, sets `accessibilityHint`.
  public var customHint: String?
  /// Format string for the accessibility value. Use `%@` for the numeric value and `%@` for the maximum.
  /// Example: `"%@ out of %@ stars"`.
  public var valueFormat: String

  public init(
    customLabel: String? = nil,
    customHint: String? = nil,
    valueFormat: String = "%@ out of %@"
  ) {
    self.customLabel = customLabel
    self.customHint = customHint
    self.valueFormat = valueFormat
  }
}
