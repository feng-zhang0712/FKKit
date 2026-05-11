# ListKit

**ListKit** groups list-related **state**, **pagination**, and **plugin** helpers for composite list screens in **FKCompositeKit**. It integrates with **FKUIKit** (empty states, refresh controls, skeleton).

## Highlights

- **`FKListStateManager`** / **`FKListState`**: coordinates loading / empty / error / content phases.
- **`FKListPlugin`**: composition-first coordinator (pagination + refresh + state) **without** subclassing `UIViewController`.
- **`FKPageManager`** / **`FKPageManagerCore`**: page index and request orchestration (`@MainActor`).
- **`FKListPresentationDrivers`**: protocol-driven bridges for skeleton, primary surface, empty state host, and refresh.
- **`FKListScreen`**: adopt on view controllers that retain plugins; use ``detachAllListPlugins()`` from lifecycle.
- **`FKListTableCellConfigurable`** / **`FKListCollectionCellConfigurable`**: lightweight cell binding contracts.
- **`FKListConfiguration`**: unified flags for ``FKListPlugin``.

Type-level documentation lives in the `.swift` files.
