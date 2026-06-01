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
| Public API | `Public/FKTabBar/` | Main `UIView` subclass split by topic (`FKTabBar.swift` core + `FKTabBar+*.swift` extensions; collection callbacks live in `Internal/Views/FKTabBarCollectionCoordinator.swift`) |
| | `Public/Configuration/` | `FKTabBarConfiguration`, `FKTabBarPresets`, `FKTabBarCustomization`, layout/appearance/animation enums |
| | `Public/Models/` | `FKTabBarItem`, text/image models, badge, accessory, scroll edge fade, selection snapshot/progress, item changes, resolved title/layout hints |
| | `Public/Protocols/` | `FKTabBarDelegate`, `FKTabBarDataSource` |
| | `Public/Indicator/` | Indicator style configuration |
| | `Public/SwiftUI/` | `FKTabBarRepresentable` |
| Internal | `Internal/Configuration/` | Configuration diff domains and apply routing |
| | `Internal/Selection/` | Selection reducer, item diff engine, index sync |
| | `Internal/Layout/` | Width measurement, flow layout, scroll alignment, indicator frame math |
| | `Internal/Views/` | `FKTabBarItemCell`, `FKTabBarItemButtonConfigurator`, `FKTabBarCollectionCoordinator`, indicator, scroll edge fade |
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

Partial item updates: ``setItem(_:at:animated:)`` / ``setItem(_:forItemID:animated:)``, ``setBadge(_:at:animated:accessibilityValue:)`` / ``setBadge(_:forItemID:animated:accessibilityValue:)``. Structural batches: ``applyChanges(_:)`` (returns `false` when any change is invalid). Full reload with ID diff: ``reload(items:)``. Configuration refresh: ``applyConfiguration(_:animated:)``. ``updateItem(at:animated:)`` only re-renders from the current in-memory model — it does not fetch new data. When models change but selection index is unchanged, call ``reapplyVisibleItemConfigurations()`` so visible cells pick up new title/icon/badge data.

Batch helpers: ``performBatchUpdates(_:)`` groups mutations with one layout pass; ``realignSelection()`` recenters scroll/indicator after external layout changes.

### DataSource

When ``FKTabBar/dataSource`` is set, assigning the property triggers ``reloadData()`` automatically. Use ``reloadData(updatePolicy:)`` after mutating backing storage. Manual ``reload(items:)`` still updates the internal cache used when `dataSource` is `nil`.

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
| `resolvedTitlePresentationForCurrentEnvironment()` | Debug/read effective overflow mode, line count, and bar-height growth policy |
| `resolvedLayoutHintsForCurrentEnvironment()` | Bundled snapshot: title presentation, safe-area behavior, alignment/spacing flags |

Callback order for a committed change: `shouldSelect` → delegate `shouldSelect` → `willSelect` → visual update → `onSelectionChanged` → delegate `didSelect`. Retapping the selected tab emits `onReselect` then delegate `didReselect` before any optional duplicate `didSelect` when ``TapEventTriggerBehavior/always`` is active.

**Callbacks vs delegate:** use either pattern or both — when both are set, closures run first, then delegate methods. Prefer one style per event in app code to keep wiring obvious.

---

## Custom indicators

For ``FKTabBarIndicatorStyle/custom(id:)``, supply the view via ``FKTabBarCustomization/customIndicatorView(id:)``. When follow mode is ``FKTabBarIndicatorFollowMode/custom(id:)``, resolve the effective behavior through ``FKTabBarCustomization/indicatorFollowMode(forCustomID:)`` — return ``trackContentProgress`` to participate in paging interpolation.

Line/backdrop fills come from the style configuration's `fill`. ``FKTabBarAppearance/colors/indicator`` is the fallback tint; ``FKTabBar`` re-applies indicator appearance whenever ``colors`` or ``indicatorStyle`` change (including equal ``Equatable`` payloads) so theme overrides cannot stick on ``FKTabBarDefaults`` black.

---

## Layout notes

