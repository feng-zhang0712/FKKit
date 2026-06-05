import Foundation

/// Structured onboarding/coach-mark payload (title, body, optional close, primary action).
public struct FKCalloutCoachMarkContent: Sendable, Equatable {
  /// Bold title shown at the top.
  public var title: String
  /// Supporting body copy.
  public var message: String
  /// Primary button title (for example "Got it").
  public var primaryActionTitle: String
  /// Shows a trailing close affordance.
  public var showsCloseButton: Bool

  /// Creates coach-mark content.
  public init(
    title: String,
    message: String,
    primaryActionTitle: String = FKUIKitI18n.string("fkuikit.callout.got_it"),
    showsCloseButton: Bool = true
  ) {
    self.title = title
    self.message = message
    self.primaryActionTitle = primaryActionTitle
    self.showsCloseButton = showsCloseButton
  }
}
