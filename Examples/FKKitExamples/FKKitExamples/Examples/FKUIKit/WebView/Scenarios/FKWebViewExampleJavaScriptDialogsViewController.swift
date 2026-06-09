import FKUIKit
import UIKit

/// Default ``WKUIDelegate`` alert / confirm / prompt forwarding.
final class FKWebViewExampleJavaScriptDialogsViewController: UIViewController {
  private let webView = FKWebView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "JS dialogs"
    view.backgroundColor = .systemBackground

    let caption = FKWebViewExampleSupport.makeCaptionLabel(
      "Expected: native UIAlertController for each button — Alert shows a message; Confirm offers OK/Cancel; Prompt adds a text field."
    )
    view.addSubview(caption)
    NSLayoutConstraint.activate([
      caption.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      caption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      caption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
    ])

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)
    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: caption.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    FKWebViewExampleSupport.loadBundledDemoHTML(named: "fkwebview-js-dialogs", into: webView)
  }
}
