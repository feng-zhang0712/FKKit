import UIKit

@MainActor
final class FKActionSheetSession {
  let handle: FKActionSheetHandle
  private(set) var configuration: FKActionSheetConfiguration
  let haptics = FKActionSheetHaptics()

  let hostContext: FKActionSheetPresentationHostContext
  weak var presenter: UIViewController?

  private weak var presentationController: FKPresentationController?
  private var lastInteractiveDismissProgress: CGFloat = 0
  private(set) var lastCapturedReason: FKActionSheetDismissReason = .tapOutside
  var onDidPresentExtra: (() -> Void)?

  init(
    handle: FKActionSheetHandle,
    configuration: FKActionSheetConfiguration,
    presentationController: FKPresentationController,
    hostContext: FKActionSheetPresentationHostContext,
    presenter: UIViewController
  ) {
    self.handle = handle
    self.configuration = configuration
    self.presentationController = presentationController
    self.hostContext = hostContext
    self.presenter = presenter
    haptics.prepare(configuration: configuration.haptics)
    bindPresentationHandlers(to: presentationController)
  }

  func updateConfiguration(_ configuration: FKActionSheetConfiguration) {
    self.configuration = configuration
    haptics.prepare(configuration: configuration.haptics)
    presentationController?.handlers = makePresentationHandlers()
  }

  func rebindPresentationHandlers(to presentation: FKPresentationController) {
    presentationController = presentation
    bindPresentationHandlers(to: presentation)
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
      handle.commitConfiguration(updated)
      handle.contentController.refreshAction(action)
    }
  }

  func captureDismissReason(default defaultReason: FKActionSheetDismissReason) -> FKActionSheetDismissReason {
    if let pending = handle.peekPendingDismissReason() {
      lastCapturedReason = pending
      handle.consumePendingDismissReason(default: defaultReason)
      return lastCapturedReason
    }
    if lastInteractiveDismissProgress > 0.02 {
      lastCapturedReason = .swipe
    } else {
      lastCapturedReason = defaultReason
    }
    return lastCapturedReason
  }

  func notifyWillPresent() {
    lastInteractiveDismissProgress = 0
    configuration.hooks.willPresent?()
    configuration.delegate?.actionSheetWillPresent(handle)
  }

  func notifyDidPresent() {
    configuration.hooks.didPresent?()
    configuration.delegate?.actionSheetDidPresent(handle)
    onDidPresentExtra?()
  }

  func notifyWillDismiss(reason: FKActionSheetDismissReason) {
    configuration.hooks.willDismiss?(reason)
    configuration.delegate?.actionSheetWillDismiss(handle, reason: reason)
  }

  func notifyDidDismiss(reason: FKActionSheetDismissReason) {
    configuration.hooks.didDismiss?(reason)
    configuration.delegate?.actionSheetDidDismiss(handle, reason: reason)
  }

  func notifyDidSelect(_ action: FKActionSheetAction) {
    configuration.delegate?.actionSheet(handle, didSelect: action)
  }

  func applySingleSelection(action: FKActionSheetAction, sectionID: UUID?) {
    var updated = configuration
    switch configuration.selection.mode {
    case .none:
      return
    case .single(let scope):
      updated.sections = updated.sections.map { section in
        var copy = section
        copy.actions = section.actions.map { row in
          var rowCopy = row
          let inScope: Bool = {
            switch scope {
            case .allSections:
              return true
            case .section(let id):
              return section.id == id
            }
          }()
          if inScope {
            rowCopy.isSelected = row.id == action.id
          }
          return rowCopy
        }
        return copy
      }
    }
    updated.selection.selectedActionID = action.id
    configuration = updated
    handle.reload(configuration: updated)
  }

  private func bindPresentationHandlers(to presentation: FKPresentationController) {
    presentation.handlers = makePresentationHandlers()
  }

  private func makePresentationHandlers() -> FKPresentationLifecycleHandlers {
    weak var session = self
    return FKPresentationLifecycleHandlers(
      willPresent: { session?.notifyWillPresent() },
      didPresent: { session?.notifyDidPresent() },
      willDismiss: {
        guard let session else { return }
        let reason = session.captureDismissReason(default: .tapOutside)
        session.notifyWillDismiss(reason: reason)
      },
      didDismiss: {
        guard let session else { return }
        session.notifyDidDismiss(reason: session.lastCapturedReason)
      },
      progress: { value in
        session?.lastInteractiveDismissProgress = max(session?.lastInteractiveDismissProgress ?? 0, value)
      }
    )
  }
}
