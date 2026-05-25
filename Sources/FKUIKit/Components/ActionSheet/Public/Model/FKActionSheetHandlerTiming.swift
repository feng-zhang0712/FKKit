import Foundation

/// Controls when an action `handler` runs relative to sheet dismissal.
public enum FKActionSheetHandlerTiming: Sendable, Equatable {
  /// Invokes the handler immediately when the row is tapped, then starts dismissal.
  case beforeDismiss
  /// Invokes the handler after the dismissal transition completes.
  case afterDismissAnimation
}
