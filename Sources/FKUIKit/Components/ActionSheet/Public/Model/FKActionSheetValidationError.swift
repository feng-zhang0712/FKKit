import Foundation

/// Errors thrown by ``FKActionSheet/validate(_:)`` and presentation APIs.
public enum FKActionSheetValidationError: Error, Equatable, Sendable {
  /// No actions were provided in sections or as `cancelAction`.
  case noActions
  /// Standard loading content has no spinner, title, or message configured.
  case emptyLoadingContent
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

  /// A short localized message suitable for alerts or toasts.
  public var localizedMessage: String {
    switch self {
    case .noActions:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.no_actions")
    case .emptyLoadingContent:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.empty_loading")
    case .multipleCancelActions:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.multiple_cancel")
    case .presenterNotFound:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.presenter_not_found")
    case .popoverAnchorRequired:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.popover_anchor")
    case .alreadyPresented:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.already_presented")
    case .selectedCountExceedsMaximum:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.selection_exceeds_max")
    case .unknownSelectedActionIDs:
      return FKUIKitI18n.string("fkuikit.actionsheet.error.unknown_selection")
    }
  }
}
