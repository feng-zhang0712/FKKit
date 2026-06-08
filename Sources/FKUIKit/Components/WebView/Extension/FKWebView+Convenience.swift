import Foundation

public extension FKWebView {
  /// Loads a URL with explicit per-load options.
  func load(_ url: URL, options: FKWebViewRequestOptions) {
    let previous = requestOptions
    requestOptions = options
    load(url)
    requestOptions = previous
  }

  /// Loads a request with explicit per-load options.
  func load(_ request: URLRequest, options: FKWebViewRequestOptions) {
    let previous = requestOptions
    requestOptions = options
    load(request)
    requestOptions = previous
  }
}

public extension FKWebViewConfiguration {
  /// Registers OAuth / custom-scheme handlers on the navigation policy.
  func registerCustomSchemes(_ schemes: [String], policy: FKWebCustomSchemePolicy = .notifyHost) -> Self {
    var copy = self
    for scheme in schemes {
      copy.navigation.policy.customSchemes[scheme.lowercased()] = policy
    }
    return copy
  }
}
