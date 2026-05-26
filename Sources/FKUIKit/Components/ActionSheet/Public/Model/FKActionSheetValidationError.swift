import Foundation

/// Errors thrown by ``FKActionSheet/validate(_:)`` and ``FKActionSheet/present(configuration:from:animated:completion:)``.
public enum FKActionSheetValidationError: Error, Equatable, Sendable {
  /// No actions were provided in sections or as `cancelAction`.
  case noActions
  /// More than one `.cancel` style action or multiple separated cancel rows were detected.
  case multipleCancelActions
  /// No presenter could be resolved from the supplied host context.
  case presenterNotFound
  /// Popover presentation requires `popoverSourceView` or `popoverBarButtonItem` in the host context.
  case popoverAnchorRequired
}
