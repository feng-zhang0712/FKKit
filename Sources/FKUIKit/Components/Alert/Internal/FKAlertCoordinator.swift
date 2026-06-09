import UIKit

@MainActor
final class FKAlertCoordinator {
  private struct QueuedRequest {
    let content: FKAlertContent
    let configuration: FKAlertConfiguration
    let presenter: UIViewController?
    let presenterDelegate: FKAlertDelegate?
    let allowsDuplicateByID: Bool
    let continuation: CheckedContinuation<FKAlertResult?, Never>
  }

  private struct ActiveSession {
    let contentID: String?
    let alertViewController: FKAlertViewController
    let sheetController: FKSheetPresentationController
    let configuration: FKAlertConfiguration
    let continuation: CheckedContinuation<FKAlertResult?, Never>
    let presenterDelegate: FKAlertDelegate?
  }

  private var queue: [QueuedRequest] = []
  private var activeSessions: [ActiveSession] = []
  private var activePresentingIDs: Set<String> = []

  private var activeSession: ActiveSession? {
    activeSessions.last
  }

  func present(
    content: FKAlertContent,
    from presenter: UIViewController?,
    configuration: FKAlertConfiguration,
    presenterDelegate: FKAlertDelegate?,
    allowsDuplicateByID: Bool
  ) async -> FKAlertResult? {
    await withCheckedContinuation { continuation in
      enqueue(
        QueuedRequest(
          content: content,
          configuration: configuration,
          presenter: presenter,
          presenterDelegate: presenterDelegate,
          allowsDuplicateByID: allowsDuplicateByID,
          continuation: continuation
        )
      )
    }
  }

  func dismissActive(animated: Bool, result: FKAlertResult, invokeHandlers: Bool) {
    guard let session = activeSession else { return }
    finishSession(session, result: result, invokeHandlers: invokeHandlers, animated: animated)
  }

  func setLoading(_ isLoading: Bool) {
    activeSession?.alertViewController.setLoading(isLoading)
  }

  private func enqueue(_ request: QueuedRequest) {
    FKAlertActionResolver.validateContent(request.content)

    if !request.allowsDuplicateByID,
       let id = request.content.id,
       !id.isEmpty,
       activePresentingIDs.contains(id) {
      request.continuation.resume(returning: nil)
      return
    }

    switch request.configuration.queue {
    case .replaceCurrent:
      if let session = activeSession {
        let staleSession = session
        removeSession(staleSession)
        clearPresentingID(staleSession.contentID)
        staleSession.sheetController.dismiss(animated: false) {
          staleSession.presenterDelegate?.alertDidDismiss(staleSession.alertViewController, result: .dismissed)
          staleSession.continuation.resume(returning: .dismissed)
          self.start(request)
        }
      } else {
        start(request)
      }
    case .allowStack:
      start(request)
    case .singleActive, .presentOnceByID:
      if activeSession != nil {
        queue.append(request)
      } else {
        start(request)
      }
    }
  }

