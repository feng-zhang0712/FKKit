import Foundation
import UIKit

/// Default implementation of ``FKBusinessAlertManaging`` with de-duplication.
public final class FKBusinessAlertManager: FKBusinessAlertManaging, @unchecked Sendable {
  /// Supplies runtime alert backend configuration.
  private let configurationProvider: @Sendable () -> FKBusinessKitConfiguration
  /// Supplies optional host-provided FKAlert bridge.
  private let alertPresenterProvider: @Sendable () -> (any FKBusinessAlertPresenting)?

  /// Lock protecting de-duplication state when ``presentOnce`` schedules UI work.
  private let lock = NSLock()
  /// IDs of alerts currently being presented.
  private var presentingIDs: Set<String> = []

  /// Creates alert manager.
  ///
  /// - Parameters:
  ///   - configurationProvider: Supplies alert backend selection.
  ///   - alertPresenterProvider: Supplies optional custom presenter for ``FKBusinessAlertBackend/fkAlert``.
  public init(
    configurationProvider: @escaping @Sendable () -> FKBusinessKitConfiguration = { FKBusinessKitConfiguration() },
    alertPresenterProvider: @escaping @Sendable () -> (any FKBusinessAlertPresenting)? = { nil }
  ) {
    self.configurationProvider = configurationProvider
    self.alertPresenterProvider = alertPresenterProvider
  }

  /// Presents a single alert instance for a given identifier.
  public func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    presenter: UIViewController?
  ) {
    guard !id.isEmpty else { return }

    lock.lock()
    if presentingIDs.contains(id) {
      lock.unlock()
      return
    }
    presentingIDs.insert(id)
    lock.unlock()

    let backend = configurationProvider().alertBackend
    let customPresenter = alertPresenterProvider()
    let resolvedActions = actions.isEmpty
      ? [FKAlertAction(title: FKI18n.string("fkcore.common.ok"), style: .default, handler: nil)]
      : actions

    Task { @MainActor in
      let wrappedActions = resolvedActions.map { action in
        FKAlertAction(title: action.title, style: action.style) { [weak self] in
          action.handler?()
          self?.finish(id: id)
        }
      }

      FKBusinessAlertPresentation.presentOnce(
        id: id,
        title: title,
        message: message,
        actions: wrappedActions,
        presenter: presenter,
        backend: backend,
        customPresenter: customPresenter
      )

      if presenter == nil, UIViewController.fk_topMostViewController() == nil {
        self.finish(id: id)
      }
    }
  }

  /// Marks alert identifier as finished so it can be presented again.
  private func finish(id: String) {
    lock.lock()
    presentingIDs.remove(id)
    lock.unlock()
  }
}
