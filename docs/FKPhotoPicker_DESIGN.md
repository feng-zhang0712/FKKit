# FKPhotoPicker — Design Requirements

Implementation guide for FKKit **`FKPhotoPicker`**: a production-oriented wrapper around **`PHPickerViewController`** and **`UIImagePickerController`** with **`FKPermissions`** preflight, selection limits, post-processing (compression, resize), and typed results (`UIImage`, `Data`, file URL).

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.6  
**中文版本:** [FKPhotoPicker_DESIGN.zh-CN.md](FKPhotoPicker_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Architectural Overview](#4-architectural-overview)
- [5. Module Boundaries](#5-module-boundaries)
- [6. Picker Backends & Selection Strategy](#6-picker-backends--selection-strategy)
- [7. Sources & Presentation Modes](#7-sources--presentation-modes)
- [8. Permission Preflight](#8-permission-preflight)
- [9. Selection Limits & Media Types](#9-selection-limits--media-types)
- [10. Pick Flow & Lifecycle](#10-pick-flow--lifecycle)
- [11. Result Model & Delivery](#11-result-model--delivery)
- [12. Image Processing Pipeline](#12-image-processing-pipeline)
- [13. Video Handling](#13-video-handling)
- [14. Public API Surface](#14-public-api-surface)
- [15. Error Taxonomy](#15-error-taxonomy)
- [16. Configuration Model](#16-configuration-model)
- [17. Presentation Integration](#17-presentation-integration)
- [18. Security & Privacy](#18-security--privacy)
- [19. Concurrency & Memory](#19-concurrency--memory)
- [20. Accessibility & Localization](#20-accessibility--localization)
- [21. SwiftUI Bridge](#21-swiftui-bridge)
- [22. Proposed Source Layout](#22-proposed-source-layout)
- [23. FKKitExamples Scenarios](#23-fkkitexamples-scenarios)
- [25. Open Questions](#25-open-questions)
- [26. Revision History](#26-revision-history)

---

## 1. Executive Summary

Avatar upload, KYC document capture, chat image attachments, and product listing photos all require **camera capture** and/or **photo library selection**. Raw integration of `PHPickerViewController` and `UIImagePickerController` forces every team to reimplement:

- Permission checks aligned with Info.plist copy
- PHPicker vs legacy picker choice and `selectionLimit`
- Multi-select caps and mixed media policies
- Main-thread presentation and delegate wiring
- Image downscaling, JPEG compression, temp file export
- Denied / limited library UX

**`FKPhotoPicker`** (`Sources/FKUIKit/Components/PhotoPicker/`) is a **`@MainActor`** coordinator that presents system pickers from a host `UIViewController`, runs **`FKPermissions`** preflight, processes assets on a background executor, and returns **`FKPhotoPickerResult`** arrays via `async` continuations or callbacks.

| Deliverable | Role |
|-------------|------|
| **`FKPhotoPicker`** | Main coordinator (`presentPick`, `presentCamera`, `presentLibrary`) |
| **`FKPhotoPickerConfiguration`** | Sendable policy: sources, limits, media types, processing |
| **`FKPhotoPickerResult`** | Per-asset output: image, data, file URL, metadata |
| **`FKPhotoPickerError`** | Typed failures (permission, cancel, processing, unavailable) |
| **`FKPhotoPicking`** | Protocol for dependency injection |

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Unified entry API** — one configuration struct drives library, camera, or chooser (action sheet).
2. **FKPermissions integration** — preflight + optional `FKPermissionPrePrompt` before system dialogs.
3. **PHPicker-first** — library picking on iOS 15+ via `PHPickerViewController`; camera via `UIImagePickerController` (or `UIImagePickerController` camera source).
4. **Selection limits** — single (avatar) and multi (max N) with PHPicker `selectionLimit`.
5. **Processing pipeline** — max pixel dimension, JPEG/HEIC quality, strip GPS EXIF option, temp file URLs.
6. **Typed results** — `UIImage` for in-memory UI; `URL` for upload pipelines; raw `Data` optional.
7. **Limited Photos library** — handle `FKPermissionStatus.limited` with documented UX (manage selection / open Settings).
8. **Swift 6** — `Sendable` configuration and results; background processing off main actor.
9. **Cancellation** — user dismiss maps to `FKPhotoPickerError.cancelled`, not generic failure.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Custom gallery grid UI | System pickers only |
| Built-in crop UI beyond `allowsEditing` on camera | v1.1 `FKImageCropper` roadmap |
| SwiftUI `PhotosPicker` wrapper as primary | Optional thin bridge; UIKit coordinator is canonical |
| iCloud full video download orchestration beyond picker handoff | Host handles large uploads |
| RAW / ProRAW processing | Out of scope |
| Live Photo playback UI | Export still frame or paired MOV per config |
| macOS / Catalyst camera | iOS 15+ UIKit |
| Background photo monitoring / `PHPhotoLibrary` change observer | Host responsibility |

### 2.3 Success Criteria

- [ ] Single image from library with compression + max dimension enforced.
- [ ] Multi-select (e.g. 9) returns ordered results.
- [ ] Camera capture after `FKPermissions` camera grant.
- [ ] Denied permission returns typed error without crashing; Examples show fallback UI.
- [ ] Temp file URLs cleaned per configuration / documented host duty.
- [ ] README lists Info.plist keys and PHPicker vs UIImagePicker matrix.

---

## 3. Background & Problem Statement

### 3.1 Current FKKit state

| Area | Status |
|------|--------|
| `PHPicker` / `UIImagePicker` under `Sources/` | **None** |
| **`FKPermissions`** | Camera, `.photoLibraryRead`, `.photoLibraryAddOnly` |
| **`FKSheetPresentationController`** | Sheet presentation for chooser UI |
| **`FKImageLoader` / `FKImageView`** | Remote/local display (roadmap §1.1) — consume picker output |
| **`FKFileManager`** | File paths, sharing — pair with exported URLs |

### 3.2 Repeated pain

| Pain | Impact |
|------|--------|
| Forgetting `NSPhotoLibraryUsageDescription` | App Store rejection |
| Using `UIImagePicker` for library on iOS 14+ | Privacy review friction |
| Loading 12 full-res images into memory | Jetsam kills |
| No standard compression before upload | Slow networks, cost |
| `limited` library not handled | Broken multi-select UX |
| Delegate retain cycles | Leaks in VC hierarchies |

---

## 4. Architectural Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ Host UIViewController                                           │
│  FKPhotoPicker.present(from:configuration:)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKPhotoPickerCoordinator (@MainActor)                           │
│  1. FKPermissions preflight                                     │
│  2. Present PHPicker / UIImagePicker / source chooser           │
│  3. Receive NSItemProvider / UIImage / URL                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKPhotoProcessingPipeline (background)                          │
│  decode → orient → resize → compress → write temp file          │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ Completion: [FKPhotoPickerResult] or FKPhotoPickerError         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Module Boundaries

| Concern | FKUIKit PhotoPicker | FKCoreKit |
|---------|---------------------|-----------|
| Present system pickers | **Yes** | No |
| Permission request | Orchestrates | **`FKPermissions`** |
| Image decode/resize | **Yes** (UIKit/CoreGraphics) | No |
| Network upload | No | **`FKNetwork`** (host) |
| Persistent storage | Temp export only | **`FKFileManager`** / Storage |

Dependencies: `FKUIKit` → `FKCoreKit` (Permissions, FKI18n). `import Photos`, `import PhotosUI`, `import UniformTypeIdentifiers`.

---

## 6. Picker Backends & Selection Strategy

### 6.1 Normative backend matrix

| Flow | iOS 15+ backend | Fallback |
|------|-----------------|----------|
| Photo library (read) | **`PHPickerViewController`** | `UIImagePickerController` photo library (document deprecation) |
| Camera capture | **`UIImagePickerController`** (`.camera`) | Error `.cameraUnavailable` if no camera |
| Video library | `PHPickerViewController` with `UTType.movie` | Same |
| Video camera | `UIImagePickerController` `.camera` + `kUTTypeMovie` | Config flag |

**Rationale:** PHPicker does not require full photo library permission for read (Apple privacy model). Still run **`FKPermissions`** when configuration requests preflight for UX consistency or when using legacy fallback.

### 6.2 PHPicker configuration mapping

| `FKPhotoPickerConfiguration` field | `PHPickerConfiguration` |
|-----------------------------------|-------------------------|
| `selectionLimit` | `selectionLimit` (0 = system default unlimited → cap internally) |
| `mediaTypes` | `filter` (`.images`, `.videos`, `.livePhotos`, any combination) |
| `preferredAssetRepresentation` | `.current` / `.compatible` |

### 6.3 UIImagePicker usage

Camera and optional legacy library:

- `sourceType = .camera` / `.photoLibrary`
- `mediaTypes` from config
- `allowsEditing` from `configuration.camera.allowsEditing` (square crop system UI)
- `cameraDevice` front/rear from config
- `videoMaximumDuration` when capturing video

---

## 7. Sources & Presentation Modes

### 7.1 Source enum

```swift
public enum FKPhotoPickerSource: Sendable, Equatable {
  case photoLibrary
  case camera
  case cameraFront
  case cameraBack
  /// Presents action sheet: Library / Camera (FKActionSheet or UIAlertController)
  case libraryOrCamera
  /// Host supplies custom UI; coordinator only runs chosen source
  case custom(FKPhotoPickerSource)
}
```

### 7.2 Source chooser

When `libraryOrCamera`:

- Use **`FKActionSheet`** when available in host style, else `UIAlertController` action sheet
- Titles localized via `FKI18n` keys `fkui.photo_picker.source.*`
- iPad popover anchor from `configuration.presentation.barButtonItem` or `sourceView`

### 7.3 Presentation style

| `FKPhotoPickerPresentation` | Behavior |
|-----------------------------|----------|
| `.automatic` | Full screen camera; sheet/form sheet library per idiom |
| `.fullScreen` | Camera default |
| `.pageSheet` | Library on iPhone |
| `.popover(anchor:)` | iPad |

Integrate with **`FKSheetPresentationController`** when host already uses FK sheet infra (optional helper, not mandatory).

---

## 8. Permission Preflight

### 8.1 Policy

```swift
public struct FKPhotoPickerPermissionPolicy: Sendable, Equatable {
  public var checksPhotoLibrary: Bool      // default false for PHPicker-only library
  public var checksCamera: Bool          // default true for camera flows
  public var photoLibraryPrePrompt: FKPermissionPrePrompt?
  public var cameraPrePrompt: FKPermissionPrePrompt?
  public var opensSettingsOnDenied: Bool // default false; host usually handles
}
```

### 8.2 Flow (normative)

**Library (PHPicker):**

1. If `checksPhotoLibrary == false` → present PHPicker directly (recommended default).
2. If `true` → `await FKPermissions.shared.request(.photoLibraryRead)`; on denied → `.permissionDenied(.photoLibraryRead)` without presenting picker.

**Camera:**

1. `await FKPermissions.shared.request(.camera)` with optional pre-prompt.
2. On denied → `.permissionDenied(.camera)`.
3. On granted → present `UIImagePickerController`.

### 8.3 Limited library

When status is `.limited`:

- PHPicker still works for user-selected subset
- Document presenting `PHPhotoLibrary.shared().presentLimitedLibraryPicker(from:)` helper on **`FKPhotoPicker`**:

```swift
public func presentLimitedLibraryManagement(from viewController: UIViewController)
```

### 8.4 Add-only permission

Not required for pick flows. Document separately when saving back to library (host uses `.photoLibraryAddOnly`).

---

## 9. Selection Limits & Media Types

### 9.1 Selection limit

```swift
public struct FKPhotoPickerSelectionPolicy: Sendable, Equatable {
  /// 1 = single selection; >1 = multi; max enforced (e.g. 20).
  public var limit: Int
  /// When user selects more than limit (legacy picker), trim or error — default error.
  public var overflowBehavior: FKPhotoPickerOverflowBehavior
}

public enum FKPhotoPickerOverflowBehavior: Sendable, Equatable {
  case fail
  case takeFirst(limit: Int)
}
```

**Normative caps:** `limit` clamped to `1...50` internally; default multi cap `9` (chat attachment convention).

### 9.2 Media types

```swift
public struct FKPhotoPickerMediaTypes: OptionSet, Sendable {
  public static let images
  public static let videos
  public static let livePhotos
}
```

| Config | PHPicker filter | Camera |
|--------|-----------------|--------|
| `.images` | `.images` | image only |
| `.videos` | `.videos` | movie |
| `.images, .videos` | any(of: ...) | both mediaTypes |

### 9.3 Live Photos

| `FKLivePhotoExportPolicy` | Output |
|---------------------------|--------|
| `.stillImageOnly` | JPEG/HEIC still |
| `.pairedMovieAndStill` | Still + MOV URL in result |
| `.skip` | Filter live photos from multi-select |

---

## 10. Pick Flow & Lifecycle

### 10.1 State machine

```text
idle → presenting → processing → completed
                 ↘ cancelled / failed
```

- Only one active pick session per `FKPhotoPicker` instance (or per coordinator ID).
- Second `present` while active → `FKPhotoPickerError.alreadyPresenting`.

### 10.2 Entry points

```swift
@MainActor
public final class FKPhotoPicker {
  public func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration = .init()
  ) async throws -> [FKPhotoPickerResult]

  public func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration,
    completion: @escaping @Sendable (Result<[FKPhotoPickerResult], FKPhotoPickerError>) -> Void
  )
}
```

Static convenience:

```swift
extension FKPhotoPicker {
  public static func pickAvatar(from vc: UIViewController) async throws -> FKPhotoPickerResult
  public static func pickImages(from vc: UIViewController, limit: Int) async throws -> [FKPhotoPickerResult]
}
```

### 10.3 Dismissal & cancel

- PHPicker `picker(_:didFinish:)` with empty selection → `.cancelled`
- UIImagePicker cancel → `.cancelled`
- Host dismisses presented VC → cancel in-flight continuation with `.cancelled`

### 10.4 Retention

Coordinator holds weak `presentingViewController`; strong self until completion (document pattern to avoid retain cycle).

---

## 11. Result Model & Delivery

### 11.1 Per-asset result

```swift
public struct FKPhotoPickerResult: Sendable, Equatable {
  public var id: String                    // UUID string
  public var mediaType: FKPhotoPickerMediaType
  public var image: UIImage?               // when delivery includes image
  public var data: Data?                   // compressed payload
  public var fileURL: URL?                 // temp file; JPEG/HEIC/MOV
  public var thumbnail: UIImage?           // optional small preview
  public var pixelSize: CGSize
  public var byteCount: Int?
  public var uniformTypeIdentifier: String?
  public var assetIdentifier: String?      // PHPicker asset ID when available
  public var exifProperties: [String: Any]? // nil when stripped
}
```

**Sendable note:** `UIImage` is not `Sendable` — mark result `@unchecked Sendable` or use `struct` with `@MainActor` delivery only. **Normative:** complete `async` on `@MainActor` with results containing UIKit types; document that upload work should copy `Data`/`URL` off main before network.

### 11.2 Delivery mode

```swift
public enum FKPhotoPickerDelivery: Sendable, Equatable {
  case image                    // UIImage only
  case compressedData           // Data only
  case fileURL                  // temp file
  case imageAndFileURL          // default for uploads
  case imageAndData
}
```

### 11.3 Ordering

Preserve picker selection order in returned array.

### 11.4 Empty selection

Zero items after user Done → `.cancelled` (not empty success), unless `configuration.allowsEmptySelection == true` (default false).

---

## 12. Image Processing Pipeline

### 12.1 Options

```swift
public struct FKPhotoCompressionOptions: Sendable, Equatable {
  public var maxPixelDimension: CGFloat?   // e.g. 2048; nil = no resize
  public var jpegQuality: CGFloat          // 0...1; default 0.85
  public var outputFormat: FKPhotoOutputFormat
  public var stripLocationEXIF: Bool       // default true (privacy)
  public var stripAllEXIF: Bool            // default false
  public var preserveAlpha: Bool
}

public enum FKPhotoOutputFormat: Sendable, Equatable {
  case jpeg
  case heic   // when available
  case png    // preserveAlpha true
  case matchSource
}
```

### 12.2 Pipeline steps (background)

1. Load representation from `NSItemProvider` or `UIImagePickerControllerMediaURL`
2. Decode image (downsample with `CGImageSource` when possible — reuse pattern from roadmap `FKImageLoader`)
3. Apply `imageOrientation` fix
4. Resize if `maxPixelDimension` set (aspect fit)
5. Encode per format/quality
6. Write to `FileManager.default.temporaryDirectory` subdirectory `FKPhotoPicker/` with unique name
7. Hop to main actor with `FKPhotoPickerResult`

### 12.3 Temp file lifecycle

| `FKPhotoPickerTempFilePolicy` | Behavior |
|-------------------------------|----------|
| `.hostResponsible` | URLs valid until host deletes (document) |
| `.deleteOnDeinit` | Coordinator tracks URLs, deletes on deinit |
| `.deleteAfterCompletion(seconds:)` | Optional delayed cleanup |

Default: `.hostResponsible` + README sample `try FileManager.default.removeItem(at:)`.

### 12.4 Progress

Optional `FKPhotoPickerProgressHandler` for multi-asset:

```swift
public typealias FKPhotoPickerProgressHandler = @Sendable (Int, Int) -> Void
```

Invoke on main actor: `(processed, total)`.

---

## 13. Video Handling

### 13.1 v1 scope

- Library: return `fileURL` to copied temp MOV/MP4 (no transcode v1)
- Max duration enforced on camera via `videoMaximumDuration`
- Max file size: optional `maxVideoBytes` — fail with `.fileTooLarge` after copy

### 13.2 Thumbnail

Generate `thumbnail` via `AVAssetImageGenerator` first frame (background).

### 13.3 Delivery

`mediaType == .video` → `fileURL` required; `image` is thumbnail only.

---

## 14. Public API Surface

### 14.1 Protocol

```swift
@MainActor
public protocol FKPhotoPicking: AnyObject {
  func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration
  ) async throws -> [FKPhotoPickerResult]
}
```

### 14.2 Configuration root

```swift
public struct FKPhotoPickerConfiguration: Sendable, Equatable {
  public var source: FKPhotoPickerSource
  public var mediaTypes: FKPhotoPickerMediaTypes
  public var selection: FKPhotoPickerSelectionPolicy
  public var delivery: FKPhotoPickerDelivery
  public var compression: FKPhotoCompressionOptions
  public var permission: FKPhotoPickerPermissionPolicy
  public var presentation: FKPhotoPickerPresentationConfiguration
  public var camera: FKPhotoPickerCameraOptions
  public var video: FKPhotoPickerVideoOptions
  public var livePhoto: FKLivePhotoExportPolicy
  public var tempFilePolicy: FKPhotoPickerTempFilePolicy
  public var allowsEmptySelection: Bool
}
```

### 14.3 Presets

```swift
public enum FKPhotoPickerPresets {
  public static func avatar() -> FKPhotoPickerConfiguration
  public static func chatAttachments(max: Int = 9) -> FKPhotoPickerConfiguration
  public static func documentScan() -> FKPhotoPickerConfiguration  // camera, no resize aggressive
  public static func highQualitySingle() -> FKPhotoPickerConfiguration
}
```

| Preset | Traits |
|--------|--------|
| `avatar` | Single, libraryOrCamera, square edit optional, 1024px, JPEG 0.9 |
| `chatAttachments` | Multi 9, images, compressed file URL |
| `documentScan` | Camera, strip GPS, higher dimension cap |
| `highQualitySingle` | Library, minimal compression |

### 14.4 Global defaults

```swift
public enum FKPhotoPickerDefaults {
  public static var configuration: FKPhotoPickerConfiguration
}
```

---

## 15. Error Taxonomy

```swift
public enum FKPhotoPickerError: Error, Sendable, Equatable {
  case cancelled
  case permissionDenied(FKPermissionKind)
  case permissionError(FKPermissionError)
  case cameraUnavailable
  case sourceUnavailable(FKPhotoPickerSource)
  case alreadyPresenting
  case selectionLimitExceeded(selected: Int, limit: Int)
  case processingFailed(underlyingDescription: String)
  case fileTooLarge(bytes: Int, max: Int)
  case unsupportedMediaType
  case emptySelection
  case underlying(code: Int, domain: String)
}
```

`LocalizedError` via `FKUIKitI18n` / `FKI18n` keys.

| Error | Host UX |
|-------|---------|
| `.cancelled` | Silent |
| `.permissionDenied` | Settings CTA via `FKPermissions.openAppSettings()` |
| `.processingFailed` | Retry + support |

---

## 16. Configuration Model

### 16.1 Camera options

```swift
public struct FKPhotoPickerCameraOptions: Sendable, Equatable {
  public var allowsEditing: Bool
  public var cameraDevice: UIImagePickerController.CameraDevice?  // nil = rear default
  public var flashMode: UIImagePickerController.CameraFlashMode?
  public var showsCameraControls: Bool  // default true
}
```

### 16.2 Presentation configuration

```swift
public struct FKPhotoPickerPresentationConfiguration: Sendable, Equatable {
  public var style: FKPhotoPickerPresentation
  public var barButtonItem: UIBarButtonItem?  // popover anchor
  public var sourceView: CGRect?              // fallback anchor
}
```

---

## 17. Presentation Integration

- Camera: full screen `modalPresentationStyle = .fullScreen`
- PHPicker: `.pageSheet` on iPhone; popover on iPad when anchor provided
- Optional wrapper: `FKPhotoPicker+Sheet.swift` using `FKSheetPresentationController` for post-pick preview (non-goal v1)

---

## 18. Security & Privacy

### 18.1 Info.plist (README required)

| Key | When |
|-----|------|
| `NSPhotoLibraryUsageDescription` | Legacy library / limited management |
| `NSCameraUsageDescription` | Camera |
| `NSMicrophoneUsageDescription` | Video with audio |

### 18.2 EXIF / GPS

Default `stripLocationEXIF = true` before upload-oriented export.

### 18.3 Logging

**Forbidden:** full file paths with user content in release logs; image bytes.

### 18.4 Temp directory

Use `temporaryDirectory` only; never Documents without host opt-in.

---

## 19. Concurrency & Memory

- Presentation and delegate callbacks: `@MainActor`
- Decode/resize/encode: detached task or `FKSecurity`-style background queue
- Multi-select: process sequentially or limited parallelism (default **2** concurrent) to cap memory
- Downsample large assets before building full `UIImage` when `delivery` is `.fileURL` only

---

## 20. Accessibility & Localization

- System pickers inherit Apple accessibility
- Source chooser action sheet: VoiceOver labels from FKI18n
- Error alerts: localized descriptions

---

## 21. SwiftUI Bridge

```swift
public struct FKPhotoPickerButton<Label: View>: View {
  public var configuration: FKPhotoPickerConfiguration
  public var onResults: ([FKPhotoPickerResult]) -> Void
  public var onError: (FKPhotoPickerError) -> Void
}
```

Uses `UIViewControllerRepresentable` to find presenter VC or `@Environment` helper `fkPhotoPickerPresenter`.

**Non-goal:** Duplicate SwiftUI `PhotosPicker` API surface.

---

## 22. Proposed Source Layout

> **Layout guidance (non-normative):** The directory tree below is a **recommended starting point**, not a mandatory template. Adjust folders and file grouping to fit component complexity and neighboring FKKit components, while keeping the layout **discoverable**, **documented** in the component `README.md`, and aligned with FKKit conventions (clear public vs internal boundaries, English `///`, Swift 6 concurrency). See [COMPONENT_ROADMAP.md — Component source layout policy](COMPONENT_ROADMAP.md#component-source-layout-policy).

```text
Sources/FKUIKit/Components/PhotoPicker/
├── README.md
├── Public/
│   ├── FKPhotoPicker.swift
│   ├── FKPhotoPicking.swift
│   ├── FKPhotoPickerConfiguration.swift
│   ├── FKPhotoPickerResult.swift
│   ├── FKPhotoPickerError.swift
│   ├── FKPhotoCompressionOptions.swift
│   ├── FKPhotoPickerPresets.swift
│   └── Bridge/
│       └── FKPhotoPickerButton.swift
├── Internal/
│   ├── FKPhotoPickerCoordinator.swift
│   ├── FKPHPickerDelegateAdapter.swift
│   ├── FKImagePickerDelegateAdapter.swift
│   ├── FKPhotoProcessingPipeline.swift
│   ├── FKPhotoTempFileStore.swift
│   └── FKPhotoEXIFStripper.swift
└── Extension/
    └── FKPhotoPicker+Convenience.swift
```

---

## 23. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/PhotoPicker/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `SingleAvatar` | libraryOrCamera, 1 image, compression |
| 2 | `MultiChatImages` | 9 limit, ordered results |
| 3 | `CameraOnly` | permission + capture |
| 4 | `PermissionDenied` | camera denied UX |
| 5 | `LimitedLibrary` | manage limited picker helper |
| 6 | `FileURLOutput` | upload-ready temp URL |
| 7 | `StripGPS` | EXIF location removed |
| 8 | `VideoPick` | movie fileURL + thumbnail |
| 9 | `CancelFlow` | cancelled error |
| 10 | `SwiftUIPickerButton` | bridge |
| 11 | `iPadPopover` | popover anchor |
| 12 | `LargeImageDownscale` | 40MP → max dimension |

---

## 25. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | PHPicker library without any permission check? | Yes default |
| Q2 | `UIImage` in `Sendable` result? | `@MainActor` completion only |
| Q3 | Parallel processing count? | 2 |
| Q4 | HEIC output default? | JPEG for compatibility |
| Q5 | Use FKActionSheet for source chooser? | Yes when linked |

---

## 26. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §2.6 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKPermissions README](../Sources/FKCoreKit/Components/Permissions/README.md)
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md)
- [FKSheetPresentationController README](../Sources/FKUIKit/Components/SheetPresentationController/README.md)
