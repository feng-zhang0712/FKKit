# FKNavigationBarScrollTransition — Design Specification

Implementation guide for **`FKNavigationBarScrollTransition`**: an opt-in, behavior-first engine that drives **navigation-bar chrome** (background opacity/color, title/tint colors, shadow, status-bar style) from a scroll view’s vertical offset. This is **not** a custom navigation bar widget and **not** a sticky / affix engine — hosts keep `UINavigationController` / `UINavigationItem` ownership.

**Document type:** Design specification (normative for implementers)  
**Status:** Implemented (v1 — unit tests deferred)  
**Module:** `FKUIKit` → `Sources/FKUIKit/Components/NavigationBarScrollTransition/`  
**Language:** English only (source, APIs, comments, README)  
**Related:** [FKSticky](FKSticky_DESIGN.md) (content-strip affix — orthogonal; often composed on the same page); app-level navigation presets remain host-owned  
**Component README:** [NavigationBarScrollTransition README](../Sources/FKUIKit/Components/NavigationBarScrollTransition/README.md)

---

## Table of contents

- [1. Overview](#1-overview)
- [2. Goals, non-goals, and success criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background and problem statement](#3-background-and-problem-statement)
- [4. Relationship to FKSticky and page chrome](#4-relationship-to-fksticky-and-page-chrome)
- [5. Architecture](#5-architecture)
- [6. Module boundaries](#6-module-boundaries)
- [7. Public API surface](#7-public-api-surface)
- [8. Progress model](#8-progress-model)
- [9. Appearance model](#9-appearance-model)
- [10. Application model](#10-application-model)
- [11. Observation model](#11-observation-model)
- [12. Configuration model](#12-configuration-model)
- [13. Threading and concurrency](#13-threading-and-concurrency)
- [14. Accessibility](#14-accessibility)
- [15. Source layout](#15-source-layout)
- [16. Integration patterns](#16-integration-patterns)
- [17. Pitfalls and hard constraints](#17-pitfalls-and-hard-constraints)
- [18. FKKitExamples](#18-fkkitexamples)
- [19. Design decisions](#19-design-decisions)
- [20. Revision history](#20-revision-history)

---

## 1. Overview

Product screens repeatedly need scroll-driven navigation chrome:

- Hero / banner under a **transparent** bar → solid bar as content scrolls up
- Title / bar-button **tint** flipping from light-on-image to dark-on-solid
- Optional **title fade-in** once the hero leaves the viewport
- **Status bar** style switching at a discrete threshold
- Hairline / shadow fading in with the solid background

Apps currently duplicate offset math, `UINavigationBarAppearance` construction, and push/pop appearance fights. **`FKNavigationBarScrollTransition`** centralizes **progress mapping + appearance interpolation + optional automatic apply**, while hosts own brand presets and navigation stack policy.

| Concern | Owned by this module | Owned by host |
|---------|----------------------|---------------|
| Offset → progress `0…1` | Yes | Threshold distances / hero heights |
| Interpolate continuous chrome fields | Yes | Brand `from` / `to` snapshots |
| Apply `UINavigationBarAppearance` (opt-in) | Yes | When using custom bar systems / FK Base styles |
| Status bar discrete flip | Yes (reported + optional apply hint) | `preferredStatusBarStyle` plumbing |
| Sticky tabs / header collapse | — | FKSticky / page coordinator |
| Brand presets (primary / homeWhite) | — | App appearance layer |

---

## 2. Goals, non-goals, and success criteria

### 2.1 Goals

1. **Behavior module, not a nav bar replacement** — drive system `UINavigationBar` / `UINavigationItem` appearances; do not invent a second bar UI.
2. **Complete v1 scroll→chrome pipeline** — configurable start/end offsets, adjusted-offset option, continuous interpolation, discrete status-bar threshold, auto or manual scroll drive, enable/disable, reset, force progress.
3. **Opt-in apply** — automatic appearance application when configured; otherwise progress + interpolated snapshot via callbacks only.
4. **Composable with FKSticky** — no hard dependency; same scroll view may drive both engines.
5. **Safe defaults** — progress clamped; appearance writes prefer **per-item** `navigationItem` appearances to cooperate with push stacks.
6. **Swift 6 / `@MainActor`** — UI work isolated; configuration / progress value types `Sendable` where practical (`UIColor` snapshots use `@unchecked Sendable` like neighbor widgets).
7. **Open-source quality** — English `///` docs, README directory map, `Package.swift` README exclude.

### 2.2 Non-goals (v1)

| Excluded | Reason |
|----------|---------|
| Brand / app navigation presets | Belong in host (`BaseNavigationAppearance`, theme tokens) |
| Content sticky / affix / reparenting | Belongs to `FKSticky` |
| Header height collapse / nested paging scroll handoff | Page coordinator concern |
| Custom `UINavigationBar` subclass / fake bar overlay | Host may do that; out of scope |
| Large-title morphing beyond standard appearance title attributes | System large-title behavior is fragile; leave `prefersLargeTitles` to host |
| Hiding / showing the navigation bar (`setNavigationBarHidden`) | Different product gesture; easy to break interactive pop |
| Tab bar / toolbar scroll hide | Separate chrome |
| SwiftUI-first API | UIKit-first; bridge later if needed |
| Built-in FKPaging / FKBaseViewController adapters | Host wires progress; avoid BusinessKit coupling in FKUIKit |
| Examples app / unit tests in this delivery | Explicitly deferred by request |

### 2.3 Success criteria (v1)

- [x] Public API covers engine, configuration, appearance snapshots, progress, scroll-view convenience API.
- [x] Continuous fields interpolate; status bar flips at a configurable discrete threshold.
- [x] Automatic apply to `navigationItem` and/or `navigationBar`, plus callback-only mode.
- [x] Component `README.md` + `Package.swift` exclude entry.
- [x] `xcodebuild` **BUILD SUCCEEDED** with `SWIFT_STRICT_CONCURRENCY=complete`.
- [x] FKKitExamples hub (full public-API coverage; unit tests remain deferred).
- [ ] Unit tests (follow-up, only if requested).

---

## 3. Background and problem statement

Naïve scroll-nav implementations fail in production for predictable reasons:

- Writing `navigationBar.backgroundColor` / `isTranslucent` every tick without `UINavigationBarAppearance` → inconsistent on iOS 15+ and during transitions
- Applying only `UINavigationBar.standardAppearance` while `scrollEdgeAppearance` stays transparent → flicker at top
- Mutating the **shared** bar without restoring on disappear → next VC inherits wrong chrome
- Ignoring `adjustedContentInset` when a refresh control or safe-area inset shifts `contentOffset`
- Mixing continuous alpha with discrete status-bar changes without a threshold → illegible icons mid-scroll
- Coupling sticky-tab math into the same type → unreadable APIs and retain cycles

This module owns the **scroll→chrome** slice only.

---

## 4. Relationship to FKSticky and page chrome

```text
UIScrollView.contentOffset
        ├──► FKStickyEngine                    (pin content strips)
        └──► FKNavigationBarScrollEngine       (mutate nav chrome)
```

| | FKSticky | FKNavigationBarScrollTransition |
|--|----------|----------------------------------|
| Mutates | Content views (reparent / overlay) | Navigation bar appearance |
| Typical content | `FKTabBar`, filter strip | System nav bar |
| Progress meaning | Stick transition for a target | Chrome blend `from` → `to` |

They **compose**; they do **not** merge. Hosts that need both attach both engines to the driving scroll view. `FKSticky` `stickyInsetProvider` may read nav height independently — no API bridge required in v1.

---

## 5. Architecture

```text
 UIScrollView ──KVO / handleScroll──► FKNavigationBarScrollEngine
                                            │
                                            ├─ configuration (range, observation, apply policy)
                                            ├─ fromAppearance / toAppearance
                                            ├─ progress (0…1) + resolved appearance
                                            │
                                            ├─ (optional) apply → UINavigationItem / UINavigationBar
                                            └─ callbacks: onProgressChange / onAppearanceChange
```

**Single update pass per scroll tick** (coalesced): read offset → map progress → interpolate → apply if enabled → emit callbacks only when progress changes beyond epsilon (appearance callback when resolved snapshot changes meaningfully).

---

## 6. Module boundaries

| Module | Role |
|--------|------|
| `FKUIKit` / `Components/NavigationBarScrollTransition` | Engine, models, UIScrollView extension |
| `FKCoreKit` | Reuse `BinaryFloatingPoint.fk_lerp` for scalars; no nav-scroll types in Core |
| FKSticky / Paging / BusinessKit | May compose later; no hard dependency |

---

## 7. Public API surface

| Type | Kind | Purpose |
|------|------|---------|
| `FKNavigationBarScrollEngine` | `@MainActor` class | Orchestrates observation, progress, apply |
| `FKNavigationBarScrollConfiguration` | `Sendable` struct | Range, observation, apply policy, thresholds |
| `FKNavigationBarScrollAppearance` | `@unchecked Sendable` struct | From/to chrome snapshot |
| `FKNavigationBarScrollProgress` | `Sendable` struct | `value` + discrete status-bar resolution helpers |
| `FKNavigationBarScrollApplicationTarget` | enum | `.navigationItem` / `.navigationBar` / `.both` |
| `UIScrollView` helpers | extension | `fk_navigationBarScrollEngine`, `fk_handleNavigationBarScroll`, … |

### Engine responsibilities

- Bind weakly to `UIScrollView` and optionally `UIViewController` (for `navigationItem` + status-bar updates)
- Compute progress from configuration range
- Interpolate appearance
- Optionally build and assign `UINavigationBarAppearance` variants (`standard` / `scrollEdge` / `compact` / `compactScrollEdge` when available)
- Expose `progress`, `resolvedAppearance`, `forceProgress`, `reset`, `reload`

---

## 8. Progress model

```text
rawOffset =
  usesAdjustedContentOffset
    ? contentOffset.y + adjustedContentInset.top
    : contentOffset.y

span = max(endOffset - startOffset, ε)
progress = clamp((rawOffset - startOffset) / span, 0, 1)
```

- **`startOffset`**: progress `0` (typically `0` at rest under a transparent bar).
- **`endOffset`**: progress `1` (typically hero/banner height or a design token distance).
- If `endOffset <= startOffset`, progress stays `0` (invalid range is treated as disabled mapping, not a crash).
- **`forceProgress(_:)`** bypasses scroll mapping until `clearForcedProgress()` or `reset()`.
- **Discrete fields** (status bar style): use `to` when `progress >= discreteThreshold`, else `from`. Continuous fields always lerp.

---

## 9. Appearance model

`FKNavigationBarScrollAppearance` fields (v1):

| Field | Continuous? | Notes |
|-------|-------------|-------|
| `backgroundColor` | Yes (RGBA lerp when both sides resolvable) | Combined with `backgroundAlpha` |
| `backgroundAlpha` | Yes | `0` → clear background effect |
| `titleColor` | Yes | Title text attributes |
| `titleAlpha` | Yes | Multiplies into title color alpha |
| `tintColor` | Yes | Bar button / bar tint |
| `shadowAlpha` | Yes | `0` hides shadow; else hairline/shadow color alpha |
| `statusBarStyle` | **Discrete** | Flips at `discreteThreshold` |

Factories:

- `.clear` / transparent-leaning defaults for hero pages
- `.solid(background:title:tint:)` convenience for opaque end state
- Hosts may construct fully custom snapshots

**Blur materials / custom background effects:** not first-class in v1 (hosts can ignore automatic apply and paint via `onAppearanceChange`). Keeps the module honest about what `UINavigationBarAppearance` can express portably.

---

## 10. Application model

### Targets

| Target | Behavior |
|--------|----------|
| `.navigationItem` | Writes `standardAppearance`, `scrollEdgeAppearance`, `compactAppearance`, and `compactScrollEdgeAppearance` (iOS 15+) on the bound VC’s `navigationItem`. **Preferred** for push stacks. |
| `.navigationBar` | Writes the same appearances on `navigationController?.navigationBar`. Use when the host intentionally manages bar-wide chrome. |
| `.both` | Item first, then bar (item wins for the current VC on modern iOS). |

### Automatic apply

When `configuration.appliesAppearanceAutomatically == true` and a binding exists:

1. Build a `UINavigationBarAppearance` from the resolved snapshot:
   - `backgroundAlpha <= epsilon` → `configureWithTransparentBackground()`
   - else → `configureWithOpaqueBackground()` / default configure + colored background
2. Apply title text attributes from `titleColor` × `titleAlpha`
3. Apply shadow via `shadowColor` alpha / `shadowImage` clearing when alpha ~ 0
4. Set `navigationBar.tintColor` when tint is non-`nil` (bar-level tint still needed for button items)
5. If `updatesStatusBarAppearance == true`, call `setNeedsStatusBarAppearanceUpdate()` on the bound VC (host must return `resolvedStatusBarStyle` from `preferredStatusBarStyle`)

### Callback-only

When automatic apply is `false`, engine still updates `progress` / `resolvedAppearance` and invokes:

- `onProgressChange: (FKNavigationBarScrollProgress) -> Void`
- `onAppearanceChange: (FKNavigationBarScrollAppearance, progress: CGFloat) -> Void`

Hosts that use FK Base gradient bars or non-appearance styling use this path exclusively.

---

## 11. Observation model

- Default: KVO on `contentOffset` and `adjustedContentInset` (inset changes shift adjusted progress).
- `observesAutomatically == false`: host calls `handleScroll()` from `scrollViewDidScroll` (same pattern as FKSticky).
- Rebinding `scrollView` tears down prior observations.

---

## 12. Configuration model

`FKNavigationBarScrollConfiguration` (Sendable):

| Property | Default | Role |
|----------|---------|------|
| `isEnabled` | `true` | Master switch; when `false`, freezes updates (last applied chrome remains unless `reset`) |
| `startOffset` | `0` | Progress 0 |
| `endOffset` | `88` | Progress 1 (≈ nav+status ballpark; hosts should set to hero height) |
| `usesAdjustedContentOffset` | `true` | Prefer content-relative offset |
| `observesAutomatically` | `true` | KVO vs manual |
| `appliesAppearanceAutomatically` | `true` | Write appearances |
| `applicationTarget` | `.navigationItem` | Where to write |
| `updatesStatusBarAppearance` | `true` | `setNeedsStatusBarAppearanceUpdate` |
| `discreteThreshold` | `0.5` | Status-bar flip point |
| `progressEpsilon` | `0.001` | Callback / apply coalescing |

---

## 13. Threading and concurrency

- `FKNavigationBarScrollEngine` and UIScrollView helpers are **`@MainActor`**.
- Configuration / progress structs are `Sendable`.
- Appearance structs that store `UIColor` are `@unchecked Sendable` (matches Chip / IconView / Toast neighbors).
- Closures capture `[weak self]` guidance in README; engine does not retain the host VC strongly.

---

## 14. Accessibility

- Do not reduce contrast below HIG mid-transition for long dwell; hosts should choose short `endOffset` or snap via forced progress if needed.
- Status bar and tint must remain readable at both endpoints; mid-lerp illegibility is a host design concern (short transition distances help).
- VoiceOver: no extra accessibility elements; system nav items unchanged.

---

## 15. Source layout

Paths under `Sources/FKUIKit/Components/NavigationBarScrollTransition/`:

### `Public/`

| Folder / file | Role |
|---------------|------|
| `Core/FKNavigationBarScrollEngine.swift` | Orchestrator |
| `Configuration/FKNavigationBarScrollConfiguration.swift` | Policy |
| `Models/FKNavigationBarScrollAppearance.swift` | From/to snapshots + interpolation |
| `Models/FKNavigationBarScrollProgress.swift` | Progress snapshot |
| `Models/FKNavigationBarScrollApplicationTarget.swift` | Apply target enum |

### `Internal/`

| File | Role |
|------|------|
| `FKNavigationBarScrollAssociationKeys.swift` | Associated-object key |
| `FKNavigationBarScrollAppearanceApplicator.swift` | Build/apply `UINavigationBarAppearance` |
| `FKNavigationBarScrollColorInterpolation.swift` | UIColor RGBA lerp helper |

### `Extension/`

| File | Role |
|------|------|
| `UIScrollView+FKNavigationBarScrollTransition.swift` | Convenience API |

### Docs

| File | Role |
|------|------|
| `README.md` | Integrator-facing overview + directory map |
| `docs/FKNavigationBarScrollTransition_DESIGN.md` | This specification |

---

## 16. Integration patterns

### Transparent → solid under a hero

```swift
let engine = scrollView.fk_navigationBarScrollEngine
engine.configuration.endOffset = heroHeight
engine.bind(viewController: self)
engine.fromAppearance = .transparent(tint: .white, statusBarStyle: .lightContent)
engine.toAppearance = .solid(
  backgroundColor: .systemBackground,
  titleColor: .label,
  tintColor: .label,
  statusBarStyle: .darkContent
)
engine.onProgressChange = { [weak self] progress in
  self?.cachedStatusBarStyle = progress.resolvedStatusBarStyle(
    from: engine.fromAppearance,
    to: engine.toAppearance,
    threshold: engine.configuration.discreteThreshold
  )
}
```

Host:

```swift
override var preferredStatusBarStyle: UIStatusBarStyle { cachedStatusBarStyle }
```

### Callback-only with app presets

```swift
engine.configuration.appliesAppearanceAutomatically = false
engine.onAppearanceChange = { appearance, progress in
  // Map into BaseNavigationAppearance / FK Base bar style
}
```

### Manual observation with FKSticky on the same scroll view

```swift
sticky.configuration.observesAutomatically = false
nav.configuration.observesAutomatically = false

func scrollViewDidScroll(_ scrollView: UIScrollView) {
  scrollView.fk_handleStickyScroll()
  scrollView.fk_handleNavigationBarScroll()
}
```

---

## 17. Pitfalls and hard constraints

- Always restore or re-apply endpoint chrome in `viewWillAppear` after push/pop if another VC mutated the shared bar.
- Prefer `.navigationItem` application for stack safety.
- Set `endOffset` to the real collapse distance; the `88` default is only a safe placeholder.
- Do not fight large-title interactive scrub without host testing.
- Dynamic provider colors that do not resolve via `getRed` fall back to end-stop picking (no hue-space magic).

---

## 18. FKKitExamples

Hub: **FKUIKit → NavigationBarScrollTransition** (`FKNavigationBarScrollExamplesHubViewController`).

| Section | Coverage |
|---------|----------|
| Basics | Transparent → solid, title fade, brand blend |
| Application targets | `.navigationBar`, `.both`, callback-only |
| Progress & configuration | Offset range, adjusted offset, status-bar threshold |
| Observation | Manual forwarding + start/stop observing |
| Runtime controls | Enable, force, reload, reset, re-bind |
| Composition | Shared scroll with FKSticky |
| Combined | Interactive playground |

Unit tests remain deferred unless requested.

---

## 19. Design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Engine vs widget | Engine | Matches FKSticky; avoids second nav system |
| Separate from Sticky | Yes | Different mutation target; clearer APIs |
| Per-item appearance default | `.navigationItem` | Safer with `UINavigationController` stacks |
| Status bar discrete | Threshold flip | Cannot interpolate `UIStatusBarStyle` |
| No brand presets in FKUIKit | Host-owned | Keeps library neutral |
| No blur material API in v1 | Deferred | Portability / complexity; callback escape hatch |
| Default `endOffset = 88` | Placeholder | Forces hosts to think; avoids `0` span |

---

## 20. Revision history

| Date | Change |
|------|--------|
| 2026-09-18 | v1 design + implementation (source only; examples/tests deferred) |
