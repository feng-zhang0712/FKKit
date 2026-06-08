import FKCoreKit
import UIKit
import WebKit

// MARK: - Presentation

/// Chrome, progress bar, and status-bar presentation for ``FKWebView``.
public struct FKWebPresentationConfiguration: Sendable, Equatable {
  public var chrome: FKWebChromeMode
  public var progress: FKWebProgressConfiguration
  public var updatesNavigationTitle: Bool
  public var statusBarStyle: UIStatusBarStyle

  public init(
    chrome: FKWebChromeMode = .none,
    progress: FKWebProgressConfiguration = FKWebProgressConfiguration(),
    updatesNavigationTitle: Bool = true,
    statusBarStyle: UIStatusBarStyle = .default
  ) {
    self.chrome = chrome
    self.progress = progress
    self.updatesNavigationTitle = updatesNavigationTitle
    self.statusBarStyle = statusBarStyle
  }
}

/// Progress bar wiring for ``FKWebView``.
public struct FKWebProgressConfiguration: Sendable, Equatable {
  public var presentation: FKWebProgressPresentation
  public var hidesWhenComplete: Bool
  public var completeHideDelay: TimeInterval

  public init(
    presentation: FKWebProgressPresentation = .linearBar,
    hidesWhenComplete: Bool = true,
    completeHideDelay: TimeInterval = 0.15
  ) {
    self.presentation = presentation
    self.hidesWhenComplete = hidesWhenComplete
    self.completeHideDelay = completeHideDelay
  }
}

// MARK: - Interaction

/// Scroll, gesture, and refresh behavior.
public struct FKWebInteractionConfiguration: Sendable, Equatable {
  public var allowsBackForwardGestures: Bool
  public var pullToRefreshEnabled: Bool
  public var scrollBounces: Bool?
  public var previewingEnabled: Bool

  public init(
    allowsBackForwardGestures: Bool = true,
    pullToRefreshEnabled: Bool = false,
    scrollBounces: Bool? = nil,
    previewingEnabled: Bool = false
  ) {
    self.allowsBackForwardGestures = allowsBackForwardGestures
    self.pullToRefreshEnabled = pullToRefreshEnabled
    self.scrollBounces = scrollBounces
    self.previewingEnabled = previewingEnabled
  }
}

// MARK: - Navigation

/// Navigation policy and domain rules.
public struct FKWebNavigationConfiguration: Sendable, Equatable {
  public var policy: FKWebNavigationPolicy

  public init(policy: FKWebNavigationPolicy = FKWebNavigationPolicy()) {
    self.policy = policy
  }
}

// MARK: - JavaScript

/// User-script and bridge registration (handler names only; delivery via delegate / callbacks).
public struct FKWebJavaScriptConfiguration: Sendable, Equatable {
  public var bridge: FKJavaScriptBridge
  public var userScripts: [FKUserScriptRegistration]

  public init(
    bridge: FKJavaScriptBridge = FKJavaScriptBridge(),
    userScripts: [FKUserScriptRegistration] = []
  ) {
    self.bridge = bridge
    self.userScripts = userScripts
  }
}

// MARK: - Security

/// Security defaults for file access and data store selection.
public struct FKWebSecurityConfiguration: Sendable, Equatable {
  public var blocksFileURLNavigationFromRemotePages: Bool
  public var allowsJavaScriptOpenWindowsAutomatically: Bool
  public var usesEphemeralWebsiteDataStore: Bool

  public init(
    blocksFileURLNavigationFromRemotePages: Bool = true,
    allowsJavaScriptOpenWindowsAutomatically: Bool = false,
    usesEphemeralWebsiteDataStore: Bool = false
  ) {
    self.blocksFileURLNavigationFromRemotePages = blocksFileURLNavigationFromRemotePages
    self.allowsJavaScriptOpenWindowsAutomatically = allowsJavaScriptOpenWindowsAutomatically
    self.usesEphemeralWebsiteDataStore = usesEphemeralWebsiteDataStore
  }
}

// MARK: - Reachability

/// Offline preflight and optional reachability observation.
public struct FKWebReachabilityConfiguration: Sendable, Equatable {
  public var showsOfflineEmptyStateBeforeLoad: Bool
  public var observesReachabilityChanges: Bool

  public init(
    showsOfflineEmptyStateBeforeLoad: Bool = false,
    observesReachabilityChanges: Bool = false
  ) {
    self.showsOfflineEmptyStateBeforeLoad = showsOfflineEmptyStateBeforeLoad
    self.observesReachabilityChanges = observesReachabilityChanges
  }
}

// MARK: - Error presentation

