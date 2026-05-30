import Foundation

/// How a visible callout reacts when the software keyboard changes layout.
public enum FKCalloutKeyboardAvoidance: Sendable, Equatable {
  /// Ignores keyboard layout changes.
  case none
  /// Recomputes bubble placement inside the reduced layout bounds.
  case relayout
  /// Dismisses the callout when the keyboard will show.
  case dismiss
}
