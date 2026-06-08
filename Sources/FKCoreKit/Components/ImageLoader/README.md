# FKImageLoader

Production default implementation of ``FKImageLoading`` and ``FKImageCaching`` for FKCoreKit.

## Overview

`FKImageLoader` closes the Pluggable image-loading gap with a zero–third-party stack:

- Remote `http`/`https` and local `file://` sources
- Off–main-thread decode and downsampling via `CGImageSource`
- Memory (`NSCache`) and disk caches with LRU/TTL eviction
- Conditional GET (`If-None-Match` / `If-Modified-Since`) when disk metadata exists
- In-flight request coalescing per cache key with per-waiter cancellation
- Concurrent prefetch, cache statistics, optional `FKLogger` debug output

Swap it at the app composition root or inject a custom ``FKImageLoading`` implementation.

## Requirements

- iOS 15+
- Swift 6
- FKCoreKit only (no FKUIKit dependency)

## Directory layout

| Path | Responsibility |
|------|----------------|
| `Public/FKImageLoader.swift` | Main `@MainActor` facade; protocol conformance |
| `Public/FKImageLoaderConfiguration.swift` | `Sendable` runtime configuration + reachability helper |
| `Public/FKImageLoaderURLSessionSettings.swift` | Equatable URLSession rebuild settings |
| `Public/FKImageLoadResult.swift` | Detailed load result (`image`, optional `sourceData`, `wasCached`) |
| `Public/FKImageLoaderStatistics.swift` | Debug cache/in-flight snapshot |
| `Public/FKImageLoaderError.swift` | Typed error surface |
| `Public/FKImageLoadOptions.swift` | Cache policy, disk exclusion, source-data return |
| `Public/FKImageLoaderEvent.swift` | Optional metrics events |
| `Internal/FKImageLoaderEngine.swift` | Actor: fetch, coalesce, decode orchestration |
| `Internal/FKImageMemoryCache.swift` | Thread-safe `NSCache` wrapper |
| `Internal/FKImageDiskCache.swift` | Disk byte cache with deferred index persistence |
| `Internal/FKImageDecoder.swift` | Downsample + format validation |
| `Internal/FKImageCacheKeyBuilder.swift` | Default cache key formatting |
| `Internal/FKImageLoaderLogging.swift` | `FKLogger` debug adapter |

## Quick start

```swift
import FKCoreKit

let loader = FKImageLoader.shared

let request = FKImageLoadRequest(
  url: URL(string: "https://example.com/photo.jpg")!,
  targetSize: CGSize(width: 120, height: 120)
)

Task { @MainActor in
  let image = try await loader.loadImage(for: request)
}
```

### Detailed result with source bytes

```swift
var options = FKImageLoadOptions()
options.returnsSourceData = true
let result = try await loader.loadImageResult(for: request, options: options)
```

### Reachability fast-fail

```swift
var config = FKImageLoaderConfiguration()
config.useNetworkReachability(FKNetworkReachability())
loader.apply(config)
```

### Custom URLSession

```swift
var config = FKImageLoaderConfiguration()
config.urlSessionProvider = { URLSession.shared }
loader.apply(config)
```

### Prefetch (concurrent)

```swift
await loader.prefetch(urls: feedURLs, targetSize: CGSize(width: 80, height: 80))
// UITableView cancel:
loader.cancelPrefetch(for: request)
```

### Cache statistics (debug)

```swift
let stats = await loader.cacheStatistics()
```

## Cancellation note

``cancelLoad(for:)`` cancels the loader-side waiter for a cache key. **Also cancel the caller's Swift `Task`** when you need `await loadImage` to throw immediately. Structured concurrency from ``loadImageResult(for:options:)`` handles this automatically via `withTaskCancellationHandler`.

## Configuration highlights

| Field | Default |
|-------|---------|
| `memoryCostLimit` | 100 MB |
| `memoryCountLimit` | 200 |
| `diskSizeLimit` | 200 MB |
| `diskEntryTTL` | 7 days |
| `requestTimeout` | 60 s |
| `maxConcurrentDecodes` | 4 |
| `maxConcurrentPrefetches` | 4 |
| `enablesConditionalGET` | `true` |
| `validatesFileURLs` | `true` |
| `diskIndexPersistDelay` | 2 s |

Memory warnings call ``clearMemoryCache()`` automatically.

## Related

- Pluggable contracts: `Components/Pluggable/Media/FKImageLoading.swift`
- UIImage helpers: `Components/Extension/UIKit/UIImage.swift`
- UI binding: [FKImageView](../../FKUIKit/Components/ImageView/README.md) in FKUIKit

## Examples (FKKitExamples)

Loader scenarios live under **FKUIKit → ImageView** alongside `FKImageView` demos (`Examples/FKKitExamples/Examples/FKUIKit/ImageView/Scenarios/Loader/`):

- **Async load & result** — `loadImage`, `loadImageResult`, `returnsSourceData`, Task cancellation
- **Cache policies** — `default`, `reloadIgnoringCache`, `cacheOnly`, `excludesFromDiskCache`
- **Prefetch API** — `prefetch(_:)`, `prefetch(urls:)`, `cancelPrefetch`
- **Cache inspector** — `cachedImage`, `store`, `removeImage`, `removeAllImages`, `trimMemoryCache`, `cacheStatistics`
- **Configuration & events** — `apply(_:)`, `onEvent`, `flushDiskCacheIndex`
