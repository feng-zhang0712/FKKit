import UIKit

/// Full-screen host for ``FKWebView`` with optional navigation chrome and close button.
@MainActor
open class FKWebViewController: UIViewController {
  /// Embedded web container.
  public let webView: FKWebView

  private let initialURL: URL?
  private let showsCloseBarButton: Bool

  /// Creates a controller and optionally loads `url` on first appearance.
  public init(
    url: URL? = nil,
    configuration: FKWebViewConfiguration = FKWebViewDefaults.defaultConfiguration,
    context: FKWebViewConfigurationContext = FKWebViewConfigurationContext(),
    showsCloseBarButton: Bool = false
  ) {
    self.initialURL = url
    self.showsCloseBarButton = showsCloseBarButton
    self.webView = FKWebView(configuration: configuration, context: context)
    super.init(nibName: nil, bundle: nil)
    wireTitleUpdatesIfNeeded(configuration: configuration)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    embedWebView()
    configureCloseButtonIfNeeded()
    loadInitialURLIfNeeded()
  }

  open override var preferredStatusBarStyle: UIStatusBarStyle {
    webView.configuration.presentation.statusBarStyle
  }

  private func embedWebView() {
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func configureCloseButtonIfNeeded() {
    guard showsCloseBarButton else { return }
    let item = UIBarButtonItem(
      barButtonSystemItem: .close,
      target: self,
      action: #selector(closeTapped)
    )
    item.accessibilityLabel = FKUIKitI18n.string("fkuikit.webview.chrome.close")
    navigationItem.rightBarButtonItem = item
  }

  private func loadInitialURLIfNeeded() {
    guard let initialURL else { return }
    webView.load(initialURL)
  }

  private func wireTitleUpdatesIfNeeded(configuration: FKWebViewConfiguration) {
    guard configuration.presentation.updatesNavigationTitle else { return }
    let existing = webView.callbacks.onFinish
    webView.callbacks.onFinish = { [weak self] url in
      existing?(url)
      guard let self else { return }
      self.navigationItem.title = self.webView.title
    }
  }

  @objc private func closeTapped() {
    webView.callbacks.onClose?()
  }
}
