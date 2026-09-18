# FKSticky — Design Specification

Implementation guide for **`FKSticky`**: an opt-in, behavior-first sticky / affix engine for UIKit scroll containers. Pins arbitrary strip / bar / header views to a viewport edge (or coordinated multi-target push-off) while content scrolls underneath. This is **not** a visual chrome control — hosts supply their own `UIView` content (`FKTabBar`, filter strips, custom bars, etc.).

**Document type:** Design specification (normative for implementers)  
**Status:** Implemented (v1 — Examples and unit tests deferred by request)  
**Module:** `FKUIKit` → `Sources/FKUIKit/Components/Sticky/`  
**Language:** English only (source, APIs, comments, README)  
**Related:** [Search `FKSearchBarPlacement`](../Sources/FKUIKit/Components/SearchViewController/Public/FKSearchBarPlacement.swift) (page-level sticky chrome); [Sheet `FKAnchor`](../Sources/FKUIKit/Components/SheetPresentationController/Public/Anchor/FKAnchor.swift) (popover/sheet anchoring — different problem)  
**Component README:** [Sticky README](../Sources/FKUIKit/Components/Sticky/README.md)

---

## Table of contents

- [1. Overview](#1-overview)
- [2. Goals, non-goals, and success criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background and problem statement](#3-background-and-problem-statement)
- [4. Problem taxonomy](#4-problem-taxonomy)
- [5. Architecture](#5-architecture)
- [6. Module boundaries](#6-module-boundaries)
- [7. Public API surface](#7-public-api-surface)
- [8. Geometry and state machine](#8-geometry-and-state-machine)
- [9. Multi-target collision](#9-multi-target-collision)
- [10. Overlay host and placeholders](#10-overlay-host-and-placeholders)
- [11. Observation model](#11-observation-model)
- [12. Configuration model](#12-configuration-model)
- [13. Threading and concurrency](#13-threading-and-concurrency)
- [14. Accessibility](#14-accessibility)
- [15. Relationship to existing FKKit types](#15-relationship-to-existing-fkkit-types)
- [16. Source layout](#16-source-layout)
- [17. Integration patterns](#17-integration-patterns)
- [18. Pitfalls and hard constraints](#18-pitfalls-and-hard-constraints)
- [19. FKKitExamples (deferred)](#19-fkkitexamples-deferred)
- [20. Design decisions](#20-design-decisions)
- [21. Revision history](#21-revision-history)

---

## 1. Overview

Product screens repeatedly need “adsorb / stick” behavior:

- Filter / category strips that pin under the navigation bar after scrolling
- In-content tab headers that remain visible while paging content scrolls
- Section-like bars that push each other off (next bar replaces the current sticky one)
- Footer toolbars that pin above the home indicator / keyboard inset (viewport pin)

Historically FKKit briefly shipped `FKSticky` / `FKStickyHeader` and later removed them. Sticky placement today appears only as **page policy** inside composites (e.g. `FKSearchBarPlacement.stickyHeader` / `.stickyFooter`). That leaves generic scroll sticky as duplicated business glue.

**`FKSticky`** restores a **reusable behavior engine** in FKUIKit:

| Concern | Owned by FKSticky | Owned by host |
|---------|-------------------|---------------|
| Scroll geometry, pin threshold, push-off | Yes | — |
| Placeholder / overlay hosting | Yes | — |
| Lifecycle + progress callbacks | Yes | React (shadow, separators) |
| Visual content (titles, tabs, filters) | — | Yes (`FKTabBar`, custom views, …) |
| Business selection / networking | — | Yes |

---

## 2. Goals, non-goals, and success criteria

### 2.1 Goals

1. **Behavior module, not a chrome widget** — attach any `UIView`; do not invent a second TabBar.
2. **Complete v1 scroll sticky** — top/bottom edges, sticky inset (avoid nav overlays), multi-target push-off, placeholder, progress, lifecycle callbacks, enable/disable, force-stick, reload/reset.
3. **Opt-in** — nothing runs until a host creates / retrieves an engine and adds targets.
4. **Automatic or manual drive** — KVO on scroll metrics by default; `handleScroll()` for hosts that already forward `scrollViewDidScroll`.
5. **Safe defaults** — preserve layout space via placeholders; pin overlay to `UIScrollView.frameLayoutGuide` (does not scroll away).
6. **Swift 6 / `@MainActor`** — UI work isolated; configuration structs `Sendable` where practical.
7. **Open-source quality** — English `///` docs, README directory map, `Package.swift` README exclude.

### 2.2 Non-goals (v1)

| Excluded | Reason |
|----------|--------|
| Visual strip / tab UI | Belongs to `FKTabBar`, Search chrome, business views |
| Anchor-to-arbitrary-sibling popovers | Use Callout / Sheet `FKAnchor` |
| Replacing UITableView plain section-header sticky | System behavior; reparenting headers is unsafe |
| Fighting `UICollectionViewCompositionalLayout` `pinToVisibleBounds` | Prefer system pin when it already solves the case; document coexistence |
| Global `FKStickyManager` singleton that mutates every scroll view | Hard to debug; conflicts with host ownership |
| SwiftUI-first API | Optional bridge later; UIKit-first |
| Examples app / unit tests in this delivery | Explicitly deferred |

### 2.3 Success criteria (v1)

- [x] Public API covers engine, targets, configuration, state/progress, scroll-view convenience API.
- [x] Overlay hosted above the scroll view (superview frame sync); placeholders prevent content jump.
- [x] Multi-target top (and bottom) push-off.
- [x] Component `README.md` + `Package.swift` exclude entry.
- [x] `xcodebuild` **BUILD SUCCEEDED** with `SWIFT_STRICT_CONCURRENCY=complete`.
- [x] FKKitExamples hub (full public-API coverage; unit tests remain deferred).
- [ ] Unit tests (follow-up, only if requested).

---

## 3. Background and problem statement

Naïve sticky implementations fail in production for predictable reasons:

- Mutating `frame` every scroll tick without a placeholder → content jumps
- Reparenting into the window without hit-test / rotation / split-view handling
- Ignoring `adjustedContentInset` (refresh headers, safe area, keyboard)
- Double-processing with system sticky headers
- Per-frame target rebuild → jank
- Retain cycles between scroll view, engine, and target callbacks

FKSticky centralizes geometry + lifecycle so business code only supplies content and policy.

---

## 4. Problem taxonomy

| Kind | Description | FKSticky v1 |
|------|-------------|-------------|
| **Scroll sticky** | View scrolls with content until it hits a viewport edge, then pins | **Primary** |
| **Viewport pin** | Always pinned to safe area / keyboard (Search sticky footer) | Supported via bottom edge + inset provider; full keyboard tracking remains host/Keyboard concern |
| **Anchor affix** | Stick to another view’s edge while that view moves | **Out of scope** → `FKAnchor` / Callout |

---

## 5. Architecture

```text
 UIScrollView
      │
      ├─ content (targets live here while idle)
      │
      └─ FKStickyOverlayHost  ← constrained to frameLayoutGuide
              └─ stuck target views (reparented while stuck)

 FKStickyEngine
      ├─ configuration (Sendable)
      ├─ sessions[targetID] → placeholder, original parent, natural origin, state
      ├─ KVO: contentOffset / bounds / contentSize / adjustedContentInset
      └─ layout pass: compute desired frames → apply reparent / push-off / callbacks
```

**Single layout pass per scroll tick** (coalesced): read metrics → sort enabled targets → compute desired viewport Y → apply hosting → emit state/progress only on change.

---

## 6. Module boundaries

| Module | Role |
|--------|------|
| `FKUIKit` / `Components/Sticky` | Sticky engine, models, UIScrollView extension |
| `FKCoreKit` | Reuse existing scroll helpers if needed; no sticky types in Core |
| Search / Paging / BusinessKit | May **consume** FKSticky later; not required for v1 land |

Do **not** duplicate sticky math inside Search in this change set (migration is a follow-up).

---

## 7. Public API surface

| Type | Kind | Purpose |
|------|------|---------|
| `FKStickyEngine` | `@MainActor` class | Orchestrates targets, observation, layout |
| `FKStickyTarget` | `@MainActor` class | One stickable view + callbacks + per-target overrides |
| `FKStickyConfiguration` | `Sendable` struct | Edge, insets, observation, placeholder, collision, hysteresis, appearance |
| `FKStickyCollisionBehavior` | enum | `.pushOff` / `.stack` |
| `FKStickyEdge` | enum | `.top` / `.bottom` |
| `FKStickyState` | enum | `.idle` / `.sticking` / `.stuck` / `.unsticking` |
| `FKStickyProgress` | struct | Normalized 0…1 + state snapshot |
| `UIScrollView` helpers | extension | `fk_stickyEngine`, `fk_addStickyTarget`, `fk_reloadStickyLayout`, `fk_resetSticky`, `fk_handleStickyScroll` |

### 7.1 Typical call site

```swift
let engine = scrollView.fk_stickyEngine
engine.configuration.stickyInset = navigationChromeHeight
engine.add(
  FKStickyTarget(id: "filters", view: filterStrip) { progress in
    filterStrip.layer.shadowOpacity = Float(progress.value) * 0.18
  }
)
// Optional if observesAutomatically == false:
// engine.handleScroll()
```

---

## 8. Geometry and state machine

### 8.1 Coordinate spaces

- **Content space:** positions as if laid out inside scrollable content (`convert` into scroll view, then add `contentOffset`).
- **Viewport space:** positions relative to the scroll view’s visible bounds (overlay / `frameLayoutGuide`).

Natural content origin is captured (and refreshed on `reloadLayout`) while the target is **idle** in its original superview.

### 8.2 Top-edge threshold

Stick decisions use the target’s frame in the scroll view’s **bounds** (visible) space:

```text
pinLineViewportY = adjustedContentInset.top + stickyInset
stick when: view.convert(bounds, to: scrollView).minY <= pinLineViewportY
```

Do **not** add `contentOffset` on top of a bounds-space rect — that double-counts and prevents sticking.

Content-space origin (for restore / push-off) is derived as `boundsOrigin + contentOffset` and frozen when a target becomes stuck.

### 8.3 Bottom-edge threshold

Mirrored using `bounds.height - adjustedContentInset.bottom - stickyInset - height`.

### 8.4 States

| State | Meaning |
|-------|---------|
| `idle` | In original hierarchy; scrolling with content |
| `sticking` | Crossing threshold; progress in (0, 1) within `transitionDistance` |
| `stuck` | Hosted in overlay at pin position (possibly push-offset) |
| `unsticking` | Leaving stuck; progress decreasing |

Progress uses `transitionDistance` from configuration (default small positive value). Callbacks fire on state transitions and when progress changes beyond an epsilon.

---

## 9. Multi-target collision

Controlled by ``FKStickyCollisionBehavior`` (default `.pushOff`). ``FKStickyConfiguration/allowsPushOff`` remains as a convenience (`true` → `.pushOff`, `false` → `.stack`).

### 9.1 Push-off (default)

1. Sort enabled targets by natural content position along the sticky axis.
2. Each candidate that has crossed its threshold receives a desired pin Y.
3. The **next** target’s natural viewport position clamps the previous target’s Y so the previous view is pushed off as the next arrives (classic section-header behavior).

### 9.2 Stack

Targets that have crossed the threshold remain stuck **simultaneously**, stacked along the pin edge (e.g. filter strip under a tab bar). Earlier targets occupy space; later ones pin below (top edge) or above (bottom edge) them.

Priority (`FKStickyTarget.priority`) breaks ties when natural positions are equal.

---

## 10. Overlay host and placeholders

### Overlay

- `FKStickyOverlayHost` is a non-interactive container (`isUserInteractionEnabled = true` so stuck controls remain tappable; empty areas pass through via hit-test override).
- **Preferred:** hosted as a **sibling** on `scrollView.superview`, framed to `scrollView.frame` (viewport in parent coordinates). Frame updates are no-ops during rubber-band (offset-only) changes — critical for `UITableView` near max content offset.
- **Fallback:** in-scroll host synced to `contentOffset` + `bounds.size` only when the scroll view has no superview yet; engine reattaches to the parent via `ensurePreferredHosting` once one appears.
- Created lazily on first stick; removed when no sessions remain hosted (or on `reset()`).
- Do **not** `bringSubviewToFront` the overlay on every scroll tick when sibling-hosted (only keep it above the scroll view).

### Placeholder

- Inserted in the original superview at the target’s index with the same bounds.
- Keeps Auto Layout / stack views from collapsing.
- Removed on unstick / reset.

Hosts may set `preservesPlaceholder = false` only when they manage spacing themselves (discouraged).

**UIStackView:** The engine restores targets with `insertArrangedSubview` (not plain `insertSubview`). Using a stack as the idle parent is supported.

---

## 11. Observation model

| Mode | Behavior |
|------|----------|
| `observesAutomatically = true` (default) | KVO on `contentOffset`, `bounds`, `contentSize`, `adjustedContentInset` |
| `false` | Host calls `handleScroll()` / `fk_handleStickyScroll()` |

`reloadLayout()` recomputes natural origins for idle targets **and** remasures sizes for stuck targets (updating placeholders). Call after Dynamic Type, filter height changes, or structure updates.  
`reset()` unsticks all, removes placeholders/overlay, clears observation if tearing down.

Query helpers: `stuckTargetIDs`, `progress(for:)`, `state(for:)`, `target(id:)`, plus `onStuckTargetsChange` when the active stuck set changes.

---

## 12. Configuration model

`FKStickyConfiguration` fields (v1):

| Field | Default | Role |
|-------|---------|------|
| `isEnabled` | `true` | Master switch |
| `edge` | `.top` | Pin edge |
| `stickyInset` | `0` | Extra inset beyond `adjustedContentInset` |
| `observesAutomatically` | `true` | KVO |
| `preservesPlaceholder` | `true` | Spacer while stuck |
| `collisionBehavior` | `.pushOff` | Multi-target interaction (`.pushOff` / `.stack`) |
| `allowsPushOff` | computed | Convenience for `collisionBehavior` |
| `transitionDistance` | `8` | Progress ramp (pt) |
| `unstickHysteresis` | `0` | Extra release distance to reduce threshold flicker |
| `appliesStuckShadow` | `false` | Optional engine-applied shadow |
| `stuckShadowOpacity` | `0.12` | Used when `appliesStuckShadow` |
| `stuckShadowRadius` | `4` | Used when `appliesStuckShadow` |
| `stuckShadowOffset` | `(0, 2)` | Used when `appliesStuckShadow` |

Engine-level (not part of the Sendable struct):

| Field | Role |
|-------|------|
| `FKStickyEngine.stickyInsetProvider` | Dynamic inset; when non-`nil`, replaces `configuration.stickyInset` |
| `FKStickyEngine.onStuckTargetsChange` | Fired when ordered stuck ids change |

Per-target: `isEnabled`, `priority`, `stickyInsetOverride`, callbacks.

---

## 13. Threading and concurrency

- `FKStickyEngine`, `FKStickyTarget`, overlay, and UIScrollView extensions are **`@MainActor`**.
- Configuration value types are **`Sendable`** / `Equatable` where closures are absent.
- `stickyInsetProvider` and target callbacks are `@MainActor` closures; not Sendable — fine for UIKit hosts.
- Associated-object keys use `nonisolated(unsafe)` static storage (same pattern as Refresh / EmptyState).
- Target callbacks must capture `[weak]` hosts to avoid cycles (engine holds targets strongly; targets hold weak views).

---

## 14. Accessibility

- Sticky does not alter accessibility identifiers; stuck views remain in the hierarchy under the overlay.
- VoiceOver order may change when reparenting — hosts that need a fixed order should prefer keeping chrome outside the scroll view (viewport pin) instead of scroll sticky.
- Dynamic Type height changes require `reloadLayout()`.

---

## 15. Relationship to existing FKKit types

| Type | Relationship |
|------|--------------|
| `FKTabBar` / filter strips | Typical **content** for a sticky target |
| `FKSearchBarPlacement.stickyHeader/Footer` | Page-level pin; may adopt engine later |
| `FKAnchor` / Callout | Different: attach overlays to a source view |
| `FKRefresh` | Shares scroll view; sticky inset must account for refresh-driven `adjustedContentInset` |
| `FKKeyboard` | Bottom sticky footers that follow keyboard should combine Keyboard layout guides with `stickyInsetProvider` |
| Deleted legacy `Sticky` / `StickyHeader` | Historical; this design supersedes them with clearer non-goals |

---

## 16. Source layout

```text
Sources/FKUIKit/Components/Sticky/
├── README.md
├── Public/
│   ├── Core/
│   │   └── FKStickyEngine.swift
│   ├── Models/
│   │   ├── FKStickyEdge.swift
│   │   ├── FKStickyCollisionBehavior.swift
│   │   ├── FKStickyState.swift
│   │   ├── FKStickyProgress.swift
│   │   └── FKStickyTarget.swift
│   └── Configuration/
│       └── FKStickyConfiguration.swift
├── Internal/
│   ├── FKStickyOverlayHost.swift
│   ├── FKStickyPlaceholderView.swift
│   ├── FKStickyTargetSession.swift
│   ├── FKStickyGeometry.swift
│   └── FKStickyAssociationKeys.swift
└── Extension/
    └── UIScrollView+FKSticky.swift
```

---

## 17. Integration patterns

### 17.1 In-content filter strip (top)

1. Place strip in scroll content (stack / table header / collection header).
2. `fk_addStickyTarget(id:view:)`.
3. Set `stickyInset` to remaining chrome below the navigation bar if the scroll view does not already extend under it via adjusted insets.

### 17.2 Chained section bars

Register multiple targets in document order; keep `allowsPushOff == true`.

### 17.3 Bottom composer chrome

`configuration.edge = .bottom`; provide inset via `stickyInsetProvider` reading safe area / keyboard.

### 17.4 Manual scroll forwarding

Disable automatic observation when a nested scroll coordinator already owns `didScroll`.

---

## 18. Pitfalls and hard constraints

1. **Do not sticky-reparent `UITableViewHeaderFooterView` managed as section headers** — use system plain sticky headers or a free-standing view in content.
2. **Do not combine** with Compositional Layout `pinToVisibleBounds` on the same supplementary item.
3. **Nested scroll views** — attach the engine to the scroll view that actually moves.
4. **clipsToBounds** on intermediate superviews can clip before stick; prefer targets whose idle ancestors do not clip, or accept clipping until stick.
5. **Transform / scale** on ancestors invalidates naive frames — call `reloadLayout()` after animations settle.
6. **Performance** — no target list rebuild allocations on every frame beyond sorting enabled sessions; debounce callback epsilon.
7. **Ownership** — scroll view retains engine via associated object; engine weakly retains scroll view; targets weakly retain views.

---

## 19. FKKitExamples

Hub: `Examples/FKKitExamples/.../Sticky/Hub/FKStickyExamplesHubViewController.swift` (menu: **FKUIKit → Sticky**).

Coverage includes:

- UIScrollView / UITableView / UICollectionView single target
- Multi-target push-off and stack
- Bottom edge; stickyInset + stickyInsetProvider
- Progress / lifecycle / engine shadow; stuck-set observation & queries
- Enable/disable, force stick, target toggle, remove/reset
- reloadLayout while stuck
- Manual observation forwarding
- Placeholder, hysteresis, priority, stickyInsetOverride
- Interactive playground

---

## 20. Design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Engine vs widget | Engine | Matches analysis; avoids second chrome system |
| Overlay via sibling of scroll view | Yes | Fixed to `scrollView.frame`; avoids in-table `contentOffset` frame writes that jitter at max offset |
| Reparent vs transform | Reparent while stuck | Reliable hit-testing and layer effects |
| Global manager | No | Host ownership clarity |
| System section headers | Documented non-goal | Reparenting breaks UIKit table internals |
| Examples in this PR | Deferred | Per product request |

---

## 21. Revision history

| Date | Change |
|------|--------|
| 2026-09-17 | Initial design for FKSticky v1 behavior module |
| 2026-09-17 | Gap pass: collision `.stack`, query APIs, stuck-set callback, stuck remasure on reload, hysteresis, sync main-thread KVO layout |