- ``FKTabBarLayoutConfiguration/contentInsets`` — section insets around the whole tab strip (collection layout), not per-tab title/icon padding.
- ``FKTabBarLayoutConfiguration/itemInsets`` — single knob for per-tab padding from the cell edge to title/icon. Applied only as the hosted ``FKButton`` appearance `contentInsets`; the cell does not add a second margin layer. Prefer this over tuning `FKButton` insets in ``FKTabBarCustomization/configure(button:item:isSelected:)``.
- Item width in ``FKTabBarItemWidthMode/intrinsic`` is measured with the same ``FKButton`` layout path as ``FKTabBarItemCell`` (see ``FKTabBarItemContentMeasurer`` / ``FKTabBarItemButtonConfigurator``) so center alignment does not leave extra slack inside ``FKButton/contentContainerView``.
- Indicator ``trackContentFrame`` modes use the laid-out ``FKButton`` stack bounds so line/backdrop width matches visible content when `itemInsets` changes.
- ``FKTabBarCustomization/customSpacing(after:context:)`` — per-gap spacing after each visible index (honored by ``FKTabBarFlowLayout`` when content alignment is not distributing extra width).
- ``FKTabBarAppearance/subtitleConfiguration`` — global subtitle fallback when ``FKTabBarItem/subtitle`` is nil; item-level subtitle always wins.
- ``FKTabBarLayoutConfiguration/nonScrollableOverflowPolicy`` — shrink / truncate / clip when ``isScrollable`` is `false`.
- ``FKTabBarLayoutConfiguration/intrinsicWidthMeasurement`` — how intrinsic/constrained widths are measured (see below).
- ``FKTabBarLayoutConfiguration/contentAlignment`` — leading / center / trailing group alignment when the strip is non-scrollable and total item width is smaller than the container. Use ``widthMode = .fillEqually`` for equal-width tabs.
- ``FKTabBarLayoutConfiguration/emptyStateMessage`` — optional centered placeholder when the visible strip is empty.
- ``FKTabBarLayoutConfiguration/scrollEdgeFade`` — horizontal edge fade when scrollable (enabled in ``FKTabBarPresets/filterStrip()``).
- ``FKTabBar/expandedItemID`` — host-owned expansion state (does not change selection). Built-in chevrons render ``chevron.down`` only; drive rotation or other expansion visuals in host code (see ``FKTabBar/visibleItemButton(at:)``).
- ``FKTabBar/visibleItemButton(at:)`` — returns the internal ``FKButton`` for popover/menu anchoring.
- Item width measurement uses each item's ``FKTabBarImageStyle/fixedSize`` (not a hard-coded icon size).

### Safe area (bottom-docked bars)

Use a single knob — ``FKTabBarLayoutConfiguration/bottomSafeAreaBehavior``:

| Case | Effect |
|------|--------|
| ``ignore`` | Header/pager default — no automatic safe-area adjustment |
| ``padContent`` | Adds bottom safe area to ``contentInsets.bottom`` at layout time |
| ``extendBarHeight`` | Adds bottom safe area to ``intrinsicContentSize`` height |
| ``bottomDocked`` | Both pad + extend — use for ``FKTabBarPresets/bottomDocked(showsIndicator:)`` |

### Title overflow resolution

Static configuration interacts in this order:

1. ``titleOverflowMode`` — base overflow when scrollable or as input to non-scrollable rules
2. ``nonScrollableOverflowPolicy`` — may override toward shrink/truncate when ``isScrollable == false``
3. ``largeTextLayoutStrategy`` — applies when Dynamic Type is an accessibility category

Read the effective result with ``resolvedTitlePresentationForCurrentEnvironment()`` or the bundled ``resolvedLayoutHintsForCurrentEnvironment()`` snapshot.

**`.clip` vs `.truncate`:** both resolve to truncated title layout for non-scrollable strips. ``clip`` additionally sets ``collectionView.clipsToBounds = true`` when the strip does not scroll.

### Intrinsic width measurement

``FKTabBarIntrinsicWidthMeasurement`` applies when ``widthMode`` is ``intrinsic`` or ``constrained`` (ignored for ``fillEqually`` / ``fixed``):

