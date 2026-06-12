# FKCopyChip

Capsule control for displaying truncated IDs, order numbers, or tokens with one-tap copy to the pasteboard.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## When to use

| Need | Use |
|------|-----|
| Copy order/tracking ID with optional toast | `FKCopyChip` |
| Toggle/filter chips | `FKChip` |
| Read-only promo/category label | `FKTag` |

## Source layout

| Path | Role |
|------|------|
| `Public/FKCopyChip.swift` | Interactive `UIControl` — display + copy |
| `Public/FKCopyChipConfiguration.swift` | Layered configuration, truncation, feedback modes |
| `Public/FKCopyChipNotifications.swift` | `Notification.Name.fk_copyChipDidCopy` |
| `Public/Bridge/FKCopyChipRepresentable.swift` | SwiftUI wrapper |
| `Internal/FKCopyChipPasteboardWriter.swift` | Pasteboard write + optional expiration |
| `Internal/FKCopyChipI18n.swift` | Localized strings |
| `Internal/FKCopyChipLayoutEngine.swift` | Display formatting and capsule layout metrics |

Shared utilities: `String.fk_middleTruncated` (FKCoreKit), `FKToast`, `FKWidgetIcon` template tinting.

## Quick start

```swift
import FKUIKit

var config = FKCopyChipConfiguration()
config.layout.prefix = "Order #"
config.layout.truncation = .middle(prefixLength: 5, suffixLength: 3)
config.feedback.mode = .toast

let chip = FKCopyChip(configuration: config, text: "A128839F2", copyText: "A128839F2")
chip.onCopy = { copied in print(copied) }
```

## Display vs copy

- `text` — shown in the chip (truncation/prefix applied).
- `copyText` — written to `UIPasteboard.general` when set; otherwise `text` is copied.

## Feedback

| `FKCopyChipFeedback` | Behavior |
|----------------------|----------|
| `.none` | Silent copy (no toast, haptic, flash, or spoken announcement) |
| `.hapticOnly` | Light impact |
| `.toast` | `FKToast` success (optional haptic via `playsHapticWithToast`) |

## Privacy

iOS 16+ may show the system pasteboard access indicator when your app reads the pasteboard elsewhere. This control only **writes** on user action.

## Defaults

- `FKCopyChipDefaults.configuration`

## Examples

Open **FKKitExamples → FKUIKit → CopyChip** for grouped scenarios:

- **Display & copy** — order ID (prefix + middle truncation + copyText), monospaced tracking
- **Feedback** — toast, haptic only, silent copy
- **Integration** — playground, callbacks/notifications, SwiftUI, RTL & appearance

## License

See the repository root `LICENSE`.
