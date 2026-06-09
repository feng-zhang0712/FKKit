# FKBiometricAuth

Production-grade `LocalAuthentication` wrapper for device-owner verification (Face ID, Touch ID, Optic ID, and device passcode fallback).

`FKBiometricAuth` lives in `FKCoreKit` and provides typed errors, silent capability probing, explicit policy models, and documented Keychain pairing patterns. It does **not** store or process biometric templates.

## Table of Contents

- [Overview](#overview)
- [Directory Layout](#directory-layout)
- [Requirements](#requirements)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Policies](#policies)
- [Capability Probing](#capability-probing)
- [Error Handling](#error-handling)
- [Keychain Integration](#keychain-integration)
- [Configuration](#configuration)
- [Concurrency](#concurrency)
- [Info.plist](#infoplist)
- [Pluggable / Dependency Injection](#pluggable--dependency-injection)
- [Security Notes](#security-notes)

## Overview

| Type | Role |
|------|------|
| `FKBiometricCapability` | Sendable snapshot: hardware type, enrollment, policy evaluability |
| `FKBiometricPolicy` | Maps `LAPolicy` with documented passcode fallback semantics |
| `FKBiometricAuthenticating` | Sendable protocol for Pluggable injection |
| `FKBiometricAuth` | Default `LAContext` orchestration |
| `FKBiometricError` | Stable error classification |
| `FKMockBiometricAuthenticator` | Mock for tests and Examples |

## Directory Layout

| Path | Responsibility |
|------|----------------|
| `Public/` | Public API types and default `FKBiometricAuth` implementation |
| `Internal/` | `LAContext` configuration, capability probe, error mapper |
| `Extension/` | Protocol convenience (`authenticateIfAvailable`, closure overloads) |

## Requirements

- Swift 6
- iOS 15+
- `LocalAuthentication.framework`
- No third-party dependencies

## Installation

`FKBiometricAuth` ships with `FKCoreKit`:

```swift
import FKCoreKit

let auth = FKBiometricAuth.shared
```

## Basic Usage

```swift
import FKCoreKit

let auth = FKBiometricAuth.shared

// 1. Silent capability probe (no UI)
let cap = auth.capability()
guard cap.isBiometryEnrolled else {
  // Guide user to Settings → Face ID & Passcode
  return
}

// 2. Authenticate
do {
  try await auth.authenticate(reason: FKBiometricReason.unlockApp())
  // Proceed with sensitive work
} catch FKBiometricError.userCancelled {
  // Silent exit — no alert needed
} catch FKBiometricError.biometryLockout {
  // Explain lockout; user must wait or use device passcode via Settings
} catch {
  // Other typed errors
}
```

## Policies

| `FKBiometricPolicy` | `LAPolicy` | Passcode fallback |
|---------------------|------------|-------------------|
| `.biometricsOnly` | `.deviceOwnerAuthenticationWithBiometrics` | No |
| `.biometricsOrPasscode` | `.deviceOwnerAuthentication` | Yes |
| `.devicePasscode` | `.deviceOwnerAuthentication` | Yes (biometry may still appear on some OS versions) |

**Recommendations:**

- App unlock / view balance → `.biometricsOrPasscode`
- High-risk confirmation → `.biometricsOnly` when enrolled
- No biometry hardware → `.devicePasscode` or disable feature

Set `FKBiometricAuthOptions.allowPasscodeFallback = false` on `.biometricsOrPasscode` to require biometrics only.

## Capability Probing

`capability(for:)` and `capability()` use `canEvaluatePolicy` only — **never** `evaluatePolicy`. Do not cache results across app lifecycle events; re-probe after returning from Settings or on `didBecomeActive`.

## Error Handling

| Error | Suggested host behavior |
|-------|-------------------------|
| `.userCancelled` | Exit flow silently |
| `.biometryLockout` | Explain wait/passcode recovery |
| `.biometryNotEnrolled` | Guide to Settings → Face ID & Passcode |
| `.passcodeNotSet` | Guide to set device passcode |
| `.notInteractive` | Retry when app is active |

All cases implement `LocalizedError` via FKI18n keys under `fkcore.biometric.error.*`.

## Keychain Integration

### Pattern A — App-layer gate (v1 recommended)

1. Store secrets with `FKKeychainStorage(service:)` (no biometric `SecAccessControl`).
2. Call `FKBiometricAuth.authenticate` before sensitive reads.
3. On success, `try storage.value(key:as:)`.

```swift
try await auth.authenticate(reason: "Unlock wallet")
let token: String = try storage.value(key: "refresh_token", as: String.self)
```

### Pattern B — Keychain AccessControl (document only / future API)

When using `SecAccessControl` with `.biometryCurrentSet`, Keychain reads may trigger their own UI. Coordinate with `reuseDuration` or choose a single authentication path to avoid double prompts.

### Logout

Call `FKKeychainStorage.removeAll()` and optionally `auth.cancelAuthentication()`.

See also: [FKStorage README](../Storage/README.md), [FKSecurity README](../Security/README.md).

## Configuration

```swift
let config = FKBiometricAuthConfiguration(
  defaultPolicy: .biometricsOrPasscode,
  reuseDuration: nil,              // nil = prompt every time
  localizedFallbackTitle: nil,
  invalidateContextAfterSuccess: true,
  invalidateContextAfterFailure: true
)
let auth = FKBiometricAuth(configuration: config)
```

`reuseDuration > 0` sets `LAContext.touchIDAuthenticationAllowableReuseDuration` (behavior per Apple docs).

## Concurrency

- Public API is callable from any thread.
- Internal serial queue protects `LAContext`.
- `authenticate` resumes on the cooperative thread pool — dispatch UI updates to `@MainActor`.
- Only one in-flight authentication per instance; concurrent calls are serialized on the internal queue.
- When the caller's Swift `Task` is cancelled, the active `LAContext` is invalidated and authentication ends with ``FKBiometricError/appCancelled``.

## Info.plist

| Key | When required |
|-----|---------------|
| `NSFaceIDUsageDescription` | Face ID / Optic ID devices |

Touch ID has no separate usage string on modern iOS.

## Pluggable / Dependency Injection

Register `FKBiometricAuth.shared` or `FKMockBiometricAuthenticator` against `FKBiometricAuthenticating` at app launch. See `Components/Pluggable/Security/FKBiometricAuthPluggable.swift`.

## Security Notes

- Never log full authentication `reason` strings in release builds.
- Does not replace server-side authentication.
- Does not detect jailbreak — see `FKSecurity` utilities if needed.
- Biometric templates remain in Apple Secure Enclave; FKBiometricAuth only surfaces success/failure.

## Examples

Runnable scenarios live in **FKKitExamples** → **FKCoreKit** → **BiometricAuth**:

| Hub section | Scenario |
|-------------|----------|
| Inspection & readiness | Capability inspection, Not enrolled guidance |
| Live authentication | Authentication basics, Policy comparison |
| Configuration | Localized reasons & options, Reuse duration |
| Cancellation & lifecycle | Cancel in flight, Swift Task cancellation |
| Testing & integration | Mock & error catalog, Keychain unlock pattern |

Entry: `Examples/FKKitExamples/.../FKCoreKit/BiometricAuth/Hub/FKBiometricAuthExamplesHubViewController.swift`
