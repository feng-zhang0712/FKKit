import UIKit
import WebKit

/// Production-oriented `WKWebView` wrapper with progress, error recovery, optional chrome, and policy-driven navigation.
@MainActor
public final class FKWebView: UIView {
  // MARK: - Public state

  /// Current loading lifecycle state.
  public private(set) var loadingState: FKWebViewLoadingState = .idle

  /// Active equatable configuration snapshot.
  public var configuration: FKWebViewConfiguration {
    didSet {
      applyConfiguration()
    }
  }

  /// Optional delegate for lifecycle and policy overrides.
  public weak var delegate: FKWebViewDelegate? {
    didSet { syncCoordinatorWiring() }
  }

  /// Optional UI delegate for JavaScript panels.
  public weak var uiDelegate: FKWebViewUIDelegate? {
    didSet { syncCoordinatorWiring() }
  }

  /// Optional dedicated JavaScript handler.
  public weak var javascriptHandler: FKWebViewJavaScriptHandling? {
    didSet { syncCoordinatorWiring() }
  }

  /// Closure-based callbacks mirroring the delegate API.
  public var callbacks = FKWebViewCallbacks()

  /// Default per-load request options.
  public var requestOptions = FKWebViewRequestOptions()

  /// Host view controller for JavaScript alert / confirm / prompt presentation.
  ///
  /// When `nil`, the nearest ancestor view controller is resolved automatically.
  public weak var panelPresentingViewController: UIViewController?

  /// Whether the internal web view can navigate backward.
  public var canGoBack: Bool { wkWebView.canGoBack }

  /// Whether the internal web view can navigate forward.
  public var canGoForward: Bool { wkWebView.canGoForward }

  /// Current document URL, when available.
  public var url: URL? { wkWebView.url }

  /// Current document title, when available.
  public var title: String? { wkWebView.title }

  // MARK: - Private

  private let context: FKWebViewConfigurationContext
  private let coordinator: FKWebNavigationCoordinator
  private let wkWebView: WKWebView
  private let chromeView = FKWebChromeView()
  private let progressPresenter: FKWebProgressPresenter
  private let emptyStatePresenter = FKWebEmptyStatePresenter()
  private let contentLayoutGuide = UILayoutGuide()
  private var refreshControl: UIRefreshControl?
  private var chromeHeightConstraint: NSLayoutConstraint?
  private var progressTopConstraint: NSLayoutConstraint?

  // MARK: - Init

  public init(
    configuration: FKWebViewConfiguration = FKWebViewDefaults.defaultConfiguration,
    context: FKWebViewConfigurationContext = FKWebViewConfigurationContext()
  ) {
    self.configuration = configuration
    self.context = context
    self.progressPresenter = FKWebProgressPresenter(configuration: configuration.presentation.progress)
    self.coordinator = FKWebNavigationCoordinator(configuration: configuration, context: context)

    let wkConfiguration = coordinator.makeWKWebViewConfiguration()
    self.wkWebView = WKWebView(frame: .zero, configuration: wkConfiguration)

    super.init(frame: .zero)

    coordinator.webView = self
    coordinator.delegate = delegate
    coordinator.uiDelegate = uiDelegate
    coordinator.javascriptHandler = javascriptHandler

    emptyStatePresenter.attach(hostView: self)
    setupHierarchy()
    applyConfiguration()
    coordinator.attach(to: wkWebView)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    MainActor.assumeIsolated {
      coordinator.detach(from: wkWebView)
    }
  }

  // MARK: - Loading API

  /// Loads a fully constructed request.
  public func load(_ request: URLRequest) {
    guard beginLoadPreflight() else { return }
    let enriched = enrichedRequest(from: request)
    coordinator.storeLastRequest(enriched)
    wkWebView.load(enriched)
  }

  /// Loads a URL with ``requestOptions``.
  public func load(_ url: URL) {
    load(URLRequest(url: url))
  }

  /// Loads local HTML with an optional base URL.
  public func loadHTMLString(_ string: String, baseURL: URL?) {
    guard beginLoadPreflight() else { return }
    wkWebView.loadHTMLString(string, baseURL: baseURL)
  }

  /// Loads a sandboxed file URL.
  public func loadFileURL(_ url: URL, allowingReadAccessTo readAccessURL: URL) {
    guard beginLoadPreflight() else { return }
    wkWebView.loadFileURL(url, allowingReadAccessTo: readAccessURL)
  }

  /// Reloads the current document.
  public func reload() {
    if coordinator.shouldPreflightOffline() {
      showOfflineOverlay()
      return
    }
    emptyStatePresenter.hide()
    loadingState = .loading(progress: nil)
    if let last = coordinator.lastStoredRequest() {
      wkWebView.load(last)
    } else {
      wkWebView.reload()
    }
  }

