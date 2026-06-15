# FKListKit — Version Roadmap

Performance, smoothness, and UX upgrade plan for `FKUIKit/Components/ListKit/`.

**Status:** Living document — tracks v2+ delivery against [FKListKit_DESIGN.md](FKListKit_DESIGN.md).

---

## Goals

1. **Feed-grade smoothness** — load-more without flicker, prefetch on by default for media lists.
2. **Cell lifecycle hooks** — visibility callbacks for video, exposure, and lazy work.
3. **Lighter updates** — `reconfigureItems` for in-place row refresh.
4. **Better first paint** — real skeleton placeholder rows (not overlay-only).
5. **Clear presets** — `FKListDefaults.feedConfiguration` / `settingsConfiguration`.
6. **Do not bloat ListKit** — complex row layouts stay in **FKCellKit** (Phase 6).

---

## Version matrix

| Version | Theme | Priority | Depends on |
|---------|-------|----------|------------|
| **v2** | Performance & UX foundations | P0 | — |
| **v3** | Feed reference & media integration | P1 | v2 |
| **v4** | Parity, platform bridge, scale | P2 | FKCellKit Phase 6 (partial) |

---

## v2 — Performance & UX foundations ✅ (delivered 2026-06-15)

| ID | Item | Rationale |
|----|------|-----------|
| v2-1 | `FKListAnimationConfiguration` | Configurable `defaultRowAnimation`; load-more defaults to no animation |
| v2-2 | `FKListLayoutConfiguration.estimatedRowHeight` | Feed rows need accurate estimates (default 52 → configurable) |
| v2-3 | `FKListDefaults.feedConfiguration` / `settingsConfiguration` | One-line feed vs settings setup |
| v2-4 | `FKListDelegate` `willDisplay` / `didEndDisplaying` | Video pause, exposure, off-screen cancel |
| v2-5 | `FKListSnapshotMutation.reconfigureItems` | Lighter than `reloadItems` for like counts, read state |
| v2-6 | `FKListImagePrefetchHelper` | DRY icon-row prefetch; pairs with `FKImageLoader` |
| v2-7 | `FKListSkeletonPolicy.presetRows` (Table) | Placeholder skeleton cells instead of overlay-only |
| v2-8 | Forward `automaticallyEndsRefreshingOnAsyncCompletion` to FKRefresh | Document ListKit still ends with token guards |
| v2-9 | Examples: feed optimized, visibility, reconfigure, preset skeleton | Full v2 API coverage |

**Non-goals (v2):** Collection swipe, SwiftUI bridge, FKCellKit preset migration.

---

## v3 — Feed reference & media integration ✅ (delivered 2026-06-15)

| ID | Item | Rationale |
|----|------|-----------|
| v3-1 | **Complex Feed Reference Example** | Multi-line text, remote images, reconfigure, visibility, load-more |
| v3-2 | `FKListImagePrefetchHelper` + custom payload protocol | Prefetch from custom cells via opt-in protocol |
| v3-3 | Optional `FKListVideoVisibilityCoordinator` hook | Thin wrapper over `FKVideoFeedPlaybackCoordinator` |
| v3-4 | `presetRows` skeleton for Collection | Collection placeholder cells |
| v3-5 | Height cache helper (`FKListHeightCache`) | Dynamic feed rows without layout thrash |
| v3-6 | `FKSearchViewController` + ListKit integration example | ListKit hub + SearchViewController hub cross-link |
| v3-7 | `animatesRefreshDifferences` policy tuning | `feedConfiguration` defaults refresh to no animation |

---

## v4 — Parity, bridge, scale ✅ (delivered 2026-06-15)

| ID | Item | Rationale |
|----|------|-----------|
| v4-1 | FKCellKit preset mapping (Phase 6) | **Deferred** — FKCellKit not in tree |
| v4-2 | Collection swipe actions UI | Registry wired to collection delegate |
| v4-3 | SwiftUI bridge | `FKDiffable*ViewControllerRepresentable` |
| v4-4 | Long-list windowing / trim policy | `FKListWindowingConfiguration` |
| v4-5 | Drag reorder (optional v4+) | **Deferred** — not requested |
| v4-6 | UITableView Extension diffable conveniences | `fk_applyDiffableDataSourceSnapshot` |

---

## Success criteria

### v2

- [x] `FKListDefaults.feedConfiguration` used in at least one Example
- [x] Load-more append uses `animatesLoadMoreDifferences` (default `false`)
- [x] Delegate visibility hooks demonstrated
- [x] `reconfigureItems` demonstrated without full cell reload flash
- [x] `presetRows` shows skeleton cells on Table initial load
- [x] `xcodebuild FKKit-Package` **BUILD SUCCEEDED**
- [x] FKKitExamples ListKit hub lists new scenarios

### v3

- [x] Complex Feed Reference covers all v2+v3 public APIs used together
- [x] `FKListImagePrefetchProviding` + helper prefetch/cancel
- [x] `FKListVideoVisibilityCoordinator` + scroll forwarding on table/collection
- [x] Collection `presetRows` skeleton cells
- [x] `FKListHeightCache` demonstrated in complex feed
- [x] `FKSearchViewController` integration (`FKListKitSearchViewControllerIntegrationExampleViewController`)
- [x] `feedConfiguration` sets `animatesRefreshDifferences = false`

### v4

- [x] Collection swipe actions wired and demonstrated
- [x] SwiftUI bridge representables delivered
- [x] `FKListWindowingConfiguration` with load-more trim
- [x] Diffable apply convenience on UITableView/UICollectionView
- [ ] FKCellKit Phase 6 preset mapping (deferred — FKCellKit absent)
- [ ] Drag reorder (deferred)

---

## Related

- [FKListKit_DESIGN.md](FKListKit_DESIGN.md)
- [FKCellKit_DESIGN.md](FKCellKit_DESIGN.md) §14.10
- [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §7.1

---

## Revision history

| Date | Change |
|------|--------|
| 2026-06-15 | v3-6 delivered: FKSearchViewController + ListKit integration example |
| 2026-06-15 | v4 delivered: collection swipe, SwiftUI bridge, windowing, diffable helpers |
| 2026-06-15 | v3 delivered: complex feed reference, prefetch protocol, height cache, video coordinator, collection skeleton |
| 2026-06-15 | v2 delivered; initial roadmap |
