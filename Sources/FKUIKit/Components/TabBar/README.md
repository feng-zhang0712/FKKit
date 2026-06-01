# FKTabBar

`FKTabBar` is a UIKit-native **tab strip** (segmented header) for apps worldwide: it renders tabs, animates an indicator, integrates `FKBadge`, and exposes deterministic selection APIs. It intentionally does **not** own view controllers, navigation, or paging—hosts wire selection to their own containers.

Typical uses:

- **Pager header**: drive `setSelectionProgress(from:to:progress:)` from an external scroll view, then commit with `setSelectedIndex(_:reason:)`. For full `UIPageViewController` integration use [`FKPagingController`](../PagingController/README.md).
- **Bottom bar surface**: pin the view like `UITabBar` using layout + `FKTabBarAppearance` (still no `UITabBarController` wrapper).

---

## Source layout (Swift Package)

Files are grouped for readability; **all types remain `import FKUIKit`** regardless of folder.

| Area | Path | Responsibility |
|------|------|----------------|
| Public API | `Public/FKTabBar.swift` | Main `UIView` subclass and item update APIs |
| | `Public/Configuration/` | `FKTabBarConfiguration`, `FKTabBarPresets`, `FKTabBarCustomization`, layout/appearance/animation enums |
| | `Public/Models/` | `FKTabBarItem`, text/image models, badge, accessory, scroll edge fade, selection snapshot/progress, item changes |
| | `Public/Protocols/` | `FKTabBarDelegate`, `FKTabBarDataSource` |
| | `Public/Indicator/` | Indicator style configuration |
| | `Public/SwiftUI/` | `FKTabBarRepresentable` |
| Internal | `Internal/Configuration/` | Configuration diff domains and apply routing |
| | `Internal/Selection/` | Selection reducer, item diff engine, index sync |
| | `Internal/Layout/` | Width, scroll alignment, indicator frame math |
| | `Internal/Views/` | `FKTabBarItemCell`, `FKTabBarIndicatorView`, scroll edge fade overlay |
| | `Internal/Badge/` | Badge anchor resolution |

---

## Requirements

- Swift 6 language mode (see repo `Package.swift`)
- iOS 15+ / UIKit (current `FKUIKit` target)

---

## Installation (SwiftPM)

Add the `FKKit` package and depend on the **`FKUIKit`** product.

```swift
dependencies: [
  .package(url: "https://github.com/your-org/FKKit.git", from: "1.0.0"),
],
targets: [
  .target(name: "YourApp", dependencies: [.product(name: "FKUIKit", package: "FKKit")]),
]
```

```swift
import FKUIKit
```

---

## Threading

All public entry points are `@MainActor`. Call from the main thread only.

---

## Core concepts

### Items vs visible strip

- `items` — full array you pass in (includes `isHidden` tabs).
- `visibleItems` — read-only list actually laid out (hidden filtered out). Selection indices are **always relative to `visibleItems`**.

### Stable IDs

Use a stable `FKTabBarItem.id` across reloads. Selection preservation, badge updates by ID, and SwiftUI bridging rely on it.

### Configuration entry point

Use ``FKTabBarConfiguration`` via ``FKTabBar/configuration`` or a preset from ``FKTabBarPresets``:

```swift
let tabBar = FKTabBar(
  items: items,
  selectedIndex: 0,
  configuration: FKTabBarPresets.pagerHeader()
)
```

Scene presets: ``FKTabBarPresets/pagerHeader()``, ``bottomDocked(showsIndicator:)``, ``segmentedControl(itemSpacing:)``, ``filterStrip()``.

Partial item updates: ``updateItem(at:animated:)`` (refresh visible cell for an existing model), ``setItem(_:at:animated:)`` (replace model). Structural batches: ``applyChanges(_:)``. Full reload with ID diff: ``reload(items:)``. Configuration refresh: ``applyConfiguration(_:animated:)``.

---

## Selection API

| API | Purpose |
|-----|---------|
| `setSelectedIndex(_:animated:notify:reason:)` | Programmatic selection; `notify: false` skips callbacks and VoiceOver announcement |
| `setSelectedIndex(forItemID:animated:notify:reason:)` | Select by stable `id` (returns `false` if ID not visible) |
| `selectedItemID` | Stable ID of the selected visible tab |
| `selectionSnapshot` | Read-only phase/index snapshot for coordination |
| `selectionControlMode = .controlled` | Tap emits `onSelectionRequest` / delegate; host commits when ready |
| `setSelectionProgress(from:to:progress:)` | Interactive pager interpolation |
| `onSelectionProgress` | Observe fractional progress during paging-style transitions |

Callback order for a committed change: `shouldSelect` → delegate `shouldSelect` → `willSelect` → visual update → `onSelectionChanged` → delegate `didSelect`.

---

## Custom indicators