  /// Stops the in-flight navigation.
  public func stopLoading() {
    wkWebView.stopLoading()
    loadingState = .idle
    progressPresenter.hideForFailure()
    updateChrome()
  }

  /// Navigates back when possible.
  @discardableResult
  public func goBack() -> Bool {
    guard wkWebView.canGoBack else { return false }
    wkWebView.goBack()
    return true
  }

  /// Navigates forward when possible.
  @discardableResult
  public func goForward() -> Bool {
    guard wkWebView.canGoForward else { return false }
    wkWebView.goForward()
    return true
  }

  /// Evaluates JavaScript in the current document.
  public func evaluateJavaScript(
    _ script: String,
    completion: (@MainActor (Result<Any?, Error>) -> Void)? = nil
  ) {
    wkWebView.evaluateJavaScript(script) { result, error in
      Task { @MainActor in
        if let error {
          completion?(.failure(error))
        } else {
          completion?(.success(result))
        }
      }
    }
  }

  /// Clears website data for this web view's ``WKWebsiteDataStore`` (persistent or ephemeral).
  public func clearWebsiteData(
    types: Set<String>,
    since: Date = .distantPast,
    completion: (@MainActor () -> Void)? = nil
  ) {
    wkWebView.configuration.websiteDataStore.removeData(ofTypes: types, modifiedSince: since) {
      Task { @MainActor in
        completion?()
      }
    }
  }

