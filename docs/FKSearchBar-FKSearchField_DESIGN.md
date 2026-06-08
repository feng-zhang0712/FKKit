# FKSearchBar & FKSearchField — Design Requirements

Implementation guide for FKKit **search input controls**: a configurable **`FKSearchBar`** (`UIControl`-based) and optional compact **`FKSearchField`**, with debounced text events, clear/cancel affordances, and integration with **FKDebouncer**, **FKListKit**, and **FKEmptyState**.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.3  
**中文版本:** [FKSearchBar-FKSearchField_DESIGN.zh-CN.md](FKSearchBar-FKSearchField_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Product Split: FKSearchBar vs FKSearchField](#4-product-split-fksearchbar-vs-fksearchfield)
- [5. Architectural Overview](#5-architectural-overview)
- [6. Visual Styles & Layout Modes](#6-visual-styles--layout-modes)
- [7. Text Input & Keyboard Behavior](#7-text-input--keyboard-behavior)
- [8. Debouncing & Event Model](#8-debouncing--event-model)
- [9. Clear Button — Rules & Behavior](#9-clear-button--rules--behavior)
- [10. Cancel Button — Rules & Behavior](#10-cancel-button--rules--behavior)
- [11. Submit & Return Key](#11-submit--return-key)
- [12. Focus, Editing & Programmatic Text](#12-focus-editing--programmatic-text)
- [13. Loading & Progress States](#13-loading--progress-states)
- [14. Appearance & Theming](#14-appearance--theming)
- [15. Configuration Model](#15-configuration-model)
- [16. Callbacks & Delegate API](#16-callbacks--delegate-api)
- [17. Navigation Bar & Toolbar Hosting](#17-navigation-bar--toolbar-hosting)
- [18. Integration with FKListKit & FKEmptyState](#18-integration-with-fklistkit--fkeemptystate)
- [19. Accessibility](#19-accessibility)
- [20. SwiftUI Bridge](#20-swiftui-bridge)
- [21. Global Defaults](#21-global-defaults)
- [22. Performance & Threading](#22-performance--threading)
- [23. Proposed Source Layout](#23-proposed-source-layout)
- [24. FKKitExamples Scenarios](#24-fkkitexamples-scenarios)
- [26. Open Questions](#26-open-questions)
- [27. Revision History](#27-revision-history)

---

## 1. Executive Summary

Search is one of the highest-frequency UI patterns in iOS apps (ecommerce catalogs, social graphs, settings, messaging). FKKit provides rich **`FKTextField`** for form entry but **no dedicated search control** with:

- Debounced query streaming for list filtering
- Cancel/dismiss editing flow (navigation search pattern)
- Clear affordance visibility rules tuned for search
- Consistent FK visual language in bar and inline placements

This design delivers :

| Type | Role |
|------|------|
| **`FKSearchBar`** | Full-featured search control: leading search icon, text field, clear, optional cancel, debounced callbacks, loading indicator, navigation/inline layouts. |
| **`FKSearchField`** | Compact variant: search icon + field + clear **without** cancel button column — for embedded filters in content areas. |

Both are **`UIControl`** subclasses (or composition root exposing `UIControl` events) built on **`UITextField`**, **not** thin wrappers around **`UISearchBar`**, to preserve FKKit styling flexibility and avoid fighting private `UISearchBar` subviews.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Single control for 90% search UX** — bar search, inline filter, navigation `titleView`.
2. **Built-in debouncing** via **`FKDebouncer`** (`FKCoreKit/Async`) with configurable interval and immediate-preview option.
3. **Explicit event taxonomy** — text changed (raw/debounced), submit, cancel, clear, begin/end editing.
4. **HIG compliance** — 44pt minimum height, Dynamic Type, VoiceOver, Dark Mode, RTL.
5. **Composable** — works standalone, inside `UINavigationItem`, above `FKDiffableTableViewController`, with `FKEmptyState` no-result scenarios.
6. **Do not merge into `FKTextField`** — search-specific cancel semantics and debounce defaults stay isolated.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Voice search / Speech framework | Future optional accessory |
| `UISearchController` wrapper | Host may still use Apple APIs separately |
| Search suggestions dropdown / autocomplete UI | Host or future `FKSearchSuggestions` component |
| Recent searches persistence | Host layer (`FKStorage`) |
| Barcode/QR scanner leading action | Out of scope |
| Scope bar (`UISegmentedControl` under bar) | Phase 2; use `FKSegmentedControl` when available |
| macOS / tvOS | iOS 15+ UIKit |

### 2.3 Success Criteria

- [ ] `FKSearchBar` + `FKSearchField` ship with layered configuration and English docs.
- [ ] Debounced callback fires once after idle period; rapid typing coalesces to one event.
- [ ] Cancel clears text + resigns first responder + fires cancel callback per configuration.
- [ ] Navigation bar embedding example passes layout on iPhone SE and Pro Max, light/dark.
- [ ] SwiftUI `FKSearchBarRepresentable` updates text and config from SwiftUI state.
- [ ] FKKitExamples covers §24 scenarios.

---

## 3. Background & Problem Statement

### 3.1 Why not `FKTextField`?

`FKTextField` optimizes for:

- Validation, formatting, error inline messages, OTP, counters, password toggle
- Form decoration modes (border, underline)

Search needs different defaults:

| Concern | Form (`FKTextField`) | Search (`FKSearchBar`) |
|---------|----------------------|------------------------|
| Autocapitalization | context-dependent | `.none` default |
| Autocorrection | often on | **off** default |
| Return key | `.done` / `.next` | **`.search`** default |
| Trailing affordance | clear while editing | clear + **cancel column** |
| Text change rate | every keystroke OK | **debounced** for network/filter |
| Cancel semantics | N/A | dismiss keyboard + optional revert text |

Merging would bloat `FKTextFieldConfiguration` and confuse integrators.

### 3.2 Why not wrap `UISearchBar`?

- Limited styling of internal subviews across iOS versions
- Harder to align with `FKButton` / `FKCornerShadow` / material blur patterns
- `UISearchBar` delegate model less flexible for dual raw/debounced streams

FKKit builds on **`UITextField`** inside a styled container — same strategy as many production apps.

### 3.3 Existing reuse points

| API | Module | Use in search |
|-----|--------|---------------|
| `FKDebouncer` | FKAsync | Debounced textChanged |
| `FKTextFieldClearButtonConfiguration` patterns | FKUIKit | Clear button a11y/copy |
| `FKCornerShadow` / `FKBlurView` | FKUIKit | Optional bar background |
| `FKUIKitI18n` | FKUIKit | Cancel/clear/search hints |
| `FKEmptyStateConfiguration.scenario(.noSearchResult)` | FKUIKit | Document pairing |

---

## 4. Product Split: FKSearchBar vs FKSearchField

### 4.1 FKSearchBar

**Primary control** — superset feature set.

| Element | Included |
|---------|----------|
| Leading search icon | Yes (configurable/hidden) |
| `UITextField` | Yes |
| Clear button | Yes |
| Cancel button | Yes (visibility configurable) |
| Loading indicator | Yes (optional trailing) |
| Debounced + raw events | Yes |
| Navigation layout helper | Yes |

### 4.2 FKSearchField

**Compact control** — subset for toolbars, filter rows, card headers.

| Element | Included |
|---------|----------|
| Leading search icon | Yes |
| Text field | Yes |
| Clear button | Yes |
| Cancel button | **No** (use clear to reset) |
| Loading indicator | Optional |
| Debounced events | Yes |

**Implementation note:** `FKSearchField` may share `FKSearchBarInputEngine` internal type; public types remain distinct for API clarity.

### 4.3 Naming in docs

- Use **`FKSearchBar`** when describing navigation search or cancel flow.
- Use **`FKSearchField`** for inline/filter-only placements.
- Roadmap title **FKSearchBar / FKSearchField** reflects both public types in one module folder `SearchBar/`.

---

## 5. Architectural Overview

```text
┌─────────────────────────────────────────────────────────────┐
│ FKSearchBar (UIControl, @MainActor)                         │
│  ┌──────────┐ ┌─────────────────────┐ ┌───────┐ ┌────────┐ │
│  │ Search   │ │ UITextField         │ │ Clear │ │ Cancel │ │
│  │ icon     │ │ (delegate forward)  │ │ btn   │ │ btn    │ │
│  └──────────┘ └─────────────────────┘ └───────┘ └────────┘ │
│         │               │                  │         │      │
│         └───────────────┴──────────────────┴─────────┘      │
│                         │                                     │
│              FKSearchInputCoordinator                         │
│                · FKDebouncer                                  │
│                · event gating (programmatic set)              │
│                · loading state                                │
└─────────────────────────────────────────────────────────────┘
                             │
              debounced / raw / submit / cancel / clear
                             ▼
                    Host (filter list, API, FKListKit)
```

---

## 6. Visual Styles & Layout Modes

### 6.1 Layout presets (`FKSearchBarLayoutStyle`)

| Preset | Description | Typical placement |
|--------|-------------|-------------------|
| `.navigationBar` | Expands when active; cancel appears on focus | `navigationItem.titleView` |
| `.inlineCard` | Full-width rounded rect, fixed height | Below nav, above table |
| `.compactToolbar` | Shorter height, tight insets | Toolbars, bottom sheets |
| `.minimal` | No outer chrome; underline optional | Dense admin UIs |

### 6.2 Structural layout (FKSearchBar)

```text
[ HStack: leadingIcon | textField (flex) | loading? | clear? | cancel? ]
```

**Must support:**

| Capability | Requirement |
|------------|-------------|
| Minimum height | **44pt** touch target for bar; field tap area inclusive |
| Horizontal insets | Configurable content padding |
| Capsule corner | Default `cornerRadius = height/2` for `.inlineCard` |
| Icon spacing | 8pt between icon and field (configurable) |
| Cancel width | Intrinsic title width + padding; supports localization |
| Intrinsic width in nav | Compresses gracefully; text field truncates with tail ellipsis |

### 6.3 FKSearchField layout

```text
[ HStack: leadingIcon | textField (flex) | loading? | clear? ]
```

Same height rules; no cancel column.

### 6.4 RTL

**Must** mirror leading/trailing icons and cancel placement using `directionalLayoutMargins` / `UISemanticContentAttribute`. Search icon on trailing side in RTL.

### 6.5 Safe area & width

Document recommended Auto Layout:

- Inline: leading/trailing to safe area or readable content guide
- Navigation: width ≤ available `titleView` width; use `sizeToFit()` helper

---

## 7. Text Input & Keyboard Behavior

### 7.1 UITextField defaults (normative)

| Trait | FKSearchBar default | FKSearchField default |
|-------|---------------------|----------------------|
| `autocorrectionType` | `.no` | `.no` |
| `autocapitalizationType` | `.none` | `.none` |
| `spellCheckingType` | `.no` | `.no` |
| `smartQuotesType` | `.no` | `.no` |
| `smartDashesType` | `.no` | `.no` |
| `returnKeyType` | `.search` | `.search` |
| `textContentType` | nil (or `.nickname` opt-in) | nil |
| `keyboardType` | `.default` | `.default` |
| `clearButtonMode` | `.never` (custom clear) | `.never` |

All overridable via `FKSearchTextInputTraitsConfiguration`.

### 7.2 Allowed character policies

```swift
public enum FKSearchTextNormalization: Sendable, Equatable {
  case none
  case trimWhitespaceAndNewlines        // on submit/debounce emit
  case collapseInternalWhitespace     // optional aggressive
  case maxLength(Int)
}
```

Apply normalization **before** debounced emit and submit when configured.

### 7.3 Password / secure entry

**Not supported** — search controls reject `isSecureTextEntry = true` (debug assert).

---

## 8. Debouncing & Event Model

### 8.1 FKDebouncer integration

Internal coordinator owns:

```swift
private let debouncer: FKDebouncer
```

Configuration:

| Field | Default | Purpose |
|-------|---------|---------|
| `debounceInterval` | `0.35` seconds | Quiet period |
| `isDebounceEnabled` | `true` | Pass-through when false |
| `debounceQueue` | `.main` | FKDebouncer queue |

### 8.2 Event channels

| Event | When fired | Debounced? |
|-------|------------|------------|
| **`textChanged`** (raw) | Every `editingChanged` | No |
| **`searchQueryChanged`** | After debounce idle | Yes |
| **`submit`** | Return `.search` | No (immediate) |
| **`clear`** | Clear tapped | No |
| **`cancel`** | Cancel tapped | No |
| **`editingDidBegin`** | Became first responder | No |
| **`editingDidEnd`** | Resigned | No |

Public API shape:

```swift
public struct FKSearchBarCallbacks {
  public var onTextChanged: (@MainActor (String) -> Void)?
  public var onSearchQueryChanged: (@MainActor (String) -> Void)?
  public var onSubmit: (@MainActor (String) -> Void)?
  public var onClear: (@MainActor () -> Void)?
  public var onCancel: (@MainActor () -> Void)?
  public var onEditingDidBegin: (@MainActor () -> Void)?
  public var onEditingDidEnd: (@MainActor () -> Void)?
}
```

### 8.3 Coalescing rules

**Must:**

- Each keystroke schedules debouncer; prior pending work cancelled (`FKDebouncer.signal`).
- On `deinit`, cancel pending debounce.
- Programmatic text set with `options: .suppressEvents` skips raw + debounced.
- Clear button: emit raw immediately with `""`; debouncer receives final empty after interval OR flush immediately (config `flushDebounceOnClear`, default **true**).

### 8.4 Minimum query length

Optional `minimumQueryLengthForSearchCallback` (default **0**):

- Shorter queries still fire `textChanged` but skip `searchQueryChanged` until length met.
- Document for hosts avoiding 1-char API calls.

---

## 9. Clear Button — Rules & Behavior

### 9.1 Visibility modes (`FKSearchClearButtonVisibility`)

| Mode | Visible when |
|------|--------------|
| `.whileEditingNonEmpty` | First responder AND text not empty (**default**) |
| `.whileNonEmpty` | Any time text non-empty |
| `.never` | Hidden (host handles reset) |
| `.alwaysWhenNonEmpty` | Same as whileNonEmpty (alias) |

### 9.2 Interaction

**Must on tap:**

1. Set text to `""` without animation flicker.
2. Fire `onClear`.
3. Fire raw `textChanged("")`.
4. Flush debounced callback per §8.3.
5. Optionally keep first responder (config `clearResignsFirstResponder`, default **false**).
6. Announce VoiceOver "cleared" if configured.

### 9.3 Appearance

Reuse patterns from `FKTextFieldClearButtonConfiguration`:

- Default SF Symbol `xmark.circle.fill`
- Tint from appearance config
- Minimum 44×44pt hit area (content insets)
- Custom image + accessibility label via i18n key `fkuikit.search.clear_label`

---

## 10. Cancel Button — Rules & Behavior

*(FKSearchBar only)*

### 10.1 Visibility modes (`FKSearchCancelButtonVisibility`)

| Mode | Behavior |
|------|----------|
| `.whileEditing` | Hidden until `editingDidBegin`; visible while first responder (**default** for `.navigationBar`) |
| `.always` | Always visible when enabled in config |
| `.never` | Hidden — inline/filter mode |

### 10.2 Interaction

**Must on tap:**

1. Fire `onCancel`.
2. Apply cancel policy (`FKSearchCancelPolicy`):
   - `.clearAndResign` — clear text + resign (**default navigation**)
   - `.resignOnly` — keep text, resign
   - `.revertAndResign` — restore `textAtEditingBegin` snapshot + resign
3. Hide cancel if mode `.whileEditing`.
4. Cancel debouncer pending work.

### 10.3 Title

- Default title from `FKUIKitI18n.string("fkuikit.common.cancel")`.
- Configurable `cancelButtonTitle`.
- Styled as plain text button (not `FKButton` required v1 — UIButton type `.system` OK if matches FK typography).

### 10.4 Animation

When cancel appears/disappears in navigation layout:

- Animate width constraint changes (0.25s ease) unless Reduce Motion → instant.

---

## 11. Submit & Return Key

### 11.1 Return key `.search`

**Must on primary action:**

1. Normalize text per §7.2.
2. Fire `onSubmit(normalizedText)`.
3. Fire immediate `onSearchQueryChanged` with final query (**flush debounce**).
4. Optionally resign first responder (`submitResignsFirstResponder`, default **false** for filter UX, **true** optional for directory-style search).

### 11.2 Empty submit

When text empty after normalization:

- Still fire submit if config `allowsEmptySubmit` (default false).
- Otherwise ignore.

---

## 12. Focus, Editing & Programmatic Text

### 12.1 Public API

```swift
public var text: String { get set }
public var isEditing: Bool { get }
@discardableResult public func becomeFirstResponder() -> Bool
@discardableResult public func resignFirstResponder() -> Bool
public func setText(_ text: String, options: FKSearchTextUpdateOptions)
```

```swift
public struct FKSearchTextUpdateOptions: Sendable, Equatable {
  public var suppressEvents: Bool
  public var triggerSearchQueryChanged: Bool  // flush debounced path
}
```

### 12.2 Editing snapshot

Store `textAtEditingBegin` on `editingDidBegin` for `.revertAndResign` cancel policy.

### 12.3 UIControl events

Expose standard control events where applicable:

- `.editingDidBegin` / `.editingDidEnd` mapped to `UIControl.Event` extensions or documented callbacks only (prefer callbacks + optional `addAction` for iOS 14+).

---

## 13. Loading & Progress States

### 13.1 When to show

Configuration `FKSearchLoadingPresentation`:

| Mode | UI |
|------|-----|
| `.none` | Default |
| `.activityIndicator` | Small spinner trailing, hides clear while loading |
| `.disabledInput` | Field disabled + spinner |

Host calls:

```swift
func setLoading(_ isLoading: Bool, animated: Bool)
```

### 13.2 Behavior during loading

- Text entry may remain enabled (default) or disabled per config.
- Submit/clear policies documented when loading.
- Loading does not block cancel button (user can abort search).

---

## 14. Appearance & Theming

### 14.1 Layered appearance config

```swift
public struct FKSearchBarAppearanceConfiguration: Sendable, Equatable {
  public var backgroundColor: UIColor
  public var backgroundMaterial: FKSearchBackgroundMaterial  // none, blur(FKBlurConfiguration), solid
  public var cornerStyle: FKSearchCornerStyle
  public var border: FKSearchBorderStyle?
  public var leadingIcon: FKSearchIconConfiguration
  public var textStyle: FKSearchTextStyle
  public var placeholderStyle: FKSearchPlaceholderStyle
  public var tintColor: UIColor
  public var cancelTitleStyle: FKSearchCancelTitleStyle
}
```

### 14.2 States

Support visual states:

| State | Appearance delta |
|-------|------------------|
| Normal | Base chrome |
| Focused | Stronger border/tint optional |
| Disabled | Reduced contrast |
| Loading | Spinner visible |

Use `FKSearchBarStateAppearance` overrides similar to `FKButtonStateAppearances` (normal/focused/disabled).

### 14.3 Dark Mode

Semantic colors:

- Default background `.secondarySystemBackground` or `.tertiarySystemFill` for inline card
- Placeholder `.placeholderText`
- Cover light/dark in Examples

### 14.4 Dynamic Type

- Text field font scales with `UIFontMetrics` from configuration base font (default `body`).
- Bar height **may grow** with Dynamic Type XL+ (config `growsWithDynamicType`, default **true**); maintain min 44pt.

---

## 15. Configuration Model

```swift
public struct FKSearchBarConfiguration: Sendable, Equatable {
  public var layout: FKSearchBarLayoutConfiguration
  public var appearance: FKSearchBarAppearanceConfiguration
  public var textInput: FKSearchTextInputTraitsConfiguration
  public var debounce: FKSearchDebounceConfiguration
  public var clearButton: FKSearchClearButtonConfiguration
  public var cancelButton: FKSearchCancelButtonConfiguration
  public var loading: FKSearchLoadingConfiguration
  public var submit: FKSearchSubmitConfiguration
  public var accessibility: FKSearchAccessibilityConfiguration
}

public enum FKSearchBarDefaults {
  public static var defaultConfiguration: FKSearchBarConfiguration
  public static func navigationBar() -> FKSearchBarConfiguration
  public static func inlineCard() -> FKSearchBarConfiguration
}
```

`FKSearchFieldConfiguration` — same minus `cancelButton`; shared nested types in `SearchBar/Shared/`.

Apply:

```swift
public func apply(_ configuration: FKSearchBarConfiguration)
public func apply(_ block: (inout FKSearchBarConfiguration) -> Void)
```

---

## 16. Callbacks & Delegate API

Optional delegate mirror for ObjC-friendly hosts:

```swift
@MainActor
public protocol FKSearchBarDelegate: AnyObject {
  func searchBar(_ searchBar: FKSearchBar, textDidChange text: String)
  func searchBar(_ searchBar: FKSearchBar, searchQueryDidChange query: String)
  func searchBarSearchButtonClicked(_ searchBar: FKSearchBar)
  func searchBarCancelButtonClicked(_ searchBar: FKSearchBar)
  func searchBarClearButtonClicked(_ searchBar: FKSearchBar)
  func searchBarTextDidBeginEditing(_ searchBar: FKSearchBar)
  func searchBarTextDidEndEditing(_ searchBar: FKSearchBar)
}
```

All methods optional via extension defaults. **`callbacks` struct and delegate must not double-fire** — if both set, document precedence: delegate wins OR callbacks only (pick **callbacks primary, delegate optional** — recommend callbacks for Swift, delegate for compatibility).

---

## 17. Navigation Bar & Toolbar Hosting

### 17.1 Helper API

```swift
public enum FKSearchBarNavigationHosting {
  @MainActor
  public static func install(
    _ searchBar: FKSearchBar,
    in navigationItem: UINavigationItem,
    placeholder: String? = nil
  )
}
```

**Must:**

- Assign `navigationItem.titleView = searchBar` with proper `sizeThatFits`.
- Document width constraint: `searchBar.widthAnchor ≤ navigationBar.width * 0.95` pattern in README.

### 17.2 Large title compatibility

When `prefersLargeTitles == true`:

- Document pattern: search bar in `navigationItem.searchController`-free zone — use table header or `UINavigationItem.titleView` below large title collapse (Examples demonstrate inline below nav).

### 17.3 Toolbar

`FKSearchField` fits `UIToolbar` custom items or stack in `inputAccessoryView` for filter sheets.

---

## 18. Integration with FKListKit & FKEmptyState

### 18.1 FKListKit filter flow (normative recipe)

```swift
searchBar.callbacks.onSearchQueryChanged = { [weak listVC] query in
  let filtered = Self.filter(allItems, query: query)
  listVC?.applySnapshot(filteredSnapshot(filtered), animatingDifferences: true)
}
```

When query non-empty and filtered empty → `FKEmptyStateConfiguration.scenario(.noSearchResult)`.

FKListKit §20 references this component — Examples **`SearchFilter`** joint demo.

### 18.2 FKEmptyState

Search module **does not** embed empty state internally — host drives overlay on table. Document in README.

### 18.3 FKDebouncer-only usage

Hosts may disable built-in debounce and use raw `textChanged` with external debouncer — config flag documented.

---

## 19. Accessibility

**Must:**

| Element | Requirement |
|---------|-------------|
| Text field | `accessibilityLabel` from placeholder or explicit config |
| Search icon | Decorative → hidden from VO OR included in label |
| Clear | `accessibilityLabel` "Clear text" localized |
| Cancel | `accessibilityLabel` "Cancel" localized |
| Loading | `accessibilityNotify` announcement optional on start/end |
| Traits | Search field `.searchField` when available (iOS 13+) |

**Keyboard:** Full keyboard navigation not required v1; VoiceOver double-tap activates buttons.

**Reduce Motion:** Cancel show/hide instant (§10.4).

---

## 20. SwiftUI Bridge

Ship **`FKSearchBarRepresentable`** and **`FKSearchFieldRepresentable`**:

```swift
public struct FKSearchBarRepresentable: UIViewRepresentable {
  public var text: Binding<String>
  public var configuration: FKSearchBarConfiguration
  public var isLoading: Bool
  public var onSearchQueryChanged: ((String) -> Void)?
  public var onSubmit: ((String) -> Void)?
}
```

**Must:**

- `updateUIView` syncs text binding without event loops (`suppressEvents` on programmatic sync from SwiftUI).
- Loading flag maps to `setLoading`.
- Optional two-way binding for `isEditing` (advanced).

---

## 21. Global Defaults

```swift
public enum FKSearchBarDefaults {
  public static var defaultConfiguration: FKSearchBarConfiguration
}
```

App launch mutation pattern (match `FKBlurView.defaultConfiguration`):

```swift
FKSearchBarDefaults.defaultConfiguration.debounce.debounceInterval = 0.5
```

---

## 22. Performance & Threading

| Rule | Requirement |
|------|-------------|
| UI | `@MainActor` public API |
| Debouncer | `FKDebouncer` on main queue default |
| Callbacks | All on main actor |
| Heavy filter | Host responsibility — not on main for 10k+ items; document background filter + main snapshot apply |

---

## 23. Proposed Source Layout

```text
Sources/FKUIKit/Components/SearchBar/
├── README.md
├── Public/
│   ├── FKSearchBar.swift
│   ├── FKSearchField.swift
│   ├── FKSearchBarState.swift
│   ├── Configuration/
│   │   ├── FKSearchBarConfiguration.swift
│   │   ├── FKSearchBarAppearanceConfiguration.swift
│   │   ├── FKSearchDebounceConfiguration.swift
│   │   ├── FKSearchClearButtonConfiguration.swift
│   │   ├── FKSearchCancelButtonConfiguration.swift
│   │   └── FKSearchFieldConfiguration.swift
│   ├── Callbacks/
│   │   └── FKSearchBarCallbacks.swift
│   ├── Protocols/
│   │   └── FKSearchBarDelegate.swift
│   ├── Hosting/
│   │   └── FKSearchBarNavigationHosting.swift
│   └── Bridge/
│       ├── FKSearchBarRepresentable.swift
│       └── FKSearchFieldRepresentable.swift
├── Internal/
│   ├── FKSearchInputCoordinator.swift
│   ├── FKSearchBarLayoutEngine.swift
│   └── FKSearchBarChromeView.swift
└── Extension/
    └── FKSearchBar+Convenience.swift
```

Add `Components/SearchBar` to `Package.swift` `readmeExcludes`.

---

## 24. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/SearchBar/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `DebouncedFilter` | Live list filter + debounce interval toggle |
| 2 | `SubmitOnReturn` | Return key submit + optional resign |
| 3 | `NavigationBarSearch` | titleView + cancel while editing |
| 4 | `InlineCard` | Rounded inline above table |
| 5 | `FKSearchFieldCompact` | Compact field without cancel |
| 6 | `LoadingSearch` | `setLoading` during async API |
| 7 | `EmptyNoResults` | With FKEmptyState `.noSearchResult` |
| 8 | `FKListKitIntegration` | FKDiffableTableViewController filter |
| 9 | `SwiftUIHost` | Representable + Binding |
| 10 | `DarkDynamicType` | Dark mode + large content size |

---

## 26. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Single folder `SearchBar/` vs `Search/`? | `SearchBar/` matches type name |
| Q2 | Callbacks vs delegate only? | Both; callbacks primary |
| Q3 | Use `FKButton` for cancel/clear? | v1 UIButton; migrate to FKButton for visual parity later |
| Q4 | Built-in recent queries UI? | Defer |
| Q5 | `UISearchTextField` private API avoidance? | Public UITextField only |

---

## 27. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §1.3 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKListKit_DESIGN.md](FKListKit_DESIGN.md) — list filter integration
- [TextField README](../Sources/FKUIKit/Components/TextField/README.md)
- [FKAsync Debouncer](../Sources/FKCoreKit/Components/Async/DebounceThrottle/Debouncer.swift)
