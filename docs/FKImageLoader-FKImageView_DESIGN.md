# FKImageLoader & FKImageView — Design Requirements

Implementation guide for the FKKit image loading stack: default `FKImageLoading` / `FKImageCaching` in **FKCoreKit** and the **`FKImageView`** UI component in **FKUIKit**.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.1  
**中文版本:** [FKImageLoader-FKImageView_DESIGN.zh-CN.md](FKImageLoader-FKImageView_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Architectural Overview](#4-architectural-overview)
- [5. Module Boundaries](#5-module-boundaries)
- [6. FKImageLoader — Functional Requirements](#6-fkimageloader--functional-requirements)
- [7. FKImageLoader — Cache Requirements](#7-fkimageloader--cache-requirements)
- [8. FKImageLoader — Concurrency & Threading](#8-fkimageloader--concurrency--threading)
- [9. FKImageLoader — Configuration & API Surface](#9-fkimageloader--configuration--api-surface)
- [10. FKImageLoader — Error Model & Observability](#10-fkimageloader--error-model--observability)
- [11. FKImageView — State Machine](#11-fkimageview--state-machine)
- [12. FKImageView — Visual & Layout Capabilities](#12-fkimageview--visual--layout-capabilities)
- [13. FKImageView — Loading Lifecycle](#13-fkimageview--loading-lifecycle)
- [14. FKImageView — Placeholder, Progress, Failure & Retry](#14-fkimageview--placeholder-progress-failure--retry)
- [15. FKImageView — Integration with Existing FKUIKit](#15-fkimageview--integration-with-existing-fkuikit)
- [16. FKImageView — List & Cell Reuse Behavior](#16-fkimageview--list--cell-reuse-behavior)
- [17. FKImageView — Interaction & Gestures](#17-fkimageview--interaction--gestures)
- [18. FKImageView — Accessibility](#18-fkimageview--accessibility)
- [19. FKImageView — Configuration & API Surface](#19-fkimageview--configuration--api-surface)
- [20. SwiftUI Bridge](#20-swiftui-bridge)
- [21. Global Defaults & Dependency Injection](#21-global-defaults--dependency-injection)
- [22. Performance & Resource Budgets](#22-performance--resource-budgets)
- [23. Security & Privacy](#23-security--privacy)
- [24. Proposed Source Layout](#24-proposed-source-layout)
- [25. FKKitExamples Scenarios](#25-fkkitexamples-scenarios)
- [27. Open Questions](#27-open-questions)
- [28. Revision History](#28-revision-history)

---

## 1. Executive Summary

FKKit defines **`FKImageLoading`** and **`FKImageCaching`** in Pluggable but ships **no default implementation** and **no reusable image view**. Every feed, avatar, banner, and product cell therefore reimplements URLSession fetching, cache keys, downsampling, placeholders, cancellation, and failure UI.

This design specifies two deliverables :

| Deliverable | Module | Role |
|-------------|--------|------|
| **`FKImageLoader`** | FKCoreKit | Production default for `FKImageLoading` + `FKImageCaching`: network/local fetch, decode, downsample, memory+disk cache, deduplication, cancellation. |
| **`FKImageView`** | FKUIKit | Configuration-driven view that binds load state to UI: placeholder, optional skeleton, transition, failure/retry, styling, accessibility, SwiftUI bridge. |

The loader must remain **swappable** at the app composition root; the view must **not** hard-code Kingfisher/SDWebImage or any third-party SDK.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Close the Pluggable gap** — provide a reference `FKImageLoader` integrators can use out of the box or replace.
2. **Cover the 80% case** — remote HTTPS images in lists and detail screens with correct reuse and cancellation.
3. **Align with FKKit patterns** — layered `Sendable` configuration, `@MainActor` UI, English docs, FKKitExamples full coverage, reuse `FKAsync` / Extension / neighbor components.
4. **Production-safe defaults** — bounded memory, disk eviction, no main-thread decode for large images, explicit errors.
5. **Composable** — `FKImageView` works standalone; `FKImageLoader` works without the view (prefetch, programmatic loads).

### 2.2 Non-Goals (v1)

- GIF/APNG/WebP animation playback (static `UIImage` only unless system decoder handles format natively).
- Image editing pipelines (filters, cropping UI, markup).
- Full photo browser / zoom gallery (future `FKCarousel` / separate component).
- SVG or PDF vector rendering.
- Third-party CDN-specific transformers (Cloudinary-style URL building) — host may preprocess URLs before passing to FKKit.
- Background URLSession downloads for offline galleries (use `FKFileManager` / `FKNetwork` instead).
- tvOS / macOS product targets (iOS 15+ UIKit only for this component).

### 2.3 Success Criteria

Implementation is complete when:

- [ ] `FKImageLoader` conforms to `FKImageLoading` and `FKImageCaching` and passes contract behavior described in §6–10.
- [ ] `FKImageView` implements §11–19 and ships `FKImageViewRepresentable`.
- [ ] List fast-scroll scenario cancels stale loads and shows no wrong image (identity check).
- [ ] Memory cache respects configured cost limit under heavy load in Examples.
- [ ] FKKitExamples hub covers every major capability in §25.
- [ ] Component README(s) with directory map; root README index updated.

---

## 3. Background & Problem Statement

### 3.1 Current state

`Sources/FKCoreKit/Components/Pluggable/Media/FKImageLoading.swift` defines:

- `FKImageLoadRequest` — `url`, optional `targetWidth` / `targetHeight`, optional `cacheKey`.
- `FKImageLoading` — `loadImage(for:)` async throws, `cancelLoad(for:)`.
- `FKImageCaching` — get/store/remove/removeAll by string key.

**No type in the repository implements these protocols.**

`UIImage` extensions under `FKCoreKit/Extension/UIKit/UIImage.swift` provide resize, tint, corner rounding, crop, and JPEG helpers — the loader/view **must reuse** these instead of duplicating bitmap utilities.

`FKSkeleton` exposes `UIImageView` convenience shims — `FKImageView` **may** delegate loading shimmer to skeleton overlay APIs when configured.

### 3.2 User pain

| Pain | Frequency | Without FKKit |
|------|-----------|---------------|
| Wrong image on reused cell | Very high | Manual request token / URL identity checks |
| Memory spikes scrolling feeds | High | Unbounded caches or full-size decode |
| Duplicate network requests | High | Ad-hoc in-flight task maps per screen |
| Inconsistent placeholder/failure UI | High | One-off per feature team |
| Cannot swap CDN policy | Medium | Direct URLSession in view controllers |

---

## 4. Architectural Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ App composition root                                            │
│   var imageLoader: any FKImageLoading = FKImageLoader.shared    │
└────────────────────────────┬────────────────────────────────────┘
                             │ inject
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ FKImageView (FKUIKit, @MainActor)                               │
│   state machine · placeholder · retry · styling · a11y          │
└────────────────────────────┬────────────────────────────────────┘
                             │ FKImageLoadRequest
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ FKImageLoader (FKCoreKit)                                       │
│   coalesce · fetch · decode/downsample · memory cache · disk    │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         URLSession    FileManager      NSCache + disk index
         (remote)      (file://)        (FKImageDiskCache)
```

**Data flow**

1. Host sets `url` (and optional explicit `targetSize`) on `FKImageView`.
2. View computes effective target size from layout if not provided (after `layoutSubviews` when policy says so).
3. View builds `FKImageLoadRequest` (cache key policy from configuration).
4. View checks optional synchronous memory cache preview via loader/cache protocol when enabled.
5. View starts async load through injected `FKImageLoading`.
6. On success, view verifies **request identity** still matches current URL/key/size before applying `UIImage`.
7. On failure, view transitions to failure UI per configuration.

---

## 5. Module Boundaries

| Concern | FKCoreKit (`FKImageLoader`) | FKUIKit (`FKImageView`) |
|---------|----------------------------|-------------------------|
| URLSession / file read | Yes | No |
| Decode & downsample | Yes | No |
| Memory + disk cache | Yes | No |
| In-flight deduplication | Yes | No |
| UIView hierarchy | No | Yes |
| Placeholder / failure layers | No | Yes |
| Corner radius, border, shadow | No (may use processed UIImage) | Yes (view + optional pre-process) |
| Skeleton shimmer overlay | No | Yes (via `FKSkeleton`) |
| SwiftUI Representable | No | Yes |
| VoiceOver presentation | No | Yes |

**Dependency rule:** `FKImageView` imports `FKCoreKit` and `FKUIKit` only; `FKImageLoader` must not import `FKUIKit`.

---

## 6. FKImageLoader — Functional Requirements

### 6.1 Load sources

The loader **must** support:

| Source | Scheme / input | Behavior |
|--------|----------------|----------|
| Remote HTTP/HTTPS | `https://`, `http://` | `URLSession.data(for:)` (or shared session from config) |
| Local file | `file://` | Read synchronously on decode queue, no network |
| Already-local path | `URL` pointing to existing file | Same as file |
| In-memory cache hit | N/A | Return immediately without I/O |
| Disk cache hit | N/A | Load Data from disk, decode on decode queue |

The loader **must not** fetch non-file/non-http(s) schemes in v1; return a typed error (e.g. `FKImageLoaderError.unsupportedURLScheme`).

### 6.2 Request identity & cache keys

**Default cache key** when `FKImageLoadRequest.cacheKey == nil`:

```text
{absoluteURLString}|w={targetWidth}|h={targetHeight}
```

- Use stable string formatting (e.g. `%g` or fixed decimal) for dimensions.
- Omit dimension segments when corresponding value is `nil` (full-size bucket).

**Custom cache key** — when provided, used as-is for both memory and disk maps (integrator responsible for uniqueness).

### 6.3 In-flight coalescing (deduplication)

When multiple concurrent callers request the **same cache key**:

- Only **one** underlying fetch/decode task runs.
- All callers await the same `Task` result.
- If one caller cancels, cancellation semantics (§6.5) apply per **caller token**, not necessarily aborting shared work until last observer cancels (document chosen policy — recommended: **shared task continues** unless all waiters cancelled).

### 6.4 Decode & downsampling

**Must:**

- Decode off the main thread ( dedicated serial or limited concurrent decode queue).
- When `targetWidth` and/or `targetHeight` are set, downsample **before** or **during** decode so peak memory ≈ target pixel buffer, not full source dimensions.
- Prefer `CGImageSource` incremental/downsample APIs when available; fallback to decode-then-`fk_resized(to:)` only when necessary.
- Preserve `UIImage.scale` appropriate for screen scale (use main-screen scale when known; allow configuration default scale).
- Respect EXIF orientation when decoding ( upright `UIImage` for display).

**Should:**

- Support `targetWidth` only or `targetHeight` only — compute aspect-preserving dimension from decoded metadata when one dimension missing.
- Reject non-positive target dimensions with validation error.

### 6.5 Cancellation

`cancelLoad(for request: FKImageLoadRequest)` **must**:

- Accept cancellation keyed by resolved cache key.
- Cancel associated `URLSessionDataTask` when no other coalesced waiters remain (if policy above allows abort).
- Prevent completion handlers from publishing results to waiters that cancelled (use structured concurrency cancellation checks).

`loadImage(for:)` **must** honor `Task.isCancelled` and throw `CancellationError` or `FKImageLoaderError.cancelled`.

### 6.6 HTTP behavior

Configuration **must** expose:

| Option | Default | Notes |
|--------|---------|-------|
| `URLSessionConfiguration` or shared session provider | `.default` ephemeral | Allow inject for cookie/auth |
| Per-request timeout | 60s | Tunable |
| `URLRequest.CachePolicy` | `.useProtocolCachePolicy` | |
| Optional HTTP headers | `[:]` | Auth, User-Agent |
| Acceptable status codes | 2xx | Map others to HTTP error |

**Should** support optional `FKNetworkReachability` preflight hook (injected closure or provider) — when unreachable, fail fast with `FKImageLoaderError.offline` without starting URLSession (opt-in via configuration).

### 6.7 Local file behavior

- Read file on background queue.
- Apply same decode/downsample path as network.
- File missing → `FKImageLoaderError.fileNotFound`.
- Permission denied → `FKImageLoaderError.fileReadFailed`.

### 6.8 Prefetch API

Provide explicit prefetch entry points (still on loader, usable without view):

```swift
func prefetch(_ request: FKImageLoadRequest) async
func prefetch(urls: [URL], targetSize: CGSize?) async
```

- Prefetch populates cache only; no callback to UI.
- Must respect cache limits and coalesce with in-flight loads.
- Cancellation: `cancelPrefetch(for:)` optional in v1 (may defer if scope tight).

### 6.9 Cache-only query

Support synchronous memory read for UI instant display:

```swift
func cachedImage(for request: FKImageLoadRequest) -> UIImage?
```

Uses resolved cache key; checks memory first, optionally disk sync read (config flag, default **memory only** for sync API to avoid main-thread I/O — if disk sync allowed, document main-thread prohibition).

### 6.10 Pluggable conformance

`FKImageLoader` **must** conform to:

- `FKImageLoading`
- `FKImageCaching` (when caching enabled; when disabled, `store`/`cachedImage` no-op / nil)

**Cache-disabled** mode supported via `FKImageLoaderConfiguration.isCachingEnabled = false`.

---

## 7. FKImageLoader — Cache Requirements

### 7.1 Memory cache

**Must:**

- Backed by `NSCache` or equivalent with **total cost limit** and **count limit** from configuration.
- Cost function: `pixelWidth * pixelHeight * 4` (RGBA bytes) unless overridden.
- Thread-safe access (lock or queue); `@MainActor` protocol methods may delegate to internal actor/queue.
- `removeImage(forKey:)` and `removeAllImages()` evict memory entries.

**Default configuration (starting point, tunable):**

| Parameter | Default |
|-----------|---------|
| `memoryCostLimit` | 100 MB |
| `memoryCountLimit` | 200 |

### 7.2 Disk cache

**Must:**

- Store encoded bytes (prefer original Data when from network; JPEG/PNG as received) under Caches directory subdirectory, e.g. `FKImageLoader/DiskCache/`.
- Filename: SHA256(cacheKey) or safe hash — reuse patterns from `FKFileStorage` naming discipline.
- Maintain lightweight index (in-memory + optional JSON index file) for enumeration and eviction.
- Enforce **maximum disk size** (bytes) and **maximum entry age** (TTL optional).
- LRU or approximate LRU eviction when over budget.
- `removeAllImages()` clears disk + memory.
- Disk I/O on background queue only.

**Default configuration:**

| Parameter | Default |
|-----------|---------|
| `diskSizeLimit` | 200 MB |
| `diskEntryTTL` | 7 days (optional enforcement) |

### 7.3 Cache policy per request (optional extension)

`FKImageLoadRequest` may gain optional `cachePolicy` enum in implementation (if added, update Pluggable in separate semver decision):

| Policy | Behavior |
|--------|----------|
| `.default` | Memory → disk → network |
| `.reloadIgnoringCache` | Skip memory/disk read; still write after fetch |
| `.cacheOnly` | Fail if not cached |

If not extending Pluggable request struct when shipped, support via parallel loader method:

```swift
func loadImage(for request: FKImageLoadRequest, options: FKImageLoadOptions) async throws -> UIImage
```

Document decision in implementation PR.

### 7.4 Eviction & memory warnings

**Must** listen for `UIApplication.didReceiveMemoryWarningNotification` (via existing Extension helpers if present) and trim memory cache (clear or reduce to fraction).

**Should** expose manual `trimMemoryCache(toCost:)` for hosts.

---

## 8. FKImageLoader — Concurrency & Threading

| Operation | Thread |
|-----------|--------|
| `loadImage` entry | `@MainActor` protocol surface; hop to internal actor |
| URLSession callbacks | URLSession delegate queue → internal |
| Disk read/write | Serial background queue |
| Decode/downsample | Limited concurrent background queue (max 3–4) |
| NSCache | Lock-protected |
| Completion to awaiters | Resume on `@MainActor` if protocol requires MainActor conformance |

**Swift 6:** Internal state isolated in `actor FKImageLoaderEngine` or class + lock; public `FKImageLoader` marked `@MainActor` to match Pluggable protocol.

**No retain cycles:** tasks hold weak loader; views hold loader via injection, not strong singleton cycles.

---

## 9. FKImageLoader — Configuration & API Surface

### 9.1 Core types (normative names)

```swift
// FKCoreKit — Components/ImageLoader/

public struct FKImageLoaderConfiguration: Sendable, Equatable { ... }

public enum FKImageLoaderError: Error, Sendable, Equatable {
  case unsupportedURLScheme(String)
  case invalidTargetDimensions
  case httpStatus(code: Int)
  case network(underlying: Error)
  case decodeFailed
  case fileNotFound
  case fileReadFailed
  case offline
  case cancelled
  case cacheMissUnderCacheOnlyPolicy
}

@MainActor
public final class FKImageLoader: FKImageLoading, FKImageCaching {
  public static let shared: FKImageLoader
  public var configuration: FKImageLoaderConfiguration
  public init(configuration: FKImageLoaderConfiguration = .init())
  // protocol methods + prefetch + trim APIs
}
```

### 9.2 Configuration fields (minimum)

| Field | Type | Purpose |
|-------|------|---------|
| `memoryCostLimit` | Int | NSCache cost cap |
| `memoryCountLimit` | Int | NSCache count cap |
| `diskSizeLimit` | Int | Bytes |
| `diskEntryTTL` | TimeInterval? | Optional expiry |
| `isCachingEnabled` | Bool | Toggle caches |
| `sessionConfiguration` | URLSessionConfiguration | Or use callback provider |
| `defaultHeaders` | [String: String] | HTTP headers |
| `requestTimeout` | TimeInterval | Per request |
| `maxConcurrentDecodes` | Int | Backpressure |
| `reachabilityFastFail` | Bool | Offline quick fail |
| `diskCacheDirectoryURL` | URL? | Override location |

Apply via `configuration` property with copy-on-write or `apply(_:)` method matching neighbor components.

---

## 10. FKImageLoader — Error Model & Observability

### 10.1 Error mapping

Errors **must** be equatable where underlying Error is not equatable — use categorized cases (§9.1).

### 10.2 Logging (optional hook)

**Should** integrate with `FKLogger` at debug level:

- Cache hit/miss (memory/disk)
- Fetch start/complete/cancel
- Eviction events

No URL credentials or auth header values in logs.

### 10.3 Metrics hook (optional)

Configuration callback:

```swift
var onEvent: (@Sendable (FKImageLoaderEvent) -> Void)?
```

Events: `.cacheHit(level:)`, `.fetchStarted`, `.fetchCompleted(duration:)`, `.fetchFailed`, `.evicted(count:)`.

Default `nil` (zero overhead).

---

## 11. FKImageView — State Machine

### 11.1 States

```swift
public enum FKImageViewState: Equatable, Sendable {
  case idle           // No URL set, or cleared
  case placeholder    // URL set, showing placeholder only (cache miss, load not started)
  case loading        // In-flight load; may show placeholder and/or skeleton/progress
  case success(UIImage)
  case failure(FKImageViewFailureReason)
}

public enum FKImageViewFailureReason: Equatable, Sendable {
  case network
  case decode
  case cancelled
  case offline
  case custom(message: String?)
}
```

### 11.2 Transitions

| From | Event | To |
|------|-------|-----|
| idle | `url` set | placeholder or loading (if cache hit → success) |
| placeholder | load starts | loading |
| loading | success + identity match | success |
| loading | failure | failure |
| loading | url changed / cancel | placeholder (new url) or idle |
| success | url changed | placeholder → loading |
| failure | retry tapped | loading |
| any | `url = nil` | idle |

**Identity rule:** Before applying image to layer, verify `currentLoadToken` or `(url, cacheKey, targetSize)` triple matches. Mismatches discard result silently (debug log only).

### 11.3 Published state

- `public private(set) var state: FKImageViewState`
- Optional `var onStateChange: (@MainActor (FKImageViewState) -> Void)?`

---

## 12. FKImageView — Visual & Layout Capabilities

### 12.1 Image presentation

**Must support:**

| Capability | Details |
|------------|---------|
| `contentMode` | Full `UIView.ContentMode` set |
| `clipsToBounds` | Default `true` when corner radius > 0 |
| `tintColor` / template rendering | Optional template mode for monochrome icons |
| `adjustsImageWhenHighlighted` | Optional highlight dimming for tappable images |
| `preferredImageDynamicRange` | Pass-through when iOS 17+ API available |

### 12.2 Corner radius & rounding

**Must support** (configuration-driven):

| Mode | Behavior |
|------|----------|
| `.none` | Square |
| `.fixed(CGFloat)` | Uniform radius |
| `.capsule` | min(width,height)/2 |
| `.perCorner(UIRectCorner, radius)` | Partial corners |

Implementation may use layer `cornerRadius` + `maskedCorners`, or `FKCornerShadow` mask when border/shadow co-configured.

### 12.3 Border

Reuse `FKLayerBorderStyle` or mirror `FKButton` border configuration:

- Color, width, alignment (inside/outside/center if supported).

### 12.4 Shadow

Optional `FKLayerShadowStyle` on container layer; shadow on outer container, image clipped inside.

### 12.5 Background

Background color/image visible in letterboxed regions when content mode is `.scaleAspectFit`.

### 12.6 Transition on success

| Transition | Description |
|------------|-------------|
| `.none` | Immediate set |
| `.crossDissolve(duration:)` | UIView transition |
| `.fadeIn(duration:)` | Alpha animation |

Default: `.crossDissolve(0.2)` — configurable; respect `UIAccessibility.isReduceMotionEnabled` → force `.none`.

### 12.7 Intrinsic content size

- Without fixed size constraints: intrinsic size from image size or placeholder intrinsic hint.
- Support `contentHuggingPriority` / compression resistance like `UIImageView`.

---

## 13. FKImageView — Loading Lifecycle

### 13.1 Public loading API

```swift
public var url: URL? { get set }
public var image: UIImage? { get } // Current displayed UIImage, nil if none
public func load(url: URL?, placeholder: UIImage? = nil)
public func cancelLoad()
public func reload() // Re-fetch current url ignoring memory (not disk) per policy
public func reset() // Clear url, image, state → idle
```

Setting `url` triggers load when `loadsAutomatically` (default `true`).

### 13.2 Target size resolution

| Policy | When size computed |
|--------|-------------------|
| `.automaticFromBounds` | After layout; uses bounds.size × screen scale |
| `.explicit(CGSize)` | Host-provided |
| `.none` | Full resolution (discouraged for remote; document perf warning) |

Reload when bounds change significantly (threshold configurable, e.g. 10% dimension delta) if policy is automatic.

### 13.3 Loader injection

```swift
public var imageLoader: (any FKImageLoading)?
```

Default: `FKImageLoader.shared`. Host replaces with custom CDN client or alternative implementation.

### 13.4 Lifecycle with view hierarchy

- `willMove(toWindow:)` — optional pause/resume (config `pausesLoadingWhenOffscreen`, default false in v1).
- `deinit` — cancel in-flight load token.

---

## 14. FKImageView — Placeholder, Progress, Failure & Retry

### 14.1 Placeholder

Configuration supports:

| Placeholder kind | Support |
|------------------|---------|
| Static `UIImage` | Yes |
| Solid color | Yes (via generated image or background) |
| SF Symbol name | Yes |
| Initials string + font/colors | Yes (avatar use case) |
| Custom `UIView` provider | Optional slot (advanced) |

Placeholder shown in: `idle` (optional), `placeholder`, `loading` (under progress/skeleton).

### 14.2 Progress indicator

| Mode | UI |
|------|-----|
| `.none` | Default |
| `.activityIndicator` | `UIActivityIndicatorView` centered |
| `.linearProgress(FKProgressBarConfiguration?)` | Thin bar at bottom edge |

Progress is **indeterminate** unless loader exposes byte progress in future; v1 indeterminate only.

### 14.3 Skeleton integration

When `loadingPresentation.includesSkeleton == true`:

- Call `fk_showSkeleton` on image bounds or use overlay matching `FKSkeletonPresets` avatar/card shapes.
- Hide skeleton before cross-dissolve image in.

Must not leak skeleton layers after `reset()` or reuse.

### 14.4 Failure presentation

| Element | Required |
|---------|----------|
| Failure icon | Configurable SF Symbol or image |
| Message label | Optional short text (localized template + custom) |
| Retry affordance | Button or tap-on-image when `isRetryEnabled` |
| Offline hint | When failure reason `.offline`, prefer copy from `FKUIKitI18n` |

### 14.5 Retry behavior

- Tap retry or call `retry()` → transitions to `loading`, uses `.reloadIgnoringCache` or standard load per config.
- Debounce retry taps (300ms) to prevent storms.

---

## 15. FKImageView — Integration with Existing FKUIKit

| Component | Integration |
|-----------|-------------|
| **FKSkeleton** | Loading shimmer overlay; reuse `UIView+FKSkeleton` |
| **FKCornerShadow** | Optional rounded + shadow container |
| **FKProgressBar** | Optional bottom progress strip |
| **FKButton** | Optional retry button styling |
| **FKBadge** | Not inside FKImageView v1; document pattern for avatar badge overlay in Examples |
| **FKBlurView** | Not required v1 |
| **FKUIKitI18n** | Failure/retry strings |

**Must not** duplicate `UIImage.fk_*` helpers in FKUIKit — call FKCoreKit extensions when pre-processing bitmaps.

---

## 16. FKImageView — List & Cell Reuse Behavior

### 16.1 Requirements

**Must:**

- `prepareForReuse()` equivalent via `resetForReuse()` public method clearing url, cancelling load, resetting to placeholder, removing skeleton/progress views.
- Changing `url` cancels previous token synchronously on main actor before starting new load.
- Never display image whose URL does not match current `url`.

### 16.2 UITableView / UICollectionView

Provide documentation snippet (not necessarily subclass):

```swift
override func prepareForReuse() {
  super.prepareForReuse()
  imageView.resetForReuse()
}
```

### 16.3 Prefetching

Document pairing with `UITableViewDataSourcePrefetching` / `UICollectionViewDataSourcePrefetching`:

- Host calls `FKImageLoader.prefetch` in `prefetchItemsAt`.
- Host calls `cancelPrefetch` in `cancelPrefetchingForItemsAt` when implemented.

---

## 17. FKImageView — Interaction & Gestures

| Feature | v1 requirement |
|---------|----------------|
| Tap callback | Optional `onTap: (@MainActor () -> Void)?` |
| Retry tap on failure | Required when enabled |
| Long press | Non-goal v1 |
| Highlight on press | Optional alpha animation |

Use `UIControl` subclass **or** `UIView` + `UITapGestureRecognizer` — decision left to implementer; if `UIView`, ensure accessibility activation.

---

## 18. FKImageView — Accessibility

**Must:**

- `accessibilityLabel` from configuration or derived from host `accessibilityImageDescription`.
- In `loading`, optionally post `UIAccessibilityLayoutChangedNotification` when image loads (config flag, default false to avoid noise).
- Failure state: announce failure + hint if retry available (`accessibilityHint`).
- Placeholder-only decorative images: `accessibilityElementsHidden = true` when host marks decorative.
- Support Dynamic Type for failure message label only (not image content).

**Traits:** `.image` when success; `.button` when tappable retry.

---

## 19. FKImageView — Configuration & API Surface

### 19.1 Layered configuration (match FKButton / FKEmptyState)

```swift
public struct FKImageViewConfiguration: Sendable, Equatable {
  public var appearance: FKImageViewAppearanceConfiguration
  public var loading: FKImageViewLoadingConfiguration
  public var failure: FKImageViewFailureConfiguration
  public var layout: FKImageViewLayoutConfiguration
  public var accessibility: FKImageViewAccessibilityConfiguration
  public var interaction: FKImageViewInteractionConfiguration
}

public enum FKImageViewDefaults {
  public static var defaultConfiguration: FKImageViewConfiguration
}
```

### 19.2 Appearance configuration fields

| Field | Description |
|-------|-------------|
| `cornerStyle` | See §12.2 |
| `borderStyle` | Optional |
| `shadowStyle` | Optional |
| `backgroundColor` | Letterbox fill |
| `contentMode` | Default `.scaleAspectFill` |
| `successTransition` | §12.6 |
| `tintColor` | Template images |

### 19.3 Loading configuration fields

| Field | Description |
|-------|-------------|
| `placeholder` | Image/color/symbol/initials |
| `targetSizePolicy` | §13.2 |
| `loadsAutomatically` | Default true |
| `loadingPresentation` | progress mode, skeleton flag |
| `cachePolicy` | Per-view override if supported |

### 19.4 Failure configuration fields

| Field | Description |
|-------|-------------|
| `isRetryEnabled` | Default true |
| `icon` | SF Symbol |
| `message` | Optional copy |
| `retryButtonTitle` | Optional; nil = tap image |

### 19.5 Type alias convenience

```swift
public final class FKImageView: UIView {
  public var configuration: FKImageViewConfiguration { get set }
  public func apply(_ configuration: FKImageViewConfiguration)
  public func apply(_ block: (inout FKImageViewConfiguration) -> Void)
}
```

---

## 20. SwiftUI Bridge

Ship **`FKImageViewRepresentable`** in `FKUIKit/Components/ImageView/Public/Bridge/`:

```swift
public struct FKImageViewRepresentable: UIViewRepresentable {
  public var url: URL?
  public var configuration: FKImageViewConfiguration
  public var onStateChange: ((FKImageViewState) -> Void)?
}
```

**Must** update on url/config changes via `updateUIView`.

Optional **`FKAsyncImage`**-style struct wrapping same engine for ergonomic SwiftUI (nice-to-have v1; Representable is mandatory).

---

## 21. Global Defaults & Dependency Injection

### 21.1 Process-wide defaults

```swift
public enum FKImageViewDefaults {
  public static var defaultConfiguration: FKImageViewConfiguration
  public static var sharedImageLoader: any FKImageLoading
}
```

Mutate once at app launch (document thread: main).

### 21.2 App composition root pattern

```swift
// App launch
FKImageLoader.shared.configuration.memoryCostLimit = 80 * 1024 * 1024
FKImageViewDefaults.sharedImageLoader = FKImageLoader.shared
FKImageViewDefaults.defaultConfiguration.appearance.cornerStyle = .fixed(8)
```

Custom loader:

```swift
final class CDNImageLoader: FKImageLoading {
  func loadImage(for request: FKImageLoadRequest) async throws -> UIImage { ... }
  func cancelLoad(for request: FKImageLoadRequest) { ... }
}
imageView.imageLoader = CDNImageLoader()
```

---

## 22. Performance & Resource Budgets

| Metric | Target |
|--------|--------|
| Main-thread decode | **Forbidden** for network/file payloads |
| Memory cache default | 100 MB (configurable) |
| Disk cache default | 200 MB |
| Coalesced duplicate requests | 1 network call per cache key |
| Cell reuse wrong-image rate | 0 in Examples fast-scroll scenario |
| Time to first placeholder | < 1 frame on main when url set |

**Scroll performance:** Loading 50+ visible+prefetch cells must not exceed configured concurrent decode limit.

---

## 23. Security & Privacy

- **HTTPS default** — allow HTTP only if host explicitly uses http URL (no downgrade).
- **Do not log** Authorization cookies or signed query params.
- **Validate file URLs** — do not follow symlinks outside expected sandbox when loading app files.
- **App Transport Security** — respect host ATS; document integrator responsibility.
- **Sensitive images** — optional config `excludesFromDiskCache` per request (future) or global flag for auth-gated URLs (v1: document using custom cache key + `reloadIgnoringCache` + disable disk for auth paths via loader config hook).

---

## 24. Proposed Source Layout

> **Layout guidance (non-normative):** The directory tree below is a **recommended starting point**, not a mandatory template. Adjust folders and file grouping to fit component complexity and neighboring FKKit components, while keeping the layout **discoverable**, **documented** in the component `README.md`, and aligned with FKKit conventions (clear public vs internal boundaries, English `///`, Swift 6 concurrency). See [COMPONENT_ROADMAP.md — Component source layout policy](COMPONENT_ROADMAP.md#component-source-layout-policy).

### FKCoreKit

```text
Sources/FKCoreKit/Components/ImageLoader/
├── README.md
├── Public/
│   ├── FKImageLoader.swift
│   ├── FKImageLoaderConfiguration.swift
│   ├── FKImageLoaderError.swift
│   ├── FKImageLoadOptions.swift          # if needed
│   └── FKImageLoaderEvent.swift          # optional metrics
├── Internal/
│   ├── FKImageLoaderEngine.swift         # actor / coalescing
│   ├── FKImageMemoryCache.swift
│   ├── FKImageDiskCache.swift
│   ├── FKImageDecoder.swift
│   └── FKImageCacheKeyBuilder.swift
└── Extension/
    └── FKImageLoader+Prefetch.swift
```

Add `Components/ImageLoader` to `Package.swift` `readmeExcludes`.

### FKUIKit

```text
Sources/FKUIKit/Components/ImageView/
├── README.md
├── Public/
│   ├── FKImageView.swift
│   ├── FKImageViewState.swift
│   ├── Configuration/
│   │   ├── FKImageViewConfiguration.swift
│   │   ├── FKImageViewAppearanceConfiguration.swift
│   │   ├── FKImageViewLoadingConfiguration.swift
│   │   ├── FKImageViewFailureConfiguration.swift
│   │   └── FKImageViewAccessibilityConfiguration.swift
│   └── Bridge/
│       └── FKImageViewRepresentable.swift
├── Internal/
│   ├── FKImageViewLoadCoordinator.swift
│   ├── FKImageViewPlaceholderView.swift
│   └── FKImageViewFailureView.swift
└── Extension/
    └── FKImageView+Convenience.swift
```

---

## 25. FKKitExamples Scenarios

Each scenario is a **separate** view controller under `Examples/FKKitExamples/.../FKUIKit/ImageView/`.

| # | Scenario ID | Title | Validates |
|---|-------------|-------|-----------|
| 1 | `BasicsRemoteURL` | Remote URL + placeholder | Default load, placeholder, success transition |
| 2 | `CornerRadiusBorder` | Corner & border styles | Appearance configuration matrix |
| 3 | `ListReuseStress` | Fast scroll list | Cancellation, no wrong image |
| 4 | `FailureRetry` | Failure & retry | Simulated 404 / offline mock |
| 5 | `SkeletonLoading` | Skeleton overlay | FKSkeleton integration |
| 6 | `Prefetch` | Table prefetch | Loader prefetch API |
| 7 | `LocalFile` | file:// image | Local load path |
| 8 | `SwiftUI` | SwiftUI host | Representable |
| 9 | `CustomLoader` | Injected loader | Pluggable swap |
| 10 | `CacheInspector` | Cache hit/miss | Debug UI showing second load instant |

Hub entry: **ImageView** with subtitle describing loader + view stack.

---

## 27. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Extend `FKImageLoadRequest` in Pluggable with cache policy? | Use parallel `FKImageLoadOptions` in FKCoreKit only for v1 |
| Q2 | Disk cache via dedicated directory vs `FKFileStorage` backend? | Dedicated directory under Caches; simpler eviction |
| Q3 | `FKImageView` subclass `UIImageView` vs composition? | Composition (container + image layer) for skeleton/failure overlays |
| Q4 | Byte-level progress in v1? | Defer; indeterminate progress only |
| Q5 | Shared `URLSession` with `FKNetworkClient`? | Separate session by default; configurable injection |

---

## 28. Revision History

| Date | Author | Change |
|------|--------|--------|
| 2026-06-08 | FKKit | Initial design requirements derived from COMPONENT_ROADMAP §1.1 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) — program roadmap (English)
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — program roadmap (Chinese)
- [Pluggable FKImageLoading](../Sources/FKCoreKit/Components/Pluggable/Media/FKImageLoading.swift) — protocol contracts
- [FKSkeleton README](../Sources/FKUIKit/Components/Skeleton/README.md) — skeleton integration
