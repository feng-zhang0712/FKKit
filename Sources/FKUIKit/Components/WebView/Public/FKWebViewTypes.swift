import Foundation
import WebKit

// MARK: - Loading state

/// Loading lifecycle for ``FKWebView``.
public enum FKWebViewLoadingState: Equatable, Sendable {
  /// No active navigation.
  case idle
  /// Navigation in progress; `progress` is `nil` for indeterminate presentation.
  case loading(progress: Double?)
  /// Last navigation finished successfully.
  case loaded
  /// Last navigation failed with a mapped ``FKWebViewError``.
  case failed(FKWebViewError)
}

// MARK: - Errors

/// Normalized web-view failure surfaced to hosts and empty-state overlays.
public enum FKWebViewError: Equatable, Sendable {
  case notConnectedToInternet
  case timedOut
  case secureConnectionFailed
  case serverError(statusCode: Int)
  case cancelled
  case webKit(code: Int, domain: String)
  case unreachableHost
  case custom(message: String)
  case hostDenied
}

// MARK: - Request options

/// Per-load request customization. Header values are never logged by FKWebView internals.
public struct FKWebViewRequestOptions: Sendable, Equatable {
  public var additionalHeaders: [String: String]
  public var cachePolicy: URLRequest.CachePolicy
  public var timeoutInterval: TimeInterval

  public init(
    additionalHeaders: [String: String] = [:],
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60
  ) {
    self.additionalHeaders = additionalHeaders
    self.cachePolicy = cachePolicy
    self.timeoutInterval = timeoutInterval
  }
}

// MARK: - Navigation disposition

/// Host-facing result of navigation policy evaluation.
public enum FKWebNavigationActionDisposition: Sendable, Equatable {
  case allow
  case cancel
  case openExternally(URL)
  /// Reserved: host may return this from policy overrides; FKWebView currently cancels the navigation.
  case download(URL)
}

// MARK: - Navigation policy

/// Policy for `http` / `https` navigations.
public enum FKWebHTTPPolicy: Sendable, Equatable {
  case allowAll
  case domainList(FKWebDomainListPolicy)
}

/// Host allow / deny / external-browser lists for HTTPS navigations.
public struct FKWebDomainListPolicy: Sendable, Equatable {
  /// `nil` allows all HTTPS hosts (still subject to ATS).
  public var allowedHosts: [String]?
  public var deniedHosts: [String]
  /// Matching hosts open in the system browser instead of in-app.
  public var externalHosts: [String]

  public init(
    allowedHosts: [String]? = nil,
    deniedHosts: [String] = [],
    externalHosts: [String] = []
  ) {
    self.allowedHosts = allowedHosts
    self.deniedHosts = deniedHosts
    self.externalHosts = externalHosts
  }
}

/// Behavior for `target="_blank"` / `targetFrame == nil` navigations.
public enum FKWebTargetBlankPolicy: Sendable, Equatable {
  case loadInPlace
  case openExternally
  case cancel
}

/// Behavior for registered custom URL schemes (for example OAuth redirects).
public enum FKWebCustomSchemePolicy: Sendable, Equatable {
  case cancel
  /// Cancels web navigation and notifies the host via OAuth redirect callbacks.
  case notifyHost
}

/// Behavior for `mailto:` and `tel:` links.
public enum FKWebSystemURLPolicy: Sendable, Equatable {
  case openExternally
  case cancel
}

/// Aggregate navigation policy applied in ``FKWebNavigationCoordinator``.
public struct FKWebNavigationPolicy: Sendable, Equatable {
  public var httpHTTPS: FKWebHTTPPolicy
  public var customSchemes: [String: FKWebCustomSchemePolicy]
  public var targetBlank: FKWebTargetBlankPolicy
  public var mailtoTel: FKWebSystemURLPolicy

  public init(
    httpHTTPS: FKWebHTTPPolicy = .allowAll,
    customSchemes: [String: FKWebCustomSchemePolicy] = [:],
    targetBlank: FKWebTargetBlankPolicy = .loadInPlace,
    mailtoTel: FKWebSystemURLPolicy = .openExternally
  ) {
    self.httpHTTPS = httpHTTPS
    self.customSchemes = customSchemes
    self.targetBlank = targetBlank
    self.mailtoTel = mailtoTel
  }
}

// MARK: - Progress presentation

/// How loading progress is rendered above the web content.
public enum FKWebProgressPresentation: Sendable, Equatable {
  case none
  case linearBar
  case linearBarTopSafeArea
  case indeterminateUntilFirstPaint
}

// MARK: - Chrome

/// Toolbar presentation mode for embedded web chrome.
public enum FKWebChromeMode: Sendable, Equatable {
  case none
  case compactToolbar(showsCloseButton: Bool)
  /// Reserved for future pluggable chrome providers; currently behaves like ``none``.
  case custom(providerID: String)
}

// MARK: - Error mapping

enum FKWebViewErrorMapper {
  static func map(_ error: Error, httpStatusCode: Int? = nil) -> FKWebViewError {
    if let status = httpStatusCode, (400 ... 599).contains(status) {
      return .serverError(statusCode: status)
    }

    let nsError = error as NSError
    if nsError.domain == NSURLErrorDomain {
      switch nsError.code {
      case NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed:
        return .notConnectedToInternet
      case NSURLErrorTimedOut:
        return .timedOut
      case NSURLErrorCancelled:
        return .cancelled
      case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateUntrusted,
        NSURLErrorServerCertificateHasBadDate, NSURLErrorServerCertificateNotYetValid:
        return .secureConnectionFailed
      case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
        return .unreachableHost
      default:
        return .webKit(code: nsError.code, domain: nsError.domain)
      }
    }

    return .webKit(code: nsError.code, domain: nsError.domain)
  }
}

enum FKWebHostPolicyEvaluator {
  static func hostMatches(_ host: String, patterns: [String]) -> Bool {
    let lowered = host.lowercased()
    for pattern in patterns {
      let candidate = pattern.lowercased()
      if lowered == candidate { return true }
      if lowered.hasSuffix(".\(candidate)") { return true }
    }
    return false
  }

  static func evaluateHTTP(url: URL, policy: FKWebHTTPPolicy) -> FKWebNavigationActionDisposition {
    guard let host = url.host?.lowercased() else { return .allow }

    switch policy {
    case .allowAll:
      return .allow
    case .domainList(let list):
      if hostMatches(host, patterns: list.deniedHosts) {
        return .cancel
      }
      if hostMatches(host, patterns: list.externalHosts) {
        return .openExternally(url)
      }
      if let allowed = list.allowedHosts {
        return hostMatches(host, patterns: allowed) ? .allow : .cancel
      }
      return .allow
    }
  }
}
