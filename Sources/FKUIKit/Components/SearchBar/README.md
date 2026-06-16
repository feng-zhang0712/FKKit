# FKSearchBar & FKSearchField

UIKit search controls built on `UITextField` (not `UISearchBar`): debounced query streaming, clear/cancel affordances, loading state, navigation hosting, and SwiftUI bridges.

| Type | Role |
|------|------|
| **`FKSearchBar`** | Full search bar — icon, field, clear, optional cancel, debounced callbacks, loading |
| **`FKSearchField`** | Compact variant for inline filters — no cancel column |

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit` (depends on `FKCoreKit` / `FKDebouncer`)

## Source layout

| Path | Role |
|------|------|
| `Public/FKSearchBar.swift` | Main `UIControl` — navigation / inline search |
| `Public/FKSearchField.swift` | Compact `UIControl` — embedded filters |
| `Public/FKSearchBarDelegate.swift` | Optional delegate (callbacks take precedence) |
| `Public/FKSearchBarNavigationHosting.swift` | `navigationItem.titleView` helper |
| `Public/FKSearchCallbacks.swift` | Closure-based event handlers |
| `Public/FKSearchTextUpdateOptions.swift` | Programmatic text update options |
| `Public/Configuration/` | Layered `FKSearchBarConfiguration`, `FKSearchFieldConfiguration`, shared nested structs |
| `Public/Models/FKSearchEnums.swift` | Layout styles, cancel/clear policies, normalization, appearance enums |
| `Public/Bridge/` | `FKSearchBarRepresentable`, `FKSearchFieldRepresentable` |
| `Internal/FKSearchControlBase.swift` | Shared chrome, debounce wiring, accessories |
| `Internal/FKSearchInputCoordinator.swift` | `FKDebouncer` + query normalization |
| `Internal/FKSearchLayoutEngine.swift` | RTL layout metrics |
| `Internal/FKSearchChromeView.swift` | Background, blur, border, underline |
| `Internal/FKSearchTextNormalizationApplier.swift` | Trim / collapse / max-length helpers |

## Quick start

```swift
import FKUIKit

// Inline list filter
let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Search")
searchBar.callbacks.onSearchQueryChanged = { query in
  applyFilter(query)
}
view.addSubview(searchBar)

// Navigation title view
let navSearch = FKSearchBar(configuration: FKSearchBarDefaults.navigationBar(), placeholder: "Search")
FKSearchBarNavigationHosting.install(navSearch, in: navigationItem)

// Compact field (no cancel)
let field = FKSearchField(configuration: FKSearchFieldDefaults.compactFilter(), placeholder: "Filter")
field.callbacks.onSearchQueryChanged = { query in applyFilter(query) }
```

## Events

| Callback | When | Debounced? |
|----------|------|------------|
| `onTextChanged` | Every keystroke | No |
| `onSearchQueryChanged` | After debounce idle | Yes |
| `onSubmit` | Return `.search` | No (flushes debounce) |
| `onClear` | Clear tapped | No |
| `onCancel` | Cancel tapped (`FKSearchBar` only) | No |
| `onEditingDidBegin` / `onEditingDidEnd` | Focus changes | No |

Set `configuration.debounce.isDebounceEnabled = false` to pass through queries immediately.

## Configuration

`FKSearchBarConfiguration` groups:

| Member | Role |
|--------|------|
| `layout` | Style preset (`.navigationBar`, `.inlineCard`, `.compactToolbar`, `.minimal`), height, insets |
| `appearance` | Colors, blur/solid chrome, icons, typography, state overrides |
| `textInput` | Keyboard traits, `FKSearchTextNormalization` |
| `debounce` | Interval, enable flag, min query length, flush-on-clear |
| `clearButton` | Visibility, image, accessibility, resign-on-clear |
| `cancelButton` | Visibility, `FKSearchCancelPolicy`, title (`FKSearchBar` only) |
| `loading` | Spinner vs disabled input |
| `submit` | Empty submit, resign on submit |
| `accessibility` | Labels, hints, decorative icon hiding |

`FKSearchFieldConfiguration` is the same minus `cancelButton`.

Presets: `FKSearchBarDefaults.navigationBar()`, `.inlineCard()`; `FKSearchFieldDefaults.compactFilter()`.

Global defaults: mutate `FKSearchBarDefaults.defaultConfiguration` at launch (same pattern as `FKBlur.defaultConfiguration`).

## Advanced

- **`searchBar.textField`** — expose `inputAccessoryView`, keyboard toolbar, etc. Do not enable secure text entry.
- **`setText(_:options:)`** — use `.silent` for SwiftUI binding sync; `.withSearchQuery` to flush debounced path.
- **`setLoading(_:animated:)`** — host-driven async search; cancel remains available during loading.
- Pair with **`FKEmptyStateConfiguration.scenario(.noSearchResult)`** on the filtered table when query is non-empty and results are empty.
- **Recommended (when delivered):** [FKSearchViewController](../../SearchViewController/) — full search page composing SearchBar + ListKit; see [FKSearchViewController_DESIGN.md](../../../../docs/FKSearchViewController_DESIGN.md).

## Examples

Runnable demos: `Examples/FKKitExamples/.../FKUIKit/SearchBar/`

| Hub section | Demonstrates |
|-------------|--------------|
| FKSearchBar | Debounced filter, submit on Return, navigation bar, inline card, loading |
| FKSearchField | Compact embedded filter |
| Behavior & configuration | Cancel policies, playground, delegate log |
| Integration & environment | Table + empty state, SwiftUI bridge, dark / Dynamic Type / RTL |

Entry: **FKKit Examples → FKUIKit → SearchBar**.

## License

MIT — see repository root `LICENSE`.
