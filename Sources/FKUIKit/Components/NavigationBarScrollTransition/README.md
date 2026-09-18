# FKNavigationBarScrollTransition

Opt-in **scroll-driven navigation-bar chrome** for UIKit. Maps a scroll view’s vertical offset to a normalized progress and interpolates navigation-bar appearance (background opacity/color, title/tint, shadow, discrete status-bar style). This module is a **behavior engine**, not a custom navigation bar.

## Requirements

- iOS 15+
- Swift 6
- `import FKUIKit` (depends on FKCoreKit)

## Source layout

Paths live under `Sources/FKUIKit/Components/NavigationBarScrollTransition/`.

### `Public/`

| Folder / file | Role |
|---------------|------|
| `Core/FKNavigationBarScrollEngine.swift` | Orchestrates observation, progress, optional appearance apply |
| `Configuration/FKNavigationBarScrollConfiguration.swift` | Sendable engine policy |
| `Models/FKNavigationBarScrollAppearance.swift` | From/to chrome snapshots + interpolation |
| `Models/FKNavigationBarScrollProgress.swift` | Normalized progress + status-bar helper |
| `Models/FKNavigationBarScrollApplicationTarget.swift` | `.navigationItem` / `.navigationBar` / `.both` |

### `Internal/`

| File | Role |
|------|------|
| `FKNavigationBarScrollAppearanceApplicator.swift` | Builds/applies `UINavigationBarAppearance` |
| `FKNavigationBarScrollColorInterpolation.swift` | RGBA color lerp |
| `FKNavigationBarScrollAssociationKeys.swift` | Associated-object key for `UIScrollView` |

### `Extension/`

| File | Role |
|------|------|
| `UIScrollView+FKNavigationBarScrollTransition.swift` | `fk_navigationBarScrollEngine` helpers |

## API overview

| Type / API | Purpose |
|------------|---------|
| `FKNavigationBarScrollEngine` | Bind scroll + VC, configure endpoints, force/reset progress |
| `FKNavigationBarScrollConfiguration` | Offset range, observation, apply target, discrete threshold |
| `FKNavigationBarScrollAppearance` | Endpoint chrome; `.transparent` / `.solid` factories |
| `FKNavigationBarScrollProgress` | `value` in `0...1` + `resolvedStatusBarStyle` |
| `scrollView.fk_navigationBarScrollEngine` | Lazy per-scroll-view engine |
| `fk_handleNavigationBarScroll()` | Manual drive when `observesAutomatically == false` |

### Threading

`FKNavigationBarScrollEngine` and `UIScrollView` helpers are **`@MainActor`**. Configuration and progress are `Sendable`. Appearance snapshots that store `UIColor` are `@unchecked Sendable`.

### Design

Normative design: [`docs/FKNavigationBarScrollTransition_DESIGN.md`](../../../../docs/FKNavigationBarScrollTransition_DESIGN.md).

## Quick start

```swift
import UIKit
import FKUIKit

let engine = scrollView.fk_navigationBarScrollEngine
engine.configuration.endOffset = heroHeight
engine.bind(viewController: self)
engine.fromAppearance = .transparent(tint: .white, statusBarStyle: .lightContent)
engine.toAppearance = .solid(
  backgroundColor: .systemBackground,
  titleColor: .label,
  tintColor: .label,
  statusBarStyle: .darkContent
)
engine.onProgressChange = { [weak self] progress in
  self?.cachedStatusBarStyle = progress.resolvedStatusBarStyle(
    from: engine.fromAppearance,
    to: engine.toAppearance,
    threshold: engine.configuration.discreteThreshold
  )
}

override var preferredStatusBarStyle: UIStatusBarStyle { cachedStatusBarStyle }
```

### Callback-only (custom / FK Base bars)

```swift
engine.configuration.appliesAppearanceAutomatically = false
engine.onAppearanceChange = { appearance, progress in
  // Map into host navigation presets
}
```

### Manual observation (e.g. alongside FKSticky)

```swift
engine.configuration.observesAutomatically = false

func scrollViewDidScroll(_ scrollView: UIScrollView) {
  scrollView.fk_handleStickyScroll()
  scrollView.fk_handleNavigationBarScroll()
}
```

## Relationship to FKSticky

| | This module | FKSticky |
|--|-------------|----------|
| Mutates | Navigation bar chrome | Content strips (reparent / pin) |
| Typical use | Transparent → solid bar | Tab / filter stick under nav |

Compose both on the same driving scroll view; do not merge responsibilities.

## Examples

Hub entry: **FKUIKit → NavigationBarScrollTransition** (`FKNavigationBarScrollExamplesHubViewController`).

| Section | Scenarios |
|---------|-----------|
| Basics | Transparent → solid hero, title fade-in, brand color blend |
| Application targets | `.navigationBar`, `.both`, callback-only (`appliesAppearanceAutomatically = false`) |
| Progress & configuration | Offset range, adjusted content offset, discrete status-bar threshold |
| Observation | Manual `fk_handleNavigationBarScroll` forwarding |
| Runtime controls | Enable, force progress, reload, reset, re-bind |
| Composition | Alongside FKSticky (shared scroll, manual forward) |
| Combined | Interactive playground |

## Non-goals (v1)

- Brand navigation presets
- Content sticky / header collapse / paging scroll handoff
- Custom navigation-bar subclasses
- Hiding the system navigation bar
- Unit tests in this delivery (deferred)

## Best practices

- Set `endOffset` to the real hero / banner height (default `88` is only a placeholder).
- Prefer ``FKNavigationBarScrollApplicationTarget/navigationItem`` for push stacks.
- Return ``FKNavigationBarScrollEngine/resolvedStatusBarStyle`` (or a cached copy) from `preferredStatusBarStyle`.
- For true clear chrome, the shared ``UINavigationBar`` must allow translucency (`isTranslucent == true`). The engine sets this while applying and mirrors appearances onto the bar so opaque root styles cannot linger. On iOS 26+, the engine also hides ``UIScrollView/topEdgeEffect`` so system scroll-edge glass does not paint a frosted band under the bar.
- Capture `[weak self]` in progress callbacks.
- Re-apply or reset chrome in `viewWillAppear` after other VCs mutate the shared bar. Hosts pushing from an opaque navigation shell should toggle `isTranslucent = true` before the first layout if content must extend under the bar.

## License

Same as FKKit.