  /// Clears the **default persistent** ``WKWebsiteDataStore`` only.
  ///
  /// For ephemeral sessions, call ``clearWebsiteData(types:since:completion:)`` on the
  /// ``FKWebView`` instance so the matching non-persistent store is cleared.
  public static func clearWebsiteData(
    types: Set<String>,
    since: Date = .distantPast,
    completion: (@MainActor () -> Void)? = nil
  ) {
    WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: since) {
      Task { @MainActor in
        completion?()
      }
    }
  }

  // MARK: - Internal hooks (coordinator)

  func loadNavigationRequest(_ request: URLRequest) {
    load(request)
  }

  func handleStateChange(_ state: FKWebViewLoadingState) {
    setState(state)
  }

  func updateProgress(_ progress: Double) {
    let isLoading: Bool
    if case .loading = loadingState { isLoading = true } else { isLoading = false }
    progressPresenter.updateProgress(progress, isLoading: isLoading)
  }

  func handleLoadFinished() {
    progressPresenter.hideForCompletion()
    emptyStatePresenter.hide()
    endRefreshingIfNeeded()
    updateChrome()
  }

  func handleLoadFailure(error: FKWebViewError, url: URL?) {
    progressPresenter.hideForFailure()
    emptyStatePresenter.showError(
      error,
      url: url,
      configuration: configuration.error,
      onRetry: { [weak self] in self?.reload() },
      onOpenInSafari: { UIApplication.shared.open($0) }
    )
    bringOverlayViewsToFront()
    endRefreshingIfNeeded()
    updateChrome()
  }

  func handleLoadCancelled() {
    progressPresenter.hideForFailure()
    endRefreshingIfNeeded()
    updateChrome()
  }

  func showOfflineOverlay() {
    loadingState = .failed(.notConnectedToInternet)
    progressPresenter.hideForFailure()
    emptyStatePresenter.showOffline(configuration: configuration.error) { [weak self] in
      self?.reload()
    }
    updateChrome()
  }

  func hideEmptyStateOverlay() {
    emptyStatePresenter.hide()
  }

  func handlePolicyDenial(error: FKWebViewError, url: URL?) {
    loadingState = .failed(error)
    progressPresenter.hideForFailure()
    emptyStatePresenter.showError(
      error,
      url: url,
      configuration: configuration.error,
      onRetry: { [weak self] in self?.reload() },
      onOpenInSafari: { UIApplication.shared.open($0) }
    )
    bringOverlayViewsToFront()
    delegate?.webView(self, didChangeState: loadingState)
    delegate?.webView(self, didFail: error)
    callbacks.onStateChange?(loadingState)
    callbacks.onFail?(error)
    updateChrome()
  }

  private func setState(_ state: FKWebViewLoadingState) {
    loadingState = state
    updateChrome()
  }

  // MARK: - Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    bringOverlayViewsToFront()
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    guard window != nil else { return }
    if panelPresentingViewController == nil {
      panelPresentingViewController = fk_nearestViewController
    }
    coordinator.ensureUIDelegate(on: wkWebView)
  }

  private func bringOverlayViewsToFront() {
    bringSubviewToFront(progressPresenter.view)
    if let overlay = fk_emptyStateView, fk_isEmptyStateOverlayVisible {
      bringSubviewToFront(overlay)
    }
  }

  // MARK: - Private setup

  private func setupHierarchy() {
    chromeView.delegate = self
    chromeView.translatesAutoresizingMaskIntoConstraints = false
    wkWebView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(chromeView)
    addSubview(wkWebView)
    addLayoutGuide(contentLayoutGuide)

    progressPresenter.install(in: self)

    let chromeHeight = chromeHeightConstraint ?? chromeView.heightAnchor.constraint(equalToConstant: 0)
    chromeHeightConstraint = chromeHeight

    NSLayoutConstraint.activate([
      chromeView.topAnchor.constraint(equalTo: topAnchor),
      chromeView.leadingAnchor.constraint(equalTo: leadingAnchor),
      chromeView.trailingAnchor.constraint(equalTo: trailingAnchor),
      chromeHeight,

      contentLayoutGuide.topAnchor.constraint(equalTo: chromeView.bottomAnchor),
      contentLayoutGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentLayoutGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

      wkWebView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
      wkWebView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
      wkWebView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
      wkWebView.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
    ])

    accessibilityTraits.insert(.updatesFrequently)
  }

  private func applyConfiguration() {
    coordinator.updateConfiguration(configuration)
    syncCoordinatorWiring()

    progressPresenter.progressConfiguration = configuration.presentation.progress
    chromeView.apply(mode: configuration.presentation.chrome)
    updateChromeLayout()
    updateProgressLayout()
    wkWebView.allowsBackForwardNavigationGestures = configuration.interaction.allowsBackForwardGestures

    if let scrollBounces = configuration.interaction.scrollBounces {
      wkWebView.scrollView.bounces = scrollBounces
    }

    wkWebView.allowsLinkPreview = configuration.interaction.previewingEnabled

    configureRefreshControl()
    updateChrome()
    updateAccessibility()
  }

  private func configureRefreshControl() {
    if configuration.interaction.pullToRefreshEnabled {
      if refreshControl == nil {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        wkWebView.scrollView.refreshControl = control
        refreshControl = control
      }
    } else {
      wkWebView.scrollView.refreshControl = nil
      refreshControl = nil
    }
  }

  private func beginLoadPreflight() -> Bool {
    if coordinator.shouldPreflightOffline() {
      showOfflineOverlay()
      return false
    }
    emptyStatePresenter.hide()
    loadingState = .loading(progress: nil)
    progressPresenter.updateProgress(0, isLoading: true)
    updateChrome()
    return true
  }

  private func enrichedRequest(from request: URLRequest) -> URLRequest {
    var enriched = request
    enriched.cachePolicy = requestOptions.cachePolicy
    enriched.timeoutInterval = requestOptions.timeoutInterval
    for (key, value) in requestOptions.additionalHeaders {
      enriched.setValue(value, forHTTPHeaderField: key)
    }
    return enriched
  }

  private func syncCoordinatorWiring() {
    coordinator.delegate = delegate
    coordinator.uiDelegate = uiDelegate
    coordinator.javascriptHandler = javascriptHandler
  }

  private func updateChromeLayout() {
    let showsToolbar: Bool
    switch configuration.presentation.chrome {
    case .compactToolbar:
      showsToolbar = true
    case .none, .custom:
      showsToolbar = false
    }
    chromeHeightConstraint?.constant = showsToolbar ? 56 : 0
  }

  private func updateProgressLayout() {
    progressTopConstraint?.isActive = false
    let progressView = progressPresenter.view

    switch configuration.presentation.progress.presentation {
    case .none:
      break
    case .linearBarTopSafeArea:
      progressTopConstraint = progressView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
    case .linearBar, .indeterminateUntilFirstPaint:
      progressTopConstraint = progressView.topAnchor.constraint(equalTo: chromeView.bottomAnchor)
    }
    progressTopConstraint?.isActive = configuration.presentation.progress.presentation != .none
  }

  private func updateChrome() {
    let isLoading: Bool
    if case .loading = loadingState { isLoading = true } else { isLoading = false }
    chromeView.update(canGoBack: canGoBack, canGoForward: canGoForward, isLoading: isLoading)
  }

  private func updateAccessibility() {
    if let label = configuration.accessibility.containerLabel {
      accessibilityLabel = label
    } else {
      accessibilityLabel = FKUIKitI18n.string("fkuikit.webview.accessibility.container")
    }
  }

  private func endRefreshingIfNeeded() {
    refreshControl?.endRefreshing()
  }

  @objc private func handleRefresh() {
    reload()
  }
}

// MARK: - Chrome delegate

extension FKWebView: FKWebChromeViewDelegate {
  func chromeViewDidTapBack(_ chromeView: FKWebChromeView) {
    _ = goBack()
  }

  func chromeViewDidTapForward(_ chromeView: FKWebChromeView) {
    _ = goForward()
  }

  func chromeViewDidTapReloadOrStop(_ chromeView: FKWebChromeView) {
    if case .loading = loadingState {
      stopLoading()
    } else {
      reload()
    }
  }

  func chromeViewDidTapClose(_ chromeView: FKWebChromeView) {
    callbacks.onClose?()
  }
}
