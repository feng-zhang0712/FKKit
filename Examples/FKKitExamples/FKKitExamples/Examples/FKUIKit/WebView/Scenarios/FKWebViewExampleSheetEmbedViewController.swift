import FKUIKit
import UIKit

/// ``FKWebView`` hosted inside centered ``FKSheetPresentationController``.
final class FKWebViewExampleSheetEmbedViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sheet embed"
    view.backgroundColor = .systemGroupedBackground

    let button = UIButton(type: .system)
    button.setTitle("Present web sheet", for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    button.addTarget(self, action: #selector(presentSheet), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(button)

    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }

  @objc private func presentSheet() {
    let configuration = FKWebViewDefaults.inAppBrowser()
    let host = FKWebViewController(
      url: FKWebViewExampleURLs.remoteHTTPS,
      configuration: configuration,
      showsCloseBarButton: true
    )
    host.webView.callbacks.onClose = { [weak host] in
      host?.dismiss(animated: true)
    }

    var sheetConfiguration = FKSheetPresentationConfiguration.centerCard
    sheetConfiguration.layout = .center(
      .init(
        size: .fitted(maxSize: .init(width: 360, height: 520)),
        minimumMargins: .init(top: 24, leading: 24, bottom: 24, trailing: 24),
        dismissEnabled: true
      )
    )
    sheetConfiguration.cornerRadius = 16
    sheetConfiguration.backdropStyle = .dim(alpha: 0.4)

    let nav = UINavigationController(rootViewController: host)
    _ = FKSheetPresentationController.present(
      contentController: nav,
      from: self,
      configuration: sheetConfiguration,
      delegate: nil,
      handlers: FKSheetPresentationLifecycleHandlers(),
      animated: true,
      completion: nil
    )
  }
}
