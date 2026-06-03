# FKPagingController — Breaking upgrade guide (navigation-bar placement)

> **Temporary document** for this refactor cycle. Remove or archive after Examples/migration notes ship.

## Goals

1. **Navigation-bar placement** — host tab strip in `UINavigationItem.titleView` while keeping full pager sync.
2. **External placement** — host owns tab strip layout (toolbar, custom header, split view chrome).
3. **Preserve** all existing paging behavior: swipe, gate, lazy/eager, delegate, SwiftUI bridge, nested scroll, empty state, etc.
4. **Breaking API** — replace `FKPagingConfiguration.tabBarPosition` with `tabBarPlacement`.

---

## API changes (breaking)

| Before | After |
|--------|--------|
| `config.tabBarPosition = .top` | `config.tabBarPlacement = .contentArea(.top)` or `.contentTop` |
| `config.tabBarPosition = .bottom` | `config.tabBarPlacement = .contentArea(.bottom)` or `.contentBottom` |
| (none) | `config.tabBarPlacement = .navigationBar()` |
| (none) | `config.tabBarPlacement = .external` |
| (none) | `pager.tabBarNavigationHost = parentVC` (optional override) |

### New types

| Type | Role |
|------|------|
| `FKPagingTabBarPlacement` | `.contentArea(FKPagingTabBarPosition)`, `.navigationBar(FKPagingNavigationBarTabOptions)`, `.external` |
| `FKPagingNavigationBarTabOptions` | Title-view insets, preferred height, host title suppression |
| `FKTabBarPresets.navigationBarSegmented()` | Compact equal-width strip for titleView |

### New `FKPagingController` members

| Member | Role |
|--------|------|
| `tabBarNavigationHost` | Weak override for navigation-bar host resolution |
| `tabBarPlacement` | Read-only mirror of configuration |
| `isTabBarExternallyManaged` | `true` when placement is `.external` |

### Host resolution (`.navigationBar`)

1. `tabBarNavigationHost` if set.
2. Else `parent` when `parent.navigationController != nil`.
3. Else `self` when embedded directly in a navigation stack.

---

## Layout rules by placement

### `.contentArea(.top | .bottom)`

Unchanged from pre-refactor:

- Tab strip inside `FKPagingController.view`, pinned to safe area top/bottom.
- Page host fills remaining space.
- Height from `tabBarHeightPolicy`.

### `.navigationBar(options)`

- Remove tab strip from paging view hierarchy.
- Assign `tabBar` to resolved host’s `navigationItem.titleView`.
- Page host top = `view.safeAreaLayoutGuide.top` (full content below nav bar).
- Width constraint: `host.view.bounds.width - 2 * horizontalInset`, updated on layout.
- Height: `options.preferredHeight` (clamped 28…44) or intrinsic when `tabBarHeightPolicy == .automatic`.
- When `suppressesHostTitle == true`, save/restore `navigationItem.title` while active.

**Lifecycle:** Re-apply on `viewWillAppear`, `didMove(toParent:)`, and configuration changes. Restore titleView/title on `viewWillDisappear` when this controller installed them.

### `.external`

- Paging controller does **not** add `tabBar` to its view or navigation item.
- Host must add `pager.tabBar` to their hierarchy and constrain it.
- Page host fills safe area (same geometry as top content placement without strip).
- `isTabBarExternallyManaged == true`.

---

## Internal architecture

| File | Responsibility |
|------|----------------|
| `Internal/FKPagingTabBarPlacementCoordinator.swift` | Placement install/teardown, constraints, nav titleView snapshot restore |
| `Public/FKPagingLayout.swift` | `FKPagingTabBarPlacement`, `FKPagingNavigationBarTabOptions` |
| `Public/FKPagingConfiguration.swift` | `tabBarPlacement` replaces `tabBarPosition` |
| `Public/FKPagingController.swift` | Delegates layout to coordinator; lifecycle hooks |

---

## Implementation checklist

- [x] Add placement types and configuration field
- [x] Add `FKTabBarPresets.navigationBarSegmented()`
- [x] Implement placement coordinator
- [x] Wire `FKPagingController` lifecycle + `applyConfiguration`
- [x] Update component `README.md`
- [x] FKKitExamples scenarios + hub (Tab bar placement section + `tabBarPlacement` migration)
- [ ] Unit/UI tests (deferred)

---

## Integrator migration snippets

```swift
// Bottom docked (unchanged behavior)
var config = FKPagingConfiguration()
config.tabBarPlacement = .contentBottom

// Navigation bar tabs
var config = FKPagingConfiguration()
config.tabBarPlacement = .navigationBar()
config.tabBarHeightPolicy = .fixed(32)
let pager = FKPagingController(..., tabConfiguration: FKTabBarPresets.navigationBarSegmented(), configuration: config)
addChild(pager)
pager.tabBarNavigationHost = self  // when pager is a child VC
```

```swift
// External strip (host layout)
var config = FKPagingConfiguration()
config.tabBarPlacement = .external
let pager = FKPagingController(...)
headerStack.addArrangedSubview(pager.tabBar)
```

---

## Out of scope (this cycle)

- Large-title collapse / scroll-edge tab pinning
- `UISegmentedControl` wrapper (use `FKTabBar` + preset)
- Replacing `UIPageViewController` transition style

---

## Verify

```bash
xcodebuild -scheme FKKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/DerivedData-FKKit \
  CODE_SIGNING_ALLOWED=NO SWIFT_STRICT_CONCURRENCY=complete build
```
