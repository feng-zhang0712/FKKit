import FKUIKit
import UIKit

/// Domain allowlist blocks non-listed hosts with ``FKWebViewError/hostDenied`` empty state.
final class FKWebViewExampleDomainPolicyViewController: UIViewController {
  private let webView: FKWebView = {
    var configuration = FKWebViewConfiguration()
    configuration.navigation.policy.httpHTTPS = .domainList(
      FKWebDomainListPolicy(allowedHosts: ["example.com"])
    )
    return FKWebView(configuration: configuration)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Domain allowlist"
    view.backgroundColor = .systemBackground
    FKWebViewExampleSupport.embed(webView, in: view)
    if let html = FKWebViewExampleSupport.loadBundledHTML(named: "fkwebview-domain-policy") {
      webView.loadHTMLString(html, baseURL: FKWebViewExampleURLs.remoteHTTPS)
    }
  }
}
