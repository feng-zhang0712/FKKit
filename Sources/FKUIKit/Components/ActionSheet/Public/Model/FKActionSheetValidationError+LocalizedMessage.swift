import Foundation

public extension FKActionSheetValidationError {
  /// A short localized message suitable for alerts or toasts.
  var localizedMessage: String {
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
