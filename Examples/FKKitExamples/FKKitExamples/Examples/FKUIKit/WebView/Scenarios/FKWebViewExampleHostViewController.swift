import FKUIKit
import UIKit

/// Launches ``FKWebViewController`` with ``FKWebViewDefaults/inAppBrowser()`` preset.
final class FKWebViewExampleHostViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKWebViewController"
    view.backgroundColor = .systemGroupedBackground

    let button = UIButton(type: .system)
    button.setTitle("Open in-app browser host", for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    button.addTarget(self, action: #selector(openHost), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(button)

    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  @objc private func openHost() {
    var configuration = FKWebViewDefaults.inAppBrowser()
    configuration.presentation.updatesNavigationTitle = true
    let host = FKWebViewController(
      url: FKWebViewExampleURLs.remoteHTTPS,
      configuration: configuration,
      showsCloseBarButton: true
    )
    host.webView.callbacks.onClose = { [weak host] in
      host?.dismiss(animated: true)
    }
    let nav = UINavigationController(rootViewController: host)
    present(nav, animated: true)
  }
}
