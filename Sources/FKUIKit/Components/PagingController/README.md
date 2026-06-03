# FKPagingController

`FKPagingController` is a UIKit container that embeds **`FKTabBar`** and a `UIPageViewController`-powered pager. It keeps tab selection, swipe paging, and indicator progress synchronized.

## Responsibility boundaries

| Component | Owns |
|-----------|------|
| **`FKTabBar`** | Tab strip rendering, indicator animation, selection APIs (UI-only). |
| **`FKPagingController`** | Child view controllers, page caching, swipe transitions, tab↔page sync, page visibility lifecycle. |

`FKPagingController` does **not** replace `UITabBarController` or navigation stacks.

For tab-only demos (progress slider, indicator styles), see [`TabBar/README.md`](../TabBar/README.md).

### Intentionally out of scope

| Capability | Guidance |
|------------|----------|
| Custom non-scroll page transitions | Requires replacing `UIPageViewController`; not supported. |
| Infinite / circular paging | Not supported; use fixed page sets. |
| Vertical paging | Not supported; pairs with horizontal `FKTabBar` headers. |
| Async / throwing page providers | Use lazy mode + host-side loading UI inside each page. |
| `UITabBarController` replacement | Use UIKit tab controller for app-level root tabs. |

---

## Source layout

| Area | Path | Responsibility |
|------|------|----------------|
| Public API | `Public/FKPagingController.swift` | Container VC, selection, content updates, layout, gestures |
| | `Public/FKPagingConfiguration.swift` | Swipe, caching, gate scope, layout, empty state |
| | `Public/FKPagingLayout.swift` | Tab placement, navigation direction, nested scroll, tab height, empty state config |
| | `Public/FKPagingContentChange.swift` | Incremental tab/page mutations |
| | `Public/FKPagingDataSource.swift` | Dynamic tab (+ optional eager page) data source |
| | `Public/FKPagingSwitchReason.swift` | Switch reason, gate scope, reselect behavior |
| | `Public/FKPagingControllerDelegate.swift` | Transition, lifecycle, pending-switch callbacks; SwiftUI callback struct |
| | `Public/SwiftUI/FKPagingControllerRepresentable.swift` | SwiftUI bridge (index or ID binding + callbacks) |
| Internal | `Internal/FKPagingPageStore.swift` | Eager/lazy cache, sync, invalidation, parent detach |
| | `Internal/FKPagingScrollUtilities.swift` | Scroll-to-top, nested horizontal scroll discovery |
| | `Internal/FKPagingTabBarPlacementCoordinator.swift` | Tab strip placement (content / navigation bar / external) |
| | `Internal/FKPagingTabBarCoordinator.swift` | Tab delegate forwarding, gate mapping |
| | `Internal/FKPagingStateMachine.swift` | Phase tracking |

---

## Requirements

- Swift 6 / iOS 15+ (`FKUIKit` target)
- `@MainActor` — call from the main thread only

---

## Quick start

```swift
let pager = FKPagingController(
  tabs: tabs,
  viewControllers: pages,
  selectedIndex: 0,
  tabConfiguration: FKTabBarPresets.pagerHeader(),
  configuration: FKPagingConfiguration()
)
```

Bottom-docked tab strip:

```swift
var config = FKPagingConfiguration()
config.tabBarPlacement = .contentBottom
let pager = FKPagingController(
  tabs: tabs,
  viewControllers: pages,
  tabConfiguration: FKTabBarPresets.bottomDocked(),
  configuration: config
)
```

Navigation-bar tabs (child VC in a navigation stack):

```swift
var config = FKPagingConfiguration()
config.tabBarPlacement = .navigationBar()
config.tabBarHeightPolicy = .fixed(32)
let pager = FKPagingController(
  tabs: tabs,
  viewControllers: pages,
  tabConfiguration: FKTabBarPresets.navigationBarSegmented(),
  configuration: config
)
addChild(pager)
// … embed pager.view …
pager.tabBarNavigationHost = self
```

External tab strip (host lays out ``tabBar``):

```swift
var config = FKPagingConfiguration()
config.tabBarPlacement = .external
let pager = FKPagingController(tabs: tabs, viewControllers: pages, configuration: config)
headerContainer.addSubview(pager.tabBar)
```

---

## Configuration highlights

| Field | Role |
|-------|------|
| `tabBarPlacement` | `.contentTop` / `.contentBottom`, `.navigationBar(...)`, or `.external` |
| `tabBarNavigationHost` (on controller) | Override nav-bar host when placement is `.navigationBar` |
| `isTabBarExternallyManaged` | `true` when placement is `.external` — host must layout ``tabBar`` |
| `allowsSwipePaging` | Enables horizontal swipe via `UIPageViewController` |
| `allowsSwipePagingFrom` | Per settled index — master swipe enable/disable |
| `allowsSwipePagingTo` | Per index **and** ``FKPagingNavigationDirection`` — directional swipe control |
| `nestedHorizontalScrollPolicy` | `.pagerPreferred` or `.preferNestedHorizontalScroll` (see note below) |
| `pageSwitchGate` / `pageSwitchGateScope` | Controlled commit via `commitPageSwitch` |
| `interPageSpacing` | Horizontal gap between pages **during swipe**; **rebuilds** the internal page host when changed at runtime |
| `emptyStateConfiguration` | Placeholder when `pageCount == 0` |
| `evictPagesOnMemoryWarning` | Compact lazy cache on memory warning (default `true`) |
| `gesturePolicy` | Nav pop vs pager pan via `require(toFail:)` |
| `reselectBehavior` | `.scrollPageToTop` uses table/collection/scroll heuristics |

