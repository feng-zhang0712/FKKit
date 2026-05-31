# FKPagingController

`FKPagingController` is a UIKit container that embeds **`FKTabBar`** above a `UIPageViewController`-powered pager. It keeps tab selection, swipe paging, and indicator progress synchronized.

## Responsibility boundaries

| Component | Owns |
|-----------|------|
| **`FKTabBar`** | Tab strip rendering, indicator animation, selection APIs (UI-only). |
| **`FKPagingController`** | Child view controllers, page caching, swipe transitions, tab↔page sync. |

`FKPagingController` does **not** replace `UITabBarController` or navigation stacks. It does **not** support `FKTabBarDataSource` — supply tabs through `setContent` or `tabBar.reload(items:)`.

For tab-only demos (progress slider, indicator styles), see [`TabBar/README.md`](../TabBar/README.md).

---

## Source layout

| Area | Path | Responsibility |
|------|------|----------------|
| Public API | `Public/FKPagingController.swift` | Container VC, content updates, programmatic selection |
| | `Public/FKPagingConfiguration.swift` | Swipe, caching, gesture, tab alignment, page switch gate |
| | `Public/FKPagingTabBarHeightPolicy.swift` | Tab bar height policy + `FKPagingPageSwitchGate` |
| | `Public/FKPagingState.swift` | `FKPagingPhase`, `FKPagingStateSnapshot` |
| | `Public/FKPagingControllerDelegate.swift` | Transition/progress callbacks |
| | `Public/SwiftUI/FKPagingControllerRepresentable.swift` | SwiftUI bridge with structural diff |
| Internal | `Internal/FKPagingTabBarCoordinator.swift` | Forwards `FKTabBarDelegate`, maps gate → `selectionControlMode` |
| | `Internal/FKPagingPageStore.swift` | Eager/lazy VC cache, preload, retention |
| | `Internal/FKPagingStateMachine.swift` | Drag/settle/programmatic phase tracking |

---

## Requirements

- Swift 6 / iOS 15+ (`FKUIKit` target)
- `@MainActor` — call from the main thread only

---

## Quick start

```swift
let tabs: [FKTabBarItem] = /* your items */
let pages: [UIViewController] = [home, explore, profile]

let pager = FKPagingController(
  tabs: tabs,
  viewControllers: pages,
  selectedIndex: 0,
  tabConfiguration: FKTabBarPresets.pagerHeader(),
  configuration: FKPagingConfiguration()
)
addChild(pager)
// layout pager.view …
pager.didMove(toParent: self)
```

Lazy pages (large tab sets):

```swift
let pager = FKPagingController(
  tabs: tabs,
  pageCount: tabs.count,
  pageProvider: { index in DemoPage(index: index) },
  tabConfiguration: FKTabBarPresets.pagerHeader()
)
```

---

## Configuration highlights

| Field | Role |
|-------|------|
| `allowsSwipePaging` | Enables horizontal swipe via `UIPageViewController` |
| `pageSwitchGate` | `.immediate` (default) or `.controlled` (commit via `commitPageSwitch`) |
| `tabBarHeightPolicy` | `.fixed(_:)` or `.automatic` from `tabBar.intrinsicContentSize` |
| `preloadRange` / `retentionPolicy` | Lazy page warm-up and cache eviction |
| `gesturePolicy` | Navigation pop vs pager pan arbitration |
| `tabAlignment` | Optional override to center selected tab after settle |

### Gate naming (TabBar ↔ Paging)

| Paging | TabBar |
|--------|--------|
| `FKPagingConfiguration.pageSwitchGate = .controlled` | `tabBar.selectionControlMode = .controlled` |
| `commitPageSwitch(to:animated:)` | Host commits after `didRequestSelection` |

The internal coordinator maps these automatically; hosts using `tabBarDelegate` still receive forwarded tab events.

---

## Content updates

Use `setContent(tabs:viewControllers:selectedIndex:)` or the lazy overload when tabs or pages change at runtime.

`syncPagesWithVisibleTabs(...)` is a **semantic alias** for `setContent` after toggling `FKTabBarItem.isHidden` — pass the full tab array; visible page count is derived automatically.

Runtime tab appearance: mutate `pager.tabBar.configuration` or call `tabBar.applyConfiguration(_:animated:)`.

---

## Delegate callbacks

| Callback | When |
|----------|------|
| `didChangePhase` | Paging phase changes (`idle`, `dragging`, `settling`, …) |
| `didUpdateCombinedTransition` | Tab `switchPhase` + paging phase + normalized progress (preferred for coordinated UI) |
| `didUpdateProgress` | Fractional swipe progress only (legacy-friendly) |
| `didSettleAt` | Page index committed |

During drag, prefer **`didUpdateCombinedTransition`** — it already includes progress and both phase domains.

---

## SwiftUI

`FKPagingControllerRepresentable` wraps the UIKit container with binding-driven tab/page updates. See `Public/SwiftUI/FKPagingControllerRepresentable.swift`.

---

## Example app

`Examples/.../FKUIKit/PagingController/`:

- `FKPagingControllerExamplesHubViewController.swift` — hub (Basics, indicators, delegate/config, controlled gate, dynamic content, lazy, SwiftUI)
- `Support/FKPagingDemoPages.swift` — shared demo pages + `embedFullScreen` helper

---

## API checklist

- `FKPagingController`
- `FKPagingConfiguration`, `FKPagingRetentionPolicy`, `FKPagingGesturePolicy`, `FKPagingTabAlignment`, `FKPagingPageSwitchGate`, `FKPagingTabBarHeightPolicy`
- `FKPagingControllerDelegate`
- `FKPagingPhase`, `FKPagingStateSnapshot`
- `FKPagingControllerRepresentable` (SwiftUI)

---

## License

Same as the enclosing FKKit repository.
