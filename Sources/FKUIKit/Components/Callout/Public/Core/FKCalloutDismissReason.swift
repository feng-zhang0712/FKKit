import Foundation

/// Reason reported when a callout finishes dismissal.
public enum FKCalloutDismissReason: Sendable, Equatable {
  /// Caller invoked ``FKCallout/dismiss(_:animated:)`` or a facade equivalent.
  case manual
  /// User tapped outside the bubble while ``FKCalloutConfiguration/tapOutsideToDismiss`` is enabled.
  case tapOutside
  /// ``FKCalloutConfiguration/autoDismissDuration`` elapsed (common for tooltips).
  case timeout
  /// A new callout replaced the currently visible one.
  case replaced
  /// Anchor left the window hierarchy, became hidden, or its host view controller was dismissed.
  case anchorUnavailable
  /// User selected a row in a menu popover.
  case menuSelection
  /// User tapped a footer action or coach-mark primary button.
  case actionTriggered
  /// User tapped the coach-mark close button.
  case closeButton
}
