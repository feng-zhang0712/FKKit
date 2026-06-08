# FKCarousel / FKImageBanner — Design Requirements

Implementation guide for FKKit **horizontal paging carousel** controls: **`FKCarousel`** (generic page host) and **`FKImageBanner`** (image-first marketing / feed hero preset built on the same engine).

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.4  
**中文版本:** [FKCarousel-FKImageBanner_DESIGN.zh-CN.md](FKCarousel-FKImageBanner_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Product Split — FKCarousel vs FKImageBanner](#4-product-split--fkcarousel-vs-fkimagebanner)
- [5. Architectural Overview](#5-architectural-overview)
- [6. Module Boundaries](#6-module-boundaries)
- [7. FKCarousel — Data Model](#7-fkcarousel--data-model)
- [8. FKCarousel — Layout & Paging Engine](#8-fkcarousel--layout--paging-engine)
- [9. FKCarousel — Page Indicator](#9-fkcarousel--page-indicator)
- [10. FKCarousel — Auto-Scroll](#10-fkcarousel--auto-scroll)
- [11. FKCarousel — Infinite Loop](#11-fkcarousel--infinite-loop)
- [12. FKCarousel — Interaction & Gestures](#12-fkcarousel--interaction--gestures)
- [13. FKCarousel — Custom Page Content](#13-fkcarousel--custom-page-content)
- [14. FKImageBanner — Page Model & Semantics](#14-fkimagebanner--page-model--semantics)
- [15. FKImageBanner — Visual Layout & Overlays](#15-fkimagebanner--visual-layout--overlays)
- [16. FKImageBanner — Loading, Placeholder & FKImageView](#16-fkimagebanner--loading-placeholder--fkimageview)
- [17. FKImageBanner — Tap, Deep Link & CTA](#17-fkimagebanner--tap-deep-link--cta)
- [18. Configuration Model](#18-configuration-model)
- [19. Delegate, Data Source & Callback API](#19-delegate-data-source--callback-api)
- [20. Lifecycle, Visibility & Timer Policy](#20-lifecycle-visibility--timer-policy)
- [21. Prefetching, Reuse & Performance](#21-prefetching-reuse--performance)
- [22. Accessibility](#22-accessibility)
- [23. RTL, Dynamic Type & Dark Mode](#23-rtl-dynamic-type--dark-mode)
- [24. Motion, Haptics & Reduce Motion](#24-motion-haptics--reduce-motion)
- [25. Component Boundaries](#25-component-boundaries)
- [26. SwiftUI Bridge](#26-swiftui-bridge)
- [27. Proposed Source Layout](#27-proposed-source-layout)
- [28. FKKitExamples Scenarios](#28-fkkitexamples-scenarios)
- [29. Open Questions](#29-open-questions)
- [30. Revision History](#30-revision-history)

---

## 1. Executive Summary

Home feeds, ecommerce storefronts, onboarding, and campaign surfaces repeatedly implement the same **horizontal paging banner**: swipe between pages, dots or fraction indicator, optional auto-advance, infinite loop for promos, remote images with placeholders, title/CTA overlays, and tap-to-open deep links.

FKKit ships **`FKPagingController`** for **full-screen tab + child view controller** paging and **`FKTabBar`** for tab strip chrome — but **no** lightweight **`UIView`** carousel for embedding in table headers, collection supplementary views, or hero regions.

| Deliverable | Role |
|-------------|------|
| **`FKCarousel`** | Generic `@MainActor` horizontal pager: `UICollectionView`-backed pages, indicator, auto-scroll, infinite loop, custom page hosting. |
| **`FKImageBanner`** | Opinionated preset on `FKCarousel` for remote/local image slides with `FKImageView`, overlays, skeleton, and link handling. |
| **`FKCarouselConfiguration`** | Layered `Sendable` policy: layout, paging, indicator, auto-scroll, motion, accessibility. |
| **`FKImageBannerConfiguration`** | Image-specific defaults: aspect ratio, overlay typography, image loader injection, prefetch radius. |
| **`FKCarouselItem` / `FKImageBannerSlide`** | Hashable page models with stable identifiers for Diffable-style updates. |

**Module:** `FKUIKit` only (`Sources/FKUIKit/Components/Carousel/`).

**Hard dependency (FKImageBanner):** **`FKImageView`** + **`FKImageLoader`** (roadmap §1.1). `FKImageBanner` must compile against `FKImageView` when shipped; document interim `UIImageView` fallback only if ImageView lands in the same release train.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Embed anywhere** — single `UIView` with intrinsic/c configurable height; works inside `UITableView` header, `UICollectionView` supplementary, stack views, and SwiftUI representable.
2. **Production paging** — snap-to-page, velocity-aware settling, programmatic `scrollToPage`, current index callbacks, RTL mirroring.
3. **Page indicator** — dots, stretched dash, numeric fraction, progress bar, custom provider; inside/outside placement; hides when `pageCount <= 1`.
4. **Auto-scroll** — interval timer with pause-on-interaction, pause-off-screen, pause-on-background, respect Reduce Motion.
5. **Infinite loop** — optional seamless wrap for marketing loops (≥2 items); disable for bounded content (onboarding steps).
6. **Image banner preset** — URL/local asset slides, placeholder/skeleton/failure per slide, optional title/subtitle/CTA overlay, tap + link URL.
7. **Reuse FKKit** — `FKImageView`, `FKSkeleton`, `FKButton`, `FKCornerShadow`, `FKProgressBar` (optional thin progress), `FKDebouncer`, Extension layout helpers.
8. **HIG baseline** — 44pt expanded hit targets on interactive overlays; VoiceOver page announcements; Dynamic Type for text overlays.
9. **Swift 6** — `Sendable` configs; `@MainActor` UI; weak delegates; no retain cycles in timers/closures.
10. **SwiftUI** — `FKCarouselRepresentable`, `FKImageBannerRepresentable` with `Binding` for current page index.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Full-screen zoom gallery / pinch-to-zoom lightbox | Future `FKImageGallery`; banner tap may `openURL` or host callback only |
| Vertical carousel / 3D cover flow | Horizontal only v1 |
| Video playback pages (inline `AVPlayer`) | Static image banner v1; host may supply custom `FKCarousel` pages with Player |
| `UIPageViewController` child VC paging | Use `FKPagingController` instead |
| Parallax, cube, or custom transition shaders | Standard horizontal translation only |
| Auto-playing animated GIF/APNG in banner | Static image frames unless system decodes in `UIImage` |
| macOS / tvOS | iOS 15+ UIKit |
| Built-in analytics impression tracking | Host observes delegate; optional hook only |
| Drag-to-reorder pages | Host replaces items array |
| Simultaneous multi-page visible grid | Use `UICollectionView` compositional layout separately |

### 2.3 Success Criteria

- [ ] Five-slide remote image banner with dots, auto-scroll (3s), infinite loop, tap opens URL — demonstrated in Examples.
- [ ] Peek layout (next page edge visible) with card corner radius via `FKCornerShadow`.
- [ ] Auto-scroll pauses while user drags and when `window == nil`.
- [ ] Reduce Motion disables auto-scroll and uses cross-fade or instant page change per config.
- [ ] VoiceOver: "Slide 2 of 5" + optional title; swipe changes page announcement.
- [ ] List header embedding: height stable from aspect ratio; fast scroll does not leak timers.
- [ ] README decision tree vs `FKPagingController`, `FKTabBar`, `FKMarqueeLabel`.
- [ ] Component README with directory map; root README index row when public API ships.

---

## 3. Background & Problem Statement

### 3.1 Current FKKit state

| Area | Status |
|------|--------|
| Horizontal pager for child VCs | **`FKPagingController`** + **`FKTabBar`** |
| Remote image in a view | **`FKImageView`** (roadmap §1.1) |
| Shimmer placeholder preset | **`FKSkeleton`** includes banner-height preset |
| Marquee single-line text | **`FKMarqueeLabel`** (SmallComponents / Widgets) |
| **`FKCarousel` / `FKImageBanner`** | **None** |

### 3.2 Repeated integrator pain

| Pain | Without FKKit |
|------|----------------|
| `UICollectionView` paging + loop index math | Off-by-one bugs, jump glitches at boundaries |
| Timer leaks in reusable headers | Runaway timers after cell reuse |
| Indicator desync during interactive scrub | Dots animate wrong while dragging |
| Nested horizontal vs vertical scroll conflict | Banner steals table scroll |
| Image load without cancellation on swipe away | Wrong image flash, memory spikes |
| Inconsistent promo overlay typography | One-off per screen |

### 3.3 Relationship to roadmap

Roadmap §2.4 lists: horizontal paging, page indicator, auto-scroll policy, infinite loop, `FKImageView` for pages. Dependency map: **`FKImageView` → `FKCarousel` / `FKAvatar`**. Phase **G** batch includes carousel with avatar/media UI.

---

## 4. Product Split — FKCarousel vs FKImageBanner

| Aspect | **`FKCarousel`** | **`FKImageBanner`** |
|--------|------------------|---------------------|
| **Purpose** | Generic page host for any `UIView` content | Marketing / feed hero image slides |
| **Page content** | Data source provides `UIView` or configuration closure | `FKImageBannerSlide` model (URL, image, overlay) |
| **Default layout** | Full-bleed pages | Fixed aspect ratio (e.g. 16:9) + optional card inset |
| **Loading** | Host-managed | Built-in `FKImageView` pipeline |
| **Overlays** | Optional per-page accessory view from host | Title, subtitle, gradient scrim, CTA `FKButton` |
| **Typical embedding** | Custom onboarding cards, mixed media | Home banner, category promo strip |

**Implementation strategy:** `FKImageBanner` is a **`final` wrapper** or **thin subclass** that owns an internal `FKCarousel`, applies `FKImageBannerConfiguration` → `FKCarouselConfiguration` mapping, and registers a built-in cell/renderer for image slides. Public API exposes banner-specific convenience (`setSlides(_:)`, `reloadSlides()`) while advanced hosts can use raw `FKCarousel` directly.

---

## 5. Architectural Overview

```text
┌─────────────────────────────────────────────────────────────┐
│ FKImageBanner (public facade, optional)                      │
│  ├─ maps slides → carousel items                             │
│  └─ configures image cell + overlays                         │
└───────────────────────────┬─────────────────────────────────┘
                            │ owns
┌───────────────────────────▼─────────────────────────────────┐
│ FKCarousel (UIView)                                          │
│  ├─ UICollectionView + FKCarouselFlowLayout                  │
│  ├─ FKCarouselPageIndicatorView (dots / bar / fraction)      │
│  ├─ FKCarouselAutoScrollController (Timer + pause rules)     │
│  ├─ FKCarouselInfiniteLoopAdapter (index mapping)            │
│  └─ FKCarouselGestureCoordinator (nested scroll arbitration)   │
└───────────────────────────┬─────────────────────────────────┘
                            │ uses
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   FKImageView         FKSkeleton          FKButton / CornerShadow
   (image pages)       (initial load)      (CTA, card chrome)
```

**State machine (carousel):**

| Phase | Description |
|-------|-------------|
| `idle` | Settled on page index `i` |
| `dragging` | User pan; indicator may interpolate |
| `decelerating` | Snap to target page |
| `programmatic` | `scrollToPage` animated transition |
| `autoAdvancing` | Timer fired; same as programmatic with distinct delegate reason |

Expose read-only `FKCarouselStateSnapshot` for debugging and SwiftUI bindings.

---

## 6. Module Boundaries

| In scope (`FKUIKit/Components/Carousel/`) | Out of scope |
|-------------------------------------------|--------------|
| Horizontal collection paging | Vertical paging |
| Page indicator rendering | Tab labels (`FKTabBar`) |
| Auto-scroll timer orchestration | Background fetch of slide JSON |
| Infinite loop index adapter | CMS / ad server SDK |
| Image slide cell with overlays | Full-screen gallery zoom |
| SwiftUI representables | WidgetKit timelines |

**FKCoreKit:** no new types required. Image loading stays on **`FKImageLoader`** via **`FKImageView`**.

---

## 7. FKCarousel — Data Model

### 7.1 `FKCarouselItem`

```swift
public struct FKCarouselItem: Hashable, Sendable {
  public let id: String
  public let accessibilityLabel: String?
  public let isInteractive: Bool
}
```

- **`id`** — stable across reloads for image identity and analytics correlation (host-defined).
- **`accessibilityLabel`** — announced with page index; defaults to nil → generic "Slide".
- **`isInteractive`** — when `false`, suppresses tap callback and reduces opacity for disabled styling if configured.

### 7.2 Item updates

- **`setItems(_:animated:)`** — replaces all pages; resets to index `0` or clamps preserved index when IDs match.
- **`applyDifference(_:)`** — optional helper accepting `[FKCarouselItem]` with same IDs to avoid full reload when only order changes.
- **Empty items** — show optional `FKEmptyState` overlay or collapse to zero height per `emptyStatePolicy`.

### 7.3 Index spaces

| Index space | Use |
|-------------|-----|
| **Logical** | `0 ..< pageCount` exposed to host |
| **Physical** | Includes duplicate head/tail cells when infinite loop enabled |

Public API always reports **logical** `currentPageIndex`. Internal adapter maps physical ↔ logical.

---

## 8. FKCarousel — Layout & Paging Engine

### 8.1 Collection view foundation

**Must** use `UICollectionView` with custom **`FKCarouselFlowLayout`** (subclass `UICollectionViewFlowLayout` or compositional horizontal group) because:

- Cell reuse is mandatory for large slide lists.
- Interactive indicator progress maps to `contentOffset / pageWidth`.
- Per-page custom cells (image vs host-provided) fit collection architecture.

**Scroll configuration:**

- `isPagingEnabled = true` when `layoutMode == .fullPage` and page width equals bounds width.
- For peek/card modes, layout sets `itemSize` and `sectionInset` so snapping aligns to page stride (`pageWidth + interPageSpacing`).

### 8.2 Layout modes

| Mode | Behavior |
|------|----------|
| **`.fullPage`** | One page per viewport width; edge-to-edge |
| **`.cardPeek(interPageSpacing:peekWidth:)`** | Page width = bounds − peek − insets; neighbor page visible |
| **`.fixedPageWidth(_:)`** | Constant width pages centered in wider container |
| **`.insetCard(cornerRadius:horizontalInset:)`** | Card slides with rounded corners (`FKCornerShadow` or layer) |

**Height policy:**

| Policy | Behavior |
|--------|----------|
| **`.fixed(_:)`** | Constant height in points |
| **`.aspectRatio(_:)`** | `height = width / ratio` (e.g. 16/9) |
| **`.intrinsicFromCurrentPage`** | Host/content-driven; image banner may update after load |

### 8.3 Paging behavior

**Must:**

- Snap to nearest page on drag end using velocity threshold (configurable, default aligns with UIScrollView deceleration).
- **`scrollToPage(_:animated:)`** — programmatic navigation; no-op when index out of range; coalesce rapid calls.
- **`currentPageIndex`** — KVO-friendly property; fires delegate on change after settle.
- **`pageCount`** — derived from items array.
- Support **`interPageSpacing`** (0 default for full bleed).
- **`decelerationRate`** configurable (`.normal` / `.fast`) for snappy marketing banners.

**Should:**

- Expose **`scrollProgress`** (0…1 fractional position between pages) for parallax overlays (host-drawn) without built-in parallax in v1.
- **`isScrollEnabled`** toggle for display-only carousels driven only by auto-scroll.

### 8.4 Clipping and safe area

- **`clipsToBounds`** default `true` for card mode; configurable.
- **`contentInsets`** optional respect for safe area when indicator inside overlay.
- **`respectsSafeAreaForIndicator`** — pin indicator above home indicator when bottom-aligned.

---

## 9. FKCarousel — Page Indicator

### 9.1 Styles

| Style | Description |
|-------|-------------|
| **`.dots`** | Classic page dots; current dot emphasized (size/color/width animation) |
| **`.bar`** | Horizontal capsule progress representing `(index+1)/count` |
| **`.fraction`** | Text `"2 / 5"` with `FKUIKitI18n` number formatting |
| **`.line`** | Underline segment per page (FKTabBar-inspired thin line) |
| **`.custom(FKCarouselPageIndicatorRendering)`** | Host draws via callback |
| **`.none`** | Hidden |

### 9.2 Placement

| Placement | Notes |
|-----------|-------|
| **`.overlayBottom(inset:)`** | Over content with gradient scrim recommendation in docs |
| **`.overlayTop(inset:)`** | Rare; support for LTR promos |
| **`.below(spacing:)`** | Outside collection view bounds; increases intrinsic height |
| **`.above(spacing:)`** | Above collection |

### 9.3 Indicator behavior

**Must:**

- Hide when `pageCount <= 1` unless `showsIndicatorForSinglePage == true`.
- Update on settle; optional **interactive tracking** during drag (`indicatorFollowsScrollProgress`).
- Configurable **dot diameter**, **spacing**, **current/inactive colors** (semantic: `.label`, `.tertiaryLabel`).
- **Reduce Motion:** disable dot scale animation; cross-fade current index only.

**Accessibility:**

- Indicator container is **`accessibilityElementsHidden = true`** when page changes are announced on the carousel container (avoid duplicate announcements). Configurable.

---

## 10. FKCarousel — Auto-Scroll

### 10.1 Configuration

```swift
public struct FKCarouselAutoScrollConfiguration: Equatable, Sendable {
  public var isEnabled: Bool
  public var interval: TimeInterval          // default 3.0
  public var repeats: Bool                   // default true
  public var direction: FKCarouselScrollDirection // .forward / .reverse
  public var pausesOnUserInteraction: Bool   // default true
  public var pausesWhenOffscreen: Bool       // default true
  public var pausesWhenAppInactive: Bool     // default true
  public var respectsReducedMotion: Bool     // default true → disable when RM on
}
```

### 10.2 Timer implementation

**Must:**

- Use `Timer` on **`RunLoop.main`**, mode **`.common`**, so scrolling parent scroll views do not starve firing.
- **`FKCarouselAutoScrollController`** owned by carousel; invalidated on `deinit` and `didMoveToWindow(nil)`.
- On fire: advance to next page; at last page wrap to `0` when infinite loop **or** stop when `repeats == false`.
- Reset timer interval after user manual page change (debounce burst auto-advances).

**Must pause when:**

- User touch down on carousel scroll view.
- `window == nil` or `isHidden == true` or superview alpha near zero.
- `UIApplication.willResignActiveNotification`.
- `UIAccessibility.isReduceMotionEnabled` when `respectsReducedMotion`.

**Delegate:** `carouselWillAutoAdvance(from:to:)` optional cancel by host returning `false`.

---

## 11. FKCarousel — Infinite Loop

### 11.1 Enablement

- **`isInfiniteLoopEnabled`** — default `false` for onboarding; `true` recommended preset for `FKImageBanner` marketing.
- Requires **`pageCount >= 2`**. Single item disables loop.

### 11.2 Implementation requirements

**Must** use duplicate boundary items strategy:

- Physical data source inserts clone of last item at index 0 and clone of first at end (or equivalent 3-cell window technique).
- On settle at duplicate, **jump without animation** to real counterpart (standard infinite scroll pattern).
- **`scrollToPage`** uses logical indices only; adapter translates.

**Must not:**

- Allocate unbounded cell count.
- Break VoiceOver page index announcements (always speak logical index).

### 11.3 Loop + auto-scroll

- Forward auto-scroll at last logical page wraps to first seamlessly.
- Reverse direction supported when configured.

---

## 12. FKCarousel — Interaction & Gestures

### 12.1 Tap

- **`FKCarouselDelegate.carousel(_:didSelectPageAt:)`** when page `isInteractive`.
- Tap region excludes indicator when indicator is outside hit testing of overlay controls (document z-order).

### 12.2 Nested scroll arbitration

**Problem:** Banner inside vertical `UITableView` / `UICollectionView` competes for pan gestures.

**Must support policies** (mirror concepts from `FKPagingNestedHorizontalScrollPolicy`):

| Policy | Behavior |
|--------|----------|
| **`.standard`** | UIKit default |
| **`.failParentUntilCarouselAtEdge`** | When not at first/last page, carousel scroll takes precedence |
| **`.simultaneous`** | Allow vertical scroll while horizontal drag ambiguous until axis lock |

Expose **`carousel.panGestureRecognizer`** for advanced host wiring.

### 12.3 Edge navigation stack

- Optional **`requiresNavigationPopGestureToFail`** — when embedded in navigation controller, horizontal carousel at first page allows back swipe (use `require(toFail:)` pattern documented in PagingController).

---

## 13. FKCarousel — Custom Page Content

### 13.1 Data source protocol

```swift
@MainActor
public protocol FKCarouselDataSource: AnyObject {
  func numberOfPages(in carousel: FKCarousel) -> Int
  func carousel(_ carousel: FKCarousel, viewForPageAt index: Int, reusing view: UIView?) -> UIView
}
```

**Must:**

- Reuse passed `view` when same type; host clears substate before reconfigure.
- Call **`registerPageView(_:identifier:)`** optional registration for known reuse IDs.

### 13.2 Alternative: item-driven hosting

For simple cases, **`FKCarouselHostPageView`** wraps a configuration closure `(FKCarouselItem, CGRect) -> UIView` without full data source.

### 13.3 View controller pages

**Non-goal for v1.** Document that full VC pages belong in **`FKPagingController`**. If demanded later, child VC containment per visible page only.

---

## 14. FKImageBanner — Page Model & Semantics

### 14.1 `FKImageBannerSlide`

```swift
public struct FKImageBannerSlide: Hashable, Sendable {
  public let id: String
  public let imageSource: FKImageBannerImageSource
  public let title: String?
  public let subtitle: String?
  public let accessibilityLabel: String?
  public let linkURL: URL?
  public let linkOpenPolicy: FKImageBannerLinkOpenPolicy
  public let isInteractive: Bool
  public let overlayStyle: FKImageBannerOverlayStyle?
}

public enum FKImageBannerImageSource: Hashable, Sendable {
  case url(URL, cacheKey: String?)
  case image(UIImage) // not Sendable in strict sense — document @unchecked or use asset name String case
  case named(String, bundle: Bundle?)
}
```

**Notes:**

- Prefer **`case asset(String)`** for Sendable purity; `UIImage` case documented for host-only in-memory promos.
- **`linkOpenPolicy`** — `.inAppSafari`, `.openSystem`, `.callbackOnly`.
- **`overlayStyle`** — per-slide override of global overlay config (gradient, text alignment).

### 14.2 Batch API

```swift
public final class FKImageBanner: UIView {
  public func setSlides(_ slides: [FKImageBannerSlide], preservingIndex: Bool)
  public func reloadSlide(id: String)
  public var slides: [FKImageBannerSlide] { get }
}
```

---

## 15. FKImageBanner — Visual Layout & Overlays

### 15.1 Image content mode

| Mode | Use |
|------|-----|
| **`.scaleAspectFill`** | Default marketing crop |
| **`.scaleAspectFit`** | Letterboxed promos |
| **`.scaleToFill`** | Rare; document distortion |

### 15.2 Overlay stack (per page)

Layer order bottom → top:

1. **`FKImageView`** (or skeleton beneath)
2. **Gradient scrim** — `CAGradientLayer` configurable colors/stops (bottom-heavy for text legibility)
3. **Title** — `UILabel`, Dynamic Type text styles (`.headline` default)
4. **Subtitle** — `.subheadline`, secondary color
5. **CTA** — optional **`FKButton`** (compact style preset)

**Must:**

- **`maximumTextLines`** for title/subtitle (default 2 / 1).
- Truncation tail; expand not required v1.
- **Overlay visibility** — `.always`, `.accessibilityOnly`, `.never` per field.
- **RTL** — leading/trailing constraints for text and CTA.

### 15.3 Card / corner styling

- Reuse **`FKCornerShadowConfiguration`** or layer corner radius from **`FKImageBannerConfiguration.cardStyle`**.
- **`FKImageBannerPresets.homeHero()`**, **`.compactPromo()`**, **`.edgeToEdge()`** static factories.

---

## 16. FKImageBanner — Loading, Placeholder & FKImageView

### 16.1 Image loading

**Must:**

- Each visible/reusable cell hosts one **`FKImageView`**.
- Pass **`targetSize`** derived from cell bounds in points × screen scale for downsampling.
- **`imageLoader`** injectable per banner (defaults to `FKImageLoader.shared`).
- Cancel in-flight loads on reuse (`prepareForReuse`).

### 16.2 Placeholder states

| State | UI |
|-------|-----|
| Loading | Optional **`FKSkeleton`** shimmer over image area or `FKImageView` placeholder color |
| Success | Cross-fade transition (configurable duration; 0 when Reduce Motion) |
| Failure | Optional per-slide fallback image; banner-level **`failurePolicy`** (hide slide vs show error tile) |

### 16.3 Prefetch

- **`prefetchRadius`** (default 1): request images for logical index ± radius when page settles.
- Use **`FKImageLoader`** prefetch API when available; else fire-and-forget `loadImage` with lower priority documented.

### 16.4 Single-slide / empty

- Zero slides → optional empty placeholder view or zero height.
- One slide → hide indicator; auto-scroll disabled regardless of config.

---

## 17. FKImageBanner — Tap, Deep Link & CTA

### 17.1 Tap on image area

**Must:**

- Fire **`FKImageBannerDelegate.imageBanner(_:didSelectSlideAt:)`** always when interactive.
- When **`linkURL`** set and policy allows, open after delegate optionally confirms via **`shouldOpenLink(for:)`**.

### 17.2 CTA button

- Separate callback **`didTapCTA(forSlideAt:)`**; does not automatically open `linkURL` unless configured **`ctaUsesLinkURL`**.
- CTA respects **`FKButton`** loading/disabled states for async host actions.

### 17.3 Security

- Only **`http`/`https`/`tel`** schemes open by default; custom scheme allowlist in configuration.
- Do not log full URLs containing tokens.

---

## 18. Configuration Model

### 18.1 Layering (both types)

Follow **`FKButton`** / **`FKProgressBar`** pattern:

```swift
public struct FKCarouselConfiguration: Equatable, Sendable {
  public var layout: FKCarouselLayoutConfiguration
  public var paging: FKCarouselPagingConfiguration
  public var indicator: FKCarouselIndicatorConfiguration
  public var autoScroll: FKCarouselAutoScrollConfiguration
  public var interaction: FKCarouselInteractionConfiguration
  public var motion: FKCarouselMotionConfiguration
  public var accessibility: FKCarouselAccessibilityConfiguration
  public var emptyState: FKCarouselEmptyStatePolicy
}
```

**Apply:**

```swift
carousel.apply(configuration: config) // rebind layout, timer, indicator without losing index when possible
```

### 18.2 Global defaults

```swift
public enum FKCarouselDefaults {
  public static var configuration: FKCarouselConfiguration
  public static var imageBannerConfiguration: FKImageBannerConfiguration
}
```

### 18.3 Presets

| Preset | Description |
|--------|-------------|
| **`FKCarouselPresets.fullWidth()`** | Full bleed, dots bottom overlay |
| **`FKCarouselPresets.cardPeek()`** | Ecommerce style peek |
| **`FKImageBannerPresets.homeHero()`** | 16:9, infinite loop, 4s auto-scroll |
| **`FKImageBannerPresets.onboarding()`** | No loop, no auto-scroll, fraction indicator |

---

## 19. Delegate, Data Source & Callback API

### 19.1 `FKCarouselDelegate`

```swift
@MainActor
public protocol FKCarouselDelegate: AnyObject {
  func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason)
  func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int)
  func carousel(_ carousel: FKCarousel, willAutoAdvanceFrom from: Int, to: Int) -> Bool
  func carouselDidEndDragging(_ carousel: FKCarousel, willDecelerate: Bool)
}
```

**`FKCarouselPageChangeReason`:** `.userSwipe`, `.programmatic`, `.autoScroll`, `.loopCorrection`, `.reload`.

### 19.2 Closure-based alternative

**`FKCarouselCallbacks`** struct with optional `@MainActor` closures for SwiftUI-friendly integration (mirror `FKSearchBarCallbacks`).

### 19.3 `FKImageBannerDelegate`

Extends or wraps carousel delegate with slide-specific methods (`didSelectSlide`, `shouldOpenLink`, `didTapCTA`).

---

## 20. Lifecycle, Visibility & Timer Policy

**Must hook:**

| Event | Action |
|-------|--------|
| `didMoveToWindow` | Start/stop auto-scroll per visibility |
| `willMove(toSuperview:)` | Invalidate pending animations |
| `deinit` | Invalidate timer |
| `UIApplication.didEnterBackground` | Pause auto-scroll |
| `UIApplication.didBecomeActive` | Resume if visible and configured |
| `traitCollectionDidChange` | Update colors; re-evaluate Reduce Motion |

**List reuse:** when banner removed from window without dealloc, timers **must stop**. Document host duty to nil out strong references in `prepareForReuse`.

---

## 21. Prefetching, Reuse & Performance

### 21.1 Cell reuse

- **`FKImageBannerPageCell`** reuse identifier constant.
- **`prepareForReuse`** cancels image load, resets overlay text, removes CTA actions.

### 21.2 Memory

- Keep **current ± prefetchRadius** pages' bitmaps hot; rely on `FKImageLoader` cache eviction globally.
- **`evictOffscreenPagesFromMemory`** optional flag to nil images on distant cells (trade CPU for memory).

### 21.3 Main thread

- All UIKit mutations `@MainActor`.
- Image decode off main via `FKImageLoader`.

### 21.4 Budget targets

| Metric | Target |
|--------|--------|
| Settle animation | 60 fps on A15+ for 5-page banner |
| Timer drift | < 100ms over 60s interval |
| Reuse wrong-image flash | 0 with URL identity check |
| Embedded header scroll jank | No main-thread sync decode |

---

## 22. Accessibility

**Must:**

- Container **`accessibilityTraits`** includes `.allowsDirectInteraction` when swipe enabled.
- Announce **`accessibilityLabel`** combining slide label + "Slide X of Y" via `UIAccessibility.post(notification: .pageScrolled, ...)`.
- **`accessibilityScroll(_:)`** optional support for VoiceOver three-finger scroll to change pages when configured.
- CTA button is separate accessibility element with visible label (not "Button").
- Reduce Motion disables auto-scroll (§10).
- Minimum touch targets 44pt for CTA and tappable slides (`isInteractive`).

**Should:**

- Group overlay text in **`accessibilityContainerType`** when it forms one promo unit.

---

## 23. RTL, Dynamic Type & Dark Mode

- **RTL:** horizontal scroll direction reverses; indicator order mirrors; leading/trailing overlay constraints flip.
- **Dynamic Type:** title/subtitle use text styles; height may grow — **`FKImageBannerConfiguration.overlayExpansionPolicy`** (`.fixedBannerHeight` clip vs `.growBanner`).
- **Dark Mode:** semantic indicator colors; optional dimmed scrim in dark mode preset.

---

## 24. Motion, Haptics & Reduce Motion

| Feature | Default |
|---------|---------|
| Page change animation | UIScrollView deceleration |
| Indicator dot scale | Subtle spring when motion allowed |
| Image success cross-fade | 0.25s |
| Auto-scroll | Disabled when Reduce Motion |
| Haptics on page change | Off (optional light impact via config, off default) |

---

## 25. Component Boundaries

| Use | Component |
|-----|-----------|
| Tab strip + full-screen child VCs | **`FKPagingController`** |
| Filter tabs without full pager | **`FKTabBar`** |
| Single-line scrolling announcement | **`FKMarqueeLabel`** (Widgets) |
| Persistent offline notice strip | **`FKBanner`** (roadmap §2.1) — not swipe pages |
| Brief toast message | **`FKToast`** |
| Scalar progress | **`FKProgressBar`** |
| Hero image carousel in feed | **`FKImageBanner`** |
| Custom mixed page types | **`FKCarousel`** |

Document decision tree in component README.

---

## 26. SwiftUI Bridge

### 26.1 `FKCarouselRepresentable`

```swift
public struct FKCarouselRepresentable: UIViewRepresentable {
  public init(
    items: [FKCarouselItem],
    currentPage: Binding<Int>,
    configuration: FKCarouselConfiguration = FKCarouselDefaults.configuration,
    @ViewBuilder content: @escaping (FKCarouselItem) -> AnyView
  )
}
```

- **`Coordinator`** implements delegate; updates binding on page change.
- Avoid feedback loops when binding sets page from SwiftUI `.onChange`.

### 26.2 `FKImageBannerRepresentable`

- Accepts `[FKImageBannerSlide]` + bindings for `currentPage`.
- Optional **`onSlideTap`**, **`onCTATap`** closures.

---

## 27. Proposed Source Layout

```text
Sources/FKUIKit/Components/Carousel/
├── README.md
├── Public/
│   ├── FKCarousel.swift
│   ├── FKImageBanner.swift
│   ├── Models/
│   │   ├── FKCarouselItem.swift
│   │   ├── FKCarouselState.swift
│   │   ├── FKImageBannerSlide.swift
│   │   └── FKImageBannerImageSource.swift
│   ├── Configuration/
│   │   ├── FKCarouselConfiguration.swift
│   │   ├── FKCarouselLayoutConfiguration.swift
│   │   ├── FKCarouselIndicatorConfiguration.swift
│   │   ├── FKCarouselAutoScrollConfiguration.swift
│   │   ├── FKImageBannerConfiguration.swift
│   │   ├── FKCarouselPresets.swift
│   │   └── FKImageBannerPresets.swift
│   ├── Protocols/
│   │   ├── FKCarouselDataSource.swift
│   │   ├── FKCarouselDelegate.swift
│   │   ├── FKImageBannerDelegate.swift
│   │   └── FKCarouselCallbacks.swift
│   └── SwiftUI/
│       ├── FKCarouselRepresentable.swift
│       └── FKImageBannerRepresentable.swift
└── Internal/
    ├── Layout/
    │   ├── FKCarouselFlowLayout.swift
    │   └── FKCarouselLayoutEngine.swift
    ├── FKCarouselPageIndicatorView.swift
    ├── FKCarouselAutoScrollController.swift
    ├── FKCarouselInfiniteLoopAdapter.swift
    ├── FKCarouselGestureCoordinator.swift
    ├── FKCarouselCollectionCoordinator.swift
    ├── Cells/
    │   ├── FKCarouselHostCell.swift
    │   └── FKImageBannerPageCell.swift
    └── FKImageBannerOverlayView.swift
```

**Examples path:** `Examples/FKKitExamples/.../FKUIKit/Carousel/`

---

## 28. FKKitExamples Scenarios

| # | Scenario | Highlights |
|---|----------|------------|
| 1 | **HomeHeroBanner** | 5 remote URLs, infinite loop, auto-scroll, tap opens URL |
| 2 | **CardPeekPromo** | Peek layout + corner radius |
| 3 | **OnboardingCards** | Custom `FKCarousel` pages (UIView), no loop, fraction indicator |
| 4 | **SingleSlide** | Indicator hidden; auto-scroll off |
| 5 | **MixedOverlay** | Title/subtitle/CTA variants |
| 6 | **FailureFallback** | Broken URL → fallback image |
| 7 | **ReduceMotion** | System setting disables auto-scroll |
| 8 | **TableHeaderEmbed** | Banner in `UITableView` tableHeaderView; scroll + timer lifecycle |
| 9 | **RTL** | Arabic layout mirror |
| 10 | **SwiftUIBanner** | `FKImageBannerRepresentable` + `$currentPage` binding |
| 11 | **DynamicType** | Large content size overlay expansion policy |
| 12 | **ManualControl** | External prev/next buttons calling `scrollToPage` |

---

## 29. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Single type vs subclass for `FKImageBanner`? | Composition: banner owns internal `FKCarousel` |
| Q2 | Use `UICollectionViewCompositionalLayout` vs flow layout? | Flow layout v1 for predictable paging math |
| Q3 | Built-in Safari (`SFSafariViewController`) for link open? | Callback default; optional helper in Examples |
| Q4 | Expose scroll progress to sync external `FKTabBar`? | v1.1; document manual binding via delegate offset |
| Q5 | Video slide first-class? | v2 via custom carousel pages only |
| Q6 | Shared module folder name `Carousel/` vs `ImageBanner/`? | `Carousel/` containing both |

---

## 30. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements for FKCarousel / FKImageBanner |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) — program roadmap (English)
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — program roadmap (Chinese)
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md) — image loading dependency
- [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md) — related atoms (Badge, Marquee)
- [FKPagingController README](../Sources/FKUIKit/Components/PagingController/README.md) — full-screen paging boundary
