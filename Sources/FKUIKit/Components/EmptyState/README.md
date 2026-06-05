# FKEmptyState

UIKit overlay for **loading**, **empty**, **error**, and **custom** placeholders on any `UIView` or `UIScrollView`. One overlay instance per host; show/hide with `phase == .content` to avoid flicker.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit` (includes resolver types from **`CoreLite/`**)

## Layout

| Layer | Contents |
|--------|----------|
| **`Public/`** | `FKEmptyStateView`, `FKEmptyStateConfiguration`, extensions, UIKit-only layout enums |
| **`Internal/`** | Threading, host storage |
| **`Extension/`** | `UIView`, `UIScrollView`, `UIViewController` conveniences |
| **`CoreLite/`** | `FKEmptyStateType`, `FKEmptyStateInputs`, `FKEmptyStateResolver` (Foundation only, compiled into **`FKUIKit`**) |

## Source layout (`Sources/FKUIKit/Components/EmptyState/`)

Same layering as **`Badge`**: **`Public`**, **`Internal`**, **`Extension`**, plus **`CoreLite/`** (Foundation-only resolver sources under this folder).

### `Public/`

| File | Role |
|------|------|
| `FKEmptyStatePhase.swift` | `.content` / `.loading` / `.empty` / `.error` / `.custom` |
| `FKEmptyStateLayoutHints.swift` | `FKEmptyStateLayoutContext`, `Density`, `Axis` (hints carried on the configuration) |
| `FKEmptyStateConfiguration.swift` | Main configuration struct, ``FKEmptyState`` namespace (`defaultConfiguration`, `configureDefault(_:)`), scenarios, fluent `with*` helpers |
| `FKEmptyStateAction.swift` | `FKEmptyStateAction`, `FKEmptyStateActionSet`, `FKEmptyStateActionKind` |
| `FKEmptyStateView.swift` | Overlay view, delegate, notifications |
| `FKEmptyStatePresentable.swift` | `UIView` conformance for presentation abstraction |

### `Internal/`

| File | Role |
|------|------|
| `FKEmptyStateThreading.swift` | Main-thread precondition for public UI entry points |
| `FKEmptyStateHostStorage.swift` | Associated-object keys, configuration box, scroll/refresh helpers |

### `Extension/`

| File | Role |
|------|------|
| `UIView+FKEmptyState.swift` | `fk_applyEmptyState`, `fk_hideEmptyState`, `fk_setEmptyState`, visibility |
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
FKEmptyState.defaultConfiguration.titleFont = .systemFont(ofSize: 20, weight: .semibold)
// or
FKEmptyState.configureDefault { $0.buttonStyle.cornerRadius = 12 }
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
switch FKEmptyStateResolver.resolve(input) {
case .none:
  view.fk_hideEmptyState()
case .show(let type):
  var config = FKEmptyStateConfiguration.scenario(.noSearchResult)
  config.type = type
  view.fk_applyEmptyState(config)
}
```

## API summary

### `UIView`

- `fk_applyEmptyState(_:animated:actionHandler:viewTapHandler:)` — primary entry; `phase == .content` hides.
- `fk_applyEmptyState(_:animated:actionHandler:)` — single trailing closure (preferred when no background tap handler).
- `fk_setEmptyState(phase:…)` / `fk_setEmptyState(animated:configure:)` — template-based shortcuts.
- `fk_hideEmptyState(animated:)`
- `fk_emptyStateView`, `fk_emptyStateConfiguration`, `fk_isEmptyStateOverlayVisible`

### `UIScrollView`

- `fk_updateEmptyState(_:animated:)` — in-place content update.
- `fk_updateEmptyState(itemCount:configuration:…)`, `fk_updateEmptyStateVisibility(isEmpty:configuration:…)`
- `fk_refreshEmptyStateAutomatically(…)` when `automaticallyShowsWhenContentFits`.
- `UITableView.fk_totalRowCount()`, `fk_updateEmptyStateForTable(configuration:…)`
- `UICollectionView.fk_totalItemCount()`

### `FKEmptyStateView`

- `configuration` — last applied ``FKEmptyStateConfiguration``.
- `apply(_:animated:)` — push updates to the overlay.

### `UIViewController`

- `fk_bindEmptyStateActions(from:handler:)` — observe `.fkEmptyStateActionInvoked` for a host’s overlay.
- `fk_clearEmptyStateActionObservers()`

### Notifications

- `Notification.Name.fkEmptyStateActionInvoked` — `userInfo` keys: `FKEmptyStateNotificationKeys.id`, `.kind`, `.title`, `.payload`.

## Design notes

- **Phase vs type**: `FKEmptyStatePhase` drives layout (spinner vs buttons). `FKEmptyStateType` is semantic (offline, noResults, …) for i18n and analytics.
- **Error phase**: A primary retry action is enforced when copy would otherwise leave users stuck.
- **Reduce Motion**: Fade transitions respect `UIAccessibility.isReduceMotionEnabled`.
- **Prefer host**: `UIViewController.view` or the scroll view itself — not `UITableView.backgroundView`, so refresh controls stay usable.

## Examples

Under `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/EmptyState/`:

- **`Support/`** — shared factory and view-controller helpers.
- **`Basics/`** — empty, search miss, error/retry, offline, permission.
- **`Advanced/`** — loading transition, layout comparison, custom illustration, dark mode, RTL, i18n, resolver.

Entry: `FKEmptyStateExamplesHubViewController`.

## License

Part of FKKit — see the repository root [LICENSE](../../../../LICENSE).
