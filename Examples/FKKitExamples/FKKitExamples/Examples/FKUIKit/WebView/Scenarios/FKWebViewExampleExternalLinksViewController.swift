import FKUIKit
import UIKit

/// `target="_blank"` navigations open externally per ``FKWebTargetBlankPolicy/openExternally``.
final class FKWebViewExampleExternalLinksViewController: UIViewController {
  private let webView: FKWebView = {
    var configuration = FKWebViewConfiguration()
    configuration.navigation.policy.targetBlank = .openExternally
    return FKWebView(configuration: configuration)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "External links"
    view.backgroundColor = .systemBackground
    FKWebViewExampleSupport.embed(webView, in: view)
    FKWebViewExampleSupport.loadBundledDemoHTML(named: "fkwebview-external-links", into: webView)
  }
}
