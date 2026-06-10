# FKStatusPill

Read-only workflow status capsule for orders, tickets, and logistics rows. Uses workflow-specific colors (distinct from ``FKTag`` marketing variants) with an optional leading status dot.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## When to use

| Need | Use |
|------|-----|
| Order/ticket/shipment status word | `FKStatusPill` |
| Category, promo, role metadata | `FKTag` |
| User online/offline presence | `FKPresenceIndicator` |
| Filter / selectable token | `FKChip` |

## StatusPill vs Tag

| Dimension | FKStatusPill | FKTag |
|-----------|--------------|-------|
| Semantics | Workflow / order state | Category / promo / role |
| Color source | `FKWidgetStatusColorTokens` | `FKTagRenderer` (brand/marketing) |
| Leading dot | Common (`showsDot`) | Uncommon (icons) |
| Typical placement | List trailing status | Card metadata |

A single row may show both — for example, Tag “VIP” + StatusPill “In transit”.

## Source layout

| Path | Role |
|------|------|
| `Public/FKStatusPill.swift` | Main status capsule view |
| `Public/FKStatusPillStyle.swift` | Style enum, sizes, configuration |
| `Public/Bridge/FKStatusPillView.swift` | SwiftUI wrapper |
| `Internal/FKStatusPillRenderer.swift` | Colors, fonts, pulse eligibility |
| `Internal/FKStatusPillI18n.swift` | Localized accessibility strings |
| `../Core/Public/FKWidgetStatusColorTokens.swift` | Shared workflow color tokens |

## Quick start

```swift
import FKUIKit

let pill = FKStatusPill(
  title: "Shipped",
  style: .success,
  showsDot: true
)
pill.translatesAutoresizingMaskIntoConstraints = false
```

## Styles

| `FKStatusPillStyle` | Typical copy |
|---------------------|--------------|
| `.success` | Completed, shipped |
| `.warning` | Pending review, at risk |
| `.error` | Failed, rejected |
| `.info` | Processing, in progress |
| `.neutral` | Draft, unknown |
| `.custom(...)` | Backend-mapped enums |

## Defaults

- `FKStatusPillDefaults.configuration`
- Default size: `.s` (28 pt)
- Dot: 8 pt diameter, 6 pt spacing when `showsDot == true`
- Optional info-style dot pulse: `appearance.pulsesDotForInfoStyle` (default `false`)

## Examples

FKKitExamples → **FKUIKit → StatusPill** (grouped hub):

| Section | Scenarios |
|---------|-----------|
| Workflow styles | Order status pills, With leading dot, Custom backend enum, Info pulse dot |
| Layout & integration | Size tiers, Configuration playground, List row with Tag |
| Accessibility & SwiftUI | Accessibility, SwiftUI bridge, Light & dark |

## License

See the repository root `LICENSE`.
