import Foundation

/// Controls whether lifecycle events are delivered through the delegate, handlers, or both channels.
public enum FKSheetPresentationCallbackDelivery: Sendable, Equatable {
  /// Delivers events only through ``FKSheetPresentationControllerDelegate``.
  case delegateOnly
  /// Delivers events only through ``FKSheetPresentationLifecycleHandlers``.
  case handlersOnly
  /// Delivers events through both channels.
  case both
}
