import FKUIKit
import UIKit
import WebKit

/// ``FKWebViewDefaults/ephemeralAuth()`` non-persistent data store and website-data cleanup.
final class FKWebViewExampleEphemeralAuthViewController: UIViewController {
  private let webView = FKWebView(configuration: FKWebViewDefaults.ephemeralAuth())
  private let statusLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.text = "Uses WKWebsiteDataStore.nonPersistent(). Tap Clear data after a login flow."
    return label
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Ephemeral session"
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Clear data",
      style: .plain,
      target: self,
      action: #selector(clearData)
    )

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      container.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    webView.load(FKWebViewExampleURLs.remoteHTTPS)
  }

  @objc private func clearData() {
    let types: Set<String> = [
      WKWebsiteDataTypeCookies,
      WKWebsiteDataTypeLocalStorage,
      WKWebsiteDataTypeSessionStorage,
    ]
    webView.clearWebsiteData(types: types, since: .distantPast) { [weak self] in
      self?.statusLabel.text = "Website data cleared. Reload to start a fresh ephemeral session."
      self?.webView.reload()
    }
  }
}
