# FKMediaPlayer Core

Shared playback kernel for **FKVideoPlayer** and **FKAudioPlayer**. It owns format probing, engine selection, transport control, networking, audio session handling, Now Playing integration, resume storage, and playback state — not product-specific UI.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`
- Frameworks: AVFoundation, MediaPlayer, Network

## Architecture

```
FKVideoPlayer / FKAudioPlayer  (facades, UI + product logic)
            │
            ▼
FKMediaPlaybackCoordinator     (orchestration, state, plugins)
            │
     ┌──────┴──────┐
     ▼             ▼
FKAVPlayerEngine   FKExtendedPlayerEngine (AV best-effort; or custom factory)
```

| Layer | Responsibility |
|-------|----------------|
| **Core** | Engines, `FKMediaFormatProbe`, `FKMediaEngineRouter`, coordinator, errors, resume, DRM hooks |
| **VideoPlayer** | `AVPlayerLayer`, controls, PiP, subtitles UI, feed pool, live chrome |
| **AudioPlayer** | Queue, lyrics, mini bar, sleep timer, lock-screen skip for queue modes |

Core must **not** import VideoPlayer or AudioPlayer types.

## Features

| Area | Types / behavior |
|------|------------------|
| **Models** | `FKMediaItem`, `FKMediaSource` (URL, asset, photo library, offline id), `FKMediaPlaybackState`, `FKMediaError` |
| **Engines** | `FKAVPlayerEngine`, `FKExtendedPlayerEngine`, optional custom engine via `FKMediaEngineRouter.registerExtendedEngineFactory(_:)` |
| **Routing** | Automatic AV vs extended selection; configurable A↔E fallback in `FKMediaEnginePolicy` |
| **Network** | Retries, fallback URLs, headers, timeouts (`FKMediaNetworkSession`) |
| **System** | `FKMediaAudioSessionManager`, `FKMediaNowPlayingService`, remote commands |
| **Plugins** | `FKMediaResourceLoaderPlugin`, `FKMediaDRMPlugin` / FairPlay provider, `FKMediaAnalyticsPlugin` |
| **Offline** | HLS download service, download registry, playback provider bridge |
| **Advanced** | LL-HLS options, FairPlay configuration on assets |

## Quick start

```swift
import FKUIKit

let coordinator = FKMediaPlaybackCoordinator(configuration: .shared)
coordinator.delegate = self

let item = FKMediaItem(
  id: "1",
  source: .url(URL(string: "https://example.com/stream.m3u8")!),
  title: "Live stream"
)

coordinator.load(item, presentationMode: .video)
coordinator.attachRenderTarget(.playerLayer(myLayer))
coordinator.play()
```

### Custom extended engine (FFmpeg / VLC)

Register at launch before loading extended-only formats:

```swift
FKMediaEngineRouter.registerExtendedEngineFactory(myFactory)
// or
FKMediaPlayerExtended.registerExtendedEngineFactory(myFactory)
```

Without a factory, extended routes use `FKExtendedPlayerEngine` (AVPlayer best-effort).

## Key types

| Type | Role |
|------|------|
| `FKMediaPlaybackCoordinator` | Single entry for load / play / pause / seek / playlist |
| `FKMediaConfiguration` | Playback, network, engine policy, advanced options |
| `FKMediaFormatProbe` | URL → `FKMediaFormatDescriptor` |
| `FKMediaPlaybackCoordinatorDelegate` | State, time, buffer, playlist advance, errors |
| `FKMediaResumeStore` | Per-item resume position (`FKMediaUserDefaultsResumeStore`) |

### Sources

```swift
public enum FKMediaSource: Sendable {
  case url(URL, fallbackURLs: [URL] = [])
  case asset(AVURLAsset)
  case photoAsset(localIdentifier: String)
  case offline(downloadIdentifier: String)
}
```

### Presentation

```swift
public enum FKMediaPresentationMode: Sendable {
  case video      // may attach AVPlayerLayer
  case audioOnly  // no video surface
}
```

## Configuration defaults

| Setting | Default |
|---------|---------|
| `autoPlay` | `false` |
| `defaultRate` | `1.0` |
| `loopMode` | `.none` |
| `resumePlaybackEnabled` | `true` |
| `preferredForwardBufferDuration` | `5.0` s |
| `maxRetryCount` | `3` |
| `connectionTimeout` / `readTimeout` | `30` / `60` s |

## Format support (summary)

| Tier | Typical inputs | Engine |
|------|----------------|--------|
| **AV-native** | MP4, MOV, M4A, MP3, AAC, HLS, progressive HTTP | `FKAVPlayerEngine` |
| **Extended** | MKV, WebM, some legacy containers, DASH/RTMP (with custom factory) | Registered factory or AV fallback |
| **Transcode** | Unsupported combinations | `FKMediaError.transcodingRequired` |

Exact probing rules live in `FKMediaFormatProbe` and `FKMediaContainer`.

## Source layout

```
Player/Core/
├── Public/
│   ├── Coordinator/     FKMediaPlaybackCoordinator
│   ├── Engine/          FKAVPlayerEngine, FKMediaEngineRouter, protocols
│   ├── Models/          items, state, errors, configuration
│   ├── Protocols/       delegate, plugins, offline, FairPlay
│   └── Services/        probe, network, Now Playing, HLS download, QoE
├── Internal/            state machine, KVO, error mapping
└── Plugins/Extended/    FKExtendedPlayerEngine, registration helper
```

## Limitations

- **FairPlay**: `FKMediaFairPlayDRMPlugin` wires a resource-loader delegate; your app must supply `FKMediaFairPlayContentKeyProviding`.
- **Extended codecs**: No FFmpeg/VLC is bundled; register a factory or rely on AV fallback.
- **One coordinator per playback session** is recommended; `MPRemoteCommandCenter` is process-wide.
- **Unit tests** for Core are not shipped in this package target (add app-side tests as needed).

## Related modules

- [VideoPlayer](../VideoPlayer/README.md) — video facade and UI
- [AudioPlayer](../AudioPlayer/README.md) — audio facade, queue, and lyrics

## License

Same as FKKit. Third-party decoder libraries (e.g. FFmpeg) require their own license compliance.
