# FKBiometricAuth — Design Requirements

Implementation guide for FKKit **`FKBiometricAuth`**: a production-oriented wrapper around Apple **`LocalAuthentication`** for device-owner verification (Face ID, Touch ID, Optic ID) with passcode fallback, typed errors, and documented pairing with Keychain / Storage.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.7  
**中文版本:** [FKBiometricAuth_DESIGN.zh-CN.md](FKBiometricAuth_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Architectural Overview](#4-architectural-overview)
- [5. Module Boundaries](#5-module-boundaries)
- [6. Capability Detection](#6-capability-detection)
- [7. Authentication Lifecycle & State](#7-authentication-lifecycle--state)
- [8. Biometric Policies](#8-biometric-policies)
- [9. Public API Surface](#9-public-api-surface)
- [10. Error Taxonomy & LAError Mapping](#10-error-taxonomy--laerror-mapping)
- [11. Configuration Model](#11-configuration-model)
- [12. LAContext Management](#12-lacontext-management)
- [13. Keychain & Storage Integration](#13-keychain--storage-integration)
- [14. Token Unlock Patterns](#14-token-unlock-patterns)
- [15. Security & Privacy](#15-security--privacy)
- [16. Concurrency & Threading](#16-concurrency--threading)
- [17. Pluggable & Dependency Injection](#17-pluggable--dependency-injection)
- [18. Localization (FKI18n)](#18-localization-fki18n)
- [19. Device, Simulator & OS Matrix](#19-device-simulator--os-matrix)
- [20. UIKit / SwiftUI Host Guidance](#20-uikit--swiftui-host-guidance)
- [21. Proposed Source Layout](#21-proposed-source-layout)
- [22. FKKitExamples Scenarios](#22-fkkitexamples-scenarios)
- [24. Open Questions](#24-open-questions)
- [25. Revision History](#25-revision-history)

---

## 1. Executive Summary

Finance, wallet, and account apps repeatedly integrate **`LAContext`** for:

- Unlocking sensitive screens (portfolio, transfer confirm)
- Gating access to tokens in Keychain
- Re-authentication after backgrounding

**`FKSecurity`** covers cryptography (hash, AES, RSA, HMAC) and **`FKKeychainKeyStore`** / **`FKKeychainStorage`** persist secrets — but FKKit ships **no** unified LocalAuthentication layer. Teams reimplement capability checks, policy selection, error mapping, and Keychain pairing inconsistently.

**`FKBiometricAuth`** (`Sources/FKCoreKit/Components/BiometricAuth/`) provides:

| Deliverable | Role |
|-------------|------|
| **`FKBiometricCapability`** | Sendable snapshot: hardware type, enrollment, policy evaluability |
| **`FKBiometricPolicy`** | Maps to `LAPolicy` with documented passcode fallback semantics |
| **`FKBiometricAuthenticating`** | `Sendable` protocol for Pluggable DI |
| **`FKBiometricAuth`** | Default `LAContext` orchestration implementation |
| **`FKBiometricError`** | Stable, integrator-facing error taxonomy |

**Critical constraint:** FKBiometricAuth performs **authentication only** — it never stores, processes, or transmits biometric templates. Apple retains biometry in Secure Enclave.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Silent capability probe** — `canEvaluatePolicy` / capability snapshot **without** system UI.
2. **`async` authentication** — `authenticate(reason:)` suspends until success, typed failure, or cancel.
3. **Explicit policy model** — biometrics-only vs biometrics-or-passcode vs device passcode; no hidden `LAPolicy` strings in host apps.
4. **Complete `LAError` mapping** — cancel, fallback, lockout, not enrolled, not available, passcode not set, app cancel, invalid context.
5. **Keychain pairing guide** — document unlocking `FKKeychainStorage` / `FKKeychainKeyStore` after successful auth (v1 does not silently auto-read Keychain).
6. **Swift 6** — `Sendable` configuration and errors; no `@MainActor` requirement (no UI owned by this module).
7. **FKI18n** — fallback reason strings and error descriptions; integrator may override reason per call.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Custom biometric UI (fake Face ID animation) | System `LAContext` UI only |
| Liveness / face matching algorithms | Apple-only |
| Storing biometry templates or scores | Forbidden |
| Extending `FKKeychainStorage` with `kSecAccessControl` biometry flags in v1 | Document recipes; optional v1.1 API |
| watchOS companion auth | iOS 15+ only |
| macOS / Catalyst LocalAuthentication | iOS target |
| Jailbreak / tamper detection beyond existing `FKSecurity` utils | Out of scope |
| Automatic re-auth on `UIApplication` lifecycle | Host responsibility; provide hooks/docs |

### 2.3 Success Criteria

- [ ] Capability API returns correct `biometryType` on Face ID / Touch ID devices without showing UI.
- [ ] Successful `authenticate` completes `async` with `.success`.
- [ ] User cancel maps to `FKBiometricError.userCancelled` (not generic failure).
- [ ] Lockout maps to `FKBiometricError.biometryLockout` with README recovery guidance.
- [ ] Examples: capability, success, cancel, lockout (simulated where needed).
- [ ] README Keychain pairing section references `FKKeychainStorage` + `FKKeychainKeyStore`.
- [ ] No API logs `reason` strings containing user PII in production paths.

---

## 3. Background & Problem Statement

### 3.1 Current FKKit state

| Area | Status |
|------|--------|
| `LocalAuthentication` usage under `Sources/` | **None** |
| `FKSecurity` | Hash, AES, RSA, signing, masking, secure random |
| `FKKeychainKeyStore` | Raw key bytes; `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` |
| `FKKeychainStorage` | Codable secrets + TTL; same default accessibility |
| `FKI18n` | Shared localization for errors and fallback copy |

### 3.2 Repeated integration pain

| Pain | Impact |
|------|--------|
| Calling `evaluatePolicy` during probe | Unexpected Face ID flash on launch |
| Wrong `LAPolicy` for “confirm payment” | Passcode when biometrics required (or vice versa) |
| Raw `LAError` in UI | Inconsistent copy; missing lockout handling |
| Reusing `LAContext` after failure | `invalidContext` crashes / silent failures |
| Keychain `kSecAccessControl` + LA mismatch | Double prompts or unreachable secrets |
| Simulator “not enrolled” | Poor dev UX without documented mock provider |

### 3.3 Relationship to roadmap risk R4

Lockout duration and fallback behavior vary by iOS version and device. **Must** map `LAError.biometryLockout` explicitly and document that only passcode or device unlock clears lockout — FKBiometricAuth does not bypass Apple policy.

---

## 4. Architectural Overview

```text
┌──────────────────────────────────────────────────────────────────┐
│ Host App (UIKit / SwiftUI)                                       │
│  - Presents sensitive screen                                     │
│  - Calls FKBiometricAuth.authenticate(reason:)                   │
│  - On success → read FKKeychainStorage / proceed                 │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│ FKBiometricAuth (FKCoreKit)                                      │
│  FKBiometricCapabilityProbe  → canEvaluatePolicy (no UI)         │
│  FKBiometricContextFactory   → fresh LAContext per auth          │
│  FKBiometricErrorMapper      → LAError → FKBiometricError        │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│ LocalAuthentication.framework                                    │
│  LAContext.evaluatePolicy / evaluateAccessControl                │
│  System UI (Face ID / Touch ID / passcode)                       │
└──────────────────────────────────────────────────────────────────┘
```

**Data flow (typical unlock):**

1. Host checks `capability()` → show “Enable Face ID in Settings” if not enrolled.
2. Host calls `authenticate(reason: "Confirm transfer")`.
3. System UI → user succeeds.
4. Host reads token from `FKKeychainStorage` (already stored without biometry access control in v1) or proceeds to business logic.

For **Keychain-bound** secrets (v1.1+), authentication may be triggered by `SecItemCopyMatching` — FKBiometricAuth documents coordination.

---

## 5. Module Boundaries

| Concern | FKBiometricAuth | FKSecurity | FKStorage |
|---------|-----------------|------------|-----------|
| Device-owner auth | **Yes** | No | No |
| Cryptographic operations | No | **Yes** | No |
| Secret persistence | No | Key bytes via Keychain store | **Yes** |
| System auth UI | Delegates to LA | No | No |
| Error type | `FKBiometricError` | `FKSecurityError` | `FKStorageError` |

**Import:** `LocalAuthentication` only in BiometricAuth target files. No UIKit dependency.

---

## 6. Capability Detection

### 6.1 Requirements

Capability probing **must not** call APIs that present UI. Allowed:

- `LAContext.canEvaluatePolicy(_:error:)`
- Reading `LAContext.biometryType` (after policy check or on fresh context)
- Optional: `LABiometryType` / enrollment inferred from `LAError.biometryNotEnrolled`

**Forbidden for probe:**

- `evaluatePolicy(_:localizedReason:reply:)`
- `evaluateAccessControl(_:operation:localizedReason:reply:)`

### 6.2 Capability model

```swift
/// Snapshot of device biometric readiness. Obtained without authentication UI.
public struct FKBiometricCapability: Sendable, Equatable {
  /// `true` when the requested policy can be evaluated (may still require UI later).
  public var canAuthenticate: Bool
  /// Hardware biometry kind on this device.
  public var biometryType: FKBiometryType
  /// `true` when biometry is enrolled (Face ID / Touch ID configured).
  public var isBiometryEnrolled: Bool
  /// `true` when device passcode is set (required for biometrics).
  public var isPasscodeSet: Bool
  /// Policy used for this snapshot.
  public var evaluatedPolicy: FKBiometricPolicy
  /// Underlying probe error when `canAuthenticate == false` (mapped, optional).
  public var probeError: FKBiometricError?
}

public enum FKBiometryType: Sendable, Equatable {
  case none
  case touchID
  case faceID
  case opticID   // Vision Pro / supported devices; map from LABiometryType.opticID when available
}
```

### 6.3 Probe API

```swift
public protocol FKBiometricAuthenticating: Sendable {
  /// Probes capability for `policy` without showing authentication UI.
  func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability

  /// Probes using `configuration.defaultPolicy`.
  func capability() -> FKBiometricCapability
}
```

### 6.4 Enrollment semantics

| `isBiometryEnrolled` | Inference |
|----------------------|-----------|
| `true` | `canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` succeeds |
| `false` | Fails with `.biometryNotEnrolled` or biometry unavailable |

Document that **Simulator** often reports not enrolled — Examples use mock provider.

### 6.5 Caching

**Must not** cache capability across major system events indefinitely. Optional short-lived cache (e.g. 1s) inside single call chain only. Host should re-probe when app returns from Settings or `UIApplication.didBecomeActiveNotification`.

---

## 7. Authentication Lifecycle & State

### 7.1 Result type

```swift
public enum FKBiometricAuthResult: Sendable, Equatable {
  case success
  case failure(FKBiometricError)
}
```

Authentication API throws `FKBiometricError` on failure (preferred) **or** returns `Result` — pick one style; **normative: `async throws`** for alignment with FKCoreKit async APIs:

```swift
/// Throws `FKBiometricError` on failure; returns normally on success.
func authenticate(
  reason: String,
  policy: FKBiometricPolicy,
  options: FKBiometricAuthOptions
) async throws
```

### 7.2 State (internal)

```text
idle → authenticating → success
                     ↘ failure (typed error)
```

- Only **one** in-flight `authenticate` per `FKBiometricAuth` instance at a time; concurrent second call throws `FKBiometricError.authenticationInProgress` or awaits queue (document choice — **default: serial queue, second call waits**).

### 7.3 Reason string

- **Required** non-empty `reason` shown in system UI (`NSFaceIDUsageDescription` is separate Info.plist requirement).
- Trim whitespace; empty reason → `FKBiometricError.invalidReason`.
- Max length: document 128 char practical limit for UI clipping.

### 7.4 Cancellation

```swift
public func cancelAuthentication()
```

Maps to `LAContext.invalidate()` on active context → pending `authenticate` resumes with `FKBiometricError.appCancelled`.

---

## 8. Biometric Policies

### 8.1 Policy enum

```swift
/// Maps to Apple LAPolicy with documented fallback behavior.
public enum FKBiometricPolicy: Sendable, Equatable {
  /// Face ID / Touch ID only; fails if biometry unavailable (no passcode fallback).
  case biometricsOnly
  /// Biometry with device passcode fallback (most common for "unlock app").
  case biometricsOrPasscode
  /// Device passcode only (no biometry requirement).
  case devicePasscode
}
```

### 8.2 LAPolicy mapping (normative)

| `FKBiometricPolicy` | `LAPolicy` |
|---------------------|------------|
| `.biometricsOnly` | `.deviceOwnerAuthenticationWithBiometrics` |
| `.biometricsOrPasscode` | `.deviceOwnerAuthentication` |
| `.devicePasscode` | `.deviceOwnerAuthentication` with biometry disabled via context flags where applicable |

**Note:** For `.devicePasscode`, use `LAContext` interaction policy or evaluate only passcode path — document that biometry may still appear on some OS versions unless `biometricsOnly` is avoided; prefer `.deviceOwnerAuthentication` when passcode fallback is intended.

### 8.3 Use-case guide

| Scenario | Recommended policy |
|----------|-------------------|
| App unlock / view balance | `.biometricsOrPasscode` |
| High-risk confirm (wire transfer) | `.biometricsOnly` if enrolled; else block |
| Device has no biometry | `.devicePasscode` or gate feature |
| Settings toggle "Require Face ID" | Host stores preference; still use `.biometricsOrPasscode` |

### 8.4 Fallback button

When using `.biometricsOnly`, system may not show passcode fallback. `FKBiometricAuthOptions.allowPasscodeFallback` applies only to policies that support it (document per policy table).

---

## 9. Public API Surface

### 9.1 Protocol

```swift
public protocol FKBiometricAuthenticating: Sendable {
  func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability
  func capability() -> FKBiometricCapability

  func authenticate(
    reason: String,
    policy: FKBiometricPolicy,
    options: FKBiometricAuthOptions
  ) async throws

  func authenticate(reason: String) async throws

  func cancelAuthentication()
}
```

### 9.2 Concrete type

```swift
public final class FKBiometricAuth: FKBiometricAuthenticating, @unchecked Sendable {
  public init(configuration: FKBiometricAuthConfiguration = .init())
  public static let shared: FKBiometricAuth
}
```

`@unchecked Sendable` with internal serial `DispatchQueue` or actor — same pattern as `FKKeychainStorage`.

### 9.3 Convenience extensions

```swift
extension FKBiometricAuthenticating {
  public func authenticateIfAvailable(reason: String) async throws {
    let cap = capability()
    guard cap.canAuthenticate else { throw cap.probeError ?? .biometryNotAvailable }
    try await authenticate(reason: reason)
  }
}
```

### 9.4 Closure overload (optional v1)

```swift
public func authenticate(
  reason: String,
  completion: @escaping @Sendable (Result<Void, FKBiometricError>) -> Void
)
```

Dispatch to `Task` internally; mark deprecated in favor of `async` if both ship.

---

## 10. Error Taxonomy & LAError Mapping

### 10.1 Error enum

```swift
public enum FKBiometricError: Error, Sendable, Equatable {
  case biometryNotAvailable
  case biometryNotEnrolled
  case biometryLockout
  case passcodeNotSet
  case authenticationFailed
  case userCancelled
  case userFallback          // user chose "Enter Password" where available
  case systemCancelled
  case appCancelled
  case invalidContext
  case notInteractive        // app not active / UI cannot present
  case invalidReason
  case authenticationInProgress
  case watchNotAvailable     // companion watch scenarios
  case underlying(code: Int, domain: String)  // unmapped LAError
}
```

### 10.2 LAError mapping table (normative)

| `LAError.Code` | `FKBiometricError` |
|----------------|-------------------|
| `.authenticationFailed` | `.authenticationFailed` |
| `.userCancel` | `.userCancelled` |
| `.userFallback` | `.userFallback` |
| `.systemCancel` | `.systemCancelled` |
| `.passcodeNotSet` | `.passcodeNotSet` |
| `.biometryNotAvailable` | `.biometryNotAvailable` |
| `.biometryNotEnrolled` | `.biometryNotEnrolled` |
| `.biometryLockout` | `.biometryLockout` |
| `.appCancel` | `.appCancelled` |
| `.invalidContext` | `.invalidContext` |
| `.notInteractive` | `.notInteractive` |
| `.watchNotAvailable` | `.watchNotAvailable` |
| Other | `.underlying(code:domain:)` |

### 10.3 LocalizedError

Implement `LocalizedError` using `FKI18n` keys under `fkcore.biometric.error.*`. **Never** embed raw `localizedReason` from LA in user-facing strings.

### 10.4 Host UX guidance (README)

| Error | Suggested host action |
|-------|----------------------|
| `.userCancelled` | Dismiss flow; no alert |
| `.biometryLockout` | Explain wait / use passcode; link to Settings |
| `.biometryNotEnrolled` | Prompt Settings → Face ID & Passcode |
| `.passcodeNotSet` | Prompt Settings to set passcode |
| `.notInteractive` | Retry when app is active |

---

## 11. Configuration Model

```swift
public struct FKBiometricAuthConfiguration: Sendable, Equatable {
  public var defaultPolicy: FKBiometricPolicy
  public var reuseDuration: TimeInterval?  // LAContext.touchIDAuthenticationAllowableReuseDuration / equivalent
  public var localizedFallbackTitle: String?
  public var invalidateContextAfterSuccess: Bool  // default true
  public var invalidateContextAfterFailure: Bool // default true
}

public struct FKBiometricAuthOptions: Sendable, Equatable {
  public var policy: FKBiometricPolicy?  // nil → configuration.defaultPolicy
  public var allowPasscodeFallback: Bool
  public var reuseDuration: TimeInterval?
  public var localizedFallbackTitle: String?
}
```

### 11.1 Reuse duration

When `reuseDuration > 0`, set on `LAContext` before evaluate to allow recent-auth reuse (document Apple behavior: user may not see UI again within window). Default `nil` (always prompt).

### 11.2 Fallback title

Maps to `localizedFallbackTitle` on `LAContext` when policy supports Enter Password entry.

---

## 12. LAContext Management

### 12.1 Context factory (internal)

- Create **fresh** `LAContext` per `authenticate` call unless reuse window explicitly configured.
- Set `localizedReason`, `localizedFallbackTitle`, reuse duration before evaluate.
- On completion (success or failure), invalidate per configuration flags.

### 12.2 Why fresh contexts

Reusing `LAContext` after `.biometryLockout` or `.invalidContext` causes failures. FKBiometricAuth hides this from hosts.

### 12.3 Info.plist

Document required keys:

| Key | When |
|-----|------|
| `NSFaceIDUsageDescription` | Face ID / Optic ID on supported devices |

Touch ID does not require a separate usage string on modern iOS but README should mention App Store review expectations for auth UX.

---

## 13. Keychain & Storage Integration

### 13.1 v1 scope

FKBiometricAuth **does not** modify `FKKeychainStorage` or `FKKeychainKeyStore` implementations in v1. Integration is **documented patterns**.

### 13.2 Pattern A — App-level gate (v1 recommended)

1. Store secrets with existing `FKKeychainStorage(service:)` (no biometry access control).
2. On sensitive read, call `FKBiometricAuth.authenticate` first.
3. On success, `try storage.value(key:as:)`.

**Pros:** Simple; one auth prompt. **Cons:** Secret bytes in memory after read until host clears.

### 13.3 Pattern B — Keychain access control (v1.1 / documented)

Use `SecAccessControl` with `.biometryCurrentSet` or `.userPresence` when writing items:

```swift
// Illustrative — host or future FKKeychainStorage API
let access = SecAccessControlCreateWithFlags(
  nil,
  kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
  .biometryCurrentSet,
  nil
)
```

`SecItemCopyMatching` may prompt automatically — coordinate with FKBiometricAuth to avoid **double prompts** (authenticate once, then read within reuse window, or rely on Keychain-only prompt).

### 13.4 FKKeychainKeyStore

Same patterns for raw AES key bytes — authenticate before `key(forKey:)` in Pattern A.

### 13.5 Logout

On logout: `FKKeychainStorage.removeAll()` + invalidate any in-memory caches; optional `FKBiometricAuth.cancelAuthentication()`.

---

## 14. Token Unlock Patterns

### 14.1 Session unlock flow

```text
User opens app
  → capability(): not enrolled → show onboarding
  → authenticate(reason:)
  → success → load refresh token from FKKeychainStorage
  → FKNetwork attaches token
```

### 14.2 Background re-auth

Host listens `UIApplication.willEnterForegroundNotification`:

- If idle > N minutes, call `authenticate` again.
- FKBiometricAuth does not register for lifecycle events (keeps module pure).

### 14.3 Failed auth backoff

Host should implement exponential UI backoff on repeated `.authenticationFailed`; FKBiometricAuth does not throttle (Apple may lock out biometry).

---

## 15. Security & Privacy

### 15.1 No biometry storage

**Must not** persist Face ID templates, scores, or LA artifacts. Only boolean success/failure crosses API boundary.

### 15.2 Logging

**Forbidden:**

- Successful biometry raw data (none exists in API)
- Keychain secret values after unlock
- Full `reason` strings in release logs if they contain account identifiers

Allowed: error enum case names, `biometryType`, policy enum.

### 15.3 Jailbreak

Do not claim jailbreak detection in FKBiometricAuth. Refer to `FKSecurity` anti-debug utilities separately if needed.

### 15.4 Threat model (README)

- Protects **casual device sharing** and **shoulder surfing** when combined with app gate.
- Does **not** replace server-side auth or root/jailbreak resistance.

---

## 16. Concurrency & Threading

- Public API safe from any thread; internal serial queue synchronizes `LAContext` usage.
- `authenticate` `async` resumes on **cooperative thread pool**; not guaranteed main — hosts update UI on `@MainActor`.
- `LAContext` evaluate callbacks hop to internal queue before resuming continuation.
- No `@MainActor` on type — FKCoreKit non-UI module.

---

## 17. Pluggable & Dependency Injection

### 17.1 Protocol registration

Optional Pluggable slot:

```swift
// Sources/FKCoreKit/Components/Pluggable/Security/FKBiometricAuthenticating.swift
public protocol FKBiometricAuthenticating: Sendable { ... }
```

Host registers live `FKBiometricAuth.shared` or mock provider in Examples.

### 17.2 Mock implementation (Examples)

```swift
public struct FKMockBiometricAuthenticator: FKBiometricAuthenticating {
  public var capabilityResult: FKBiometricCapability
  public var authenticateOutcome: Result<Void, FKBiometricError>
}
```

Ship in **Examples** for Simulator and demo scenarios (document for integrators).

---

## 18. Localization (FKI18n)

### 18.1 Keys (add to FKCoreKit bundle)

| Key | Purpose |
|-----|---------|
| `fkcore.biometric.error.user_cancelled` | Error description |
| `fkcore.biometric.error.biometry_lockout` | Lockout message |
| `fkcore.biometric.error.biometry_not_enrolled` | Settings hint |
| `fkcore.biometric.reason.unlock_app` | Default reason if host passes key via helper |
| `fkcore.biometric.reason.confirm_action` | Generic confirm |

### 18.2 Reason helpers

```swift
public enum FKBiometricReason {
  public static func unlockApp() -> String
  public static func confirmAction() -> String
  public static func custom(_ key: String) -> String  // FKI18n lookup
}
```

Integrator may still pass arbitrary localized `String` to `authenticate(reason:)`.

---

## 19. Device, Simulator & OS Matrix

| Environment | Capability | Authenticate |
|-------------|------------|--------------|
| Face ID device | `.faceID` | System UI |
| Touch ID device | `.touchID` | System UI |
| Simulator | Often `.none` / not enrolled | Use mock or Features → Face ID → Enrolled |
| No passcode | `passcodeNotSet` | Fail probe |

**iOS 15+** minimum; map `LABiometryType.opticID` when SDK provides.

---

## 20. UIKit / SwiftUI Host Guidance

FKBiometricAuth has **no** UIView. Host patterns:

- **UIKit:** Call from `viewDidAppear` or button action; show `FKEmptyState` if not enrolled (FKUIKit).
- **SwiftUI:** `.task { try await auth.authenticate(...) }` on sensitive view appear.
- **Double presentation:** Disable button while `authenticating`.

Optional future: `FKBiometricGate` UIViewController in FKUIKit ( **non-goal v1** ).

---

## 21. Proposed Source Layout

> **Layout guidance (non-normative):** The directory tree below is a **recommended starting point**, not a mandatory template. Adjust folders and file grouping to fit component complexity and neighboring FKKit components, while keeping the layout **discoverable**, **documented** in the component `README.md`, and aligned with FKKit conventions (clear public vs internal boundaries, English `///`, Swift 6 concurrency). See [COMPONENT_ROADMAP.md — Component source layout policy](COMPONENT_ROADMAP.md#component-source-layout-policy).

```text
Sources/FKCoreKit/Components/BiometricAuth/
├── README.md
├── Public/
│   ├── FKBiometricAuth.swift
│   ├── FKBiometricCapability.swift
│   ├── FKBiometricPolicy.swift
│   ├── FKBiometricError.swift
│   ├── FKBiometricAuthConfiguration.swift
│   ├── FKBiometricAuthOptions.swift
│   ├── FKBiometryType.swift
│   ├── FKBiometricReason.swift
│   └── FKBiometricAuthenticating.swift
├── Internal/
│   ├── FKBiometricContextFactory.swift
│   ├── FKBiometricCapabilityProbe.swift
│   ├── FKBiometricErrorMapper.swift
│   └── FKLAContext+FKBiometric.swift
└── Extension/
    └── FKBiometricAuthenticating+Convenience.swift
```

Pluggable re-export (optional):

```text
Sources/FKCoreKit/Components/Pluggable/Security/FKBiometricAuthenticating.swift
```

(typealias or forward protocol — avoid duplicate protocol definitions)

---

## 22. FKKitExamples Scenarios

Path: `Examples/.../FKCoreKit/BiometricAuth/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `CapabilityInspection` | biometryType, enrolled, passcode set — no UI |
| 2 | `SuccessfulAuthentication` | happy path `async` success |
| 3 | `UserCancel` | cancel → `.userCancelled` |
| 4 | `PolicyComparison` | biometricsOnly vs biometricsOrPasscode |
| 5 | `MockLockout` | mock provider → lockout UX copy |
| 6 | `KeychainUnlockPattern` | authenticate then `FKKeychainStorage` read |
| 7 | `NotEnrolledHint` | capability false → UI hint to Settings |
| 8 | `CancelInFlight` | `cancelAuthentication()` |
| 9 | `ReuseDuration` | optional second auth within window |
| 10 | `LocalizedReasons` | FKI18n fallback reasons |

Hub entry under FKCoreKit alongside `FKSecurity` example.

---

## 24. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | `async throws` vs `Result` return? | `async throws` |
| Q2 | Extend `FKKeychainStorage` with access control in v1? | Document only; v1.1 API |
| Q3 | Ship `FKMockBiometricAuthenticator` publicly? | Public in FKCoreKit for Examples and DI |
| Q4 | Singleton `shared`? | Yes, mirror `FKSecurity.shared` |
| Q5 | Actor vs queue for Sendable? | Serial queue `@unchecked Sendable` |
| Q6 | `FKBiometricGate` UIKit helper in FKUIKit? | Post-v1 |

---

## 25. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §1.7 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKSecurity README](../Sources/FKCoreKit/Components/Security/README.md)
- [FKStorage README](../Sources/FKCoreKit/Components/Storage/README.md)
- [FKWebView_DESIGN.md](FKWebView_DESIGN.md)
