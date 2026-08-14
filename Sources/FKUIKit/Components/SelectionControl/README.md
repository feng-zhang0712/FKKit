# FKSelectionControl

Discrete selection controls for forms and lists: **`FKCheckbox`** (multi-select, three-state), **`FKRadioButton`** (single circular indicator), **`FKRadioGroup`** (mutually exclusive options with optional card chrome), and **`FKSelectionListChrome`** (rounded card + separators for checkbox lists).

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

| Path | Role |
|------|------|
| `Public/Shared/` | Shared size/tint/edge enums, motion & a11y configs, defaults, state aggregator, list chrome |
| `Public/Checkbox/` | `FKCheckbox`, content/configuration, presets |
| `Public/Radio/` | `FKRadioButton`, `FKRadioGroup`, option model, configurations |
| `Public/Bridge/` | SwiftUI `UIViewRepresentable` wrappers |
| `Internal/Shared/` | Indicator drawing, metrics, tint resolver, attributed text, row layout, haptics, i18n |
| `Extension/` | Fluent `tint(_:)` / `size(_:)` builders |

## Quick start

```swift
import FKUIKit

let checkbox = FKCheckbox(title: "Enable notifications")
checkbox.onStateChanged = { print($0) }

let group = FKRadioGroup(options: [
  FKRadioOption(id: "week", title: "Weekly"),
  FKRadioOption(id: "month", title: "Monthly"),
])
group.selectedOptionID = "week"
group.onSelectionChanged = { print($0 ?? "nil") }
```

## Configuration

Each control uses layered configuration (`layout` / `appearance` / `interaction` / `motion` / `accessibility`), similar to `FKRatingControl` / `FKButton`.

Defaults: `FKSelectionControlDefaults.checkbox` / `.radioButton` / `.radioGroup` / `.listChrome`.

Presets: `FKCheckboxPresets.settingsRow()`, `.indicatorOnly()`, `.agreement()`.

## API notes

- ``FKCheckbox/checkState`` is used instead of `state` because ``UIControl`` already exposes ``UIControl/state``.
- ``FKCheckbox/setCheckState(_:animated:sendActions:)`` is the programmatic setter.

## Design tokens

| Size | Indicator | Checkbox corner | Radio ring |
|------|-----------|-----------------|------------|
| small | 16 | 3.5 | 1.5 |
| medium | 22 | 5 | 2 |
| large | 28 | 6 | 2.5 |

Tint presets: `.blue` / `.green` / `.red` / `.orange` / `.purple` / `.custom(UIColor)`.

## Examples

Runnable demos: `Examples/FKKitExamples/.../FKUIKit/SelectionControl/`

| Hub section | Demonstrates |
|-------------|--------------|
| Checkbox | States, sizes, tints, list chrome, indicator-only, indeterminate tap, programmatic, error, agreement links, select-all aggregate, read-only, trailing indicator, custom glyphs |
| Radio button | States, sizes & tints, trailing indicator |
| Radio group | Inset grouped, plain & horizontal, disabled option, deselection, images, subtitles, error, header/footer |
| Integration | SwiftUI representables |

Entry: **FKKit Examples → FKUIKit → SelectionControl**.

## License

See the repository root `LICENSE`.
