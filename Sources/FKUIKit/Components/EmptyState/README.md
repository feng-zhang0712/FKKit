# FKEmptyState

UIKit overlay for **loading**, **empty**, **error**, and **custom** placeholders on any `UIView` or `UIScrollView`. One overlay instance per host; show/hide with `phase == .content` to avoid flicker.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit` (includes resolver types from **`CoreLite/`**)

## Layout

| Layer | Contents |
|--------|----------|
| **`Public/`** | `FKEmptyStateView`, `FKEmptyStateConfiguration`, `Public/Configuration/` sub-configs, extensions |
| **`Internal/`** | Threading, host storage |
| **`Extension/`** | `UIView`, `UIScrollView`, `UIViewController` conveniences |
| **`CoreLite/`** | `FKEmptyStateType`, `FKEmptyStateInputs`, `FKEmptyStateResolver` (Foundation only, compiled into **`FKUIKit`**) |

## Source layout (`Sources/FKUIKit/Components/EmptyState/`)

Same layering as **`Badge`**: **`Public`**, **`Internal`**, **`Extension`**, plus **`CoreLite/`** (Foundation-only resolver sources under this folder).

### `Public/`

| File | Role |
|------|------|
| `FKEmptyStatePhase.swift` | `.content` / `.loading` / `.empty` / `.error` / `.custom` |
| `FKEmptyStateTransition.swift` | Content update animations for `apply(_:animated:)` |
| `FKEmptyStateLayoutHints.swift` | `FKEmptyStateLayoutContext`, `Density`, `Axis` (hints carried on ``FKEmptyStateLayoutConfiguration``) |
| `FKEmptyStateConfiguration.swift` | Aggregate configuration, ``FKEmptyState`` namespace, scenarios, fluent `with*` / `updating*` helpers |
| `Configuration/` | Layered sub-configurations (content, layout, appearance, presentation, slots) |
| `FKEmptyStateAction.swift` | `FKEmptyStateAction`, `FKEmptyStateActionSet`, `FKEmptyStateActionKind` |
| `FKEmptyStateView.swift` | Overlay view, delegate, notifications |
| `FKEmptyStatePresentable.swift` | `UIView` conformance for presentation abstraction |

### `Public/Configuration/`

| File | Role |
|------|------|
| `FKEmptyStateContentConfiguration.swift` | Copy, `FKEmptyStateImageContent`, `FKEmptyStateCustomAccessory` |
| `FKEmptyStateLayoutConfiguration.swift` | Context, density, axis, optional layout overrides |
| `FKEmptyStateSpacingConfiguration.swift` | Per-segment stack spacing overrides |
| `FKEmptyStateAppearanceConfiguration.swift` | Typography, buttons, background, loading chrome |
| `FKEmptyStatePresentationConfiguration.swift` | Transitions, scroll/keyboard behavior, loading rules |
| `FKEmptyStateSlotConfiguration.swift` | Header/media/content/actions/footer slots |
| `FKEmptyStateButtonStyle.swift` | Button chrome + `FKEmptyStateButtonAppearance` |
| `FKEmptyStateButtonCornerStyle.swift` | Fixed radius vs capsule corner treatment |
| `FKEmptyStateLayoutEnums.swift` | `FKEmptyStateCustomPlacement`, `FKEmptyStateContentAlignment` |

### `Internal/`

| File | Role |
|------|------|
| `FKEmptyStateThreading.swift` | Main-thread precondition for public UI entry points |
| `FKEmptyStateHostStorage.swift` | Associated-object keys, configuration box, scroll/refresh helpers |
| `FKEmptyStateLayoutMetrics.swift` | Density-driven spacing and typography scaling |
| `FKEmptyStateContextLayout.swift` | Context presets and resolved layout values |

### `Extension/`

| File | Role |
|------|------|
| `UIView+FKEmptyState.swift` | `fk_applyEmptyState`, `fk_updateVisibleEmptyState`, `fk_hideEmptyState`, `fk_removeEmptyState`, `fk_setEmptyState`, visibility |
| `UIScrollView+FKEmptyState.swift` | `fk_updateEmptyState`, list helpers, auto short-content visibility |
| `UIViewController+FKEmptyState.swift` | `fk_bindEmptyStateActions` / `fk_clearEmptyStateActionObservers` |

### `CoreLite/`

Foundation-only sources compiled as part of the **`FKUIKit`** target.

| File | Role |
|------|------|
| `FKEmptyStateSemantic.swift` | `FKEmptyStateType`, `FKEmptyStateInputs`, `FKEmptyStateResolution`, `FKEmptyStateResolver` |

## Global defaults (FKBadge-style)

Set once at launch:

```swift
FKEmptyState.configureAppearance { $0.typography.titleFont = .systemFont(ofSize: 20, weight: .semibold) }
FKEmptyState.configureLayout { $0.context = .section }
FKEmptyState.configurePresentation { $0.loadingBehavior.skipsWhileRefreshing = false }
// or mutate the aggregate defaults in one pass:
FKEmptyState.configureDefault { $0.appearance.buttons.primary.cornerRadius = 12 }
```

## Quick start

```swift
import UIKit
import FKUIKit

