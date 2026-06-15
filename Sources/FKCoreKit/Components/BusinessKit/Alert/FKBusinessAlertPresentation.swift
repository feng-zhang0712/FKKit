import Foundation
import UIKit

/// Shared alert presentation that respects ``FKBusinessAlertBackend`` and optional ``FKBusinessAlertPresenting``.
enum FKBusinessAlertPresentation {
  @MainActor
  static func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    presenter: UIViewController?,
    backend: FKBusinessAlertBackend,
    customPresenter: (any FKBusinessAlertPresenting)?
  ) {
    let resolvedBackend: FKBusinessAlertBackend
    if backend == .fkAlert, customPresenter == nil {
      #if DEBUG
      print("FKBusinessKit: alertBackend is .fkAlert but alertPresenter is nil; falling back to systemAlert.")
      #endif
      resolvedBackend = .systemAlert
    } else {
      resolvedBackend = backend
    }

    let host = presenter ?? UIViewController.fk_topMostViewController()
    guard let host else { return }

    switch resolvedBackend {
    case .systemAlert:
      presentSystemAlert(title: title, message: message, actions: actions, on: host)
    case .fkAlert:
      customPresenter?.presentOnce(
        id: id,
        title: title,
        message: message,
        actions: actions,
        from: host
      )
    }
  }

  @MainActor
  private static func presentSystemAlert(
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    on host: UIViewController
  ) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let resolvedActions = actions.isEmpty
      ? [FKAlertAction(title: FKI18n.string("fkcore.common.ok"), style: .default, handler: nil)]
      : actions
    for action in resolvedActions {
      alert.addAction(UIAlertAction(title: action.title, style: mapStyle(action.style)) { _ in
        action.handler?()
      })
    }
    host.present(alert, animated: true)
  }

  private static func mapStyle(_ style: FKAlertAction.Style) -> UIAlertAction.Style {
    switch style {
    case .default: return .default
    case .cancel: return .cancel
    case .destructive: return .destructive
    }
  }
}
