import FKUIKit
import UIKit

/// ``FKWebViewDelegate`` and ``FKWebViewCallbacks`` lifecycle event log.
final class FKWebViewExampleDelegateLogViewController: UIViewController, FKWebViewDelegate {
  private let logView = FKWebViewExampleSupport.makeEventLog()
  private let webView = FKWebView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate log"
    view.backgroundColor = .systemGroupedBackground
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLog))

    webView.delegate = self
    webView.callbacks.onStateChange = { [weak self] state in
      self?.append("callback state: \(state)")
    }

    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.5),

      logView.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    webView.load(
      FKWebViewExampleURLs.remoteHTTPS,
      options: FKWebViewRequestOptions(additionalHeaders: ["X-FKKit-Demo": "webview-delegate"])
    )
  }

  func webView(_ webView: FKWebView, didChangeState state: FKWebViewLoadingState) {
    append("delegate state: \(state)")
  }

  func webView(_ webView: FKWebView, didCommit url: URL?) {
    append("didCommit: \(url?.host ?? "nil")")
  }

  func webView(_ webView: FKWebView, didFinish url: URL?) {
    append("didFinish: \(url?.host ?? "nil") title=\(webView.title ?? "")")
  }

  func webView(_ webView: FKWebView, didFail error: FKWebViewError) {
    append("didFail: \(error)")
  }

  @objc private func clearLog() {
    logView.text = ""
  }

  private func append(_ line: String) {
    FKWebViewExampleSupport.append(line, to: logView)
  }
}
