import Foundation

/// Errors thrown by ``FKActionSheet/validate(_:)`` and presentation APIs.
public enum FKActionSheetValidationError: Error, Equatable, Sendable {
  /// No actions were provided in sections or as `cancelAction`.
  case noActions
  /// More than one `.cancel` style action or multiple separated cancel rows were detected.
  case multipleCancelActions
  /// No presenter could be resolved from the supplied window or window scene.
  case presenterNotFound
  /// Popover presentation requires an anchor view or bar button item at present time.
  case popoverAnchorRequired
  /// The sheet is already presented from another view controller.
  case alreadyPresented
  /// ``FKActionSheetSelectionConfiguration/selectedActionIDs`` exceeds ``FKActionSheetSelectionConfiguration/MultipleSelection/maxSelectionCount``.
  case selectedCountExceedsMaximum
  /// ``FKActionSheetSelectionConfiguration/selectedActionIDs`` contains identifiers that are not present in the configured scope.
  case unknownSelectedActionIDs
}
