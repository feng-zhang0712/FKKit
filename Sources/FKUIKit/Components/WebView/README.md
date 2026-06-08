# FKWebView

Production-oriented `WKWebView` wrapper for hybrid screens: loading progress, error recovery, optional navigation chrome, JavaScript bridge, and policy-driven link handling.

## Requirements

- iOS 15+
- Swift 6
- Modules: `FKUIKit` (depends on `FKCoreKit` for reachability and layout helpers)

## Directory layout

| Path | Responsibility |
|------|----------------|
| `Public/FKWebView.swift` | Embeddable `UIView` container and load/navigation API |
| `Public/FKWebViewController.swift` | Optional full-screen host with navigation bar close button |
| `Public/FKWebViewTypes.swift` | Loading state, errors, navigation policy types |
| `Public/FKWebViewConfiguration.swift` | Sendable configuration structs and presets |
| `Public/FKWebViewDelegate.swift` | Delegate, UI delegate, and closure callbacks |
| `Public/FKWebViewBridge.swift` | JavaScript bridge registration and message types |
| `Public/FKWebViewRepresentable.swift` | SwiftUI `UIViewRepresentable` bridge |
| `Internal/FKWebNavigationCoordinator.swift` | `WKNavigationDelegate` / `WKUIDelegate`, policy engine, KVO |
| `Internal/FKWebChromeView.swift` | Compact back/forward/reload/close toolbar |
| `Internal/FKWebProgressPresenter.swift` | `FKProgressBar` progress wiring |
| `Internal/FKWebEmptyStatePresenter.swift` | `FKEmptyState` error/offline overlays |
| `Extension/FKWebView+Convenience.swift` | Per-load options and configuration helpers |

## Quick start

```swift
let webView = FKWebView(configuration: .init())
webView.load(URL(string: "https://example.com")!)
view.addSubview(webView)
```

Use `FKWebViewDefaults.inAppBrowser()` for toolbar + progress defaults, or `FKWebViewController` for a ready-made host.

## Examples

Entry: **FKKitExamples → FKUIKit → WebView**

| Group | Scenarios |
|-------|-----------|
| Getting started | Remote HTTPS, local HTML/file URL, `FKWebViewController` |
| Chrome & progress | Toolbar history, progress modes, pull to refresh |
| Errors & offline | HTTP retry/Safari, offline preflight |
| Navigation policy | External links, domain allowlist, mailto/tel |
| JavaScript & auth | JS bridge, JS dialogs, OAuth redirect |
| Integration | Delegate log, SwiftUI, sheet embed, ephemeral data store |

## Security

- Never logs `Authorization` headers, cookie values, OAuth tokens, or URLs internally.
- JavaScript message handlers are opt-in via `javascript.bridge`.
- Remote pages cannot navigate to `file://` URLs unless you change `security.blocksFileURLNavigationFromRemotePages`.
- Ephemeral sessions: clear data with ``FKWebView/clearWebsiteData(types:since:completion:)`` on the instance, not the static helper (which targets the default persistent store only).

## NSError mapping

| Condition | `FKWebViewError` |
|-----------|------------------|
| `NSURLErrorNotConnectedToInternet` | `.notConnectedToInternet` |
| `NSURLErrorTimedOut` | `.timedOut` |
| Certificate / SSL errors | `.secureConnectionFailed` |
| HTTP 4xx/5xx response | `.serverError(statusCode:)` |
| `NSURLErrorCancelled` | `.cancelled` |
| Host not found / cannot connect | `.unreachableHost` |
| Denied by domain policy | `.hostDenied` |
