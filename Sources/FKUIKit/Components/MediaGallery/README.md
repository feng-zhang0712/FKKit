# FKMediaGallery

Full-screen mixed media lightbox for browsing images and videos with hero transitions, pinch zoom, swipe-to-dismiss, and `FKVideoPlayer` integration.

## Requirements

- Swift 6, iOS 15+
- `import FKUIKit`

## When to use

| Need | Component |
|------|-----------|
| Pick new media | `FKPhotoPicker` |
| Embedded banner / carousel | `FKCarousel` / `FKImageBanner` |
| Full-screen browse a group of images/videos | **`FKMediaGallery`** |
| PiP, subtitles, offline HLS, full controls | `FKVideoPlayerViewController` |

## Source layout

| Path | Role |
|------|------|
| `Public/FKMediaGallery.swift` | `@MainActor` facade and presentation API |
| `Public/FKMediaGalleryViewController.swift` | Full-screen host, paging collection, runtime updates |
| `Public/FKMediaGalleryViewController+Gestures.swift` | Tap, pan dismiss, long-press context menu |
| `Public/FKMediaGalleryViewController+ShareSave.swift` | Default share/save flows |
| `Public/FKMediaGalleryItem.swift` | Page model and image/video source enums |
| `Public/FKMediaGalleryConfiguration.swift` | Sendable configuration structs |
| `Public/FKMediaGalleryError.swift` | Typed failures |
| `Public/FKMediaGalleryDelegate.swift` | Lifecycle and action callbacks |
| `Public/FKMediaGalleryPresets.swift` | Factory presets and defaults |
| `Public/Transition/` | Hero transition source and animator |
| `Public/Bridge/FKMediaGalleryPresenter.swift` | SwiftUI presenter modifier |
| `Extension/` | Photo picker mapping, gallery video preset, static convenience |
| `Internal/` | Coordinator, cells, compact chrome bars, layout helpers |
| `Internal/Chrome/` | Top bar, bottom caption, chrome pairing |

## Quick start

```swift
import FKUIKit

let gallery = FKMediaGallery()
try gallery.present(
  from: self,
  items: post.media,
  startIndex: tappedIndex,
  transitionSource: FKMediaGalleryTransitionSource(
    thumbnailView: thumbnailImageView,
    placeholderImage: thumbnailImageView.image
  ),
  configuration: .socialFeed()
)
gallery.delegate = self
```

Photo picker bridge:

```swift
let items = FKMediaGalleryItem.from(pickerResults)
try FKMediaGallery.present(from: self, items: items)
```

Runtime update while presented:

```swift
try gallery.viewController?.updateItems(updatedItems, animated: true)
```

## Video policy

Gallery video pages **must** use `FKVideoPlayer` + `FKVideoPlayerView` with the `FKVideoPlayerConfiguration.galleryEmbedded()` preset. Delegate `requestFullScreenVideoPlayerFor` hands off to `FKVideoPlayerViewController` for PiP, subtitles, and full chrome.

## Configuration presets

- `socialFeed()` — hero, mixed media, Wi‑Fi autoplay, context menu
- `chatAttachments()` — cross-dissolve, muted default
- `productDetail()` — high max zoom, no autoplay
- `previewOnly()` — no share/edit actions
- `authenticatedCDN()` — conservative autoplay defaults

## Customization

- Inject `imageLoader` on `FKMediaGallery(imageLoader:)` for global CDN headers.
- Implement `FKMediaGalleryChromeProviding` for per-page overlays.
- Override delegate share/save/edit/full-screen video actions; return `false` to use built-in defaults where available.

## Related components

- `FKImageView` / `FKImageLoader` — image pages and prefetch
- `FKVideoPlayer` — gallery and full-screen video playback
- `FKPhotoPicker` — selection; map results with `FKMediaGalleryItem.from(_:)`
- `FKFileManager.makeShareController(for:)` — default share sheet

## Examples

Entry: **FKKitExamples → FKUIKit → MediaGallery**

| Hub section | Scenarios |
|-------------|-----------|
| Getting started | Social feed, presets, single image, product detail |
| Media sources | Local/remote/mixed, loading failure, cache key, auth headers |
| Gestures & video | Zoom, swipe dismiss, autoplay, context menu, full player handoff |
| Runtime & integration | Chat updateItems, PhotoPicker bridge, custom chrome, SwiftUI |
| Accessibility & layout | Reduce Motion, RTL |
