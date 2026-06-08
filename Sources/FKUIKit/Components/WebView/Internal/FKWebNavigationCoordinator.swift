import FKCoreKit
import UIKit
import WebKit

/// Forwards `WKScriptMessageHandler` callbacks to the navigation coordinator on the main actor.
final class FKWebScriptMessageProxy: NSObject, WKScriptMessageHandler {
  unowned var owner: FKWebNavigationCoordinator!

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    Task { @MainActor [weak owner] in
      owner?.handleScriptMessage(message)
    }
  }
}

/// Forwards `WKUIDelegate` callbacks to the navigation coordinator on the main actor.
@MainActor
@objcMembers
final class FKWebUIDelegateProxy: NSObject, WKUIDelegate {
  unowned var owner: FKWebNavigationCoordinator!

  func webView(
    _ webView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction,
    windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    owner.handleCreateWebView(configuration: configuration, navigationAction: navigationAction)
  }

  func webView(
    _ webView: WKWebView,
    runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping @MainActor () -> Void
  ) {
    owner.handleJavaScriptAlertPanel(
      message: message,
      frame: frame,
      completionHandler: completionHandler
    )
  }

  func webView(
    _ webView: WKWebView,
    runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping @MainActor (Bool) -> Void
  ) {
    owner.handleJavaScriptConfirmPanel(
      message: message,
      frame: frame,
      completionHandler: completionHandler
    )
  }

  func webView(
    _ webView: WKWebView,
    runJavaScriptTextInputPanelWithPrompt prompt: String,
    defaultText: String?,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping @MainActor (String?) -> Void
  ) {
    owner.handleJavaScriptPromptPanel(
      prompt: prompt,
      defaultText: defaultText,
      frame: frame,
      completionHandler: completionHandler
    )
  }
}

@MainActor
final class FKWebNavigationCoordinator: NSObject {
  weak var webView: FKWebView?

  var configuration: FKWebViewConfiguration
  var context: FKWebViewConfigurationContext
  weak var delegate: FKWebViewDelegate?
  weak var uiDelegate: FKWebViewUIDelegate?
  weak var javascriptHandler: FKWebViewJavaScriptHandling?

  private(set) var loadingState: FKWebViewLoadingState = .idle
  private(set) var lastRequest: URLRequest?
  private var registeredHandlerNames: [String] = []
  private var handlerIDByName: [String: String] = [:]
  private let scriptMessageProxy: FKWebScriptMessageProxy
  private let uiDelegateProxy: FKWebUIDelegateProxy
  private weak var attachedWebView: WKWebView?
  private var progressObservation: NSKeyValueObservation?
  private var reachabilityMonitor: FKWebReachabilityMonitor?

  init(configuration: FKWebViewConfiguration, context: FKWebViewConfigurationContext) {
    self.configuration = configuration
    self.context = context
    self.scriptMessageProxy = FKWebScriptMessageProxy()
    self.uiDelegateProxy = FKWebUIDelegateProxy()
    super.init()
    self.scriptMessageProxy.owner = self
    self.uiDelegateProxy.owner = self
    configureReachabilityMonitorIfNeeded()
  }

  func storeLastRequest(_ request: URLRequest) {
    lastRequest = request
  }

  func lastStoredRequest() -> URLRequest? {
    lastRequest
  }

  func makeWKWebViewConfiguration() -> WKWebViewConfiguration {
    let wkConfiguration = WKWebViewConfiguration()
    wkConfiguration.websiteDataStore = configuration.security.usesEphemeralWebsiteDataStore
      ? .nonPersistent()
      : .default()
    wkConfiguration.preferences.javaScriptCanOpenWindowsAutomatically =
      configuration.security.allowsJavaScriptOpenWindowsAutomatically

    wkConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true

    for script in configuration.javascript.userScripts {
      let userScript = WKUserScript(
        source: script.source,
        injectionTime: script.injectionTime,
        forMainFrameOnly: script.forMainFrameOnly
      )
      wkConfiguration.userContentController.addUserScript(userScript)
    }

    registerScriptHandlers(on: wkConfiguration.userContentController)
    context.wkConfigurationBuilder.apply(wkConfiguration)
    return wkConfiguration
  }

