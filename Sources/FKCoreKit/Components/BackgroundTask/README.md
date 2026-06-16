# FKBackgroundTaskManager

Production-grade wrapper for **`BGTaskScheduler`** (App Refresh / Processing) and **`UIApplication.beginBackgroundTask`** (short-lived work after entering background) on iOS 15+.

`FKBackgroundTaskManager` lives in `FKCoreKit`. It does **not** replace **`URLSession` background transfers** — use `FKFileManager` for large file download/upload.

## Table of Contents

- [Overview](#overview)
- [Directory Layout](#directory-layout)
- [Requirements](#requirements)
- [Component Selection](#component-selection)
- [Host Integration Checklist](#host-integration-checklist)
- [Basic Usage](#basic-usage)
- [Handler Lifecycle](#handler-lifecycle)
- [Short-Lived Background Work](#short-lived-background-work)
- [Pluggable / Dependency Injection](#pluggable--dependency-injection)
- [Concurrency](#concurrency)
- [Debug](#debug)

## Overview

| Type | Role |
|------|------|
| `FKBackgroundTaskScheduling` | Sendable Pluggable protocol for BG register + schedule |
| `FKBackgroundWorkExtending` | Sendable protocol for `beginBackgroundTask` |
| `FKBackgroundTaskManager` | Default `BGTaskScheduler` + `UIApplication` orchestration |
| `FKBackgroundTaskRegistration` | Launch-time registration descriptor |
| `FKBackgroundAppRefreshRequest` | App Refresh schedule input |
| `FKBackgroundProcessingRequest` | Processing schedule input (network/power at submit time) |
| `FKBackgroundTaskHandle` | Handler context — completion and expiration |
| `FKBackgroundWorkToken` | Short-lived work token (`end()`) |
| `FKMockBackgroundTaskScheduler` | In-memory mock for tests and Examples |

## Directory Layout

| Path | Responsibility |
|------|----------------|
| `Public/` | Public API types, manager, mock |
| `Internal/` | Scheduler abstraction, registry center, work session, mappers |
| `Extension/` | Debug `pendingTaskRequests()` |

Pluggable protocol: `Components/Pluggable/BackgroundTask/FKBackgroundTaskScheduling.swift`

## Requirements

- Swift 6
- iOS 15+
- `BackgroundTasks.framework`, `UIKit`
- Info.plist: `BGTaskSchedulerPermittedIdentifiers`
- Capabilities: **Background fetch** (App Refresh), **Background processing** (Processing)
- No third-party dependencies

## Component Selection

| Scenario | Use |
|----------|-----|
| Light refresh while app is **not running** | **`FKBackgroundTaskManager`** — `BGAppRefreshTask` |
| Heavier cleanup/sync while app is **not running** | **`FKBackgroundTaskManager`** — `BGProcessingTask` |
| Finish work within ~30s after **entering background** | **`beginBackgroundWork`** |
| Large file transfer | **`FKFileManager`** — background `URLSession` |
| Deferred **foreground** startup work | **`FKBusinessKit.utils.startup`** |
| Observe foreground/background state | **`FKBusinessKit.lifecycle`** |
| In-process delay/debounce | **`FKAsync`** |

## Host Integration Checklist

1. Add identifiers to `BGTaskSchedulerPermittedIdentifiers` in Info.plist (must match code exactly).
2. Enable Background Modes: **Background fetch** and/or **Background processing**.
3. In `application(_:didFinishLaunchingWithOptions:)` **before returning**:
   - Call `registerAppRefresh` / `registerProcessing` for each task.
   - Call `installRegistrations([...])` with matching descriptors.
4. Schedule after user actions or on lifecycle `.background` — not necessarily at launch.
5. Debug with Xcode → **Debug → Simulate Background Tasks** (simulator execution is unreliable).

> **Migration:** After adding `BGTaskSchedulerPermittedIdentifiers`, the system disables `performFetchWithCompletionHandler` and `setMinimumBackgroundFetchInterval`. Use `BGAppRefreshTask` instead.

## Basic Usage

```swift
import FKCoreKit

let refreshID = "com.example.app.refresh.config"
let processingID = "com.example.app.processing.cleanup"

// 1. Register handlers (didFinishLaunching, before return)
try FKBackgroundTaskManager.shared.registerAppRefresh(identifier: refreshID) { handle in
  guard !handle.isExpired else { return false }
  // await pullRemoteConfig()
  return true
}

try FKBackgroundTaskManager.shared.registerProcessing(identifier: processingID) { handle in
  // await deleteExpiredCache()
  return true
}

try FKBackgroundTaskManager.shared.installRegistrations([
  .init(identifier: refreshID, kind: .appRefresh),
  .init(identifier: processingID, kind: .processing),
])

// 2. Schedule after a user action or on background
Task {
  try await FKBackgroundTaskManager.shared.scheduleAppRefresh(
    FKBackgroundAppRefreshRequest(
      identifier: refreshID,
      earliestBeginDate: Date().addingTimeInterval(15 * 60)
    )
  )
}
```

## Handler Lifecycle

- Handlers receive a **`FKBackgroundTaskHandle`** (reference type) — check `isExpired` during long work.
- Return `true` for success, `false` for incomplete work.
- The manager calls `setTaskCompleted(success:)` once; expiration sets `isExpired` and completes with `false` if needed.
- Do **not** call `setTaskCompleted` directly on `BGTask`.

## Short-Lived Background Work

```swift
// Synchronous token; work runs in a detached Task
_ = FKBackgroundTaskManager.shared.beginBackgroundWork(name: "flush") {
  // await analytics.flush()
}
```

Merge multiple quick tasks into one block per `didEnterBackground` (v1 does not nest tokens).

## Pluggable / Dependency Injection

```swift
let scheduler: any FKBackgroundTaskScheduling = FKBackgroundTaskManager.shared

// Tests / Examples
let mock = FKMockBackgroundTaskScheduler()
try mock.registerAppRefresh(identifier: refreshID) { _ in true }
try mock.installRegistrations([.init(identifier: refreshID, kind: .appRefresh)])
```

## Concurrency

- Manager is **not** `@MainActor`; registry is protected by a serial queue.
- BG launch handlers run on a background queue — use `async` work inside handlers.
- `beginBackgroundWork` returns immediately; `work` is `@Sendable async`.
- UI updates inside `work` require `await MainActor.run { ... }`.

## Debug

In **DEBUG** builds, `pendingTaskRequests()` returns readable summaries of pending BG requests. In Release, enable `FKBackgroundTaskManagerConfiguration.debugLogPendingTasks`.

## FKKitExamples

Entry: **FKCoreKit → BackgroundTask** in the example app.

| Scenario | Covers |
|----------|--------|
| Install registrations | Launch wiring, Info.plist, `FKBackgroundTaskManagerConfiguration` |
| Schedule app refresh | `FKBackgroundAppRefreshRequest`, Xcode simulate |
| Schedule processing | Network/power constraints at submit |
| Handler lifecycle | `FKBackgroundTaskHandle`, expiration, `complete()` |
| Begin background work | `FKBackgroundWorkToken`, `FKBackgroundWorkExtending` |
| Cancel & pending | `cancelScheduledTask`, `pendingTaskRequests` |
| Lifecycle flush recipe | BusinessKit + `beginBackgroundWork` + schedule fallback |
| Mock & Pluggable | `FKMockBackgroundTaskScheduler`, errors, protocol injection |
