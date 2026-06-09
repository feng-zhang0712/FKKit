import FKUIKit
import UIKit

/// Offline preflight with a toggleable ``NetworkStatusProviding`` stub.
final class FKWebViewExampleOfflinePreflightViewController: UIViewController {
  private let reachability = FKWebViewExampleReachabilitySimulator()
  private lazy var webView: FKWebView = {
    var configuration = FKWebViewConfiguration()
    configuration.reachability.showsOfflineEmptyStateBeforeLoad = true
    configuration.reachability.observesReachabilityChanges = true
    let context = FKWebViewConfigurationContext(reachabilityProvider: reachability)
    return FKWebView(configuration: configuration, context: context)
  }()

  private let toggle = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Offline preflight"
    view.backgroundColor = .systemBackground

    reachability.isReachable = false

    let label = UILabel()
    label.text = "Simulate online"
    label.font = .preferredFont(forTextStyle: .subheadline)

    toggle.isOn = false
    toggle.addTarget(self, action: #selector(toggleReachability), for: .valueChanged)

    let row = UIStackView(arrangedSubviews: [label, toggle])
    row.axis = .horizontal
    row.spacing = 8
    row.alignment = .center
    row.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(row)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      row.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      row.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),

      container.topAnchor.constraint(equalTo: row.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    webView.load(FKWebViewExampleURLs.remoteHTTPS)
  }

  @objc private func toggleReachability() {
    reachability.isReachable = toggle.isOn
    if toggle.isOn {
      webView.load(FKWebViewExampleURLs.remoteHTTPS)
    } else {
      webView.load(FKWebViewExampleURLs.remoteHTTPS)
    }
  }
}
