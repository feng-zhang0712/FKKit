# FKImageView

Configuration-driven UIKit image view for remote and local images, built on FKCoreKit ``FKImageLoading``.

## Overview

`FKImageView` binds load state to UI:

- Placeholder (bitmap, color, SF Symbol, initials)
- Optional skeleton shimmer and progress chrome
- Success transitions with reduced-motion support
- Failure overlay with retry
- Corner radius, border, shadow styling
- Cell reuse safety via identity-checked loads
- SwiftUI bridge via ``FKImageViewRepresentable``

Inject ``FKImageLoader/shared`` or any custom ``FKImageLoading`` implementation at the app composition root.

## Requirements

- iOS 15+
- Swift 6
- FKUIKit (depends on FKCoreKit)

## Directory layout

| Path | Responsibility |
|------|----------------|
| `Public/FKImageView.swift` | Main `@MainActor` view and public loading API |
| `Public/FKImageViewState.swift` | State machine and failure reason types |
| `Public/Configuration/` | Layered `Sendable` configuration structs |
| `Public/Configuration/FKImageViewProfile.swift` | List/detail presets (`full`, `listCell`, `minimal`) |
| `Public/Bridge/FKImageViewRepresentable.swift` | SwiftUI `UIViewRepresentable` |
| `Internal/FKImageViewLoadCoordinator.swift` | Token-based async load orchestration |
| `Internal/FKImageViewPlaceholderView.swift` | Single-slot placeholder rendering |
| `Internal/FKImageViewFailureView.swift` | Failure + retry overlay (lazy) |
| `Internal/FKImageView+LazySubviews.swift` | On-demand loading chrome and failure overlay |
| `Internal/FKImageView+Presentation.swift` | Load lifecycle and state transitions |
| `Internal/FKImageView+Chrome.swift` | Corners, shadow, skeleton, progress |
| `Internal/FKImageView+Interaction.swift` | Tap, highlight, accessibility |
| `Extension/FKImageView+Convenience.swift` | Fluent configuration helpers |

## Quick start

```swift
import FKUIKit

let imageView = FKImageView()
imageView.configuration.loading.placeholder = .symbol(name: "photo", pointSize: 32, weight: .regular)
imageView.load(url: URL(string: "https://example.com/photo.jpg")!)
```

### Manual load control

```swift
imageView.configuration.loading.loadsAutomatically = false
imageView.load(url: url, placeholder: .color(.secondarySystemFill))
imageView.startLoading()
```

### Local image without URL

```swift
imageView.setImage(localUIImage, animated: true)
```

### Cache key override

```swift
imageView.cacheKey = "avatar-\(userID)"
imageView.load(url: avatarURL)
```

### Custom placeholder view

```swift
imageView.configuration.loading.customPlaceholderProvider = {
  let label = UILabel()
  label.text = "…"
  label.textAlignment = .center
  return label
}
```

### Integration profiles

```swift
let thumb = FKImageView(profile: .listCell)   // feed / collection thumbnails
let hero = FKImageView(profile: .full)      // detail with failure overlay + chrome
let badge = FKImageView(profile: .minimal)  // image + color fill only
```

| Profile | Failure overlay | Loading chrome | Typical success descendants |
|---------|-----------------|----------------|----------------------------|
| `.full` | Yes (lazy) | Lazy, released on success | ~2 (container + image) |
| `.listCell` | No | None | ~2 |
| `.minimal` | No | None | ~2 |

See **Profile hierarchy** in FKKitExamples to compare live subtree snapshots.

### Cell reuse

Use ``FKImageViewProfile/listCell`` for feed thumbnails — shallow success hierarchy (container + placeholder + image), no inline failure overlay:

```swift
let imageView = FKImageView(profile: .listCell)
// or: FKImageView(configuration: .profile(.listCell))

override func prepareForReuse() {
  super.prepareForReuse()
  imageView.resetForReuse()
}
```

Loading chrome (spinner, progress bar), placeholders, and failure overlays are **created on demand** and **removed when no longer needed** so list cells do not retain unused subtrees. After **success**, the steady-state hierarchy is `FKImageView → contentContainer → UIImageView`.

### Custom loader

```swift
FKImageViewDefaults.sharedImageLoader = myCDNLoader
```

### SwiftUI

```swift
FKImageViewRepresentable(
  url: imageURL,
  configuration: .init()
)
```

## Related

- [FKImageLoader](../../FKCoreKit/Components/ImageLoader/README.md) — default loader implementation
- [FKImageLoader-FKImageView design](../../../docs/FKImageLoader-FKImageView_DESIGN.md)

## Examples (FKKitExamples)

Open **FKUIKit → ImageView** in the demo app (`Examples/FKKitExamples/Examples/FKUIKit/ImageView/`):

| Hub section | Scenarios |
|-------------|-----------|
| FKImageView · Basics | Remote URL, placeholders, `setImage`, manual load, local file |
| FKImageView · Appearance & loading | Corners/border/shadow, loading chrome, failure/retry, interaction/a11y |
| FKImageView · Lists & integration | UITableView reuse (`listCell`), **profile hierarchy**, prefetch, custom loader, cache key, SwiftUI |
| FKImageLoader · Programmatic API | Async load/result, cache policies, prefetch |
| FKImageLoader · Cache & configuration | Cache inspector, configuration & `onEvent` |
