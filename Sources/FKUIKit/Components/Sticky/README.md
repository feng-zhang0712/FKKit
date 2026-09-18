# FKSticky

Opt-in **sticky / affix behavior** for UIKit scroll containers. Pins arbitrary strip, bar, or header views to a viewport edge while content scrolls underneath — including multi-target push-off. This module is a **behavior engine**, not a visual chrome control; hosts supply their own content (`FKTabBar`, filter strips, custom bars, …).

## Requirements

- iOS 15+
- Swift 6
- `import FKUIKit` (depends on FKCoreKit)

## Source layout

Paths live under `Sources/FKUIKit/Components/Sticky/`.

### `Public/`

| Folder / file | Role |
|---------------|------|
| `Core/FKStickyEngine.swift` | Orchestrates targets, KVO / manual scroll, overlay hosting |
| `Models/FKStickyEdge.swift` | `.top` / `.bottom` pin edge |
| `Models/FKStickyCollisionBehavior.swift` | `.pushOff` / `.stack` multi-target interaction |
| `Models/FKStickyState.swift` | `idle` / `sticking` / `stuck` / `unsticking` |
| `Models/FKStickyProgress.swift` | Normalized progress snapshot |
| `Models/FKStickyTarget.swift` | One stickable view + callbacks |
| `Configuration/FKStickyConfiguration.swift` | Sendable engine policy |

### `Internal/`

| File | Role |
|------|------|
| `FKStickyOverlayHost.swift` | Sibling host pinned to the scroll view’s frame (preferred), or `frameLayoutGuide` fallback; pass-through hit testing |
| `FKStickyPlaceholderView.swift` | Layout spacer while a target is reparented |
| `FKStickyTargetSession.swift` | Per-target runtime bookkeeping |
| `FKStickyGeometry.swift` | Threshold / pin-line math |
| `FKStickyAssociationKeys.swift` | Associated-object key for `UIScrollView` |

### `Extension/`

| File | Role |
|------|------|
| `UIScrollView+FKSticky.swift` | `fk_stickyEngine`, add / reload / reset / handleScroll helpers |

## API overview

| Type / API | Purpose |
|------------|---------|
| `FKStickyEngine` | Add targets, configure edge/inset, force-stick, reload/reset |
| `FKStickyTarget` | View registration + lifecycle / progress callbacks |
| `FKStickyConfiguration` | Edge, inset, observation, placeholder, collision, hysteresis, optional shadow |
| `FKStickyCollisionBehavior` | `.pushOff` (default) or `.stack` for simultaneous pins |
| `stuckTargetIDs` / `onStuckTargetsChange` | Query / observe the active stuck set |
| `progress(for:)` / `state(for:)` / `target(id:)` | Per-target snapshots |
| `scrollView.fk_stickyEngine` | Lazy per-scroll-view engine |
| `fk_addStickyTarget(...)` | One-line registration |
| `fk_reloadStickyLayout()` | Recapture origins/sizes (including stuck targets) |
| `fk_handleStickyScroll()` | Manual drive when `observesAutomatically == false` |

### Threading

`FKStickyEngine`, `FKStickyTarget`, and `UIScrollView` helpers are **`@MainActor`**. `FKStickyConfiguration`, `FKStickyEdge`, `FKStickyState`, and `FKStickyProgress` are `Sendable` value types.

### Design

Normative design: [`docs/FKSticky_DESIGN.md`](../../../../docs/FKSticky_DESIGN.md).

## Quick start

```swift
import UIKit
import FKUIKit

// `filterStrip` is laid out inside the scroll content.
let engine = scrollView.fk_stickyEngine
engine.configuration.stickyInset = 0 // or offset below custom chrome
engine.stickyInsetProvider = { /* dynamic nav chrome height */ 0 }

engine.addTarget(id: "filters", view: filterStrip) { progress in
  filterStrip.layer.shadowOpacity = Float(progress.value) * 0.18
}
```

### Multi-target push-off

```swift
scrollView.fk_addStickyTarget(id: "section-a", view: headerA)
scrollView.fk_addStickyTarget(id: "section-b", view: headerB)
// Default: configuration.collisionBehavior == .pushOff
```

### Stacked pins (filter + tabs)

```swift
var configuration = scrollView.fk_stickyEngine.configuration
configuration.collisionBehavior = .stack // or allowsPushOff = false
scrollView.fk_stickyEngine.configuration = configuration
```

### Stuck-set observation

```swift
engine.onStuckTargetsChange = { ids in
  separator.isHidden = ids.isEmpty
}
```

### Manual scroll forwarding

```swift
scrollView.fk_stickyEngine.configuration.observesAutomatically = false

func scrollViewDidScroll(_ scrollView: UIScrollView) {
  scrollView.fk_handleStickyScroll()
}
```

### Bottom edge

```swift
var configuration = FKStickyConfiguration.default
configuration.edge = .bottom
scrollView.fk_stickyEngine.configuration = configuration
```

## Non-goals (v1)

- Visual tab / filter UI (use existing components as sticky **content**)
- Reparenting `UITableView` section `HeaderFooterView` instances (prefer system plain sticky headers)
- Competing with Compositional Layout `pinToVisibleBounds` on the same supplementary
- Anchor-to-sibling popovers (use Callout / Sheet `FKAnchor`)

## Examples

Hub entry: **FKUIKit → Sticky** (`FKStickyExamplesHubViewController`).

| Section | Scenarios |
|---------|-----------|
| Basics | UIScrollView single top, UITableView header strip, UICollectionView content strip |
| Edges & insets | Bottom edge, stickyInset + stickyInsetProvider |
| Collision | Push-off, stack |
| Appearance & callbacks | Progress / lifecycle / engine shadow, stuck-set observation & queries |
| Runtime controls | Enable / force / target toggle / remove / reset, reload while stuck |
| Observation | Manual `fk_handleStickyScroll` forwarding |
| Configuration details | Placeholder, hysteresis, priority, stickyInsetOverride |
| Combined | Interactive playground |

## Best practices

- Call `fk_reloadStickyLayout()` after Dynamic Type or height changes.
- Attach the engine to the scroll view that actually moves (nested scrolls).
- Capture `[weak self]` in progress callbacks.
- Account for `adjustedContentInset` from Refresh / safe area via `stickyInset` / `stickyInsetProvider`.

## License

Same as FKKit.
