import Foundation

extension FKActionSheetSelectionConfiguration {
  /// Whether ``Mode`` enables selection accessories and selection interaction rules.
  var isSelectionActive: Bool {
    switch mode {
    case .none:
      return false
    case .single, .multiple:
      return true
    }
  }

  /// Number of currently selected rows for the active mode.
  public var selectedCount: Int {
    switch mode {
    case .none:
      return 0
    case .single:
      return selectedActionID == nil ? 0 : 1
    case .multiple:
      return selectedActionIDs.count
    }
  }

  /// Whether the row can toggle selection in the current mode (ignores `action.isEnabled`).
  func canToggleSelection(
    for action: FKActionSheetAction,
    sectionID: UUID,
    isCancelGroup: Bool
  ) -> Bool {
    guard !isCancelGroup, !action.isLoading else { return false }

    switch mode {
    case .none:
      return false
    case .single(let scope):
      return scope.contains(sectionID: sectionID)
    case .multiple(let multiple):
      guard multiple.scope.contains(sectionID: sectionID) else { return false }
      if selectedActionIDs.contains(action.id) {
        return true
      }
      if let maxSelectionCount = multiple.maxSelectionCount,
         selectedActionIDs.count >= maxSelectionCount {
        return false
      }
      return true
    }
  }

  /// Whether the row should accept taps and render as interactive for selection limits.
  func isRowInteractionEnabled(
    for action: FKActionSheetAction,
    sectionID: UUID?,
    isCancelGroup: Bool
  ) -> Bool {
    guard action.isEnabled, !action.isLoading else { return false }
    guard !isCancelGroup else { return true }

    switch mode {
    case .none, .single:
      return true
    case .multiple(let multiple):
      guard let sectionID, multiple.scope.contains(sectionID: sectionID) else { return true }
      if canToggleSelection(for: action, sectionID: sectionID, isCancelGroup: false) {
        return true
      }
      if multiple.disablesUnselectedRowsAtMax,
         !selectedActionIDs.contains(action.id),
         isAtMaximumSelection(multiple: multiple) {
        return false
      }
      return true
    }
  }

  /// Applies a single-select or multi-select toggle and returns whether selection changed.
  mutating func togglingSelection(
    for action: FKActionSheetAction,
    sectionID: UUID,
    isCancelGroup: Bool
  ) -> Bool {
    guard canToggleSelection(for: action, sectionID: sectionID, isCancelGroup: isCancelGroup) else {
      return false
    }

    switch mode {
    case .none:
      return false
    case .single:
      selectedActionID = action.id
      return true
    case .multiple:
      if selectedActionIDs.contains(action.id) {
        selectedActionIDs.remove(action.id)
      } else {
        selectedActionIDs.insert(action.id)
      }
      return true
    }
  }

  private func isAtMaximumSelection(multiple: MultipleSelection) -> Bool {
    guard let maxSelectionCount = multiple.maxSelectionCount else { return false }
    return selectedActionIDs.count >= maxSelectionCount
  }

  /// Action identifier used for scroll restoration (last selected row in table order for multiple selection).
  func scrollTargetActionIDInTableOrder(sections: [FKActionSheetSection]) -> UUID? {
    guard isSelectionActive else { return nil }

    switch mode {
    case .none:
      return nil
    case .single(let scope):
      guard let selectedActionID else { return nil }
      for section in sections {
        guard scope.contains(sectionID: section.id) else { continue }
        if section.actions.contains(where: { $0.id == selectedActionID }) {
          return selectedActionID
        }
      }
      return nil
    case .multiple(let multiple):
      var lastSelectedID: UUID?
      for section in sections {
        guard multiple.scope.contains(sectionID: section.id) else { continue }
        for action in section.actions where selectedActionIDs.contains(action.id) {
          lastSelectedID = action.id
        }
      }
      return lastSelectedID
    }
  }
}
