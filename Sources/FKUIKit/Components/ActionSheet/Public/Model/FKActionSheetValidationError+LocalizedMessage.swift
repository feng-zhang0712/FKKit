import Foundation

public extension FKActionSheetValidationError {
  /// A short English message suitable for alerts or toasts.
  var localizedMessage: String {
    switch self {
    case .noActions:
      return "Add at least one action before presenting the action sheet."
    case .emptyLoadingContent:
      return "Enable the activity indicator or provide loading title or message text."
    case .multipleCancelActions:
      return "Only one cancel action is allowed."
    case .presenterNotFound:
      return "No presenter view controller was found."
    case .popoverAnchorRequired:
      return "Popover presentation requires an anchor view or bar button item."
    case .alreadyPresented:
      return "This action sheet is already presented."
    case .selectedCountExceedsMaximum:
      return "Too many items are selected for this sheet’s maximum. Deselect some choices first."
    case .unknownSelectedActionIDs:
      return "A pre-selected action ID is not in this sheet."
    }
  }
}
