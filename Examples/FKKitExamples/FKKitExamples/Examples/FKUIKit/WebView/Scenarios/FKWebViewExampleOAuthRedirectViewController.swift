import FKUIKit
import UIKit

/// Custom scheme redirect surfaced via ``FKWebViewCallbacks/onOAuthRedirect``.
final class FKWebViewExampleOAuthRedirectViewController: UIViewController {
  private let logView = FKWebViewExampleSupport.makeEventLog()
  private lazy var webView: FKWebView = {
    var configuration = FKWebViewDefaults.ephemeralAuth(
      customSchemes: ["fkkit-examples": .notifyHost]
    )
    configuration.reachability.showsOfflineEmptyStateBeforeLoad = false
    let view = FKWebView(configuration: configuration)
    view.callbacks.onOAuthRedirect = { [weak self] url in
      guard let self else { return }
      FKWebViewExampleSupport.append("OAuth redirect: \(FKWebViewExampleSupport.redactedURL(url))", to: self.logView)
      let alert = UIAlertController(
        title: "OAuth redirect captured",
        message: "Navigation cancelled in-web. Exchange the code via your backend.",
        preferredStyle: .alert
      )
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      self.present(alert, animated: true)
    }
    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "OAuth redirect"
    view.backgroundColor = .systemGroupedBackground

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.55),

      logView.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    FKWebViewExampleSupport.loadBundledDemoHTML(named: "fkwebview-oauth", into: webView)
  }
}

private extension FKWebViewExampleSupport {
  static func redactedURL(_ url: URL) -> String {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.query = nil
    return components?.string ?? url.absoluteString
  }
}
