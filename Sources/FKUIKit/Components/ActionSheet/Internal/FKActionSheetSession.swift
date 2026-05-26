import UIKit

/// Coordinates presentation lifecycle, selection updates, and configuration mutations for one sheet instance.
@MainActor
final class FKActionSheetSession {
  private weak var actionSheet: FKActionSheet?
  private(set) var configuration: FKActionSheetConfiguration
  let haptics = FKActionSheetHaptics()

  private(set) var lastCapturedReason: FKActionSheetDismissReason = .tapOutside
  var onDidPresentExtra: (() -> Void)?

  init(actionSheet: FKActionSheet, configuration: FKActionSheetConfiguration) {
    self.actionSheet = actionSheet
    self.configuration = configuration
    haptics.prepare(configuration: configuration.haptics)
  }

  func updateConfiguration(_ configuration: FKActionSheetConfiguration) {
    self.configuration = configuration
    haptics.prepare(configuration: configuration.haptics)
  }

  func updateToggleValue(actionID: UUID, isOn: Bool) {
    var updated = configuration
    updated.sections = updated.sections.map { section in
      var copy = section
      copy.actions = section.actions.map { action in
        guard action.id == actionID, case .toggle(var toggle) = action.rowContent else { return action }
        toggle.isOn = isOn
        var actionCopy = action
        actionCopy.rowContent = .toggle(toggle)
        return actionCopy
      }
      return copy
    }
    if var cancel = updated.cancelAction, cancel.id == actionID, case .toggle(var toggle) = cancel.rowContent {
      toggle.isOn = isOn
      cancel.rowContent = .toggle(toggle)
      updated.cancelAction = cancel
    }
    configuration = updated
    if let action = updated.allActions.first(where: { $0.id == actionID }) {
      actionSheet?.applyConfiguration(updated, updateKind: .singleAction(action))
    }
  }

  func captureDismissReason(default defaultReason: FKActionSheetDismissReason) -> FKActionSheetDismissReason {
    guard let actionSheet else {
      lastCapturedReason = defaultReason
      return lastCapturedReason
    }
    if let pending = actionSheet.peekPendingDismissReason() {
      lastCapturedReason = pending
      actionSheet.consumePendingDismissReason(default: defaultReason)
      return lastCapturedReason
    }
    lastCapturedReason = defaultReason
    return lastCapturedReason
  }

  func notifyWillPresent() {
    configuration.hooks.willPresent?()
  }

  func notifyDidPresent() {
    configuration.hooks.didPresent?()
    onDidPresentExtra?()
  }

  func notifyWillDismiss(reason: FKActionSheetDismissReason) {
    lastCapturedReason = reason
    configuration.hooks.willDismiss?(reason)
  }

  func notifyDidDismiss(reason: FKActionSheetDismissReason) {
    configuration.hooks.didDismiss?(reason)
  }

  func notifyDidSelect(_ action: FKActionSheetAction) {
    configuration.hooks.didSelect?(action)
  }

  func applySingleSelection(action: FKActionSheetAction) {
    guard case .single = configuration.selection.mode else { return }
    var updated = configuration
    updated.selection.selectedActionID = action.id
    updated = updated.applyingSelectionState()
    configuration = updated
    actionSheet?.applyConfiguration(updated, updateKind: .selectionOnly)
  }

  /// Toggles multi-select state for an action row. Returns `false` when limits block the change.
  @discardableResult
  func toggleMultipleSelection(
    action: FKActionSheetAction,
    sectionID: UUID?
  ) -> Bool {
    guard case .multiple = configuration.selection.mode else { return false }
    guard let sectionID else { return false }

    var updated = configuration
    guard updated.selection.togglingSelection(
      for: action,
      sectionID: sectionID,
      isCancelGroup: false
    ) else {
      return false
    }

    updated = updated.applyingSelectionState()
    configuration = updated
    actionSheet?.applyConfiguration(updated, updateKind: .selectionOnly)
    return true
  }
}
