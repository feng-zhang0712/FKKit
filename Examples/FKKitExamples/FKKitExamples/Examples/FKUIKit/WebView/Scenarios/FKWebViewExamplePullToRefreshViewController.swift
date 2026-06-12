import FKUIKit
import UIKit

/// ``FKWebInteractionConfiguration/pullToRefreshEnabled`` on the embedded scroll view.
final class FKWebViewExamplePullToRefreshViewController: UIViewController {
  private let captionLabel = FKWebViewExampleSupport.makeCaptionLabel(
    "Uses UIRefreshControl on WKWebView's scroll view (FKWebView v1 design). FKRefresh targets hosts that own the scroll view; wiring it into WebKit is not the default path."
  )
  private let webView: FKWebView = {
    var configuration = FKWebViewConfiguration()
    configuration.interaction.pullToRefreshEnabled = true
    return FKWebView(configuration: configuration)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pull to refresh"
    view.backgroundColor = .systemBackground

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(captionLabel)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      captionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      captionLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      captionLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      container.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    webView.load(FKWebViewExampleURLs.remoteHTTPS)
  }
}
