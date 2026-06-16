# FKKit Tests

Automated unit and integration tests for the Swift package (`FKKit-Package` scheme).  
Maintenance policy and contributor workflow: [`docs/TESTING_GUIDE.md`](../docs/TESTING_GUIDE.md) (Chinese).

## Targets

| Target | Module | Path | Tests (approx.) |
|--------|--------|------|-----------------|
| `FKCoreKitTests` | `FKCoreKit` | `Tests/FKCoreKitTests/` | 311 |
| `FKUIKitTests` | `FKUIKit` | `Tests/FKUIKitTests/` | 320 |

## Layout

```
Tests/
├── FKCoreKitTests/
│   ├── Extension/
│   ├── Network/
│   ├── Storage/
│   ├── Security/
│   ├── Async/
│   ├── I18n/
│   ├── QRCode/
│   ├── BusinessKit/
│   ├── FileManager/
│   ├── ImageLoader/
│   ├── Pluggable/
│   ├── Permissions/
│   ├── LocalNotification/
│   ├── BackgroundTask/
│   ├── BiometricAuth/
│   ├── Logger/
│   └── Support/
└── FKUIKitTests/
    ├── ListKit/
    ├── Button/
    ├── Refresh/
    ├── EmptyState/
    ├── PagingController/
    ├── SearchBar/
    ├── SearchViewController/
    ├── Player/
    ├── Toast/
    ├── Alert/
    ├── TextField/
    ├── ProgressBar/
    ├── Skeleton/
    ├── Divider/
    ├── RatingControl/
    ├── ActionSheet/
    ├── Carousel/
    ├── Callout/
    ├── FlowVisualization/
    ├── ImageView/
    ├── PhotoPicker/
    ├── BlurView/
    ├── CornerShadow/
    ├── ExpandableText/
    ├── QRCode/
    ├── SheetPresentationController/
    ├── TabBar/
    ├── WebView/
    ├── Chip/
    ├── Badge/
    ├── Widgets/
    └── Support/
```

## Run locally

```bash
bash scripts/run-tests.sh
bash scripts/run-tests-with-coverage.sh   # optional; not a CI gate
```

## When to add tests

See `docs/TESTING_GUIDE.md` §18 (new public API gate) and §9 (component priority matrix).

- **P0/P1** logic changes → add tests under the matching folder.
- **Bug fixes** → regression test when reproducible without live network/system UI.
- **Visual-only** → update FKKitExamples; snapshot tests are not used ([`docs/TESTING_SNAPSHOT_EVALUATION.md`](../docs/TESTING_SNAPSHOT_EVALUATION.md)).

Test source and assertions are **English**, consistent with library code.

Component bugs found during testing (not test mistakes) are tracked in [`docs/TESTING_COMPONENT_ISSUES.md`](../docs/TESTING_COMPONENT_ISSUES.md).