var config = FKEmptyStateConfiguration.scenario(.noSearchResult)
config.phase = .empty
view.fk_applyEmptyState(config) { action in
  if action.id == "retry" { reload() }
}

// Minimal custom empty state
let custom = FKEmptyStateConfiguration(
  phase: .empty,
  image: UIImage(systemName: "tray"),
  title: "No items",
  description: "Pull to refresh.",
  primaryActionTitle: "Refresh"
)

view.fk_hideEmptyState()
// or
view.fk_applyEmptyState(FKEmptyStateConfiguration(phase: .content))
```

### Lists (`UITableView` / `UICollectionView`)

```swift
tableView.fk_updateEmptyStateForTable(configuration: emptyConfig) { _ in reload() }
collectionView.fk_updateEmptyState(
  itemCount: collectionView.fk_totalItemCount(),
  configuration: emptyConfig
)
```

### Resolver + scenario presets

```swift
let input = FKEmptyStateInputs(dataLength: 0, isLoading: false, searchQuery: "note")
let config = FKEmptyStateConfiguration.resolved(from: input)
if config.phase == .content {
  view.fk_hideEmptyState()
} else {
  view.fk_applyEmptyState(config)
}
```

Two-step resolution (when you need the semantic type before building configuration):

```swift
switch FKEmptyStateResolver.resolve(input) {
case .none:
  view.fk_hideEmptyState()
case .show(let type):
  var config = FKEmptyStateConfiguration.scenario(.noSearchResult)
  config.type = type
  view.fk_applyEmptyState(config)
}
```

### Illustration & layout

- `content.image` (`FKEmptyStateImageContent`), `content.customAccessory`, `content.title` / `description`
- `layout.context` tunes default image size, column width, insets, and alignment when override properties are `nil`
- `layout.density` scales the fallback `verticalSpacing` and typography (`compact` ×0.75, `comfortable` ×1.25); explicit `layout.segmentSpacing` values are **not** scaled
- `layout.verticalSpacing` — default stack spacing; also the fallback when segment overrides are `nil`
- `layout.segmentSpacing` — independent gaps after image, title, description, and actions slot (`afterImage`, `afterTitle`, `afterDescription`, `afterActionsSlot`)
- `layout.axis`: `.vertical` (default) or `.horizontal` (illustration beside text)
- `presentation.transition`: `.none` (default), `.crossDissolve`, `.fade`, `.scale`, `.slideUp` for in-place content updates
- `actions` — primary / secondary / tertiary payloads; empty set hides buttons
- `appearance.buttons.primary` styles the primary chrome; `appearance.buttons.secondary` / `tertiary` override bordered and plain slots
- `appearance.buttons.primary.cornerStyle` — `.capsule` for a true pill shape, or `.fixed(radius:)` for a constant radius
- `FKEmptyStateActionKind.link` renders an underlined text action; `isLoading` shows a button activity indicator (iOS 15+)

### Spacing

Use `layout.segmentSpacing` to tune gaps between standard blocks without affecting slot content:

```swift
var config = FKEmptyStateConfiguration.scenario(.noSearchResult)
config.layout.segmentSpacing.afterImage = 20
config.layout.segmentSpacing.afterTitle = 6
config.layout.segmentSpacing.afterDescription = 24
config.layout.verticalSpacing = 12 // fallback + density-scaled default stack spacing
```

### Slots

Slots (`config.slots.header`, `.media`, `.content`, `.actions`, `.footer`) insert custom views at fixed stack positions. Prefer `layout.segmentSpacing` for spacing between image, title, description, and buttons — slots are for supplementary content (badges, hints, custom controls), not invisible spacers.

```swift
config.slots.actions = myCustomAccessoryView
```

### Actions

Configure button **copy** on `actions` and **chrome** on `appearance.buttons`:

```swift
var config = FKEmptyStateConfiguration.scenario(.noFavorites)
config.actions.secondary = FKEmptyStateAction(
  id: "learn",
  title: "Learn more",
  kind: .link
)
config.appearance.buttons.primary.backgroundColor = .systemIndigo
config.appearance.buttons.primary.cornerStyle = .capsule

