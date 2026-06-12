# FKCarousel / FKImageBanner

Horizontal paging carousel controls for embeddable hero banners, onboarding cards, and marketing strips.

## Overview

| Type | Role |
|------|------|
| `FKCarousel` | Generic `UICollectionView`-backed horizontal pager with indicator, auto-scroll, and infinite loop |
| `FKImageBanner` | Image-first preset on `FKCarousel` with `FKImageView`, overlays, skeleton, and link handling |
| `FKCarouselConfiguration` | Layered layout, paging, indicator, auto-scroll, motion, and accessibility policy |
| `FKImageBannerConfiguration` | Image content mode, overlay, prefetch, and card chrome mapped to carousel config |

## When to use

| Scenario | Component |
|----------|-----------|
| Full-screen tab + child view controllers | `FKPagingController` + `FKTabBar` |
| Tab strip without full paging | `FKTabBar` |
| Single-line scrolling announcement | `FKMarqueeLabel` |
| Feed / home hero image carousel | `FKImageBanner` |
| Custom mixed page content | `FKCarousel` |

## Requirements

- iOS 15+
- Swift 6
- FKUIKit (depends on FKCoreKit)

## Directory layout

| Path | Responsibility |
|------|----------------|
| `Public/FKCarousel.swift` | Generic carousel `UIView` |
| `Public/FKImageBanner.swift` | Image banner facade over `FKCarousel` |
| `Public/Models/` | `FKCarouselItem`, state types, `FKImageBannerSlide` |
| `Public/Configuration/` | Layered `Sendable` configuration structs and presets |
| `Public/Protocols/` | Data source, delegate, and closure callbacks |
| `Public/SwiftUI/` | `FKCarouselRepresentable`, `FKImageBannerRepresentable` |
| `Internal/Layout/` | `FKCarouselFlowLayout`, layout metrics engine |
| `Internal/` | Indicator, auto-scroll, infinite loop, gesture coordinator |
| `Internal/Cells/` | Host cell and image banner page cell |

## Quick start

```swift
import FKUIKit

let banner = FKImageBanner(configuration: .homeHero())
banner.setSlides([
  .init(
    id: "promo-1",
    imageSource: .url(URL(string: "https://example.com/banner.jpg")!),
    title: "Summer Sale",
    subtitle: "Up to 50% off",
    linkURL: URL(string: "https://example.com/sale")
  ),
])
view.addSubview(banner)
```

### Custom pages with `FKCarousel`

```swift
let carousel = FKCarousel(configuration: .onboarding())
carousel.pageProvider = { item, bounds in
  let label = UILabel(frame: bounds)
  label.text = item.accessibilityLabel
  label.textAlignment = .center
  return label
}
carousel.setItems([
  .init(id: "1", accessibilityLabel: "Welcome"),
  .init(id: "2", accessibilityLabel: "Get started"),
])
```

### Programmatic paging

```swift
carousel.scrollToPage(2, animated: true)
```

## Configuration

Apply layered configuration without losing the current page when possible:

```swift
var config = carousel.configuration
config.autoScroll.isEnabled = true
config.autoScroll.interval = 3
carousel.apply(configuration: config)
```

Presets: `FKCarouselPresets.fullWidth()`, `.cardPeek()`, `.onboarding()`; `FKImageBannerPresets.homeHero()`, `.compactPromo()`, `.edgeToEdge()`.

## SwiftUI

```swift
@State private var page = 0

FKImageBannerRepresentable(
  slides: slides,
  currentPage: $page,
  configuration: .homeHero()
)
```

## Accessibility

- Container announces slide label + position (`"Slide 2 of 5"`)
- Optional VoiceOver three-finger scroll page changes
- Reduce Motion disables auto-scroll
- CTA uses `FKButton` 44pt minimum touch target

## Examples

Entry: **FKKitExamples → FKUIKit → Carousel**

| Section | Scenarios |
|---------|-----------|
| FKImageBanner · Marketing | Home hero, card peek, mixed overlay, failure fallback |
| FKImageBanner · States | Single slide & empty, Dynamic Type, presets gallery |
| FKCarousel · Layout & indicators | Onboarding, data source, indicator styles, layout modes |
| FKCarousel · Behavior & integration | Auto-scroll, manual control, table header, delegate log, SwiftUI, RTL |

`@MainActor` UI only. Image decoding runs through `FKImageLoader` off the main thread.