  func attach(to wkWebView: WKWebView) {
    attachedWebView = wkWebView
    wkWebView.navigationDelegate = self
    ensureUIDelegate(on: wkWebView)
    progressObservation = wkWebView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
      Task { @MainActor in
        self?.handleEstimatedProgress(webView.estimatedProgress)
      }
    }
  }

  /// Re-applies ``WKUIDelegate`` when WebKit clears it or the view re-enters a window.
  func ensureUIDelegate(on wkWebView: WKWebView) {
    if wkWebView.uiDelegate !== uiDelegateProxy {
      wkWebView.uiDelegate = uiDelegateProxy
    }
  }

  func detach(from wkWebView: WKWebView) {
    progressObservation?.invalidate()
    progressObservation = nil
    if attachedWebView === wkWebView {
      attachedWebView = nil
    }
    wkWebView.navigationDelegate = nil
    wkWebView.uiDelegate = nil
    removeScriptHandlers(from: wkWebView.configuration.userContentController)
  }

  func updateConfiguration(_ configuration: FKWebViewConfiguration) {
    self.configuration = configuration
    configureReachabilityMonitorIfNeeded()
  }

  func isReachable() -> Bool {
    context.reachabilityProvider?.isReachable ?? FKWebReachabilityMonitor.shared.isReachable
  }

  /// Reads live callbacks from ``FKWebView`` so in-place struct mutations stay wired.
  private var currentCallbacks: FKWebViewCallbacks {
    webView?.callbacks ?? FKWebViewCallbacks()
  }

  func shouldPreflightOffline() -> Bool {
    configuration.reachability.showsOfflineEmptyStateBeforeLoad && !isReachable()
  }

  func setState(_ state: FKWebViewLoadingState) {
    loadingState = state
    guard let webView else { return }
    webView.handleStateChange(state)
    delegate?.webView(webView, didChangeState: state)
    currentCallbacks.onStateChange?(state)
  }

  func evaluateDisposition(for navigationAction: WKNavigationAction) -> FKWebNavigationActionDisposition {
    guard let url = navigationAction.request.url else { return .allow }

    if shouldPreflightOffline() {
      webView?.showOfflineOverlay()
      return .cancel
    }

    let scheme = url.scheme?.lowercased() ?? ""

    if scheme == "mailto" || scheme == "tel" {
      switch configuration.navigation.policy.mailtoTel {
      case .openExternally:
        openExternally(url)
        return .cancel
      case .cancel:
        return .cancel
      }
    }

    if let customPolicy = configuration.navigation.policy.customSchemes[scheme] {
      switch customPolicy {
      case .cancel:
        return .cancel
      case .notifyHost:
        notifyOAuthRedirect(url)
        return .cancel
      }
    }

    if navigationAction.targetFrame == nil {
      switch configuration.navigation.policy.targetBlank {
      case .loadInPlace:
        webView?.loadNavigationRequest(navigationAction.request)
        return .cancel
      case .openExternally:
        openExternally(url)
        return .cancel
      case .cancel:
        return .cancel
      }
    }

    if scheme == "http" || scheme == "https" {
      let evaluation = FKWebHostPolicyEvaluator.evaluateHTTP(
        url: url,
        policy: configuration.navigation.policy.httpHTTPS
      )
      switch evaluation {
      case .allow, .openExternally:
        return evaluation
      case .cancel:
        webView?.handlePolicyDenial(error: .hostDenied, url: url)
        return .cancel
      case .download:
        return .cancel
      }
    }

    if scheme == "file",
      configuration.security.blocksFileURLNavigationFromRemotePages,
      isNavigatingFromRemoteDocument {
      return .cancel
    }

    return .allow
  }

  func handleScriptMessage(_ message: WKScriptMessage) {
    guard let webView else { return }
    guard registeredHandlerNames.contains(message.name) else { return }
    let handlerID = handlerIDByName[message.name] ?? message.name
    let payload = FKJavaScriptMessage(
      name: message.name,
      handlerID: handlerID,
      body: FKJavaScriptMessageBodyConverter.convert(message.body)
    )
    delegate?.webView(webView, didReceive: payload)
    javascriptHandler?.webView(webView, didReceive: payload)
    currentCallbacks.onJavaScriptMessage?(payload)
  }

  private func registerScriptHandlers(on controller: WKUserContentController) {
    registeredHandlerNames = []
    handlerIDByName = [:]
    for registration in configuration.javascript.bridge.handlers {
      registeredHandlerNames.append(registration.name)
      handlerIDByName[registration.name] = registration.handlerID
      controller.add(scriptMessageProxy, name: registration.name)
    }
  }

  private func removeScriptHandlers(from controller: WKUserContentController) {
    for name in registeredHandlerNames {
      controller.removeScriptMessageHandler(forName: name)
    }
    registeredHandlerNames = []
    handlerIDByName = [:]
  }

  private func handleEstimatedProgress(_ progress: Double) {
    guard case .loading = loadingState else {
      if progress > 0, progress < 1 {
        setState(.loading(progress: progress))
      }
      return
    }
    setState(.loading(progress: progress))
    webView?.updateProgress(progress)
  }

  private func openExternally(_ url: URL) {
    currentCallbacks.onOpenExternally?(url)
    UIApplication.shared.open(url)
  }

  private var isNavigatingFromRemoteDocument: Bool {
    guard let currentScheme = webView?.url?.scheme?.lowercased() else { return false }
    return currentScheme == "http" || currentScheme == "https"
  }

  private func notifyOAuthRedirect(_ url: URL) {
    guard let webView else { return }
    delegate?.webView(webView, didReceiveOAuthRedirect: url)
    currentCallbacks.onOAuthRedirect?(url)
  }

  private func configureReachabilityMonitorIfNeeded() {
    reachabilityMonitor?.stop()
    reachabilityMonitor = nil
    guard configuration.reachability.observesReachabilityChanges else { return }
    let monitor = FKWebReachabilityMonitor.shared
    monitor.onReachabilityChange = { [weak self] isReachable in
      guard let self, isReachable else { return }
      if case .failed(.notConnectedToInternet) = self.loadingState {
        self.webView?.hideEmptyStateOverlay()
      }
    }
    reachabilityMonitor = monitor
  }
}

