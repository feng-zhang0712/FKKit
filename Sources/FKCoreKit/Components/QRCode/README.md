# FKQRCode (Core)

QR code **generation** and **parsing** for FKCoreKit using `CoreImage` (`CIQRCodeGenerator`). No UIKit views; no camera APIs.

## Directory layout

| Path | Responsibility |
|------|----------------|
| `FKQRCodeGenerator.swift` | String → `UIImage` / `CIImage` |
| `FKQRCodeParser.swift` | Raw string → ``FKQRCodePayload`` |
| `FKQRCodeGenerationOptions.swift` | Size, colors, correction, optional logo |
| `FKQRCodePayload.swift` | Typed URL / text / unknown payloads |
| `FKQRCodeError.swift` | Generation failures |
| `FKQRCodeCorrectionLevel.swift` | L/M/Q/H correction levels |
| `FKQRCodeLogoEmbedding.swift` | Center logo options (bitmap output only) |

Scanning UI lives in **FKUIKit** (`Components/QRCode/`).

## Requirements

- Swift 6, iOS 15+
- `CoreImage`, `UIKit` (bitmap output)
- No third-party dependencies

## Usage

```swift
import FKCoreKit

let image = try FKQRCodeGenerator.makeImage(from: "https://example.com/pay?id=1")
let payload = FKQRCodeParser.parse("https://example.com")
```

### Options

```swift
var options = FKQRCodeGenerationOptions.default
options.size = CGSize(width: 256, height: 256)
options.correctionLevel = .H
options.foregroundColor = .black
options.backgroundColor = .white
options.logo = FKQRCodeLogoEmbedding(image: logoImage)
```

Logo embedding automatically uses correction level **H** and clamps logo area to **22%** of the QR side.

## Errors

| Case | Cause |
|------|--------|
| `emptyContent` | Blank string after trim |
| `contentTooLong` | UTF-8 payload exceeds 2953 bytes |
| `filterFailed` | `CIQRCodeGenerator` failure |
| `imageConversionFailed` | Bitmap conversion failure |

## Security

- Do not log full payment or auth payloads in production.
- URL handling after scan is the host’s responsibility (see FKUIKit scanner `navigationPolicy`).

## Threading

Generation is synchronous and thread-safe for independent calls. Prefer running heavy batch generation off the main actor and assigning `UIImage` on `@MainActor`.
