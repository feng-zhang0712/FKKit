import FKCoreKit
import FKUIKit
import UIKit

// MARK: - URLs

enum FKWebViewExampleURLs {
  static let remoteHTTPS = URL(string: "https://example.com")!
  /// Returns a real HTTP 404 (not a 200 body with "404" text).
  static let http404 = URL(string: "https://example.com/fkwebview-demo-404")!
  /// Slow response so progress modes are visible during reload.
  static let slowHTTPS = URL(string: "https://httpbin.org/delay/2")!
}

// MARK: - Reachability simulator

/// Toggleable reachability stub for offline-preflight demos.
final class FKWebViewExampleReachabilitySimulator: NetworkStatusProviding, @unchecked Sendable {
  private let lock = NSLock()
  private var _isReachable = true

  var isReachable: Bool {
    get { lock.withLock { _isReachable } }
    set { lock.withLock { _isReachable = newValue } }
  }
}

// MARK: - Layout & logging

enum FKWebViewExampleSupport {
  /// HTTPS origin for bundled HTML so navigation, dialogs, and custom schemes work.
  static let demoHTMLBaseURL = URL(string: "https://fkkit-examples.local/")!

  static func embed(_ webView: FKWebView, in parent: UIView) {
    webView.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: parent.topAnchor),
      webView.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
    ])
  }

  static func loadBundledDemoHTML(named resource: String, into webView: FKWebView) {
    guard let html = loadBundledHTML(named: resource) else { return }
    webView.loadHTMLString(html, baseURL: demoHTMLBaseURL)
  }

  static func makeCaptionLabel(_ text: String) -> UILabel {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = text
    return label
  }

  static func makeEventLog() -> UITextView {
    let view = UITextView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.isEditable = false
    view.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    view.backgroundColor = .secondarySystemGroupedBackground
    view.layer.cornerRadius = 8
    view.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    return view
  }

  static func append(_ line: String, to log: UITextView) {
    let stamp = Self.timestamp()
    let entry = "[\(stamp)] \(line)\n"
    log.text = (log.text ?? "") + entry
    let bottom = NSRange(location: max(0, (log.text as NSString).length - 1), length: 1)
    log.scrollRangeToVisible(bottom)
  }

  static func loadBundledHTML(named resource: String) -> String? {
    guard let url = Bundle.main.url(forResource: resource, withExtension: "html") else { return nil }
    return try? String(contentsOf: url, encoding: .utf8)
  }

  static func loadBundledFileURL(named resource: String) -> URL? {
    Bundle.main.url(forResource: resource, withExtension: "html")
  }

  static func presentSimulatorNoticeIfNeeded(
    from viewController: UIViewController,
    message: String
  ) {
    let alert = UIAlertController(title: "Handled by native", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    viewController.present(alert, animated: true)
  }

  private static func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: Date())
  }
}
