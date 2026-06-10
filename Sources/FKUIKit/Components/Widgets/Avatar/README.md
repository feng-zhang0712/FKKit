# FKAvatar / FKAvatarGroup / FKPresenceIndicator

Configuration-driven avatar widgets for profile headers, navigation bars, collaborator rows, and IM lists. Three public types: single avatar (`FKAvatar`), overlapping group (`FKAvatarGroup`), and presence dot (`FKPresenceIndicator`).

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit` (depends on `FKCoreKit` for image loading and string utilities)

## Related components

| Need | Use |
|------|-----|
| Unread / count badge on avatar | `FKBadgeController.attach(to:)` |
| Order / workflow status dot | `FKStatusPill` (not presence) |
| Remote image pipeline | `FKImageView` + `FKImageLoader` (embedded in `FKAvatar`) |
| Overflow "+N" chip styling | Neutral pill (`FKTag` equivalent via `FKAvatarGroupOverflowView`) |

## Source layout

| Path | Role |
|------|------|
| `Public/FKAvatar.swift` | Single-user `UIControl` with initials, URL loading, presence slot |
| `Public/FKAvatarConfiguration.swift` | Layered layout / appearance / interaction / accessibility / presence config |
| `Public/FKAvatarSize.swift` | XS–XL diameter presets |
| `Public/FKAvatarShape.swift` | Circle, squircle, rounded rectangle |
| `Public/FKAvatarGroup.swift` | Overlapping stack of `FKAvatar` children + "+N" overflow |
| `Public/FKAvatarContent.swift` | Sendable group row model |
| `Public/FKAvatarGroupConfiguration.swift` | Group layout parameters |
| `Public/FKPresenceIndicator.swift` | Standalone or embedded presence dot |
| `Public/FKPresenceState.swift` | Online / offline / busy / away / custom |
| `Public/FKPresenceIndicatorConfiguration.swift` | Size, border, pulse, colors |
| `Public/Bridge/` | SwiftUI `FKAvatarRepresentable`, `FKAvatarGroupRepresentable`, `FKPresenceIndicatorView` |
| `Internal/FKAvatar+LazySubviews.swift` | Lazy attach/detach for ``FKImageView`` and optional presentation subviews |
| `Internal/` | Initials generator, content renderer, story ring, pulse layer, group layout engine, overflow chip |
| `../Core/Internal/FKWidgetLayoutMetrics.swift` | Shared attachment offsets (presence on avatar) |

## Quick start

```swift
import FKUIKit

// Profile avatar with presence
var config = FKAvatarConfiguration()
config.layout.size = .l
config.showsPresenceIndicator = true
config.presenceState = .online

let avatar = FKAvatar(configuration: config)
avatar.displayName = "Alex Morgan"
avatar.setImageURL(URL(string: "https://example.com/avatar.jpg"), placeholder: nil)
view.addSubview(avatar)

// Collaborator stack
let group = FKAvatarGroup(
  avatars: [
    FKAvatarContent(id: "1", displayName: "Alex"),
    FKAvatarContent(id: "2", displayName: "Sam"),
    FKAvatarContent(id: "3", displayName: "Jordan"),
    FKAvatarContent(id: "4", displayName: "Casey"),
    FKAvatarContent(id: "5", displayName: "Riley"),
  ]
)
group.onOverflowTap = { print("Show all members") }

// Standalone presence dot
let presence = FKPresenceIndicator(state: .busy)
```

## Cell reuse

Call `avatar.resetForReuse()` from `prepareForReuse()` to cancel in-flight URL loads and clear transient content.

## Defaults

- `FKAvatarDefaults.configuration`
- `FKAvatarGroupDefaults.configuration`
- `FKPresenceIndicatorDefaults.configuration`

## Examples

Runnable demos: `Examples/FKKitExamples/.../FKUIKit/Widgets/Avatar/`

| Hub section | Demonstrates |
|-------------|----------------|
| FKAvatar · Content | XS–XL sizes, shapes, initials (Latin/CJK), local image, remote URL, failure retry |
| FKAvatar · Chrome & layout | Profile header (story ring, border, verified), navigation bar 44 pt hit area, playground |
| FKAvatar · Integration | Presence + FKBadge, runtime `presenceState`, list `resetForReuse()` |
| FKAvatarGroup | Overlap stack, +N overflow, taps, separator border, layout direction |
| FKPresenceIndicator | Online/offline/busy/away/custom, S/M/L, pulse, embedded vs standalone |
| Layout & SwiftUI | RTL, light/dark, `FKAvatarRepresentable`, `FKAvatarGroupRepresentable`, `FKPresenceIndicatorView` |

Entry: **FKKit Examples → FKUIKit → Avatar**.

## License

See the repository root `LICENSE`.
