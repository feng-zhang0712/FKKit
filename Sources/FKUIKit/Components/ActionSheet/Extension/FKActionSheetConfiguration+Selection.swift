import Foundation

public extension FKActionSheetConfiguration {
  /// Returns a copy with `isSelected` flags applied from ``FKActionSheetSelectionConfiguration/selectedActionID``.
  func applyingSelectionState() -> FKActionSheetConfiguration {
    guard case .single(let scope) = selection.mode,
          let selectedActionID = selection.selectedActionID
    else { return self }

    var copy = self
    copy.sections = sections.map { section in
      var sectionCopy = section
      sectionCopy.actions = section.actions.map { action in
        var actionCopy = action
        let inScope: Bool = {
          switch scope {
          case .allSections:
            return true
          case .section(let id):
            return section.id == id
          }
        }()
        if inScope {
          actionCopy.isSelected = action.id == selectedActionID
        }
        return actionCopy
      }
      return sectionCopy
    }
    return copy
  }
}
