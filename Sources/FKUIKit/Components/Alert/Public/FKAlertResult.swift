import FKCoreKit
import Foundation

/// Outcome of an alert presentation.
public enum FKAlertResult: Sendable, Equatable {
  /// User selected an action. `text` is populated when the alert included a text field.
  case action(index: Int, action: FKAlertActionSnapshot, text: String?)
  /// User tapped a cancel-style action.
  ///
  /// Any handler attached to the cancel ``FKAlertAction`` is not invoked; observe this result instead.
  case cancelled
  /// Alert closed via backdrop tap, swipe, or programmatic dismiss without selecting an action.
  case dismissed
}

/// Value-type snapshot of ``FKAlertAction`` suitable for ``FKAlertResult`` equality.
public struct FKAlertActionSnapshot: Sendable, Equatable {
  /// Action title.
  public let title: String
  /// Action style.
  public let style: FKAlertAction.Style

  /// Creates a snapshot from a live action descriptor.
  public init(_ action: FKAlertAction) {
    title = action.title
    style = action.style
  }
}
