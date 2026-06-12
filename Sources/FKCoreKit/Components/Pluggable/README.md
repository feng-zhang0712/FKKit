# FKPluggable (FKCoreKit)

Protocol contracts for **pluggable** iOS app infrastructure. Sources live under `Sources/FKCoreKit/Components/Pluggable/` and ship as part of the **`FKCoreKit`** product (interfaces and shared value types only—no implementations).

## Goals

- Give medium and large apps a **stable, documented boundary** for dependency injection and testing.
- Keep feature modules independent of concrete networking, analytics, storage, and SDK adapters.
- Align with FKKit’s protocol-oriented design inside the core module.

## Contract groups

| Area | Protocols | Typical production plug-in |
|------|-----------|------------------------------|
| Networking | `FKAPIClientProviding`, `FKRequestIntercepting`, `FKResponseIntercepting`, `FKRequestSigning`, `FKCredentialProviding`, `FKTokenRefreshing`, `FKNetworkReachabilityProviding` | URLSession client, auth interceptor, Keychain token store |
| Analytics | `FKPluggableAnalyticsUploading`, `FKPluggableAnalyticsCommonParametersProviding`, `FKPluggableAnalyticsTracking` | Gateway uploader, Firebase/self-hosted SDK adapter |
| Storage | `FKKeyValueStoring`, `FKCodableStoring` | UserDefaults, Keychain, file, in-memory (tests). Store raw `Data` via ``FKKeyValueStoring/set(_:forKey:)`` or the ``FKCodableStoring`` `Data` overload—do not rely on the generic `set(_:forKey:)` with a `Data` value (see `FKKeyValueStoring.swift`). |
| Session | `FKUserSessionProviding`, `FKUserSessionObserving` | Login manager, account service |
| Configuration | `FKAppEnvironmentProviding`, `FKFeatureFlagProviding`, `FKRemoteConfigProviding` | Build configs, LaunchDarkly, remote config service |
| Localization | `FKLocalizing`, `FKTranslating` | Bundle tables, CMS, A/B copy |
| Routing | `FKDeeplinkParsing`, `FKRouteHandling`, `FKDeeplinkRouting` | Per-feature route handlers |
| Logging | `FKPluggableLogging`, `FKPluggableLogLevel` | OSLog, file logger, console (debug) |
| Lifecycle | `FKAppLifecycleObserving`, `FKPluggableAppLifecycleState` | `UIApplication` notification bridge |
| Media | `FKImageLoading`, `FKImageCaching` | SDWebImage/Kingfisher wrapper |
| UIKit lists | `FKCellReusable`, `FKListTableCellConfigurable`, `FKListCollectionCellConfigurable` | Feature cells |
| Text input | `FKTextFormatting`, `FKTextValidating`, `FKTextAsyncValidating` | Phone/card formatters, server validation |

## Installation

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.68.0"),
],
targets: [
  .target(name: "MyApp", dependencies: [.product(name: "FKCoreKit", package: "FKKit")]),
]
```

### CocoaPods

```ruby
pod 'FKCoreKit'
```

## Wiring at app launch (sketch)

```swift
import FKCoreKit

// App composition root — implementations live in the app target.
final class AppServices {
  let apiClient: any FKAPIClientProviding
  let analyticsUploader: any FKPluggableAnalyticsUploading
  let storage: any FKCodableStoring
  let session: any FKUserSessionProviding
  let environment: any FKAppEnvironmentProviding
}
```

## Relationship to other FKCoreKit areas

- **`Network`**, **`Storage`**, **`BusinessKit`**, and **`Logger`** may provide default implementations that conform to these protocols.
- **`FKUIKit`** can adopt the same contracts at its public API edge over time.

## Versioning

`FKPluggable.contractVersion` increments when breaking protocol changes ship. Follow FKKit semver for releases.

## License

MIT — see repository root `LICENSE`.