For ``FKTabBarIndicatorStyle/custom(id:)``, supply the view via ``FKTabBarCustomization/customIndicatorView(id:)``. When follow mode is ``FKTabBarIndicatorFollowMode/custom(id:)``, resolve the effective behavior through ``FKTabBarCustomization/indicatorFollowMode(forCustomID:)`` — return ``trackContentProgress`` to participate in paging interpolation.

---

## Layout notes

- ``FKTabBarLayoutConfiguration/contentInsets`` — section insets around the whole tab strip (collection layout), not per-tab title/icon padding.
- ``FKTabBarLayoutConfiguration/itemInsets`` — single knob for per-tab padding from the cell edge to title/icon. Applied only as the hosted ``FKButton`` appearance `contentInsets`; the cell does not add a second margin layer. Prefer this over tuning `FKButton` insets in ``FKTabBarCustomization/configure(button:item:isSelected:)``.
- Item width in ``FKTabBarItemWidthMode/intrinsic`` is measured with the same ``FKButton`` layout path as ``FKTabBarItemCell`` (see ``FKTabBarItemContentMeasurer``) so center alignment does not leave extra slack inside ``FKButton/contentContainerView``.
- Indicator ``trackContentFrame`` modes use the laid-out ``FKButton`` stack bounds so line/backdrop width matches visible content when `itemInsets` changes.
- ``FKTabBarLayoutConfiguration/nonScrollableOverflowPolicy`` — shrink / truncate / clip when ``isScrollable`` is `false`.
- ``FKTabBarLayoutConfiguration/emptyStateMessage`` — optional centered placeholder when the visible strip is empty.
- ``FKTabBarLayoutConfiguration/scrollEdgeFade`` — horizontal edge fade when scrollable (enabled in ``FKTabBarPresets/filterStrip()``).
- ``FKTabBar/expandedItemID`` — visual accessory emphasis (chevrons) without changing selection.
- ``FKTabBar/visibleItemButton(at:)`` — returns the internal ``FKButton`` for popover/menu anchoring.
- Item width measurement uses each item's ``FKTabBarImageStyle/fixedSize`` (not a hard-coded icon size).

---

## SwiftUI

`FKTabBarRepresentable` supports `Binding<Int>`, controlled mode, customization, and `onSelectionProgress`. See `Public/SwiftUI/FKTabBarRepresentable.swift` for binding sync rules when the item list changes.

---

## Badges

Configure per item via `FKTabBarBadgeConfiguration`. For frequent updates, prefer `setBadge(_:at:)` / `setBadge(_:forItemID:)` to avoid full `reloadData()`.

---

## RTL & Dynamic Type

`FKTabBar` reacts to `traitCollection.layoutDirection` and `preferredContentSizeCategory`. Tune `layout.rtlBehavior` and `layout.largeTextLayoutStrategy` for forced direction and accessibility text sizing.

---

## Example app layout

Under `Examples/.../FKUIKit/TabBar/`:

- `Hub/` — navigation hub
- `Shared/` — `FKTabBarExampleSupport` factories
- `Scenarios/Basics`, `Scrollable`, `Indicator`, `Badge`, `Dynamic`, `Integration`, `Accessibility`, `ReplaceUITabBar`, `Performance`, …

Integration scenarios cover DataSource, overflow policy, empty state, selection telemetry, anchor button, and SwiftUI representable.

---

## API checklist (public types)

- `FKTabBar`
- `FKTabBarItem`, `FKTabBarItemChange`, `FKTabBarTextConfiguration`, `FKTabBarImageConfiguration`, …
- `FKTabBarBadgeConfiguration`, `FKTabBarBadgeContent`, `FKTabBarAccessoryConfiguration`
- `FKTabBarScrollEdgeFade`
- `FKTabBarConfiguration`, `FKTabBarLayoutConfiguration`, `FKTabBarAppearance`, `FKTabBarAnimationConfiguration`
- `FKTabBarCustomization`, `FKTabBarDefaultCustomization`
- `FKTabBarIndicatorStyle` (+ related indicator configs)
- `FKTabBarDelegate`, `FKTabBarDataSource`
- `FKTabBarRepresentable` (SwiftUI)
- `FKTabBarDefaults`, `FKTabBarSwitchPhase`, `FKTabBarSelectionSnapshot`, `FKTabBarSelectionProgress`
- `FKTabBarPresets`

---

## Best practices

1. Keep item IDs stable.
2. Prefer `applyChanges(_:)` or `reload(items:)` (ID diff) over ad-hoc full reloads when updating dynamic tabs.
3. Integrate paging with progress APIs, then commit selection explicitly.
4. Use `notify: false` when mirroring external state to prevent loops.
5. Subclass ``FKTabBarDefaultCustomization`` for custom width, badge, indicator, and button hooks — keep overrides lightweight on the main thread.
6. For bottom-docked vertical layouts, size the bar from ``intrinsicContentSize`` or set ``preferredBarHeight`` — do not assume a single-line header height.

---

## License

Same as the enclosing FKKit repository.