| Case | Behavior |
|------|----------|
| ``normalStateOnly`` (default) | Measure every item using normal-state title/image only — stable strip widths. |
| ``adjustsOnSelection`` | Re-measure the selected item with selected-state content; selection changes invalidate item widths and relayout. |

Use ``adjustsOnSelection`` when selected titles or icons are significantly wider than normal state (for example a short label that expands on selection).

---

## SwiftUI

`FKTabBarRepresentable` exposes two initializers:

- Default — `Binding<Int>` selection plus optional `onSelectionProgress` callback.
- Progress binding — adds `Binding<FKTabBarSelectionProgress?>` so SwiftUI can observe fractional transitions during paging.

Both support controlled mode and ``FKTabBarCustomization``. `updateUIView` reloads items only when the `[FKTabBarItem]` payload changes; selection binding updates skip full reload. See `Public/SwiftUI/FKTabBarRepresentable.swift` for binding sync rules when the item list changes.

---

## Badges

Configure per item via ``FKTabBarBadgeConfiguration``. Shared styling: ``FKTabBar/badgeConfiguration`` and ``FKTabBar/badgeAnimation``.

For frequent updates, prefer ``setBadge(_:at:animated:accessibilityValue:)`` / ``setBadge(_:forItemID:animated:accessibilityValue:)`` to avoid full ``reloadData()``.

**Contract:** ``setBadge`` updates ``badge.state.normal`` only (not ``selected`` / ``disabled`` overrides). The ``animated`` parameter refreshes the indicator; badge content on visible cells uses non-animated ``FKBadge`` updates. Custom badge views (``FKTabBarBadgeContent/custom``) are positioned by ``FKTabBarCustomization/customBadgeView(for:)`` and do not use per-item anchor offsets.

Badge anchor targets (icon vs title) are resolved internally; large badges in equal-width or vertical icon layouts may clip at the cell edge — tune anchor/offset or ``avoidsClipping`` on the item badge configuration.

---

## RTL & Dynamic Type

`FKTabBar` reacts to `traitCollection.layoutDirection` and `preferredContentSizeCategory`. Tune `layout.rtlBehavior` and `layout.largeTextLayoutStrategy` for forced direction and accessibility text sizing.

---

## Example app layout

Under `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/TabBar/`:

- `Hub/` — navigation hub
- `Shared/` — `FKTabBarExampleSupport` factories
- `Scenarios/Basics`, `Layout`, `Scrollable`, `Indicator`, `Badge`, `Dynamic`, `Integration`, `Accessibility`, `ReplaceUITabBar`, `Performance`, …

Integration scenarios cover DataSource, overflow policy (+ resolved layout hints), empty state, selection telemetry, anchor button, and SwiftUI representable.

---

## API checklist (public types)

- `FKTabBar`
- `FKTabBarItem`, `FKTabBarItemChange`, `FKTabBarTextConfiguration`, `FKTabBarImageConfiguration`, …
- `FKTabBarBadgeConfiguration`, `FKTabBarBadgeContent`, `FKTabBarAccessoryConfiguration`, `FKTabBarChevronAccessoryConfiguration`
- `FKTabBarScrollEdgeFade`
- `FKTabBarConfiguration`, `FKTabBarLayoutConfiguration`, `FKTabBarAppearance`, `FKTabBarAnimationConfiguration`, `FKTabBarIntrinsicWidthMeasurement`
- `FKTabBarCustomization`, `FKTabBarDefaultCustomization`
- `FKTabBarIndicatorStyle` (+ related indicator configs)
- `FKTabBarDelegate`, `FKTabBarDataSource`
- `FKTabBarRepresentable` (SwiftUI)
- `FKTabBarDefaults`, `FKTabBarSwitchPhase`, `FKTabBarSelectionSnapshot`, `FKTabBarSelectionProgress`, `FKTabBarResolvedTitlePresentation`, `FKTabBarResolvedLayoutHints`, `FKTabBarBottomSafeAreaBehavior`
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
