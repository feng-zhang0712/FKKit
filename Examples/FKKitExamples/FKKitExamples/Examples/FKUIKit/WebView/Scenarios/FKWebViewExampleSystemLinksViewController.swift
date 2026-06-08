import FKUIKit
import UIKit

/// `mailto:` and `tel:` links routed through ``FKWebSystemURLPolicy/openExternally``.
final class FKWebViewExampleSystemLinksViewController: UIViewController {
  private let statusLabel = FKWebViewExampleSupport.makeCaptionLabel(
    "Tap a link. Simulator may not open Mail/Phone — a native alert confirms the handoff."
  )
  private lazy var webView: FKWebView = {
    let view = FKWebView()
    view.callbacks.onOpenExternally = { [weak self] url in
      guard let self else { return }
      self.statusLabel.text = "Opened externally: \(url.scheme ?? "")://…"
      FKWebViewExampleSupport.presentSimulatorNoticeIfNeeded(
        from: self,
        message: "\(url.absoluteString)\n\nOn device this opens Mail or Phone."
      )
    }
    return view
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "mailto & tel"
    view.backgroundColor = .systemBackground

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    let container = UIView()
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)
    view.addSubview(container)

    NSLayoutConstraint.activate([
      statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      container.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    FKWebViewExampleSupport.embed(webView, in: container)
    FKWebViewExampleSupport.loadBundledDemoHTML(named: "fkwebview-system-links", into: webView)
  }
}
