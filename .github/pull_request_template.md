## Summary

<!-- What changed and why (1–3 bullets). -->

-

## Test plan

- [ ] Local verify: `bash scripts/run-tests.sh` (or CI green; same flags as `.github/workflows/ci.yml`)
- [ ] FKKitExamples updated when **public API** changed (if applicable)

## New public API (`Sources/`)

<!-- Required when adding or changing public API. See `docs/TESTING_GUIDE.md` §18.1. -->

- [ ] P0/P1 logic change → tests added or updated under `Tests/FKCoreKitTests/` or `Tests/FKUIKitTests/`
- [ ] Visual-only / P2+ → Examples updated; explain in PR if no automated test

## FKUIKit tests (`@MainActor`)

<!-- Complete when adding or changing `Tests/FKUIKitTests/`. See `docs/TESTING_GUIDE.md` §12.1. -->

- [ ] UI / `@MainActor` test classes use `@MainActor` or inherit `FKUIKitTestCase`
- [ ] No non-Sendable captures in async closures; use locked helpers or MainActor state
- [ ] Logic-only tests stay in plain `XCTestCase` when no UIKit hierarchy is needed

## Bug fix checklist

<!-- Complete when this PR fixes a bug. -->

- [ ] **Regression test added** in `Tests/` (or explain why not — e.g. UI-only, system API)
- [ ] Root cause noted in PR description

## Migration / breaking changes

<!-- API or behavior changes integrators must know. Omit if none. -->

None.