// MARK: - WKNavigationDelegate

extension FKWebNavigationCoordinator: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    let url = webView.url
    self.webView?.hideEmptyStateOverlay()
    guard let hostWebView = self.webView else { return }
    delegate?.webView(hostWebView, didCommit: url)
    currentCallbacks.onCommit?(url)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    let url = webView.url
    setState(.loaded)
    self.webView?.handleLoadFinished()
    guard let hostWebView = self.webView else { return }
    delegate?.webView(hostWebView, didFinish: url)
    currentCallbacks.onFinish?(url)
  }

  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error
  ) {
    handleNavigationFailure(error: error, url: webView.url)
  }

  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    handleNavigationFailure(error: error, url: webView.url)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    let finalDisposition = resolvedDisposition(for: navigationAction)
    applyDisposition(finalDisposition, navigationAction: navigationAction, decisionHandler: decisionHandler)
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    preferences: WKWebpagePreferences,
    decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void
  ) {
    preferences.allowsContentJavaScript = true
    let finalDisposition = resolvedDisposition(for: navigationAction)
    applyDisposition(finalDisposition, navigationAction: navigationAction) { policy in
      decisionHandler(policy, preferences)
    }
  }

  private func resolvedDisposition(for navigationAction: WKNavigationAction) -> FKWebNavigationActionDisposition {
    let defaultDisposition = evaluateDisposition(for: navigationAction)
    guard let hostWebView = webView else { return defaultDisposition }
    if let delegateDisposition = delegate?.webView(
      hostWebView,
      decidePolicyFor: navigationAction,
      defaultDisposition: defaultDisposition
    ) {
      return delegateDisposition
    }
    if let callback = currentCallbacks.onDecidePolicy {
      return callback(navigationAction, defaultDisposition)
    }
    return defaultDisposition
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationResponse: WKNavigationResponse,
    decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
  ) {
    if let http = navigationResponse.response as? HTTPURLResponse,
      (400 ... 599).contains(http.statusCode) {
      let error = FKWebViewError.serverError(statusCode: http.statusCode)
      setState(.failed(error))
      self.webView?.handleLoadFailure(error: error, url: navigationResponse.response.url)
      if let hostWebView = self.webView {
        delegate?.webView(hostWebView, didFail: error)
      }
      currentCallbacks.onFail?(error)
      decisionHandler(.cancel)
      return
    }
    decisionHandler(.allow)
  }

  func webView(
    _ webView: WKWebView,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    guard let hostWebView = self.webView else {
      completionHandler(.performDefaultHandling, nil)
      return
    }
    if let delegate {
      delegate.webView(hostWebView, didReceive: challenge, completionHandler: completionHandler)
    } else if let callback = currentCallbacks.onAuthenticationChallenge {
      callback(challenge, completionHandler)
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }

  private func applyDisposition(
    _ disposition: FKWebNavigationActionDisposition,
    navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    switch disposition {
    case .allow:
      if navigationAction.request.url != nil {
        lastRequest = navigationAction.request
        setState(.loading(progress: nil))
      }
      decisionHandler(.allow)
    case .cancel:
      decisionHandler(.cancel)
    case .openExternally(let url):
      openExternally(url)
      decisionHandler(.cancel)
    case .download:
      decisionHandler(.cancel)
    }
  }

  private func handleNavigationFailure(error: Error, url: URL?) {
    let mapped = FKWebViewErrorMapper.map(error)
    guard mapped != .cancelled else {
      setState(.idle)
      webView?.handleLoadCancelled()
      return
    }
    setState(.failed(mapped))
    webView?.handleLoadFailure(error: mapped, url: url)
    if let hostWebView = webView {
      delegate?.webView(hostWebView, didFail: mapped)
      currentCallbacks.onFail?(mapped)
    }
  }
}

