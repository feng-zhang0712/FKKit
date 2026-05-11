# Base (`FKBase*`)

UIKit-first building blocks for composite screens: **inheritance-friendly** base classes and an optional **composition** layer that avoids subclassing when you only need cross-cutting behavior.

All public types in this folder are documented for **`@MainActor`** usage (UIKit alignment).

---

## View controllers

### `FKBaseViewController`

Common lifecycle entry points (`setupUI`, `setupConstraints`, `setupBindings`), keyboard forwarding, navigation bar snapshot/restore, optional loading / empty / error overlays, `FKToast`, and logging hooks.

**First load:** override **`loadInitialContent()`** — runs **once** on the first `viewDidAppear`, **before** **`viewDidAppearForTheFirstTime(_:)`**. Use it to start fetches; use `viewDidAppearForTheFirstTime` for on-screen-only UI (animations).

### `FKBaseTableViewController` / `FKBaseCollectionViewController`

Single primary `UITableView` or `UICollectionView`, pinned to the safe area and **`keyboardLayoutGuide`** (iOS 15+). Optional pull-to-refresh and load-more via **FKUIKit** `fk_addPullToRefresh` / `fk_addLoadMore`.

- Set **`isPullToRefreshEnabled`** / **`isLoadMoreEnabled`** before **`setupBindings()`** runs (e.g. in `init` or early in `viewDidLoad` before `super` chain — preferably set flags in **`init`** or override **`setupBindings`** after **`super.setupBindings()`** if you toggle flags in `viewDidLoad`; simplest is setting properties on the instance before `viewDidLoad`).

Shared footer state: **`FKBaseTableLoadMoreState`** (table and collection base controllers).

### `FKBaseSearchIntegration`

Static helpers to attach or remove a **`UISearchController`** on **`navigationItem`** (`definesPresentationContext`, `hidesNavigationBarDuringPresentation`). Does not replace app-specific search results UI.

---

## Cells

### `FKBaseTableViewCell` / `FKBaseCollectionViewCell`

Shared **`containerView`**, reuse identifiers, card-style chrome, **`prepareForReuse`** → **`resetCellContent()`**, trait and selection hooks.

### `FKBaseReusableCellCore`

Internal layout/shadow helpers shared by both cell bases.

---

## Composition (no base-class inheritance)

When you **cannot** subclass `FKBaseViewController` (e.g. another base class in the app), use:

- **`FKViewControllerComposite`** — bundles keyboard, navigation chrome snapshot, interactive pop gesture, tap-to-dismiss, appearance flags.
- Protocols: **`FKViewControllerBuildPhases`**, **`FKViewControllerCompositeHosting`**, **`FKViewControllerTraitChangeHandling`**.

Forward UIKit callbacks with **`forwardComposite(_:)`** on the hosting type.

See `Composition/FKViewControllerCompositionProtocols.swift` and `FKViewControllerCompositionServices.swift`.

---

## Relationship to **ListKit** (`FKCompositeKit/Components/ListKit`)

| Need | Use |
|------|-----|
| Simple list + optional refresh on a **subclass** of `FKBaseTableViewController` / `FKBaseCollectionViewController` | Base controllers + your own data source |
| Rich **pagination**, skeleton, empty/error overlays, refresh **state machine** without bloating the VC | **`FKListPlugin`** + retain on your view controller (see **`FKListScreen`**) |

**Do not** attach **both** the base controller’s built-in refresh controls **and** a fully wired **`FKListPlugin`** to the same scroll view unless you explicitly disable one path — they would compete for the same header/footer attachments.

---

## Subclassing vs composition

- **Subclass** `FKBase*` when you want a single place for lifecycle + shared chrome.
- **Compose** `FKViewControllerComposite` or **`FKListPlugin`** when you need capabilities without a deep inheritance chain.
