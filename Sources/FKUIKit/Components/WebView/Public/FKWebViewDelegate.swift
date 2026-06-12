import WebKit

// MARK: - Delegate

/// Optional navigation and lifecycle callbacks for ``FKWebView``.
@MainActor
public protocol FKWebViewDelegate: AnyObject {
  func webView(_ webView: FKWebView, didChangeState state: FKWebViewLoadingState)
  func webView(_ webView: FKWebView, didCommit url: URL?)
  func webView(_ webView: FKWebView, didFinish url: URL?)
  func webView(_ webView: FKWebView, didFail error: FKWebViewError)
  func webView(
    _ webView: FKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    defaultDisposition: FKWebNavigationActionDisposition
  ) -> FKWebNavigationActionDisposition
  func webView(_ webView: FKWebView, didReceiveOAuthRedirect url: URL)
  func webView(_ webView: FKWebView, didReceive message: FKJavaScriptMessage)
  func webView(
    _ webView: FKWebView,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  )
}

public extension FKWebViewDelegate {
  func webView(_ webView: FKWebView, didChangeState state: FKWebViewLoadingState) {}
  func webView(_ webView: FKWebView, didCommit url: URL?) {}
  func webView(_ webView: FKWebView, didFinish url: URL?) {}
  func webView(_ webView: FKWebView, didFail error: FKWebViewError) {}
  func webView(
    _ webView: FKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    defaultDisposition: FKWebNavigationActionDisposition
  ) -> FKWebNavigationActionDisposition {
    defaultDisposition
  }
  func webView(_ webView: FKWebView, didReceiveOAuthRedirect url: URL) {}
  func webView(_ webView: FKWebView, didReceive message: FKJavaScriptMessage) {}
  func webView(
    _ webView: FKWebView,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    completionHandler(.performDefaultHandling, nil)
  }
}

// MARK: - JavaScript handling

/// Dedicated protocol for JavaScript bridge delivery.
@MainActor
public protocol FKWebViewJavaScriptHandling: AnyObject {
  func webView(_ webView: FKWebView, didReceive message: FKJavaScriptMessage)
}

// MARK: - UI delegate

/// Overrides for `WKUIDelegate` JavaScript alert, confirm, and prompt panels.
@MainActor
public protocol FKWebViewUIDelegate: AnyObject {
  func webView(
    _ webView: FKWebView,
    runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping () -> Void
  ) -> Bool

  func webView(
    _ webView: FKWebView,
    runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool

  func webView(
    _ webView: FKWebView,
    runJavaScriptTextInputPanelWithPrompt prompt: String,
    defaultText: String?,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping (String?) -> Void
  ) -> Bool
}

public extension FKWebViewUIDelegate {
  func webView(
    _ webView: FKWebView,
    runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping () -> Void
  ) -> Bool { false }

  func webView(
    _ webView: FKWebView,
    runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping (Bool) -> Void
  ) -> Bool { false }

  func webView(
    _ webView: FKWebView,
    runJavaScriptTextInputPanelWithPrompt prompt: String,
    defaultText: String?,
    initiatedByFrame frame: WKFrameInfo,
    completionHandler: @escaping (String?) -> Void
  ) -> Bool { false }
}

// MARK: - Callbacks

/// Closure-based mirror of ``FKWebViewDelegate`` for SwiftUI and lightweight hosts.
///
/// Assign the whole struct (`webView.callbacks = …`) or set individual closures in place;
/// the navigation coordinator always reads the latest values from ``FKWebView/callbacks``.
public struct FKWebViewCallbacks: @unchecked Sendable {
  public var onStateChange: (@MainActor (FKWebViewLoadingState) -> Void)?
  public var onCommit: (@MainActor (URL?) -> Void)?
  public var onFinish: (@MainActor (URL?) -> Void)?
  public var onFail: (@MainActor (FKWebViewError) -> Void)?
  public var onDecidePolicy: (
    @MainActor (WKNavigationAction, FKWebNavigationActionDisposition) -> FKWebNavigationActionDisposition
  )?
  public var onOAuthRedirect: (@MainActor (URL) -> Void)?
  public var onJavaScriptMessage: (@MainActor (FKJavaScriptMessage) -> Void)?
  public var onClose: (@MainActor () -> Void)?
  /// Invoked when a URL is handed off to `UIApplication.shared.open` (mailto, tel, external links).
  public var onOpenExternally: (@MainActor (URL) -> Void)?
  /// Invoked for TLS / client-certificate challenges when no ``FKWebViewDelegate`` is set.
  public var onAuthenticationChallenge: (
    @MainActor (
      URLAuthenticationChallenge,
      @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) -> Void
  )?

  public init(
    onStateChange: (@MainActor (FKWebViewLoadingState) -> Void)? = nil,
    onCommit: (@MainActor (URL?) -> Void)? = nil,
    onFinish: (@MainActor (URL?) -> Void)? = nil,
    onFail: (@MainActor (FKWebViewError) -> Void)? = nil,
    onDecidePolicy: (
      @MainActor (WKNavigationAction, FKWebNavigationActionDisposition) -> FKWebNavigationActionDisposition
    )? = nil,
    onOAuthRedirect: (@MainActor (URL) -> Void)? = nil,
    onJavaScriptMessage: (@MainActor (FKJavaScriptMessage) -> Void)? = nil,
    onClose: (@MainActor () -> Void)? = nil,
    onOpenExternally: (@MainActor (URL) -> Void)? = nil,
    onAuthenticationChallenge: (
      @MainActor (
        URLAuthenticationChallenge,
        @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
      ) -> Void
    )? = nil
  ) {
    self.onStateChange = onStateChange
    self.onCommit = onCommit
    self.onFinish = onFinish
    self.onFail = onFail
    self.onDecidePolicy = onDecidePolicy
    self.onOAuthRedirect = onOAuthRedirect
    self.onJavaScriptMessage = onJavaScriptMessage
    self.onClose = onClose
    self.onOpenExternally = onOpenExternally
    self.onAuthenticationChallenge = onAuthenticationChallenge
  }
}
