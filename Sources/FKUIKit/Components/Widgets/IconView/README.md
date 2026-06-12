# FKIconView

Fixed-size SF Symbol and template image container (24 / 28 / 32 pt) with optional circular or rounded background fill. Supports ``FKBadge`` via ``UIView/fk_badge``.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## When to use

| Need | Use |
|------|-----|
| List leading icon, settings row glyph | `FKIconView` |
| User avatar | `FKAvatar` |
| Remote / arbitrary bitmap | `FKImageView` |
| Chip leading icon payload | `FKWidgetIcon` → ``FKIconView/applyWidgetIcon(_:)`` |

## Source layout

| Path | Role |
|------|------|
| `Public/FKIconView.swift` | Fixed-size icon container |
| `Public/FKIconViewConfiguration.swift` | Size tiers, background style, symbol config |
| `Public/Bridge/FKIconViewRepresentable.swift` | SwiftUI wrapper |
| `Internal/FKIconViewRenderer.swift` | Glyph resolution + `FKWidgetIcon` helper |
| `../Core/Public/FKWidgetIcon.swift` | Shared icon DTO (`FKIconViewIcon` typealias) |
| `../Core/Internal/FKWidgetLayoutMetrics.swift` | Default badge offset helper |

## Quick start

```swift
import FKUIKit

var config = FKIconViewConfiguration()
config.layout.size = .m
config.appearance.backgroundStyle = .circle(fill: .systemBlue.withAlphaComponent(0.15))
config.appearance.defaultTintColor = .systemBlue

let icon = FKIconView(configuration: config, symbolName: "shippingbox")
icon.applyDefaultBadgeAnchor()
icon.fk_badge.showCount(3)
```

## Content priority

1. `image` when set (aspect-fit; optional template tint via `treatsCustomImageAsTemplate`)
2. `symbolName` (SF Symbol, template + `iconTintColor`)
3. Empty — hidden or placeholder per `emptyContentBehavior`

Init parameter `tintColor:` maps to ``iconTintColor`` (avoids clashing with ``UIView/tintColor``).

## Badge

Use `fk_badge` on the icon view. Call ``applyDefaultBadgeAnchor()`` for top-trailing placement aligned with FKBadge anchor conventions (RTL-safe).

## Accessibility

Decorative icons default to `accessibilityElementsHidden = true`. Set `accessibility.isDecorative = false` and provide `customLabel` for semantic icons.

## Defaults

- `FKIconViewDefaults.configuration`

## Examples

FKKitExamples → **FKUIKit → IconView** (grouped hub):

| Section | Scenarios |
|---------|-----------|
| Display & sizing | Three sizes, Background styles, Content sources, Empty & placeholder |
| Integration | With badge, Settings list row, In chip leading, WidgetIcon apply |
| Configuration & environment | Playground, Accessibility, SwiftUI bridge, RTL & appearance |

## License

See the repository root `LICENSE`.
