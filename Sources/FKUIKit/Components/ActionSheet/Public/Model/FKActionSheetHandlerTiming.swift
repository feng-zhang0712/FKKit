import Foundation

/// Controls when an action ``FKActionSheetAction/actionHandler`` runs relative to sheet dismissal.
public enum FKActionSheetHandlerTiming: Sendable, Equatable {
  /// Invokes the action handler immediately when the row is tapped, then starts dismissal.
  case beforeDismiss
  /// Invokes the action handler after the dismissal transition completes.
  case afterDismissAnimation
}
