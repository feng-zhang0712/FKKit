# FKMarqueeLabel

Single-line horizontal ticker that scrolls when text exceeds the available width. Supports drag-to-pause, Reduce Motion fallback, optional edge fading, and lifecycle-aware scrolling.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## When to use

| Need | Use |
|------|-----|
| Announcement bar, stock ticker, promo banner | `FKMarqueeLabel` |
| Multi-line expand/collapse | `FKExpandableText` |
| Rich HTML content | Not v1 — plain `String` only |

## Source layout

| Path | Role |
|------|------|
| `Public/FKMarqueeLabel.swift` | Main ticker view |
| `Public/FKMarqueeLabelConfiguration.swift` | Layered configuration |
| `Public/Bridge/FKMarqueeLabelRepresentable.swift` | SwiftUI wrapper |
| `Internal/FKMarqueeScrollDriver.swift` | CADisplayLink scroll driver |
| `Internal/FKMarqueeFadeMaskLayer.swift` | Leading/trailing gradient mask |
| `Internal/FKMarqueeTextMeasurement.swift` | Text width + single-line fit helpers |

## Quick start

```swift
import FKUIKit

var config = FKMarqueeLabelConfiguration()
config.animation.speed = 36
config.animation.fadeWidth = 20
config.layout.alignment = .leading

let marquee = FKMarqueeLabel(configuration: config, text: "Limited-time offer — free shipping on orders over $50")
marquee.translatesAutoresizingMaskIntoConstraints = false
// Pin width; height is intrinsic from Dynamic Type font.
```

## Behavior

- Scrolls **only** when measured text width exceeds `bounds.width`.
- Short text respects `FKMarqueeLabelAlignment` (`.leading` / `.center`).
- Seamless loop via duplicated labels and configurable `loopGap`.
- **Reduce Motion:** static single line with tail truncation; full `text` in `accessibilityLabel`.
- **Drag to pause:** hold to stop scrolling; release to resume (when `interaction.pausesOnPan`).
- **Lifecycle:** pauses when off-window, hidden, nearly transparent, in background, zero-width, or programmatically via `isPaused`.
- **RTL:** `animation.mirrorsDirectionInRTL` flips scroll direction (default `true`).

## Performance

- Reuses two labels; no per-frame attributed-string allocation.
- Display link stops when not visible or not scrolling.
- For very long copy (>500 characters), consider truncating at the host before assigning `text`.

## Defaults

- `FKMarqueeLabelDefaults.configuration`

## Examples

FKKitExamples → **FKUIKit → Marquee** (grouped hub):

| Section | Scenarios |
|---------|-----------|
| Display & scrolling | Long announcement, Short text alignment, Fade edges, Announcement bar |
| Interaction & control | Drag to pause, Programmatic pause, Animation playground |
| Environment & accessibility | Reduce Motion, RTL & appearance, Background pause, Accessibility, SwiftUI bridge |

## License

See the repository root `LICENSE`.
