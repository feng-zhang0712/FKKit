# FKQRCode (UIKit)

Camera-based QR **scanning UI** for FKUIKit. Generation and parsing live in **FKCoreKit** (`Components/QRCode/`).

## Directory layout

| Path | Responsibility |
|------|----------------|
| `Public/FKQRCodeScannerViewController.swift` | Full-screen scanner VC + async `scan(from:)` |
| `Public/FKQRCodeScannerConfiguration.swift` | Scan mode, cooldown, torch, overlay, permissions |
| `Public/FKQRCodeScannerDelegate.swift` | Scan / cancel / error callbacks |
| `Public/FKQRCodeScannerError.swift` | Scanner failures |
| `Public/FKQRCodeScanMode.swift` | Once vs continuous scanning |
| `Public/FKQRCodeNavigationPolicy.swift` | Post-scan URL handling |
| `Public/FKQRCodeOverlayStyle.swift` | Scan frame styling |
| `Public/Bridge/FKQRCodeScannerRepresentable.swift` | SwiftUI scanner bridge |
| `Public/Bridge/FKQRCodeImageView.swift` | SwiftUI generated QR image |
| `Internal/FKQRCodeCaptureSessionController.swift` | `AVCaptureSession` on serial queue |
| `Internal/FKQRCodeOverlayView.swift` | Dim mask, corners, scan line |
| `Internal/FKQRCodeMockScanner.swift` | Simulator / no-camera placeholder |

## Requirements

- Swift 6, iOS 15+
- `AVFoundation`, `UIKit`, `SafariServices` (in-app HTTP policy)
- Camera permission via **`FKPermissions.shared.request(.camera)`** (never call `AVCaptureDevice.requestAccess` directly)
- Host **`NSCameraUsageDescription`** in Info.plist

## Usage

```swift
import FKUIKit

let scanner = FKQRCodeScannerViewController(configuration: .default)
scanner.delegate = self
present(scanner, animated: true)
```

### Async

```swift
let payload = try await FKQRCodeScannerViewController.scan(from: self)
```

### SwiftUI

```swift
FKQRCodeScannerRepresentable { payload in
  print(payload.rawValue)
}

FKQRCodeImageView(content: "https://example.com")
```

## Configuration highlights

| Property | Default | Notes |
|----------|---------|-------|
| `scanMode` | `.once` | Pauses capture after first success |
| `cooldownInterval` | `2.0` | Suppresses duplicate payloads |
| `allowsMultipleCallbacks` | `false` | Same raw value debounced |
| `navigationPolicy` | `.callbackOnly` | Safest; no automatic URL open |
| `hapticsOnSuccess` | `true` | Medium impact feedback |
| `simulatorMockRawValue` | example URL | Mock scan on simulator |

## Security

- **Do not** log full payment or authentication payloads.
- Prefer `.callbackOnly` and validate URLs in the host before opening links.
- `.openExternally` calls `UIApplication.shared.open` — document user-facing risk in the host app.
- Custom URL schemes should be routed by the host (e.g. deep-link router), not opened blindly.

## Threading

- `AVCaptureSession` start/stop runs on a dedicated serial queue.
- Metadata is delivered off the main queue and marshalled to `@MainActor` before delegate callbacks.
- QR bitmap generation for SwiftUI runs in a detached task; UI updates on the main actor.

## Accessibility

- Close and torch controls expose localized accessibility labels.
- Scan success can post a VoiceOver announcement (`announcesScanSuccess`).
- Scan line animation respects Reduce Motion.

## Simulator

When no camera device is available, an internal mock view offers a **Simulate Scan** action using `simulatorMockRawValue`.
