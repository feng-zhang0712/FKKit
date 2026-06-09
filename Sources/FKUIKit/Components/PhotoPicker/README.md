# FKPhotoPicker

Production-oriented wrapper around `PHPickerViewController` and `UIImagePickerController` with `FKPermissions` preflight, selection limits, background processing (resize, compression, EXIF stripping), and typed results.

## Requirements

- Swift 6, iOS 15+
- `import FKUIKit`

## Source layout

| Path | Role |
|------|------|
| `Public/FKPhotoPicker.swift` | Main `@MainActor` coordinator and `FKPhotoPicking` protocol |
| `Public/FKPhotoPickerConfiguration.swift` | Sendable configuration, source, selection, delivery, permission models |
| `Public/FKPhotoCompressionOptions.swift` | Resize, encoding, and EXIF options |
| `Public/FKPhotoPickerResult.swift` | Per-asset output (`UIImage`, `Data`, temp `URL`, metadata) |
| `Public/FKPhotoPickerError.swift` | Typed failures with `LocalizedError` |
| `Public/FKPhotoPickerPresets.swift` | Factory presets (`avatar`, `chatAttachments`, …) and global defaults |
| `Public/Bridge/FKPhotoPickerButton.swift` | Optional SwiftUI trigger button |
| `Extension/FKPhotoPicker+Convenience.swift` | Static helpers (`pickAvatar`, `pickImages`) |
| `Internal/FKPhotoPickerCoordinator.swift` | Session lifecycle, permissions, presentation |
| `Internal/FKPHPickerDelegateAdapter.swift` | PHPicker and UIImagePicker delegate adapters |
| `Internal/FKPhotoProcessingPipeline.swift` | Background decode, resize, encode, video copy |
| `Internal/FKPhotoTempFileStore.swift` | Temporary export directory and cleanup policy |
| `Internal/FKPhotoEXIFStripper.swift` | GPS / EXIF stripping before export |

## Quick start

```swift
import FKUIKit

let picker = FKPhotoPicker()
let results = try await picker.pick(
  from: self,
  configuration: .avatar()
)
let avatar = results.first
```

Static convenience:

```swift
let avatar = try await FKPhotoPicker.pickAvatar(from: self)
let images = try await FKPhotoPicker.pickImages(from: self, limit: 9)
```

## Picker backend matrix

| Flow | iOS 15+ backend | Notes |
|------|-----------------|-------|
| Photo library | `PHPickerViewController` | No full-library permission required by default |
| Camera | `UIImagePickerController` (`.camera`) | Requires camera permission |
| Library video | PHPicker + `UTType.movie` | Copied to temp file (no transcode v1) |
| Camera video | UIImagePicker + movie | `videoMaximumDuration` from configuration |

Set `permission.checksPhotoLibrary = true` only when using legacy library flows that require read access.

## Info.plist keys

| Key | When required |
|-----|---------------|
| `NSCameraUsageDescription` | Camera capture |
| `NSPhotoLibraryUsageDescription` | Legacy library read / limited-library management |
| `NSMicrophoneUsageDescription` | Video capture with audio |

## Temporary files

Exported `fileURL` values are written under `temporaryDirectory/FKPhotoPicker/`.

| Policy | Behavior |
|--------|----------|
| `.hostResponsible` (default) | Host deletes when upload completes |
| `.deleteOnDeinit` | Coordinator deletes on deinitialization |
| `.deleteAfterCompletion(seconds:)` | Delayed cleanup after pick completes |

Example cleanup:

```swift
if let url = result.fileURL {
  try? FileManager.default.removeItem(at: url)
}
```

## Limited photo library

When photo library access is `.limited`, PHPicker still works. Call:

```swift
picker.presentLimitedLibraryManagement(from: self)
```

## Retention

The coordinator holds a strong reference to itself until the pick session completes to avoid delegate deallocation. `presentingViewController` is held weakly.

## Privacy

- Default `compression.stripLocationEXIF = true` removes GPS before export-oriented delivery.
- Do not log full temp paths or image bytes in release builds.

## Presets

| Preset | Traits |
|--------|--------|
| `avatar()` | Single, library or camera chooser, 1024 px, JPEG 0.9 |
| `chatAttachments(max:)` | Multi-select images, compressed file URLs |
| `documentScan()` | Camera, GPS stripped, higher dimension cap |
| `highQualitySingle()` | Library, minimal compression |

## SwiftUI

```swift
FKPhotoPickerButton(configuration: .avatar()) { result in
  // handle Result<[FKPhotoPickerResult], FKPhotoPickerError>
} label: {
  Text("Choose Photo")
}
```

## Examples

Entry: **FKKitExamples → FKUIKit → PhotoPicker**

| Hub section | Scenarios |
|-------------|-----------|
| Getting started | Basics, Presets & convenience |
| Sources & camera | Source chooser, Camera capture, Multi-select & progress |
| Output & processing | Delivery modes, Compression & privacy, Video, Live Photo |
| Permissions & lifecycle | Permission flows, Presentation, Lifecycle & temp files |
| Integration | SwiftUI bridge |

## Related

- [FKPermissions](../../FKCoreKit/Components/Permissions/README.md) — camera and photo library permission APIs
- [FKActionSheet](../ActionSheet/README.md) — source chooser for `.libraryOrCamera`
