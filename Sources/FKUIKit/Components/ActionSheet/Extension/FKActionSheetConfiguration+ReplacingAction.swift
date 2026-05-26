import Foundation

extension FKActionSheetConfiguration {
  /// Returns a copy with the matching action replaced in sections or cancel slot.
  func replacingAction(_ action: FKActionSheetAction) -> FKActionSheetConfiguration {
    var updated = self
    updated.sections = updated.sections.map { section in
      var copy = section
      copy.actions = section.actions.map { $0.id == action.id ? action : $0 }
      return copy
    }
    if updated.cancelAction?.id == action.id {
      updated.cancelAction = action
    }
    return updated
  }
}
