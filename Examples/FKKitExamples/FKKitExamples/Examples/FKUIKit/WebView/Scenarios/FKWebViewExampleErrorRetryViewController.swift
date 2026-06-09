import FKUIKit
import UIKit

/// HTTP 404 triggers error empty state with retry and Open in Safari.
final class FKWebViewExampleErrorRetryViewController: UIViewController {
  private let webView = FKWebView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Error & retry"
    view.backgroundColor = .systemBackground
    FKWebViewExampleSupport.embed(webView, in: view)
    webView.load(FKWebViewExampleURLs.http404)
  }
}
