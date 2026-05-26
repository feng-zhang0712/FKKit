import Foundation

public extension FKActionSheetConfiguration {
  /// Returns a copy with `isSelected` flags applied from ``FKActionSheetSelectionConfiguration``.
  func applyingSelectionState() -> FKActionSheetConfiguration {
    switch selection.mode {
    case .none:
      return self
    case .single(let scope):
      guard let selectedActionID = selection.selectedActionID else { return self }
      return applyingSelectedIDs([selectedActionID], scope: scope)
    case .multiple(let multiple):
      return applyingSelectedIDs(selection.selectedActionIDs, scope: multiple.scope)
    }
  }

  private func applyingSelectedIDs(
    _ selectedIDs: Set<UUID>,
    scope: FKActionSheetSelectionConfiguration.Scope
  ) -> FKActionSheetConfiguration {
    var copy = self
    copy.sections = sections.map { section in
      var sectionCopy = section
      sectionCopy.actions = section.actions.map { action in
        var actionCopy = action
        if scope.contains(sectionID: section.id) {
          actionCopy.isSelected = selectedIDs.contains(action.id)
        }
        return actionCopy
      }
      return sectionCopy
    }
    return copy
  }
}
