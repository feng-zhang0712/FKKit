# FKWebView — Design Requirements

Implementation guide for FKKit **`FKWebView`**: a production-oriented `WKWebView` wrapper with loading progress, error recovery, navigation chrome, JavaScript bridge, and policy-driven link handling.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.6  
**中文版本:** [FKWebView_DESIGN.zh-CN.md](FKWebView_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Architectural Overview](#4-architectural-overview)
- [5. Module Boundaries](#5-module-boundaries)
- [6. Loading Lifecycle & State Machine](#6-loading-lifecycle--state-machine)
- [7. Navigation API](#7-navigation-api)
- [8. Progress Presentation](#8-progress-presentation)
- [9. Error & Offline Recovery](#9-error--offline-recovery)
- [10. Navigation Chrome & Toolbar](#10-navigation-chrome--toolbar)
- [11. WKWebView Configuration](#11-wkwebview-configuration)
- [12. Navigation Policy & Link Handling](#12-navigation-policy--link-handling)
- [13. JavaScript Bridge](#13-javascript-bridge)
- [14. Cookies, Headers & Authentication](#14-cookies-headers--authentication)
- [15. OAuth & Custom URL Schemes](#15-oauth--custom-url-schemes)
- [16. WKUIDelegate & System Dialogs](#16-wkuidelegate--system-dialogs)
- [17. Security & Privacy](#17-security--privacy)
- [18. Configuration Model](#18-configuration-model)
- [19. Delegate & Callback API](#19-delegate--callback-api)
- [20. FKWebViewController (Optional Host)](#20-fkwebviewcontroller-optional-host)
- [21. SwiftUI Bridge](#21-swiftui-bridge)
- [22. Performance & Memory](#22-performance--memory)
- [23. Accessibility](#23-accessibility)
- [24. Proposed Source Layout](#24-proposed-source-layout)
- [25. FKKitExamples Scenarios](#25-fkkitexamples-scenarios)
- [27. Open Questions](#27-open-questions)
- [28. Revision History](#28-revision-history)

---

## 1. Executive Summary

Hybrid web content — terms of service, help centers, marketing campaigns, payment pages, OAuth login, and in-app FAQ — appears in nearly every consumer iOS app. Raw **`WKWebView`** integration repeatedly reimplements:

- Top loading progress and failure overlays
- Back/forward/close toolbar
- `decidePolicyFor` link routing and `target=_blank` behavior
- JavaScript message handlers with ad-hoc naming
- Safe logging and cookie/header injection documentation

**`FKWebView`** (`Sources/FKUIKit/Components/WebView/`) is a **`UIView`** composition that owns an internal `WKWebView`, coordinates UI state, and integrates **`FKProgressBar`**, **`FKEmptyState`**, **`FKButton`**, and **`FKNetwork`** reachability hints.

| Deliverable | Role |
|-------------|------|
| **`FKWebView`** | Embeddable web container for custom layouts |
| **`FKWebViewController`** (recommended) | `UIViewController` host with optional navigation chrome |
| **`FKWebViewConfiguration`** | Sendable policy + presentation + WK configuration hooks |
| **`FKJavaScriptBridge`** | Typed `WKScriptMessageHandler` registry |

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **80% hybrid screen** out of the box — load URL, show progress, recover from errors.
2. **FKKit-native UX** — reuse existing overlay, progress, and button styling.
3. **Explicit security defaults** — HTTPS-first, opt-in JavaScript handlers, no secret logging.
4. **OAuth-friendly** — redirect interception hooks without forcing a specific SDK.
5. **Injectable `WKWebViewConfiguration`** — cookies, data store, user agent, content blockers (host-provided).
6. **Swift 6 / `@MainActor`** UI surface; background work only inside WebKit callbacks marshaled to main.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Full browser app (tabs, bookmarks, history UI) | Out of scope |
| Content blocker rule compilation | Host supplies `WKContentRuleList` |
| Offline pack / Service Worker management | Host responsibility |
| `SFSafariViewController` wrapper | Document when to use Apple VC instead |
| Desktop user-agent spoofing beyond custom UA string | Host sets UA if needed |
| WebRTC / getUserMedia permission UI beyond WKUIDelegate passthrough | Minimal delegate forwarding v1 |
| File upload `<input type="file">` advanced customization | Forward `WKUIDelegate` runOpenPanel if needed v1.1 |
| tvOS / macOS Catalyst target | iOS 15+ UIKit |

### 2.3 Success Criteria

- [ ] Remote HTTPS page loads with linear progress; error retry works.
- [ ] OAuth redirect example intercepts custom scheme without leaking tokens to logs.
- [ ] JavaScript bridge round-trip demonstrated in Examples.
- [ ] External `https` link opens in Safari when policy says `.externalBrowser`.
- [ ] Security section in README; no API logs cookie/header values.

---

## 3. Background & Problem Statement

### 3.1 Current FKKit state

- **No** `WebKit` usage under `Sources/`.
- **`FKEmptyState`** supports error/empty overlays on any `UIView`.
- **`FKProgressBar`** supports indeterminate and determinate linear progress.
- **`FKNetwork`** / `FKNetworkReachability` provides boolean reachability (optional fast-fail messaging).

### 3.2 Repeated integration pain

| Pain | Impact |
|------|--------|
| Progress bar wired to `estimatedProgress` KVO | Boilerplate in every VC |
| Error `-1009` / SSL failures | Inconsistent retry UX |
| `target=_blank` opens blank webview | Navigation bugs |
| JS bridge name collisions | Production incidents |
| OAuth redirect swallowed by webview | Login failures |
| Logging URLs with tokens | Security leaks |

---

## 4. Architectural Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ FKWebView (UIView, @MainActor)                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ FKWebChromeView (optional toolbar: back/fwd/reload/close) │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ FKWebProgressView (FKProgressBar thin strip)              │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ WKWebView (internal, not leaked as public property v1)    │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ FKEmptyState overlay (error / offline)                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│         FKWebNavigationCoordinator                              │
│           · KVO estimatedProgress                               │
│           · WKNavigationDelegate / UIDelegate forwarding        │
│           · policy engine                                       │
│           · bridge registry                                     │
└─────────────────────────────────────────────────────────────────┘
```

**Optional:** `FKWebViewController` embeds `FKWebView` edge-to-edge and wires navigation item close button.

---

## 5. Module Boundaries

| Concern | FKUIKit WebView | FKCoreKit |
|---------|-----------------|-----------|
| `WKWebView` ownership | Yes | No |
| UI chrome | Yes | No |
| Reachability hint | Integrates | `FKNetworkReachability` optional |
| HTTP client / API auth | No | `FKNetwork` separate |
| Cookie storage policy docs | Yes | — |

**Dependency:** `import WebKit` only inside WebView module. No third-party WebView SDKs.

---

## 6. Loading Lifecycle & State Machine

### 6.1 States

```swift
public enum FKWebViewLoadingState: Equatable, Sendable {
  case idle
  case loading(progress: Double?)   // nil = indeterminate
  case loaded
  case failed(FKWebViewError)
}
```

### 6.2 Transitions

| From | Event | To |
|------|-------|-----|
| idle | `load(url:)` | loading |
| loading | `didFinish` | loaded |
| loading | `didFail` / `didFailProvisional` | failed |
| loading | `estimatedProgress` updates | loading(progress) |
| loaded | new navigation | loading |
| failed | retry | loading |
| any | `stopLoading()` | idle or loaded (document) |

### 6.3 Public load API

```swift
public func load(_ request: URLRequest)
public func load(_ url: URL)
public func loadHTMLString(_ string: String, baseURL: URL?)
public func reload()
public func stopLoading()
public func goBack() -> Bool
public func goForward() -> Bool

public var canGoBack: Bool { get }
public var canGoForward: Bool { get }
public var url: URL? { get }
public var title: String? { get }
```

**Must** cancel previous load semantics follow WebKit; document that `load` while loading replaces navigation.

---

## 7. Navigation API

### 7.1 Request building

```swift
public struct FKWebViewRequestOptions: Sendable, Equatable {
  public var additionalHeaders: [String: String]
  public var cachePolicy: URLRequest.CachePolicy
  public var timeoutInterval: TimeInterval
}
```

**Security:** `additionalHeaders` must never be logged by FKWebView internals.

### 7.2 History navigation

- `goBack()` / `goForward()` return `Bool` indicating action taken.
- Update toolbar button enabled state on `canGoBack` / `canGoForward` KVO or navigation callbacks.

### 7.3 Reload policy

- `reload()` uses `WKWebView.reload()`
- Pull-to-refresh optional via `UIRefreshControl` on scroll view when `configuration.interaction.pullToRefreshEnabled` (default false v1).

---

## 8. Progress Presentation

### 8.1 Modes (`FKWebProgressPresentation`)

| Mode | UI |
|------|-----|
| `.none` | Hidden |
| `.linearBar` | Thin `FKProgressBar` under chrome (default) |
| `.linearBarTopSafeArea` | Pin to top safe area edge |
| `.indeterminateUntilFirstPaint` | Indeterminate until `estimatedProgress > 0` |

### 8.2 Progress mapping

- Bind `WKWebView.estimatedProgress` (0...1) to `FKProgressBar` value.
- Hide bar with fade when progress ≥ 1.0 and `didFinish` (configurable delay, default 0.15s).
- On failure, hide progress immediately.

### 8.3 Configuration

```swift
public struct FKWebProgressConfiguration: Sendable, Equatable {
  public var presentation: FKWebProgressPresentation
  public var progressBar: FKProgressBarConfiguration?  // nil = FKProgressBar defaults
  public var hidesWhenComplete: Bool
  public var completeHideDelay: TimeInterval
}
```

---

## 9. Error & Offline Recovery

### 9.1 Error model

```swift
public enum FKWebViewError: Equatable, Sendable {
  case notConnectedToInternet
  case timedOut
  case secureConnectionFailed
  case serverError(statusCode: Int)
  case cancelled
  case webKit(code: Int, domain: String)  // wrapped URLError / WKError code
  case unreachableHost
  case custom(message: String)
}
```

Map from `NSError` in navigation delegate with documented code table in README.

### 9.2 Empty state overlay

On `failed` when `configuration.error.showsEmptyStateOverlay == true` (default **true**):

- Build `FKEmptyStateConfiguration` phase `.error` with:
  - Title/message from error kind (localized templates in `FKUIKitI18n`)
  - Primary action **Retry** → `reload()` or re-issue last request
  - Secondary action **Open in Safari** when URL is `http(s)` (config flag)

### 9.3 Offline preflight

When `configuration.reachability.showsOfflineEmptyStateBeforeLoad == true` and `FKNetworkReachability.isReachable == false`:

- Skip load; show offline empty state immediately with retry when reachability changes (optional observer token).

### 9.4 SSL / certificate errors

- Default: show error overlay; do **not** auto-accept invalid certs (no public bypass API v1).
- Host may implement `FKWebViewDelegate` authentication challenge handler for corporate pinning flows (advanced; document risk).

---

## 10. Navigation Chrome & Toolbar

### 10.1 Chrome modes (`FKWebChromeMode`)

| Mode | UI |
|------|-----|
| `.none` | Web content only |
| `.compactToolbar` | Back, forward, reload, optional close (default for `FKWebViewController`) |
| `.custom(providerID:)` | Host registers custom toolbar view |

### 10.2 Default toolbar items

| Item | Behavior |
|------|----------|
| Back | `goBack()`; disabled when !canGoBack |
| Forward | `goForward()` |
| Reload/Stop | toggles by loading state |
| Close | optional; calls `onClose` callback (does not dismiss VC automatically) |

Use **`FKButton`** styling when feasible for visual consistency; v1 may use `UIBarButtonItem` with FK appearance tokens.

### 10.3 Title presentation

- `FKWebViewController` may set `navigationItem.title` from `webView.title` on `didFinish` when `configuration.chrome.updatesNavigationTitle == true`.

---

## 11. WKWebView Configuration

### 11.1 Injection pattern

```swift
public struct FKWebViewConfiguration: Sendable, Equatable {
  public var presentation: FKWebPresentationConfiguration
  public var interaction: FKWebInteractionConfiguration
  public var navigation: FKWebNavigationConfiguration
  public var javascript: FKWebJavaScriptConfiguration
  public var security: FKWebSecurityConfiguration
  public var reachability: FKWebReachabilityConfiguration
  public var error: FKWebErrorConfiguration
  public var accessibility: FKWebAccessibilityConfiguration
  /// Non-Equatable factory escapes in separate `FKWebViewConfigurationContext` if needed
}
```

**WKWebViewConfiguration** is reference type — provide builder:

```swift
public struct FKWebViewWKConfigurationBuilder: Sendable {
  public var apply: @Sendable (WKWebViewConfiguration) -> Void
}
```

Applied once when internal web view created; document that mutating after load requires recreate.

### 11.2 Common WK settings (via builder)

| Setting | Default recommendation |
|---------|------------------------|
| `allowsInlineMediaPlayback` | true for media pages |
| `mediaTypesRequiringUserActionForPlayback` | `.all` or per product |
| `javaScriptEnabled` | true (iOS 14+ `defaultWebpagePreferences.allowsContentJavaScript`) |
| `websiteDataStore` | `.default()`; host may set `.nonPersistent()` for login |
| `applicationNameForUserAgent` | append FKKit-neutral suffix optional |
| `customUserAgent` | nil → system default |

### 11.3 Data store & cookies

Document recipes:

- Persistent login: default data store
- Ephemeral auth session: `WKWebsiteDataStore.nonPersistent()`
- Pre-seed cookie: `WKHTTPCookieStore.setCookie` in builder **before** first load

**Never log** cookie values.

---

## 12. Navigation Policy & Link Handling

### 12.1 Policy enum

```swift
public enum FKWebNavigationActionDisposition: Sendable, Equatable {
  case allow
  case cancel
  case openExternally(URL)
  case download(URL)           // v1.1 or callback only
}
```

```swift
public struct FKWebNavigationPolicy: Sendable, Equatable {
  public var httpHTTPS: FKWebHTTPPolicy
  public var customSchemes: [String: FKWebCustomSchemePolicy]
  public var targetBlank: FKWebTargetBlankPolicy
  public var mailtoTel: FKWebSystemURLPolicy
}

public enum FKWebTargetBlankPolicy: Sendable, Equatable {
  case loadInPlace
  case openExternally
  case cancel
}
```

### 12.2 Decision flow (normative)

In `decidePolicyFor navigationAction`:

1. If offline fast-fail enabled and unreachable → `.cancel` + show offline UI.
2. If URL scheme is `http`/`https` → apply `httpHTTPS` rules (allow / external for known domains list).
3. If `targetFrame == nil` (new window) → apply `targetBlank` policy.
4. If scheme matches `customSchemes` (e.g. `myapp://oauth`) → invoke `onCustomScheme(url)`; default `.cancel` navigation after host handles.
5. `mailto:` / `tel:` → open via `UIApplication.shared.open` when allowed.

### 12.3 Domain allowlist / blocklist

```swift
public struct FKWebDomainListPolicy: Sendable, Equatable {
  public var allowedHosts: [String]?   // nil = all https allowed
  public var deniedHosts: [String]
  public var externalHosts: [String]  // open in Safari instead of in-app
}
```

---

## 13. JavaScript Bridge

### 13.1 Registry

```swift
public struct FKJavaScriptBridge: Sendable {
  public var handlers: [FKJavaScriptHandlerRegistration]
}

public struct FKJavaScriptHandlerRegistration: Sendable, Equatable {
  public var name: String
  public var handlerID: String   // maps to host closure table
}
```

Internal `WKUserContentController` adds handlers at setup; **must remove on deinit** to avoid leaks.

### 13.2 Message delivery

```swift
public protocol FKWebViewJavaScriptHandling: AnyObject {
  func webView(_ webView: FKWebView, didReceive message: FKJavaScriptMessage)
}

public struct FKJavaScriptMessage: Sendable {
  public var name: String
  public var body: FKJavaScriptMessageBody  // type-erased JSON-safe
}
```

**Must** validate `message.name` against registered handlers only.

### 13.3 Injection scripts

```swift
public struct FKUserScriptRegistration: Sendable, Equatable {
  public var source: String
  public var injectionTime: WKUserScriptInjectionTime
  public var forMainFrameOnly: Bool
}
```

Support at document start/end via configuration.

### 13.4 Calling JavaScript from native

```swift
public func evaluateJavaScript(
  _ script: String,
  completion: (@MainActor (Result<Any?, Error>) -> Void)? = nil
)
```

---

## 14. Cookies, Headers & Authentication

### 14.1 Request headers

- Per-load headers via `FKWebViewRequestOptions.additionalHeaders`.
- Global headers via configuration builder modifying `WKWebView` customUserAgent / cookie store only — **avoid** duplicating `FKNetwork` interceptors.

### 14.2 HTTP authentication

Forward `NSURLAuthenticationMethodHTTPBasic` challenges to optional delegate method; default `performDefaultHandling`.

### 14.3 Document integrator guidance (README)

- Use HTTPS only in production.
- Prefer cookie-based session in `WKWebsiteDataStore` over embedding tokens in query strings.
- Rotate non-persistent data store on logout (`WKWebsiteDataStore.removeData`).

---

## 15. OAuth & Custom URL Schemes

### 15.1 Redirect interception

When navigation URL matches registered custom scheme:

1. Cancel web navigation (prevent error page).
2. Fire `onOAuthRedirect?(URL)` / delegate callback.
3. Host exchanges code via `FKNetwork` outside WebView.

### 15.2 Universal Links

FKWebView does not replace Associated Domains — if universal link opens app, host handles in `SceneDelegate`; document interaction.

### 15.3 Examples

Mock OAuth page posting redirect to `fkkit-examples://oauth/callback?code=demo`.

---

## 16. WKUIDelegate & System Dialogs

Forward when not overridden:

| WKUIDelegate | Default FK behavior |
|--------------|---------------------|
| `createWebViewWith` | Load in same webview if `targetBlank` = loadInPlace; else external |
| `runJavaScriptAlertPanel` | `UIAlertController` alert |
| `runJavaScriptConfirmPanel` | Confirm alert |
| `runJavaScriptTextInputPanel` | Alert with text field |
| `runOpenPanelWith` | v1.1 forward or cancel |

Allow host to override via `FKWebViewUIDelegate` for custom UI (e.g. `FKAlert` when available).

---

## 17. Security & Privacy

### 17.1 Logging

**Forbidden in FKWebView implementation:**

- `Authorization` headers
- Cookie values
- OAuth `code` / `access_token` query values
- Basic auth credentials

URLs may log path-only in debug if `configuration.security.redactsQueryInLogs == true` (default **true**).

### 17.2 JavaScript

- Handlers opt-in by registration — no default `window.webkit.messageHandlers` exposure beyond registered names.
- `javaScriptCanOpenWindowsAutomatically` default false unless config enables.

### 17.3 File access

- `loadFileURL(_:allowingReadAccessTo:)` exposed with documentation: only bundle/legal sandbox paths.
- Block `file://` navigation from remote pages unless explicitly allowed (default **block**).

### 17.4 ATS

Respect App Transport Security; no built-in ATS bypass.

### 17.5 Fraud / mixed content

Follow WebKit defaults; no mixed content override API v1.

---

## 18. Configuration Model

See §11. Key interaction flags:

```swift
public struct FKWebInteractionConfiguration: Sendable, Equatable {
  public var allowsBackForwardGestures: Bool  // default true
  public var pullToRefreshEnabled: Bool
  public var scrollBounces: Bool?
  public var zoomEnabled: Bool              // scalesPageToFit legacy avoided; use WK viewport
  public var previewingEnabled: Bool          // 3D touch peek where available
}
```

```swift
public enum FKWebViewDefaults {
  public static var defaultConfiguration: FKWebViewConfiguration
  public static func inAppBrowser() -> FKWebViewConfiguration
  public static func ephemeralAuth() -> FKWebViewConfiguration
}
```

Presets:

- **`inAppBrowser`** — toolbar + progress + external links Safari
- **`ephemeralAuth`** — nonPersistent store + custom scheme hooks

---

## 19. Delegate & Callback API

```swift
@MainActor
public protocol FKWebViewDelegate: AnyObject {
  func webView(_ webView: FKWebView, didChangeState: FKWebViewLoadingState)
  func webView(_ webView: FKWebView, didCommit url: URL?)
  func webView(_ webView: FKWebView, didFinish url: URL?)
  func webView(_ webView: FKWebView, didFail error: FKWebViewError)
  func webView(
    _ webView: FKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    defaultDisposition: FKWebNavigationActionDisposition
  ) -> FKWebNavigationActionDisposition
  func webView(_ webView: FKWebView, didReceiveOAuthRedirect url: URL)
}
```

Optional methods via protocol extension defaults.

**Callbacks struct** mirror for Swift closures (`FKWebViewCallbacks`).

---

## 20. FKWebViewController (Optional Host)

```swift
@MainActor
open class FKWebViewController: UIViewController {
  public let webView: FKWebView
  public init(url: URL, configuration: FKWebViewConfiguration = .init())
}
```

- Embeds `FKWebView` full screen
- Optional close bar button item
- Status bar style from configuration
- Safe area respect for progress bar

Not required for embed-only use cases.

---

## 21. SwiftUI Bridge

```swift
public struct FKWebViewRepresentable: UIViewRepresentable {
  public var url: URL?
  public var configuration: FKWebViewConfiguration
  public var callbacks: FKWebViewCallbacks
}
```

**Must** update URL when binding changes (load new request). Avoid reload loops.

Optional `FKWebViewControllerRepresentable` for full chrome.

---

## 22. Performance & Memory

- Single `WKWebView` per `FKWebView` instance.
- `deinit` removes script message handlers and KVO.
- `WKWebView` process pool: use default; document shared pool option in builder for multiple instances.
- Clear cache API wrapper:

```swift
public static func clearWebsiteData(
  types: Set<String>,
  since: Date,
  completion: (@MainActor () -> Void)?
)
```

---

## 23. Accessibility

- Web content accessibility handled by WebKit.
- Chrome buttons: localized labels (Back, Forward, Reload, Close).
- Error overlay inherits `FKEmptyState` accessibility.
- Optional `accessibilityLabel` on container: "Web content".

---

## 24. Proposed Source Layout

```text
Sources/FKUIKit/Components/WebView/
├── README.md
├── Public/
│   ├── FKWebView.swift
│   ├── FKWebViewController.swift
│   ├── FKWebViewState.swift
│   ├── FKWebViewError.swift
│   ├── Configuration/
│   ├── Navigation/
│   │   ├── FKWebNavigationPolicy.swift
│   │   └── FKWebNavigationActionDisposition.swift
│   ├── JavaScript/
│   │   ├── FKJavaScriptBridge.swift
│   │   └── FKJavaScriptMessage.swift
│   ├── Protocols/
│   │   ├── FKWebViewDelegate.swift
│   │   └── FKWebViewUIDelegate.swift
│   └── Bridge/
│       └── FKWebViewRepresentable.swift
├── Internal/
│   ├── FKWebNavigationCoordinator.swift
│   ├── FKWebChromeView.swift
│   ├── FKWebProgressPresenter.swift
│   ├── FKWebEmptyStatePresenter.swift
│   └── FKWebView+WKDelegates.swift
└── Extension/
    └── FKWebView+Convenience.swift
```

---

## 25. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/WebView/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `BasicRemoteLoad` | HTTPS + linear progress |
| 2 | `ErrorRetrySafari` | Force 404 + retry + open Safari |
| 3 | `OfflinePreflight` | Reachability empty state |
| 4 | `OAuthRedirect` | Custom scheme intercept mock |
| 5 | `JavaScriptBridge` | postMessage round-trip |
| 6 | `ExternalLinks` | `target=_blank` → Safari policy |
| 7 | `ToolbarNavigation` | Back/forward history |
| 8 | `EphemeralDataStore` | Login cookie cleared on dismiss |
| 9 | `EmbeddedInSheet` | `FKSheetPresentationController` host |
| 10 | `SwiftUIRepresentable` | Binding URL |
| 11 | `LocalHTML` | loadHTMLString bundle demo |
| 12 | `DomainAllowlist` | Blocked host policy |

---

## 27. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Expose `wkWebView` publicly? | No v1; use evaluate/load APIs |
| Q2 | Pull-to-refresh default? | false |
| Q3 | Use FKAlert for JS dialogs when shipped? | UIAlertController v1; migrate later |
| Q4 | Shared WKProcessPool singleton? | Document optional builder |
| Q5 | Download delegate support v1? | Callback only, no full download manager |

---

## 28. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §1.6 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKEmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
- [FKNetwork README](../Sources/FKCoreKit/Components/Network/README.md)