/// Error overlay behavior.
public struct FKWebErrorConfiguration: Sendable, Equatable {
  public var showsEmptyStateOverlay: Bool
  public var showsOpenInSafariAction: Bool

  public init(
    showsEmptyStateOverlay: Bool = true,
    showsOpenInSafariAction: Bool = true
  ) {
    self.showsEmptyStateOverlay = showsEmptyStateOverlay
    self.showsOpenInSafariAction = showsOpenInSafariAction
  }
}

// MARK: - Accessibility

/// Container accessibility overrides.
public struct FKWebAccessibilityConfiguration: Sendable, Equatable {
  public var containerLabel: String?

  public init(containerLabel: String? = nil) {
    self.containerLabel = containerLabel
  }
}

// MARK: - Aggregate configuration

/// Sendable, equatable policy and presentation for ``FKWebView``.
public struct FKWebViewConfiguration: Sendable, Equatable {
  public var presentation: FKWebPresentationConfiguration
  public var interaction: FKWebInteractionConfiguration
  public var navigation: FKWebNavigationConfiguration
  public var javascript: FKWebJavaScriptConfiguration
  public var security: FKWebSecurityConfiguration
  public var reachability: FKWebReachabilityConfiguration
  public var error: FKWebErrorConfiguration
  public var accessibility: FKWebAccessibilityConfiguration

  public init(
    presentation: FKWebPresentationConfiguration = FKWebPresentationConfiguration(),
    interaction: FKWebInteractionConfiguration = FKWebInteractionConfiguration(),
    navigation: FKWebNavigationConfiguration = FKWebNavigationConfiguration(),
    javascript: FKWebJavaScriptConfiguration = FKWebJavaScriptConfiguration(),
    security: FKWebSecurityConfiguration = FKWebSecurityConfiguration(),
    reachability: FKWebReachabilityConfiguration = FKWebReachabilityConfiguration(),
    error: FKWebErrorConfiguration = FKWebErrorConfiguration(),
    accessibility: FKWebAccessibilityConfiguration = FKWebAccessibilityConfiguration()
  ) {
    self.presentation = presentation
    self.interaction = interaction
    self.navigation = navigation
    self.javascript = javascript
    self.security = security
    self.reachability = reachability
    self.error = error
    self.accessibility = accessibility
  }
}

// MARK: - WK configuration builder

/// Non-equatable escape hatch applied once when the internal `WKWebView` is created.
public struct FKWebViewWKConfigurationBuilder: Sendable {
  public var apply: @Sendable (WKWebViewConfiguration) -> Void

  public init(apply: @escaping @Sendable (WKWebViewConfiguration) -> Void = { _ in }) {
    self.apply = apply
  }
}

/// Runtime context that cannot live inside equatable ``FKWebViewConfiguration``.
public struct FKWebViewConfigurationContext: @unchecked Sendable {
  public var wkConfigurationBuilder: FKWebViewWKConfigurationBuilder
  public var reachabilityProvider: NetworkStatusProviding?

  public init(
    wkConfigurationBuilder: FKWebViewWKConfigurationBuilder = FKWebViewWKConfigurationBuilder(),
    reachabilityProvider: NetworkStatusProviding? = nil
  ) {
    self.wkConfigurationBuilder = wkConfigurationBuilder
    self.reachabilityProvider = reachabilityProvider
  }
}

// MARK: - Presets

/// Factory presets for common hybrid flows.
public enum FKWebViewDefaults {
  /// Baseline embeddable web view: linear progress, no chrome.
  public static var defaultConfiguration: FKWebViewConfiguration {
    FKWebViewConfiguration()
  }

  /// In-app browser: compact toolbar and `target="_blank"` opens externally.
  public static func inAppBrowser() -> FKWebViewConfiguration {
    var configuration = FKWebViewConfiguration()
    configuration.presentation.chrome = .compactToolbar(showsCloseButton: true)
    configuration.navigation.policy.targetBlank = .openExternally
    return configuration
  }

  /// Ephemeral OAuth / login session with non-persistent website data.
  public static func ephemeralAuth(customSchemes: [String: FKWebCustomSchemePolicy] = [:]) -> FKWebViewConfiguration {
    var configuration = FKWebViewConfiguration()
    configuration.security.usesEphemeralWebsiteDataStore = true
    configuration.presentation.chrome = .compactToolbar(showsCloseButton: true)
    configuration.reachability.showsOfflineEmptyStateBeforeLoad = true
    if !customSchemes.isEmpty {
      configuration.navigation.policy.customSchemes = customSchemes
    }
    return configuration
  }
}
