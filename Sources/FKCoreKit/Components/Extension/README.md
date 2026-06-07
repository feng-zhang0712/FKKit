# FKCoreKit Extension

Cross-cutting Swift extensions and small toolbox types for everyday iOS development. All public members use the **`fk_`** prefix.

## Directory layout

| Folder | Responsibility |
|--------|----------------|
| `Foundation/` | Extensions on `String`, `Date`, `Array`, `Dictionary`, `FileManager`, `DispatchQueue`, numbers, JSON helpers, etc. |
| `CoreGraphics/` | Extensions on `CGFloat`, `CGPoint`, `CGSize`, `CGRect`. |
| `UIKit/` | Extensions on UIKit types (`UIView`, `UIColor`, `UIImage`, `UIApplication`, …). Files use `#if canImport(UIKit)`. |
| `Internal/` | Shared implementation (MainActor bridge, cached date formatting, regex engine). Not application-facing entry points. |
| `Toolbox/` | Helpers without a natural receiver (`FKDeviceInfo`, `FKValueParsing`). |

## Usage

```swift
import FKCoreKit

// Receiver-oriented helpers
let emailOK = "dev@example.com".fk_isValidEmail
let label = now.fk_formatted("yyyy-MM-dd")
let chunk = values.fk_chunked(into: 3)
let cacheKey = requestKey.fk_md5
let color = UIColor(fk_hexString: "#3366FF")

// Safe collection access
let item = items[fk_safe: index]

// Toolbox types
let model = FKDeviceInfo.modelIdentifier()
let docs = FileManager.fk_documentsDirectory

DispatchQueue.fk_runOnMain { /* UI update */ }

// Validation feedback
invalidField.fk_shake(amplitude: 8, shakes: 3)
```

## Provider customization

Date formatting and regex matching support injectable providers for tests or app-specific rules:

```swift
FKDateFormatting.register(provider: FKDateFormattingProvider())
FKRegexMatching.register(provider: FKRegexMatchingProvider())
```

## Requirements

- iOS 15+
- Swift 6 (strict concurrency compatible)

## Examples

See `Examples/FKKitExamples/.../FKCoreKit/Extension/FKExtensionExampleViewController.swift` for interactive coverage of major APIs.
