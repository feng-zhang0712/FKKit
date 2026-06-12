import FKUIKit
import UIKit

/// Remote HTTPS page with default linear progress bar.
final class FKWebViewExampleBasicLoadViewController: UIViewController {
  private let webView = FKWebView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Remote HTTPS"
    view.backgroundColor = .systemBackground
    FKWebViewExampleSupport.embed(webView, in: view)
    webView.load(FKWebViewExampleURLs.remoteHTTPS)
  }
}
