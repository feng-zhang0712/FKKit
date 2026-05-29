# FKRatingControl

Configurable UIKit rating control for read-only display and interactive scoring. Supports SF Symbol presets (star, heart, thumb), custom symbols/images, half-step snapping, optional caption, drag selection, accessibility, and a SwiftUI wrapper.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

| Path | Role |
|------|------|
| `Public/FKRatingControl.swift` | Main `UIControl` subclass |
| `Public/FKRatingControlDelegate.swift` | Optional delegate callbacks |
| `Public/Configuration/` | `FKRatingConfiguration` and nested layout/appearance/interaction/motion/label/accessibility structs |
| `Public/Models/FKRatingEnums.swift` | Interaction mode, step, icon preset/style, haptics, label placement |
| `Public/Bridge/FKRatingControlRepresentable.swift` | SwiftUI `UIViewRepresentable` |
| `Extension/FKRatingControl+Convenience.swift` | Factory helpers for common star ratings |
| `Internal/` | Item views, layout engine, icon resolver, label formatting |

## Quick start

```swift
import FKUIKit

let rating = FKRatingControl.interactiveStars(value: 3, step: .half)
rating.onValueChanged = { print("Rating:", $0) }
view.addSubview(rating)

// Read-only product detail
let display = FKRatingControl.readOnlyStars(value: 4.5, itemCount: 5)
display.configuration.interaction.step = .half
```

## Configuration

`rating.configuration` groups:

| Member | Type | Role |
|--------|------|------|
| `layout` | `FKRatingLayoutConfiguration` | Item count, size, spacing, insets, caption placement |
| `appearance` | `FKRatingAppearanceConfiguration` | Icon style, colors, symbol configuration, caption typography |
| `interaction` | `FKRatingInteractionConfiguration` | Read-only vs interactive, step, drag, hit target, haptics |
| `motion` | `FKRatingMotionConfiguration` | Fill animation, selection bounce, Reduce Motion |
| `label` | `FKRatingLabelConfiguration` | Optional numeric/custom caption |
| `accessibility` | `FKRatingAccessibilityConfiguration` | VoiceOver label, hint, value format |

Defaults: `FKRating.defaultConfiguration` or `FKRatingControl.defaultConfiguration`.

## Icon styles

- `.preset(.star | .heart | .thumbUp)` — SF Symbols (no bundled assets)
- `.symbols(empty:filled:half:)` — custom SF Symbol names
- `.images(empty:filled:half:)` — host-provided `UIImage`

Partial fills use a mask over the filled glyph (works for any icon).

## Examples

Runnable demos: `Examples/FKKitExamples/.../FKUIKit/RatingControl/`

| Hub row | Demonstrates |
|---------|----------------|
| Interactive stars | Tap, drag, whole/half steps |
| Read-only display | Product summary and review rows |
| Convenience factories | `readOnlyStars` / `interactiveStars` |
| Icon presets | Star, heart, thumb |
| Custom symbols & images | `.symbols` and `.images` |
| Value caption | Trailing, bottom, prefix/suffix, custom text |
| Playground | Major configuration groups |
| Modes & feedback | Disabled, tap-only, haptics |
| Center sheet + rating | `FKSheetPresentationController` `.center` + quick rate / feedback / App Store prompt |
| Delegate event log | `FKRatingControlDelegate` + closure |
| SwiftUI bridge | `FKRatingControlRepresentable` |
| RTL & VoiceOver copy | Semantic layout and accessibility strings |

Entry: **FKKit Examples → FKUIKit → RatingControl**.

## License

MIT — see repository root `LICENSE`.
