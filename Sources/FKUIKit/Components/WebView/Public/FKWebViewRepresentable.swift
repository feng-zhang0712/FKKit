#if canImport(SwiftUI)
import SwiftUI

/// SwiftUI wrapper for ``FKWebView`` that loads a bound URL without redundant reload loops.
public struct FKWebViewRepresentable: UIViewRepresentable {
  public var url: URL?
  public var configuration: FKWebViewConfiguration
  public var configurationContext: FKWebViewConfigurationContext
  public var callbacks: FKWebViewCallbacks

  public init(
    url: URL? = nil,
    configuration: FKWebViewConfiguration = FKWebViewDefaults.defaultConfiguration,
    configurationContext: FKWebViewConfigurationContext = FKWebViewConfigurationContext(),
    callbacks: FKWebViewCallbacks = FKWebViewCallbacks()
  ) {
    self.url = url
    self.configuration = configuration
    self.configurationContext = configurationContext
    self.callbacks = callbacks
  }

  public func makeUIView(context: Context) -> FKWebView {
    let webView = FKWebView(configuration: configuration, context: configurationContext)
    webView.callbacks = callbacks
    if let url {
      webView.load(url)
      context.coordinator.lastLoadedURL = url
    }
    return webView
  }

  public func updateUIView(_ webView: FKWebView, context: Context) {
    webView.configuration = configuration
    webView.callbacks = callbacks

    guard let url else { return }
    guard context.coordinator.lastLoadedURL != url else { return }
    context.coordinator.lastLoadedURL = url
    webView.load(url)
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  public final class Coordinator {
    var lastLoadedURL: URL?
  }
}
#endif
