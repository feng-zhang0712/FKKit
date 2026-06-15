# FKPluggable (FKCoreKit)

Protocol contracts and **opt-in reference implementations** for pluggable iOS app infrastructure. Sources live under `Sources/FKCoreKit/Components/Pluggable/` and ship as part of the **`FKCoreKit`** product.

## Goals

- Give medium and large apps a **stable, documented boundary** for dependency injection and testing.
- Keep feature modules independent of concrete networking, analytics, storage, and SDK adapters.
- Provide **bridges and reference implementations** so integrators can start from production-ready defaults.
- Align with FKKit’s protocol-oriented design inside the core module.

## Directory layout

| Path | Role |
|------|------|
| `FKPluggable.swift` | `contractVersion`, module overview |
| `Analytics/`, `Configuration/`, `Core/`, … | **Protocol contracts** and shared value types |
| `Notifications/`, `BackgroundTask/` | **v2 Pluggable contracts** (implementations live in sibling components) |
| `Implementations/` | Reference implementations and module bridges |
| `Implementations/Composition/` | `FKPluggableServices` composition-root template |
| `Mock/` | Reusable test/demo mocks |

## Contract alignment

| Area | Protocol / type | Status | Production default |
|------|-----------------|--------|-------------------|
| **Networking** | `FKAPIClientProviding` | 🔌 Bridge | `FKNetworkClientPluggableAdapter` |
| | `FKRequestIntercepting` / `FKResponseIntercepting` / `FKRequestSigning` | 🔌 Bridge | `FK*Adapter` → Network interceptors |
| | `FKCredentialProviding` | ✅ Reference | `FKKeychainCredentialStore` |
| | `FKTokenRefreshing` | 🔌 Bridge | `TokenRefresherPluggableAdapter` |
| | `FKNetworkReachabilityProviding` | 🔌 Bridge | `FKNetworkReachability` (dual conformance) |
| **Storage** | `FKCodableStoring` | 🔌 Bridge | `FKCodableStoragePluggableAdapter` → `FKCodableStorage` |
| | `FKCodableStoring` (memory) | ✅ Reference | `FKInMemoryKeyValueStore` |
| **Session** | `FKUserSessionProviding` / `Observing` | ✅ Reference | `FKUserSessionStore` |
| **Configuration** | `FKAppEnvironmentProviding` | ✅ Reference | `FKBuildTimeAppEnvironment` |
| | `FKFeatureFlagProviding` | ✅ Reference | `FKInMemoryFeatureFlags` |
| | `FKRemoteConfigProviding` | ✅ Reference | `FKJSONRemoteConfigProvider` |
| **Localization** | `FKLocalizing` | 🔌 Bridge | `FKI18nManager`, `FKBusinessI18nPluggableAdapter` |
| **Routing** | `FKDeeplinkRouting` | ✅ Reference | `FKPluggableDeeplinkRouter` + `FKURLDeeplinkParser` |
| | `FKDeeplinkRouting` (BusinessKit) | 🔌 Bridge | `FKBusinessDeeplinkPluggableAdapter` |
| **Logging** | `FKPluggableLogging` | 🔌 Bridge | `FKLoggerPluggableAdapter` |
| **Lifecycle** | `FKAppLifecycleObserving` | 🔌 Bridge | `FKBusinessLifecyclePluggableAdapter` |
| **Analytics** | `FKPluggableAnalyticsUploading` | 🔌 Bridge | `FKBusinessAnalyticsPluggableUploader` |
| **Media** | `FKImageLoading` | ✅ Reference | `FKImageLoader` |
| **Security** | `FKBiometricAuthenticating` | ✅ Reference | `FKBiometricAuth` |
| **Text input** | `FKTextFormatting` / `FKTextValidating` | ✅ Reference | `FKPhoneNumberTextFormatter`, `FKEmailTextValidator`, … |
| **v2 Notifications** | `FKLocalNotificationScheduling` | ✅ Reference | `FKLocalNotificationManager` |
| **v2 Background tasks** | `FKBackgroundTaskScheduling` | ✅ Reference | `FKBackgroundTaskManager` |
| **v2 Push routing** | `FKPushNotificationRouting` | 📋 Protocol | Host implements |

Legend: ✅ reference implementation · 🔌 bridge adapter · 📋 protocol only.

## Decision trees

### Storage vs Pluggable storage

- **Feature DI** → inject `any FKCodableStoring` (`FKCodableStoragePluggableAdapter` over `FKUserDefaultsStorage` / `FKKeychainStorage`).
- **Direct persistence with TTL, purge, allKeys** → use `FKCodableStorage` from the Storage module directly.

### BusinessKit vs Pluggable

- **Already on `FKBusinessKit.shared`** → keep BusinessKit lifecycle/deeplink/analytics; use Pluggable **adapters** when a feature module needs the narrow protocol.
- **New protocol-first modules** → depend on Pluggable types; wire `FKPluggableServices` or explicit constructor injection.

## Composition root

```swift
import FKCoreKit

@MainActor
func bootstrapPluggable() -> FKPluggableServices {
  FKPluggableServices.productionDefaults()
}
```

`FKPluggableServices` is an **optional template** — prefer passing individual `any Protocol` values into feature modules.

**Integration notes:**

- Call ``FKPluggableServices/productionDefaults()`` **once at app launch** (it creates a new ``FKNetworkReachability`` monitor each time).
- Storage keys from ``productionDefaults()`` are shaped `fk.pluggable.<logicalKey>` (`FKUserDefaultsStorage` prefix `fk.` + adapter namespace `pluggable`).
- ``FKJSONRemoteConfigProvider/bool(forKey:)`` treats snapshot strings with NSString boolean rules (`"true"` / `"false"` / `"1"` / `"0"`).
- Set `FKAPIBaseURL` in Info.plist when using ``FKBuildTimeAppEnvironment`` in production (see type documentation for the development fallback).
- Reference validators (``FKEmailTextValidator``, ``FKLengthTextValidator``) and Pluggable errors resolve user-facing copy via ``FKI18n`` keys under `fkcore.pluggable.*` in `Resources/Localization/`.

## Mock suite

| Type | Protocol |
|------|----------|
| `FKMockAPIClient` | `FKAPIClientProviding` |
| `FKMockFeatureFlags` | `FKFeatureFlagProviding` |
| `FKMockUserSession` | Session protocols |
| `FKMockReachability` | `FKNetworkReachabilityProviding` |
| `FKMockPluggableLogger` | `FKPluggableLogging` |
| `FKMockImageLoader` | `FKImageLoading` |

## Installation

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.69.0"),
],
targets: [
  .target(name: "MyApp", dependencies: [.product(name: "FKCoreKit", package: "FKKit")]),
]
```

### CocoaPods

```ruby
pod 'FKCoreKit'
```

## Examples

FKKitExamples hub: `Examples/FKCoreKit/Pluggable/` — composition root, storage bridge, configuration reference implementations, logger bridge, text formatters, and protocol contract demos.

## Versioning

`FKPluggable.contractVersion` increments when **breaking protocol changes** ship. New protocols and reference implementations are **semver minor**.

| Change | `contractVersion` | Semver |
|--------|-------------------|--------|
| New protocol / reference impl / bridge | unchanged | minor |
| Breaking change to existing protocol | +1 | major |

Enhancement plan: [`docs/FKPluggable_ENHANCEMENT_DESIGN.md`](../../../../docs/FKPluggable_ENHANCEMENT_DESIGN.md).

## License

MIT — see repository root `LICENSE`.
