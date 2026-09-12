# FKKeyboard — Design Specification

Implementation guide for **`FKKeyboard`**: an opt-in, composition-first keyboard toolkit for UIKit (observation, avoidance, focus scrolling, form navigation, accessory toolbar, and tap-to-dismiss). Replaces the need for global third-party managers (e.g. IQKeyboardManager-style swizzling).

**Document type:** Design specification (normative for implementers)  
**Status:** Implemented (v1 — Examples shipped; unit tests deferred)  
**Module:** `FKUIKit` → `Sources/FKUIKit/Components/Keyboard/`  
**Language:** English only (source, APIs, comments, README, Examples)  
**Roadmap:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.8 (`FKKeyboardToolbar` expanded into full `FKKeyboard`)  
**Component README:** [Keyboard README](../Sources/FKUIKit/Components/Keyboard/README.md)

---

## Table of contents

- [1. Overview](#1-overview)
- [2. Goals, non-goals, and success criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background and problem statement](#3-background-and-problem-statement)
- [4. Architecture](#4-architecture)
- [5. Module boundaries](#5-module-boundaries)
- [6. Public API surface](#6-public-api-surface)
- [7. Observation model](#7-observation-model)
- [8. Avoidance](#8-avoidance)
- [9. Focus scrolling](#9-focus-scrolling)
- [10. Form navigation](#10-form-navigation)
- [11. Accessory toolbar](#11-accessory-toolbar)
- [12. Tap-to-dismiss](#12-tap-to-dismiss)
- [13. Layout-guide helpers](#13-layout-guide-helpers)
- [14. Animation](#14-animation)
- [15. Configuration model](#15-configuration-model)
- [16. Threading and concurrency](#16-threading-and-concurrency)
- [17. Accessibility](#17-accessibility)
- [18. Relationship to existing FKKit types](#18-relationship-to-existing-fkkit-types)
- [19. Source layout](#19-source-layout)
- [20. FKKitExamples](#20-fkkitexamples)
- [21. Migration plan (Sheet / Callout / Toast / BusinessKit)](#21-migration-plan-sheet--callout--toast--businesskit)
- [22. Design decisions](#22-design-decisions)
- [23. Revision history](#23-revision-history)

---

## 1. Overview

Forms, chat composers, sheets, and search footers all need correct behavior when the system keyboard appears. FKKit already has **fragmented** solutions:

| Existing piece | Role | Gap |
|----------------|------|-----|
| `FKSheetPresentationKeyboardCoordinator` | Sheet inset / translate | Sheet-private; not reusable |
| `FKKeyboardAvoidanceStrategy` | Strategy enum (Sheet folder) | Shared name, Sheet-owned location |
| Callout / Toast keyboard observers | Lift / relayout / dismiss | Duplicated notification parsing |
| EmptyState / Search `keyboardLayoutGuide` | Auto Layout shrink | Parallel path, undocumented vs notifications |
| FKBusinessKit Base | VC lifecycle + focus scroll | App-layer glue; depends on primitives that belong in FKUIKit |
| Roadmap §2.8 `FKKeyboardToolbar` | Accessory only | Incomplete without observer / avoidance / navigator |

**`FKKeyboard`** is the single **FKUIKit** home for keyboard primitives. Integrators compose opt-in controllers; nothing runs globally by default.

Custom input views (number pads, OTP keyboards) are **out of scope** for this module — they belong with TextField / input components and attach via `inputView`, optionally reusing `FKKeyboardObserver` for height.

---

## 2. Goals, non-goals, and success criteria

### 2.1 Goals

1. **Complete v1 toolkit** — observation, avoidance, focus scroll, form prev/next/done, toolbar, tap-to-dismiss, layout-guide pin, keyboard-curve animation — so future maintenance is configuration/docs, not new primitives.
2. **Opt-in, no swizzle** — no `UIViewController` method exchange; no automatic app-wide inset mutation.
3. **Composable** — each concern is a small `@MainActor` type; hosts wire what they need.
4. **Coexist with `UIKeyboardLayoutGuide`** — document and support both Auto Layout pinning and notification-driven inset/transform.
5. **Reuse FKCoreKit** — `fk_findFirstResponder`, `fk_endEditing`, window helpers; do not reimplement.
6. **Own shared strategy** — `FKKeyboardAvoidanceStrategy` lives under Keyboard; Sheet keeps using the same type (same module).
7. **Open-source quality** — English DocComments, Sendable configs where possible, README directory map, HIG-friendly toolbar.

### 2.2 Non-goals (v1)

| Excluded | Reason |
|----------|--------|
| Global automatic keyboard manager | Hard to debug; conflicts with modern layout guides |
| Custom `inputView` keyboards | Separate TextField / pad components |
| SwiftUI `FocusState` wrappers | Optional bridge later; UIKit-first |
| Migrating Sheet / Callout / Toast internals in the same change | Follow-up; avoid risky churn |
| Snapshot / unit tests in the delivery that ships the module | Explicitly deferred by product owner |
| macOS / Catalyst | iOS 15+ UIKit only |

### 2.3 Success criteria (v1)

- [x] Public API covers observer, avoidance, focus, form navigator, toolbar, dismiss, layout pin, animate-alongside.
- [x] No Method Swizzling; default construction does not observe until `start()` / install.
- [x] `FKKeyboardAvoidanceStrategy` file lives under `Components/Keyboard/`.
- [x] Component `README.md` + `Package.swift` exclude entry.
- [x] `xcodebuild` **BUILD SUCCEEDED** with `SWIFT_STRICT_CONCURRENCY=complete`.
- [x] Design doc and README reflect shipped Examples; unit tests remain deferred.

---

## 3. Background and problem statement

Third-party “keyboard managers” typically:

- Swizzle `UIViewController.viewWillAppear` and mutate every scroll view.
- Fight interactive keyboard dismissal, sheets, and `keyboardLayoutGuide`.
- Hide ownership of insets (hard to restore on dismiss).

Apple’s direction is **explicit** layout (`UIKeyboardLayoutGuide`) plus optional notification handling for transforms and content insets. FKKeyboard follows that model.

---

## 4. Architecture

```text
                    ┌─────────────────────┐
                    │  FKKeyboardObserver │  ← single notification parser
                    └──────────┬──────────┘
                               │ FKKeyboardInfo
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
 ┌─────────────────┐  ┌────────────────┐  ┌──────────────────┐
 │ AvoidanceCtrl   │  │ FocusScroller  │  │ Host callbacks   │
 │ (inset/translate│  │ (scroll FR)    │  │ (Toast/Sheet…)   │
 └─────────────────┘  └────────────────┘  └──────────────────┘

 Orthogonals (no observer required):
   FKKeyboardToolbar + FKKeyboardFormNavigator
   FKKeyboardDismissController
   FKKeyboardLayout (keyboardLayoutGuide pins)
   FKKeyboard.animate(alongside:)
```

**Ownership:** Avoidance and focus controllers may **own** an internal observer or accept external `FKKeyboardInfo` updates so Sheet can keep a single notification stream later.

---

## 5. Module boundaries

| In FKKeyboard | Not in FKKeyboard |
|---------------|-------------------|
| System keyboard frame / animation metadata | Custom `inputView` UIs |
| Avoidance strategies + appliers | Sheet chrome / detents |
| Focus scroll into visible rect | TextField validation / formatters |
| Prev / next / done among responders | Business VC base classes (FKBusinessKit) |
| Standard accessory toolbar | IQ-style global install |

**Placement:** `FKUIKit` (depends on UIKit + FKCoreKit). FKBusinessKit Base should **consume** these APIs in a later pass.

---

## 6. Public API surface

| Type | Role |
|------|------|
| `FKKeyboardInfo` | Immutable snapshot: frames, height, duration, curve, visibility |
| `FKKeyboardObserver` | Start/stop observation; `current`; `onChange` |
| `FKKeyboardAvoidanceStrategy` | `.disabled` / `.adjustContainer` / `.adjustContentInsets` / `.interactive` |
| `FKKeyboardAvoidanceConfiguration` | Strategy, additional inset, scroll target, safe-area handling |
| `FKKeyboardAvoidanceController` | Applies avoidance to a host view |
| `FKKeyboardFocusConfiguration` | Insets, animated scroll policy |
| `FKKeyboardFocusScroller` | Scrolls first responder (or explicit view) into visible area |
| `FKKeyboardFormNavigator` | Ordered fields; previous / next / done |
| `FKKeyboardToolbarConfiguration` | Titles, visibility of prev/next/done, style |
| `FKKeyboardToolbar` | `UIToolbar` subclass for `inputAccessoryView` |
| `FKKeyboardDismissConfiguration` | Cancels touches in view policy |
| `FKKeyboardDismissController` | Tap gesture → `endEditing` |
| `FKKeyboardLayout` | Pin bottom edges to `keyboardLayoutGuide` |
| `FKKeyboard` | Facade: `animate(alongside:animations:)`, `endEditing(in:)` |

---

## 7. Observation model

### 7.1 Notifications

Observe:

- `UIResponder.keyboardWillChangeFrameNotification`
- `UIResponder.keyboardWillHideNotification` (treated as zero-height change with same parsing)

Parse `userInfo` keys for end frame, duration, and curve. Convert screen frames to a **reference view** when computing intersection height.

### 7.2 `FKKeyboardInfo`

```swift
public struct FKKeyboardInfo: Equatable, Sendable {
  public var endFrameInScreen: CGRect
  public var overlapHeight(in view: UIView) -> CGFloat  // MainActor helper (method)
  public var animationDuration: TimeInterval
  public var animationCurve: UIView.AnimationCurve
  public var animationCurveRawValue: Int
  public var isVisible: Bool
}
```

`overlapHeight` subtracts safe-area bottom when configured so hosts do not double-count home-indicator inset.

### 7.3 Observer lifecycle

- `start()` is idempotent; `stop()` removes tokens and optionally posts a zero-height update.
- `deinit` always stops.
- Callbacks hop to `@MainActor`.

---

## 8. Avoidance

### 8.1 Strategies (existing enum, relocated)

| Case | Behavior |
|------|----------|
| `.disabled` | No layout mutation |
| `.adjustContentInsets` | Add keyboard overlap to scroll `contentInset` / indicator insets; restore originals on stop |
| `.adjustContainer` | Translate host (or configured container) upward by overlap |
| `.interactive` | Same as adjust container for v1 frame updates; reserved for tracking interactive dismiss / keyboard follow (best-effort; document limits) |

### 8.2 Scroll discovery

When no explicit `UIScrollView` is set:

1. Use the controller’s weak `scrollView` if provided.
2. Else DFS for a primary scroll view (prefer visible, largest bounds) — same idea as Sheet’s finder, implemented inside Keyboard Internal so Sheet can later call into it.

### 8.3 Safe area

Default: `overlap = max(0, intersectionHeight - safeAreaInsets.bottom) + additionalBottomInset`.

---

## 9. Focus scrolling

When keyboard info changes, editing begins, or on demand:

1. Resolve target: sticky ``alignmentRectInContent`` / ``alignmentView``, else explicit ``focusedView``, else `rootView.fk_findFirstResponder()`.
2. Convert target bounds to scroll view content space.
3. By default (`alignsFocusedViewToKeyboard = true`), **pin** the field just above the keyboard whenever focus or keyboard frame changes. Do **not** expand temporary top inset when the scroll view is already at the top.
4. Opt out with `alignsFocusedViewToKeyboard = false` for **minimum** movement only when the field would be covered (or violate `keyboardDistanceFromFocusedView`).
5. **Comment / reply:** ``alignContentRect(_:toKeyboardUsing:additionalBottomInset:)`` (preferred) or ``alignBottom(of:toKeyboardUsing:additionalBottomInset:)`` always pins without top-inset expansion. Begin-editing does not retarget away from the alignment target. Pair with ``FKKeyboardLayout`` for the composer; set `appliesKeyboardBottomInset = false` when the scroll view is already pinned above the composer.
6. When `animatesAlongsideKeyboard` is `true`, apply inset/offset changes with ``FKKeyboard/animate(alongside:animations:completion:)`` using the keyboard duration/curve.
7. No-op if target is not inside the scroll view.

Reuse `UIView.fk_findFirstResponder` from FKCoreKit. Prefer ``FKKeyboardAvoidanceController``’s built-in focus scroll when that controller already owns scroll insets; do not stack ``FKKeyboardFocusScroller`` on the same scroll view.

---

## 10. Form navigation

`FKKeyboardFormNavigator`:

- Maintains an ordered list of focusable views (`UITextField` / `UITextView` / any `UIView` that can become first responder).
- `focusPrevious()` / `focusNext()` / `resignFocus()` (done).
- Exposes `canGoPrevious` / `canGoNext` for toolbar enabling.
- Optional auto-discovery of text inputs under a root view (stable DFS order).

Integrates with `FKKeyboardToolbar` via callbacks — navigator does not own the toolbar.

---

## 11. Accessory toolbar

`FKKeyboardToolbar`: `UIToolbar` suitable as `inputAccessoryView`.

- Items: Previous, Next, flexible space, Done (configurable).
- Uses system or custom titles; Dynamic Type–friendly bar appearance.
- Batch helpers: `install(asAccessoryOn:)` / `install(onFormRoot:navigator:)` attach `inputAccessoryView` and optionally wire a navigator.

Wire to navigator:

```swift
toolbar.onPrevious = { navigator.focusPrevious() }
toolbar.onNext = { navigator.focusNext() }
toolbar.onDone = { navigator.resignFocus() }
navigator.onNavigationAvailabilityChange = { toolbar.updateNavigation(canGoPrevious:canGoNext:) }
```

---

## 12. Tap-to-dismiss

`FKKeyboardDismissController` installs a (configurable) tap gesture on a container view:

- Calls `view.endEditing(true)` / `fk_endEditing` on the owning VC when appropriate.
- `cancelsTouchesInView = false` by default so controls keep working.
- Does not dismiss when tap is inside an active text input (hit-test).

---

## 13. Layout-guide helpers

`FKKeyboardLayout` static helpers:

- Pin a view’s bottom to `host.keyboardLayoutGuide.topAnchor` (iOS 15+).
- Optional identifiers for debugging.

This is the **preferred** path for new scroll/composer UIs; notification avoidance remains for transforms and legacy inset-based screens.

---

## 14. Animation

`FKKeyboard.animate(alongside:info:animations:completion:)` maps `animationCurveRawValue` to `UIView.AnimationOptions` (shift by 16, matching UIKit keyboard animation convention) and uses `info.animationDuration`.

---

## 15. Configuration model

All configurations:

- `Sendable` where free of UIKit reference types.
- Weak scroll / view targets via `weak` properties on controllers (controllers are classes, not configs).
- Sensible defaults: avoidance off until `start()`; focus animated; toolbar shows prev/next/done; dismiss gesture does not cancel touches.

---

## 16. Threading and concurrency

- All UI-mutating types are `@MainActor`.
- `FKKeyboardInfo` is a `Sendable` value; overlap helpers that take `UIView` are `@MainActor`.
- Observer notification handlers run on the main queue and update state / `onChange` synchronously so keyboard-curve animations stay in the system transaction.

---

## 17. Accessibility

- Toolbar buttons expose clear accessibility labels (“Previous field”, “Next field”, “Done”).
- Focus scrolling should not disable VoiceOver focus; prefer inset-aware content-offset adjustment over forced `becomeFirstResponder` storms.
- Done resigns keyboard without trapping VoiceOver in a dead field.

---

## 18. Relationship to existing FKKit types

| Type | Action in v1 |
|------|----------------|
| `FKKeyboardAvoidanceStrategy` | **Move** file to `Components/Keyboard/Public/Types/` (same symbol; Sheet continues to compile) |
| `FKSheetPresentationKeyboardCoordinator` | Unchanged; later refactor to call Keyboard Internal |
| Callout / Toast observers | Unchanged; later subscribe to shared observer |
| `FKCalloutKeyboardAvoidance` | Remains Callout-specific policy (relayout / dismiss) |
| `FKWeakReference` | Not required; controllers use `weak` properties |
| `UIView.fk_findFirstResponder` / `UIViewController.fk_endEditing` | Required reuse |

---

## 19. Source layout

```text
Sources/FKUIKit/Components/Keyboard/
├── README.md
├── Public/
│   ├── Core/
│   │   ├── FKKeyboard.swift
│   │   ├── FKKeyboardInfo.swift
│   │   └── FKKeyboardObserver.swift
│   ├── Types/
│   │   └── FKKeyboardAvoidanceStrategy.swift   # relocated from Sheet
│   ├── Configuration/
│   │   ├── FKKeyboardAvoidanceConfiguration.swift
│   │   ├── FKKeyboardFocusConfiguration.swift
│   │   ├── FKKeyboardToolbarConfiguration.swift
│   │   └── FKKeyboardDismissConfiguration.swift
│   ├── Avoidance/
│   │   └── FKKeyboardAvoidanceController.swift
│   ├── Focus/
│   │   ├── FKKeyboardFocusScroller.swift
│   │   └── FKKeyboardFormNavigator.swift
│   ├── Toolbar/
│   │   └── FKKeyboardToolbar.swift
│   ├── Dismiss/
│   │   └── FKKeyboardDismissController.swift
│   └── Layout/
│       └── FKKeyboardLayout.swift
└── Internal/
    ├── FKKeyboardNotificationParsing.swift
    ├── FKKeyboardEditingObservation.swift
    ├── FKKeyboardScrollInsetApplier.swift
    ├── FKKeyboardVisibleRectScrolling.swift
    └── FKKeyboardScrollViewDiscovery.swift
```

`Package.swift`: add `"Components/Keyboard"` to `fkUIKitComponentDocDirectories`.

---

## 20. FKKitExamples

Entry: **FKKitExamples → FKUIKit → Keyboard** (`FKKeyboardExamplesHubViewController`).

Grouped hub sections cover observation, avoidance strategies, layout guide, focus/form/toolbar, dismiss, facade helpers, and a combined full-form recipe.

---

## 21. Migration plan (Sheet / Callout / Toast / BusinessKit)

| Phase | Work |
|-------|------|
| **v1 (this delivery)** | New module + relocate strategy enum; no behavior change for Sheet/Callout/Toast |
| **v1.1** | Sheet coordinator delegates parsing / inset apply to Keyboard Internal |
| **v1.2** | Toast / Callout consume `FKKeyboardObserver` |
| **v1.3** | FKBusinessKit Base wraps Avoidance + Focus + Dismiss |

---

## 22. Design decisions

| Decision | Rationale |
|----------|-----------|
| Opt-in controllers vs global singleton | Predictable ownership; open-source consumers can audit |
| Keep notification path + layout guide | Real apps need both |
| Toolbar separate from navigator | Same toolbar can drive custom focus logic |
| Do not ship custom pads here | Different product surface; avoids mega-module |
| Relocate strategy enum, don’t rename | Stable public symbol already used by Sheet config |
| Defer Sheet refactor | Low-risk first ship; design already specifies migration |

---

## 23. Revision history

| Date | Change |
|------|--------|
| 2026-09-11 | Initial English design for `FKKeyboard` v1 (observation, avoidance, focus, form nav, toolbar, dismiss, layout, animation). |
| 2026-09-11 | Additive gaps: `isLocal` keyboard filtering, begin-editing focus tracking, Return-key helper, toolbar batch install, `FKKeyboardInfo.from(notification:)`. |
| 2026-09-12 | Finishing pass: Examples marked shipped; IQ-style focus align + short-content top inset; docs/API cleanup. |
| 2026-09-12 | Focus scroll default: minimum movement when already clear of keyboard; `alignsFocusedViewToKeyboard` opt-in for IQ pin. |
| 2026-09-12 | `alignBottom(of:)` + sticky `alignmentView` for comment-cell ↔ keyboard alignment; `appliesKeyboardBottomInset`. |
| 2026-09-12 | Pin-to-keyboard becomes default (`alignsFocusedViewToKeyboard = true`) without forced top pull-down; `alignContentRect`; remove dead IQ extra-top pin path. |