// MARK: - WKUIDelegate handling

extension FKWebNavigationCoordinator {
  func handleCreateWebView(
    configuration: WKWebViewConfiguration,
    navigationAction: WKNavigationAction
  ) -> WKWebView? {
    switch self.configuration.navigation.policy.targetBlank {
    case .loadInPlace:
      if let url = navigationAction.request.url {
        webView?.loadNavigationRequest(URLRequest(url: url))
      }
    case .openExternally:
      if let url = navigationAction.request.url {
        openExternally(url)
      }
    case .cancel:
      break
    }
    return nil
  }

  func handleJavaScriptAlertPanel(
    message: String,
    frame: WKFrameInfo,
    completionHandler: @escaping () -> Void
  ) {
    if let hostWebView = webView,
      uiDelegate?.webView(
        hostWebView,
        runJavaScriptAlertPanelWithMessage: message,
        initiatedByFrame: frame,
        completionHandler: completionHandler
      ) == true {
      return
    }
    presentAlert(title: nil, message: message, anchor: webView) { completionHandler() }
  }

  func handleJavaScriptConfirmPanel(
    message: String,
    frame: WKFrameInfo,
    completionHandler: @escaping (Bool) -> Void
  ) {
    if let hostWebView = webView,
      uiDelegate?.webView(
        hostWebView,
        runJavaScriptConfirmPanelWithMessage: message,
        initiatedByFrame: frame,
        completionHandler: completionHandler
      ) == true {
      return
    }
    presentConfirm(message: message, anchor: webView, completionHandler: completionHandler)
  }