**Nested horizontal scroll:** `.preferNestedHorizontalScroll` walks the settled page subtree and installs `pagingPan.require(toFail: nestedPan)` on each horizontally scrollable view. It does not use hit-testing at touch-down time.

**Inter-page spacing:** The gap appears only while pages are mid-transition (interactive swipe or animated tab switch). A settled page fills the host; compare `0` vs `24` pt while dragging slowly between tabs.

**Controlled gate:** `commitPageSwitch(to:animated:)` does **not** consult `shouldSwitchTo` — call it only after host-side validation.

---

## Content updates

| API | Use |
|-----|-----|
| `setContent(...)` | Full replace (eager or lazy) |
| `applyContentChanges(_:)` | Incremental tab diffs + lazy `invalidatePage` |
| `reloadFromDataSource()` | Refresh from ``FKPagingEagerDataSource`` (tabs + pages) or lazy tab count |
| `invalidatePage(at:replacingWith:)` | Lazy eviction; eager requires `replacingWith` |

After toggling `FKTabBarItem.isHidden`, call `setContent(...)` with visible tabs and matching pages.

---

## Dynamic data source

```swift
final class TabsDataSource: FKPagingEagerDataSource {
  func numberOfPages(in pagingController: FKPagingController) -> Int { items.count }
  func pagingController(_ pagingController: FKPagingController, tabItemAt index: Int) -> FKTabBarItem { items[index] }
  func pagingController(_ pagingController: FKPagingController, viewControllerAt index: Int) -> UIViewController { pages[index] }
}

pager.dataSource = dataSource
pager.reloadFromDataSource()
```

Lazy hosts keep the `pageProvider` from init; ``FKPagingDataSource`` supplies tabs only via `reloadFromDataSource()`.

---

## TabBar integration surface

| TabBar API | Paging access |
|------------|---------------|
| `tabBar` | Direct access for configuration, badges, `reload(items:)` |
| `tabBar.configuration.layout` | `widthMode`, `selectionScrollPosition`, `contentAlignment`, scrollability — see PagingController **Tab bar layout** example |
| `expandedTabItemID` | Forwarded property on ``FKPagingController`` |
| `visibleTabButton(at:)` | Convenience wrapper for popover/menu anchoring |
| `tabBarDelegate` | Forwarded tab callbacks |
| `applyChanges(_:)` | Prefer ``applyContentChanges(_:)`` for coordinated tab/page updates |

---

## Delegate callbacks

| Callback | When |
|----------|------|
| `didUpdateCombinedTransition` | Preferred during drag (tab phase + paging phase + progress) |
| `willDisplayPage` / `didDisplayPage` / `didEndDisplayingPage` | Visible page lifecycle (`didEndDisplaying` only after `didDisplay`) |
| `shouldSwitchTo` | Veto tab, swipe, or programmatic switches (not `commitPageSwitch`) |
| `didRequestPageSwitchTo` | Controlled gate recorded a deferred index |
| `pagingControllerDidCancelPendingPageSwitch` | Pending switch cleared without commit |
| `didSettleAt` | Page index committed |

Public control APIs: ``commitPageSwitch(to:animated:)``, ``cancelPendingPageSwitch()``.

---

## SwiftUI

`FKPagingControllerRepresentable` supports:

- `Binding<Int>` or `Binding<String?>` (stable tab ID) selection
- ``FKPagingControllerRepresentableCallbacks`` for pending index, progress, phase, and lifecycle hooks

Callbacks and binding updates are dispatched asynchronously to avoid publishing during view updates.

---

## Example app

`Examples/.../FKUIKit/PagingController/` — hub sections:

| Section | Scenarios |
|---------|-----------|
| Tab bar placement | Content top, navigation bar titleView, external host layout |
| Basics | Eager sync, tab bar indicators, tab bar layout (width / scroll / alignment) |
| Layout & lifecycle | Content bottom + spacing, empty state, reselect scroll-to-top |
| Configuration & control | Delegate/config, controlled gate (all scopes), ID selection, directional swipe |
| Dynamic content | setContent, sync visible tabs, applyContentChanges, data source |
| Gestures | Nested horizontal scroll |
| Lazy loading | UIKit lazy factory, lifecycle log, invalidatePage |
| SwiftUI | Index binding, lazy provider, ID binding + callbacks |

---

## API checklist

- `FKPagingController`
- `FKPagingConfiguration`, `FKPagingRetentionPolicy`, `FKPagingGesturePolicy`, `FKPagingTabAlignment`, `FKPagingPageSwitchGate`, `FKPagingPageSwitchGateScope`, `FKPagingTabBarHeightPolicy`, `FKPagingReselectBehavior`, `FKPagingTabBarPlacement`, `FKPagingTabBarPosition`, `FKPagingNavigationBarTabOptions`, `FKPagingNavigationDirection`, `FKPagingNestedHorizontalScrollPolicy`, `FKPagingEmptyStateConfiguration`
- `FKPagingContentChange`
- `FKPagingDataSource`, `FKPagingEagerDataSource`
- `FKPagingSwitchReason`
- `FKPagingControllerDelegate`, `FKPagingControllerRepresentableCallbacks`
- `FKPagingPhase`, `FKPagingStateSnapshot`
- `FKPagingControllerRepresentable` (SwiftUI)

---

## License

Same as the enclosing FKKit repository.
