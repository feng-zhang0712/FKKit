import FKUIKit
import UIKit

/// Bundle HTML via ``FKWebView/loadHTMLString(_:baseURL:)`` and ``FKWebView/loadFileURL(_:allowingReadAccessTo:)``.
final class FKWebViewExampleLocalHTMLViewController: UIViewController {
  private let webView = FKWebView()
  private let modeControl = UISegmentedControl(items: ["HTML string", "File URL"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Local HTML"
    view.backgroundColor = .systemBackground

    modeControl.selectedSegmentIndex = 0
    modeControl.addTarget(self, action: #selector(reloadMode), for: .valueChanged)
    modeControl.translatesAutoresizingMaskIntoConstraints = false

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(modeControl)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      modeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      modeControl.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      modeControl.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      container.topAnchor.constraint(equalTo: modeControl.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    reloadMode()
  }

  @objc private func reloadMode() {
    if modeControl.selectedSegmentIndex == 0,
      let html = FKWebViewExampleSupport.loadBundledHTML(named: "fkwebview-basic") {
      webView.loadHTMLString(html, baseURL: nil)
    } else if let fileURL = FKWebViewExampleSupport.loadBundledFileURL(named: "fkwebview-basic") {
      webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
    }
  }
}