  func handleJavaScriptPromptPanel(
    prompt: String,
    defaultText: String?,
    frame: WKFrameInfo,
    completionHandler: @escaping (String?) -> Void
  ) {
    if let hostWebView = webView,
      uiDelegate?.webView(
        hostWebView,
        runJavaScriptTextInputPanelWithPrompt: prompt,
        defaultText: defaultText,
        initiatedByFrame: frame,
        completionHandler: completionHandler
      ) == true {
      return
    }
    presentPrompt(
      prompt: prompt,
      defaultText: defaultText,
      anchor: webView,
      completionHandler: completionHandler
    )
  }

  private func presenterViewController(anchor: UIView?) -> UIViewController? {
    if let host = webView?.panelPresentingViewController {
      return host.fk_topMostPresented
    }

    let candidates: [UIView?] = [webView, anchor, attachedWebView]
    for view in candidates.compactMap({ $0 }) {
      if let viewController = view.fk_nearestViewController {
        return viewController.fk_topMostPresented
      }
      if let root = view.window?.rootViewController {
        return root.fk_topMostPresented
      }
    }
    if let root = UIApplication.shared.fk_keyWindow?.rootViewController {
      return root.fk_topMostPresented
    }
    return nil
  }

  private func presentAlert(
    title: String?,
    message: String,
    anchor: UIView?,
    completion: @escaping () -> Void
  ) {
    guard let presenter = presenterViewController(anchor: anchor) else {
      completion()
      return
    }
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.webview.alert.ok"), style: .default) { _ in
      completion()
    })
    presentModal(alert, from: presenter)
  }

  private func presentConfirm(
    message: String,
    anchor: UIView?,
    completionHandler: @escaping (Bool) -> Void
  ) {
    guard let presenter = presenterViewController(anchor: anchor) else {
      completionHandler(false)
      return
    }
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.webview.alert.cancel"), style: .cancel) { _ in
      completionHandler(false)
    })
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.webview.alert.ok"), style: .default) { _ in
      completionHandler(true)
    })
    presentModal(alert, from: presenter)
  }

  private func presentPrompt(
    prompt: String,
    defaultText: String?,
    anchor: UIView?,
    completionHandler: @escaping (String?) -> Void
  ) {
    guard let presenter = presenterViewController(anchor: anchor) else {
      completionHandler(nil)
      return
    }
    let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
    alert.addTextField { field in
      field.text = defaultText
    }
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.webview.alert.cancel"), style: .cancel) { _ in
      completionHandler(nil)
    })
    alert.addAction(UIAlertAction(title: FKUIKitI18n.string("fkuikit.webview.alert.ok"), style: .default) { _ in
      completionHandler(alert.textFields?.first?.text)
    })
    presentModal(alert, from: presenter)
  }

  private func presentModal(_ alert: UIAlertController, from presenter: UIViewController) {
    // Defer presentation to the next run loop. WebKit invokes WKUIDelegate during the
    // user-gesture / script call stack; synchronous present() is often ignored.
    DispatchQueue.main.async {
      let host = presenter.viewIfLoaded?.window != nil
        ? presenter.fk_topMostPresented
        : UIApplication.shared.fk_keyWindow?.rootViewController?.fk_topMostPresented ?? presenter
      host.present(alert, animated: true)
    }
  }
}

// MARK: - Reachability monitor

@MainActor
final class FKWebReachabilityMonitor {
  static let shared = FKWebReachabilityMonitor()

  private let reachability = FKNetworkReachability()
  private var timer: Timer?
  var onReachabilityChange: ((Bool) -> Void)?
  private(set) var isReachable: Bool = true

  private init() {
    isReachable = reachability.isReachable
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      Task { @MainActor in
        guard let self else { return }
        let current = self.reachability.isReachable
        if current != self.isReachable {
          self.isReachable = current
          self.onReachabilityChange?(current)
        }
      }
    }
  }

  func stop() {
    onReachabilityChange = nil
  }
}
