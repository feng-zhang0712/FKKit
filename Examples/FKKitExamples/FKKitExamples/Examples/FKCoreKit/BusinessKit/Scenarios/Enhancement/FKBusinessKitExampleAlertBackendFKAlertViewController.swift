import UIKit
import FKCoreKit
import FKUIKit

/// Binds ``FKAlertPresenter`` to ``FKBusinessAlertPresenting`` for BusinessKit backend switching.
@MainActor
final class FKBusinessKitFKAlertPresenterBridge: FKBusinessAlertPresenting {
  func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    from presenter: UIViewController?
  ) {
    let content = FKAlertContent(
      id: id,
      title: title,
      message: message,
      actions: actions
    )
    Task {
      _ = await FKAlertPresenter.shared.presentOnce(content, from: presenter)
    }
  }
}

/// E1 — FKAlert backend via injected ``FKBusinessAlertPresenting``.
final class FKBusinessKitExampleAlertBackendFKAlertViewController: FKBusinessKitExampleBaseViewController {
  private let alertBridge = FKBusinessKitFKAlertPresenterBridge()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "AlertBackendFKAlert"
    kit.updateConfiguration { $0.alertBackend = .fkAlert }
    kit.alertPresenter = alertBridge
    addInfoLabel("Uses FKBusinessKitConfiguration.alertBackend = .fkAlert with FKAlertPresenter bridge.")
    addActionButton("Present via FKAlert backend") { [weak self] in
      self?.kit.utils.alerts.presentOnce(
        id: "businesskit.e1.fkalert",
        title: "FKAlert Backend",
        message: "Presented through injected FKBusinessAlertPresenting.",
        actions: [FKAlertAction(title: "Got it", style: .default, handler: nil)],
        presenter: self
      )
    }
  }
}
