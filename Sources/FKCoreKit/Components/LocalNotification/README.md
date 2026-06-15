# FKLocalNotificationManager

Production-grade `UserNotifications` wrapper for scheduling, querying, and responding to **local** notifications on iOS 15+.

`FKLocalNotificationManager` lives in `FKCoreKit`. It does **not** register APNs tokens or parse remote push payloads. Request notification permission via `FKPermissions` before scheduling — this manager never prompts.

## Table of Contents

- [Overview](#overview)
- [Directory Layout](#directory-layout)
- [Requirements](#requirements)
- [Component Selection](#component-selection)
- [Basic Usage](#basic-usage)
- [Permissions](#permissions)
- [Triggers & Identifiers](#triggers--identifiers)
- [Categories & Actions](#categories--actions)
- [Foreground Presentation](#foreground-presentation)
- [Response & Deeplink](#response--deeplink)
- [Query & Badge](#query--badge)
- [Pending Limit](#pending-limit)
- [Pluggable / Dependency Injection](#pluggable--dependency-injection)
- [Concurrency](#concurrency)
- [Security Notes](#security-notes)

## Overview

| Type | Role |
|------|------|
| `FKLocalNotificationScheduling` | Sendable Pluggable protocol for DI |
| `FKLocalNotificationManager` | Default `UNUserNotificationCenter` orchestration |
| `FKLocalNotificationRequest` | Scheduling input: content + trigger + metadata |
| `FKLocalNotificationContent` | Title, body, sound, badge, `userInfo` |
| `FKLocalNotificationTrigger` | `timeInterval`, `calendar`, or `immediate` |
| `FKLocalNotificationCategory` | Registered categories with action buttons |
| `FKLocalNotificationResponseHandler` | Tap/action callback |
| `FKMockLocalNotificationScheduler` | In-memory mock for tests and Examples |

## Directory Layout

| Path | Responsibility |
|------|----------------|
| `Public/` | Public API types, manager, mock |
| `Internal/` | UN mappers, delegate adapter, center abstraction |
| `Extension/` | Optional `FKBusinessKit` deeplink bridge |

Pluggable protocol: `Components/Pluggable/Notifications/FKLocalNotificationScheduling.swift`

## Requirements

- Swift 6
- iOS 15+
- `UserNotifications.framework`
- No third-party dependencies

## Component Selection

| Scenario | Use |
|----------|-----|
| App in **foreground**, persistent strip (upgrade, offline) | `FKBanner` (FKUIKit) |
| App in **foreground**, brief feedback | `FKToast` (FKUIKit) |
| App in **background/lock screen**, timed reminders | **`FKLocalNotificationManager`** |
| Remote APNs payload routing | Host `AppDelegate` + Pluggable `FKPushNotificationRouting` (v2) |

## Basic Usage

```swift
import FKCoreKit

// 1. Request permission (never inside the manager)
let result = await FKPermissions.shared.request(
  .notifications,
  prePrompt: FKPermissionPrePrompt(
    title: "Stay Updated",
    message: "We send reminders for orders and messages."
  )
)
guard result.isGranted else { return }

// 2. Schedule
let request = FKLocalNotificationRequest(
  identifier: "order.reminder.12847",
  content: FKLocalNotificationContent(
    title: "Order Ready",
    body: "Your order is ready for pickup."
  ),
  trigger: .timeInterval(10, repeats: false)
)

try await FKLocalNotificationManager.shared.schedule(request)
```

## Permissions

| `FKPermissionStatus` | Can schedule |
|----------------------|--------------|
| `.authorized` | Yes |
| `.provisional` | Yes (quiet delivery) |
| `.ephemeral` | Yes |
| `.notDetermined`, `.denied`, `.restricted` | No — throws `FKLocalNotificationError.notAuthorized` |

```swift
if await FKLocalNotificationManager.shared.canScheduleNotifications() {
  try await FKLocalNotificationManager.shared.schedule(request)
}
```

## Triggers & Identifiers

- **Identifiers:** use stable names like `{domain}.{feature}.{id}`; re-scheduling the same id **replaces** the pending request.
- **`timeInterval`:** must be `> 0`; repeating intervals must be **≥ 60 seconds** (system requirement).
- **`calendar`:** at least one non-nil `DateComponents` field; specify `timezone` explicitly when needed.
- **`immediate`:** maps to `trigger: nil` for immediate delivery.

## Categories & Actions

Register categories at launch:

```swift
let category = FKLocalNotificationCategory(
  identifier: "message",
  actions: [
    FKLocalNotificationAction(identifier: "mark_read", title: "Mark Read"),
    FKLocalNotificationAction(identifier: "snooze", title: "Snooze", options: .foreground),
  ]
)
try await FKLocalNotificationManager.shared.registerCategories([category])
```

Scheduling with an unregistered `categoryIdentifier` still delivers the notification but logs a debug warning — custom actions will not appear.

## Foreground Presentation

By default the manager does **not** install `UNUserNotificationCenter.delegate`. Call once from `AppDelegate`:

```swift
FKLocalNotificationManager.shared.installDelegate(presentation: [.banner, .list, .sound])
```

**Warning (v1):** this replaces any existing delegate. Coordinate with remote-push SDKs or wait for v1.1 delegate chaining.

## Response & Deeplink

```swift
FKLocalNotificationManager.shared.setResponseHandler { response in
  print(response.requestIdentifier, response.actionIdentifier)
}

// Optional BusinessKit bridge
FKLocalNotificationManager.shared.useBusinessKitDeeplink()

// Or custom router
FKLocalNotificationManager.shared.setDeeplinkRouter { url in
  MyRouter.shared.open(url)
}
```

Standard `userInfo` keys:

| Key | Constant |
|-----|----------|
| Deeplink URL | `FKLocalNotificationUserInfoKey.deeplinkURL` |
| Route ID | `FKLocalNotificationUserInfoKey.routeID` |
| Analytics event | `FKLocalNotificationUserInfoKey.analyticsEvent` |

## Query & Badge

```swift
let pending = await FKLocalNotificationManager.shared.pendingRequests()
let delivered = await FKLocalNotificationManager.shared.deliveredNotifications()

try await FKLocalNotificationManager.shared.setBadgeCount(3)
try await FKLocalNotificationManager.shared.clearBadge()
```

## Pending Limit

iOS retains at most **~64** pending local notifications. Additional requests are **silently dropped** with no error callback. Monitor `pendingRequests().count` in reminder-style apps.

`cancelAllPending()` and `removeAllDelivered()` affect **all** notifications for your app in the system queue, not only those scheduled through this manager.

## Pluggable / Dependency Injection

```swift
let scheduler: any FKLocalNotificationScheduling = FKLocalNotificationManager.shared
// Tests / previews:
let mock = FKMockLocalNotificationScheduler()
```

## Concurrency

- `FKLocalNotificationManager` is **not** `@MainActor`; scheduling APIs are `async`.
- `FKPermissions` is `@MainActor` — authorization checks hop to the main actor internally.
- Delegate callbacks run on the main queue; `FKLocalNotificationResponseHandler` is invoked on the main queue.

## Security Notes

- Do not store tokens, passwords, or PII in `userInfo` — use opaque ids.
- Validate deeplink URLs before routing.
- `interruptionLevel: .timeSensitive` requires the Time Sensitive Notifications capability.
- Release builds should not log full `userInfo` payloads.

## Examples

See `Examples/FKKitExamples/.../FKCoreKit/LocalNotification/` — hub entry **LocalNotification** under FKCoreKit:

| Scenario | Demonstrates |
|----------|----------------|
| B1 Permission gate | `FKPermissions`, `canScheduleNotifications`, `.notAuthorized` |
| B2 Interval & content | `timeInterval`, `immediate`, rich `FKLocalNotificationContent`, repeating ≥60s, `installDelegate` |
| B3 Calendar daily | `FKLocalNotificationCalendarTrigger`, `pendingRequests()` |
| B4 Category actions | `registerCategories`, action buttons, response handler |
| Foreground presentation | `FKLocalNotificationPresentationOptions` |
| B5 Cancel & query | replace-by-id, batch schedule/cancel, `deliveredNotifications`, `removeDelivered` |
| B6 Badge | `setBadgeCount`, `clearBadge`, content badge |
| B7 Deeplink tap | `useBusinessKitDeeplink`, `setDeeplinkRouter`, `routeDeeplinkBeforeResponseHandler` |
| B8 Mock & Pluggable | `FKMockLocalNotificationScheduler`, `FKLocalNotificationScheduling`, validation errors |
