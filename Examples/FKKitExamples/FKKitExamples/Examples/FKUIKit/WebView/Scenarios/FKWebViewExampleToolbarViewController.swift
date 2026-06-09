import FKUIKit
import UIKit

/// Compact toolbar: back, forward, reload/stop, and close callback.
final class FKWebViewExampleToolbarViewController: UIViewController {
  private let webView = FKWebView(configuration: FKWebViewDefaults.inAppBrowser())

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Toolbar & history"
    view.backgroundColor = .systemBackground

    webView.callbacks.onClose = { [weak self] in
      self?.navigationController?.popViewController(animated: true)
    }
    FKWebViewExampleSupport.embed(webView, in: view)
    if let fileURL = FKWebViewExampleSupport.loadBundledFileURL(named: "fkwebview-navigation"),
      let readAccess = fileURL.deletingLastPathComponent() as URL? {
      webView.loadFileURL(fileURL, allowingReadAccessTo: readAccess)
    } else {
      webView.load(FKWebViewExampleURLs.remoteHTTPS)
    }
  }
}