  private func start(_ request: QueuedRequest) {
    guard let presentingViewController = resolvedPresenter(request.presenter) else {
      request.continuation.resume(returning: .dismissed)
      pumpQueue()
      return
    }

    let normalizedActions = FKAlertActionResolver.normalizedActions(for: request.content)
    let resolvedActions = FKAlertActionResolver.resolvedActions(from: normalizedActions)
    let alertViewController = FKAlertViewController(
      content: request.content,
      configuration: request.configuration,
      resolvedActions: resolvedActions
    )

    let sheetConfiguration = request.configuration.presentation.resolvedSheetConfiguration(
      for: request.content,
      motion: request.configuration.motion
    )

    var handlers = FKSheetPresentationLifecycleHandlers()
    handlers.didDismiss = { [weak self, weak alertViewController] in
      guard let self, let alertViewController else { return }
      guard let session = self.session(for: alertViewController) else { return }
      self.finishSession(session, result: .dismissed, invokeHandlers: false, animated: false)
    }

    let sheetController = FKSheetPresentationController(
      contentController: alertViewController,
      configuration: sheetConfiguration,
      handlers: handlers
    )

    alertViewController.onActionSelected = { [weak self, weak alertViewController] action in
      guard let self, let alertViewController else { return }
      self.handleAction(action, alertViewController: alertViewController)
    }

    alertViewController.onUIKitDismiss = { [weak self, weak alertViewController] in
      guard let self, let alertViewController else { return }
      guard let session = self.session(for: alertViewController) else { return }
      self.finishSession(session, result: .dismissed, invokeHandlers: false, animated: false)
    }

    registerPresentingID(request.content.id)

    let session = ActiveSession(
      contentID: request.content.id,
      alertViewController: alertViewController,
      sheetController: sheetController,
      configuration: request.configuration,
      continuation: request.continuation,
      presenterDelegate: request.presenterDelegate
    )
    activeSessions.append(session)

    request.presenterDelegate?.alertWillPresent(alertViewController)
    sheetController.present(from: presentingViewController, animated: true)
  }

  private func handleAction(_ action: FKAlertResolvedAction, alertViewController: FKAlertViewController) {
    guard let session = session(for: alertViewController) else { return }

    if action.role == .primary || action.role == .destructive {
      guard alertViewController.validateTextInput() else { return }
    }

    if action.role == .primary, !session.configuration.interaction.dismissOnPrimaryAction {
      action.action.handler?()
      return
    }

    let trimmedText = alertViewController.currentTextValue()
    let result: FKAlertResult = action.action.style == .cancel
      ? .cancelled
      : .action(index: action.sourceIndex, action: FKAlertActionSnapshot(action.action), text: trimmedText)

    if action.role == .destructive, session.configuration.interaction.hapticOnDestructive {
      UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    let handlerDelay = action.role == .destructive
      ? session.configuration.interaction.destructiveHandlerDelay
      : 0

    finishSession(
      session,
      result: result,
      invokeHandlers: true,
      animated: true,
      selectedAction: action,
      handlerDelay: handlerDelay
    )
  }

  private func finishSession(
    _ session: ActiveSession,
    result: FKAlertResult,
    invokeHandlers: Bool,
    animated: Bool,
    selectedAction: FKAlertResolvedAction? = nil,
    handlerDelay: TimeInterval = 0
  ) {
    removeSession(session)
    clearPresentingID(session.contentID)

    let complete: @MainActor () -> Void = { [weak self] in
      session.presenterDelegate?.alertDidDismiss(session.alertViewController, result: result)
      session.continuation.resume(returning: result)

      if invokeHandlers, let selectedAction {
        let handler = selectedAction.action.handler
        if handlerDelay > 0 {
          Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(handlerDelay * 1_000_000_000))
            handler?()
          }
        } else {
          handler?()
        }
      }

      self?.pumpQueue()
    }

    if session.sheetController.isPresented {
      session.sheetController.dismiss(animated: animated, completion: complete)
    } else {
      complete()
    }
  }

  private func pumpQueue() {
    guard activeSession == nil, !queue.isEmpty else { return }
    let next = queue.removeFirst()
    start(next)
  }

  private func session(for alertViewController: FKAlertViewController) -> ActiveSession? {
    activeSessions.first { $0.alertViewController === alertViewController }
  }

  private func removeSession(_ session: ActiveSession) {
    activeSessions.removeAll { $0.alertViewController === session.alertViewController }
  }

  private func registerPresentingID(_ id: String?) {
    guard let id, !id.isEmpty else { return }
    activePresentingIDs.insert(id)
  }

  private func clearPresentingID(_ id: String?) {
    guard let id, !id.isEmpty else { return }
    activePresentingIDs.remove(id)
  }

  private func resolvedPresenter(_ presenter: UIViewController?) -> UIViewController? {
    if let presenter { return presenter }
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive })
        ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
      let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first,
      var top = window.rootViewController
    else {
      return nil
    }
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
}