// Or build from scratch
config.actions = .primary("Refresh", id: "retry")
config.withPrimaryAction(nil) // remove primary
```

## Migration from ≤ 0.62

`FKEmptyStateConfiguration` used to expose ~50 flat properties. Upgrade paths:

| Legacy | Replacement |
|--------|-------------|
| `config.title` | `config.content.title` |
| `config.image` / `imageTintColor` | `config.content.image` or `withImage(_:)` / `withImageTintColor(_:)` |
| `config.customAccessoryView` | `config.content.customAccessory = FKEmptyStateCustomAccessory(view:placement:)` |
| `config.context`, `maxContentWidth`, … | `config.layout.*` (`nil` override → context preset) |
| `config.titleColor`, `titleFont`, … | `config.appearance.typography.*` |
| `config.buttonStyle` / `secondaryButtonStyle` | `config.appearance.buttons.primary` / `.secondary` (chrome only) |
| `config.buttonStyle.title = "Retry"` | `config.actions = .primary("Retry", id: "retry")` |
| `config.isButtonHidden = true` | `config.actions = FKEmptyStateActionSet()` |
| `config.withButtonTitle(_:)` | `config.withPrimaryAction(_:)` |
| `config.isTitleHidden = true` | `config.content.title = nil` |
| `config.fadeDuration`, `transition` | `config.presentation.*` |
| `FKEmptyState.defaultConfiguration.titleFont = …` | `FKEmptyState.configureAppearance { $0.typography.titleFont = … }` |

Full release notes: root [`CHANGELOG.md`](../../../../CHANGELOG.md) **`[Unreleased]`** section.

## API summary

### `UIView`

- `fk_applyEmptyState(_:animated:actionHandler:viewTapHandler:)` — primary entry; `phase == .content` hides.
- `fk_applyEmptyState(_:animated:actionHandler:)` — single trailing closure (preferred when no background tap handler).
- `fk_updateVisibleEmptyState(_:animated:actionHandler:viewTapHandler:)` — in-place content update when overlay is already visible; falls back to `fk_applyEmptyState` otherwise.
- `fk_setEmptyState(phase:…)` / `fk_setEmptyState(animated:configure:)` — template-based shortcuts.
- `fk_hideEmptyState(animated:)` — hides and keeps the overlay for reuse.
- `fk_removeEmptyState(animated:)` — removes the overlay and clears host storage; the next `fk_applyEmptyState` recreates it.
- `fk_emptyStateView`, `fk_emptyStateConfiguration`, `fk_isEmptyStateOverlayVisible`
- `FKEmptyStatePresentable` — `fk_presentEmptyState` / `fk_dismissEmptyState` aliases for test seams and protocol-oriented hosts.

### `UIScrollView`

- `fk_updateEmptyState(_:animated:)` — in-place content update (delegates to `fk_updateVisibleEmptyState`).
- `fk_updateEmptyState(itemCount:configuration:…)`, `fk_updateEmptyStateVisibility(isEmpty:configuration:…)`
- `fk_refreshEmptyStateAutomatically(…)` when `presentation.automaticallyShowsWhenContentFits`.
- `UITableView.fk_totalRowCount()`, `fk_updateEmptyStateForTable(configuration:…)`
- `UICollectionView.fk_totalItemCount()`

### `FKEmptyStateView`

- `configuration` — last applied ``FKEmptyStateConfiguration``.
- `apply(_:animated:)` — push updates to the overlay.

### `UIViewController`

- `fk_bindEmptyStateActions(from:handler:)` — observe `.fk_emptyStateActionInvoked` for a host’s overlay.
- `fk_clearEmptyStateActionObservers()`

### Notifications

- `Notification.Name.fk_emptyStateActionInvoked` — `userInfo` keys: `FKEmptyStateNotificationKeys.id`, `.kind`, `.title`, `.payload`.

## Design notes

- **Phase vs type**: `FKEmptyStatePhase` drives layout (spinner vs buttons). `FKEmptyStateType` is semantic (offline, noResults, …) for i18n and analytics.
- **Error phase**: A primary retry action is enforced when copy would otherwise leave users stuck.
- **Reduce Motion**: Content transitions and show/hide respect `UIAccessibility.isReduceMotionEnabled`.
- **Prefer host**: `UIViewController.view` or the scroll view itself — not `UITableView.backgroundView`, so refresh controls stay usable.

## Examples

Under `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/EmptyState/`:

- **`Support/`** — shared factory and view-controller helpers.
- **`Basics/`** — empty, search miss, error/retry, offline, permission.
- **`Advanced/`** — loading transition, layout comparison, custom illustration, capabilities (density/axis/link), action styles & transitions, dark mode, RTL, i18n, resolver, **layout playground**.

Entry: `FKEmptyStateExamplesHubViewController`.

## License

Part of FKKit — see the repository root [LICENSE](../../../../LICENSE).
