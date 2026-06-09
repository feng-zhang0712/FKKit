# FKFormControls — Design Requirements

Implementation guide for FKKit **form and filter controls**: **`FKSegmentedControl`**, **`FKToggle`**, **`FKCheckbox`**, **`FKRadioGroup`**, and **`FKSlider`**.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.4  
**中文版本:** [FKFormControls_DESIGN.zh-CN.md](FKFormControls_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Shared Design Language](#4-shared-design-language)
- [5. FKSegmentedControl](#5-fksegmentedcontrol)
- [6. FKToggle](#6-fktoggle)
- [7. FKCheckbox](#7-fkcheckbox)
- [8. FKRadioGroup](#8-fkradiogroup)
- [9. FKSlider](#9-fkslider)
- [10. Cross-Control Comparison](#10-cross-control-comparison)
- [11. SwiftUI Bridges](#11-swiftui-bridges)
- [12. Global Defaults](#12-global-defaults)
- [13. Proposed Source Layout](#13-proposed-source-layout)
- [14. FKKitExamples Scenarios](#14-fkkitexamples-scenarios)
- [16. Open Questions](#16-open-questions)
- [17. Revision History](#17-revision-history)

---

## 1. Executive Summary

Settings screens, filter panels, onboarding, and media players need **binary, enum, and range** inputs. FKKit today covers text via **`FKTextField`** and toggle **rows** inside **`FKActionSheet`**, but ships **no standalone `UIControl` widgets** for segmented picking, switches, checkboxes, radio groups, or sliders.

**FKFormControls** (`Sources/FKUIKit/Components/FormControls/`) delivers five public controls sharing configuration conventions with **`FKButton`** and **`FKRatingControl`**.

| Control | Primary use |
| --------- | ------------- |
| **FKSegmentedControl** | 2–N mutually exclusive options (filters, view modes) |
| **FKToggle** | On/off settings (notifications, feature flags UI) |
| **FKCheckbox** | Multi-select lists, agreements, bulk select |
| **FKRadioGroup** | Single choice among few labeled options |
| **FKSlider** | Scalar or range adjustment (price, volume, progress scrub) |

All types are **`UIControl`** subclasses (or composition roots emitting `UIControl` events), `@MainActor`, with optional SwiftUI `Representable` wrappers.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Unified FK visual language** across form controls — not raw `UISwitch` / `UISegmentedControl` / `UISlider` defaults.
2. **Layered `Sendable` configuration** — `layout`, `appearance`, `interaction`, `motion`, `accessibility` per control.
3. **HIG baseline** — 44pt minimum touch targets, Dynamic Type, VoiceOver, Dark Mode, RTL, Reduce Motion.
4. **Clear boundaries** vs `FKActionSheet` toggle rows and `FKTabBar` segmented preset — document when to use which.
5. **Composable** in settings VCs, filter toolbars, `FKListKit` cells, and SwiftUI forms.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Full form builder / validation orchestration | Future `FKForm` (Tier 3 roadmap) |
| Stepper (`+` / `−` numeric) | Separate control if needed later |
| `UIPickerView` wheel replacement | `FKDatePicker` roadmap |
| Color picker | Out of scope |
| macOS / tvOS | iOS 15+ UIKit |
| Binding to Combine/ObservableObject frameworks | Host wiring; controls expose values + callbacks |

### 2.3 Success Criteria

- [ ] Segment + Toggle and Checkbox, Radio, Slider ship.
- [ ] Each control: README section, Examples scenario, root README index row.
- [ ] Disabled/loading states behave consistently across family.
- [ ] ActionSheet vs standalone decision tree documented (§10).

---

## 3. Background & Problem Statement

### 3.1 Gap analysis

| Need | Current FKKit | Gap |
|------|---------------|-----|
| Filter tabs (Price / Rating / New) | `FKTabBar` segmented **preset** | TabBar is **header/navigation** oriented (collection, paging); awkward as inline `UISegmentedControl` replacement in forms |
| Settings switch row | `FKActionSheet` toggle **row** | Not embeddable in `UITableView`/`FKListKit` without sheet |
| Multi-select agreements | — | No checkbox |
| Payment method pick one | — | No radio group |
| Price range filter | Player-internal slider only | No public slider |

### 3.2 Relationship to FKTabBar `segmentedControl` preset

`FKTabBarPresets.segmentedControl()` configures **FKTabBar** (collection-based tab header). **FKSegmentedControl** is a **standalone** control:

| Aspect | FKTabBar (segmented preset) | FKSegmentedControl |
|--------|------------------------------|-------------------|
| Role | Tab header / paging strip | Inline filter or settings control |
| Child items | `FKTabBarItem` + badges | `FKSegment` segments |
| Paging linkage | `FKPagingController` | None |
| Scroll | Optional horizontal scroll | Optional; default non-scroll equal width |

**May reuse internal indicator animation math** from TabBar indicator engine as private shared code — **no public type dependency** on `FKTabBar`.

### 3.3 Relationship to FKActionSheet toggle row

Use **ActionSheet toggle** when switch lives inside modal action sheet list. Use **FKToggle** when switch is inline in settings cell, form, or custom layout.

---

## 4. Shared Design Language

### 4.1 Configuration layering (all controls)

```swift
// Pattern (names vary per control)
public struct FKSegmentedControlConfiguration: Sendable, Equatable {
  public var layout: ...
  public var appearance: ...
  public var interaction: ...
  public var motion: ...
  public var accessibility: ...
}
```

### 4.2 Shared enums (FormControls/Core/)

| Type | Purpose |
|------|---------|
| `FKFormControlEnabledState` | normal / disabled |
| `FKFormControlLoadingState` | idle / loading (spinner overlay) |
| `FKFormControlHaptic` | none / light / selection / impact (default **none**) |
| `FKFormControlSize` | small / medium / large (touch target presets) |
| `FKFormControlLabelPlacement` | leading / trailing / hidden (where applicable) |

### 4.3 UIControl events

Each control **must** emit:

- `.valueChanged` when value changes (user or programmatic per policy)
- `.touchUpInside` where tap-centric (checkbox/radio)
- Support `addAction(_:for:)` iOS 14+ pattern documented in README

### 4.4 Motion & Reduce Motion

- Animated selection transitions respect `UIAccessibility.isReduceMotionEnabled`.
- When reduced motion: cross-fade or instant state change — no spring slide.

### 4.5 Disabled & loading

| State | Visual | Interaction |
|-------|--------|-------------|
| Disabled | Reduced alpha (configurable, default ~0.48) | Ignores touches |
| Loading | Optional trailing `UIActivityIndicator` or overlay | Value change blocked unless config allows |

---

## 5. FKSegmentedControl

### 5.1 Purpose

Mutually exclusive selection among **2–8** segments (soft max 8 for layout; document hard max configurable). Replaces `UISegmentedControl` for FK-styled filters and mode switches.

### 5.2 Public API (sketch)

```swift
@MainActor
public final class FKSegmentedControl: UIControl {
  public var configuration: FKSegmentedControlConfiguration
  public var segments: [FKSegment] { get set }
  public var selectedIndex: Int { get set }          // NSNotFound style: use optional selectedSegmentID
  public var selectedSegmentID: FKSegmentID? { get set }
  public var onSelectionChanged: (@MainActor (Int, FKSegment) -> Void)?
}
```

```swift
public struct FKSegment: Hashable, Sendable, Identifiable {
  public var id: FKSegmentID
  public var title: String?
  public var icon: FKSegmentIcon?           // SF Symbol or UIImage
  public var badge: FKSegmentBadge?         // count or dot
  public var isEnabled: Bool
  public var accessibilityLabel: String?
}
```

### 5.3 Layout capabilities

| Capability | Options |
|------------|---------|
| Width mode | `.fillEqually`, `.intrinsic`, `.mixed` (icons fixed, text flex) |
| Height | Min 32pt compact / **44pt default** |
| Content insets | Padding inside track |
| Segment spacing | 0 (joined) or gap (floating pills) |
| Scroll | Horizontal scroll when intrinsic overflow |
| RTL | Segment order mirrors |

### 5.4 Indicator styles (`FKSegmentedIndicatorStyle`)

| Style | Description |
|-------|-------------|
| `.pill` | Sliding capsule behind selected segment (learn from TabBar pill) |
| `.underline` | Line under selected (thickness, inset configurable) |
| `.filledSegment` | Selected segment filled background, no sliding pill |
| `.none` | Color/text only |

**Must animate** indicator position on selection change (configurable duration, default 0.25s).

### 5.5 Appearance

- Track background color / material blur optional
- Selected vs normal title colors and fonts (Dynamic Type)
- Icon tint follows title state
- Badge: dot or numeric (reuse `FKBadge` styling concepts, not required dependency)
- Border corner radius on track

### 5.6 Interaction

| Behavior | Requirement |
|----------|-------------|
| Tap segment | Select if enabled; fire `valueChanged` |
| Drag across segments | Optional scrub selection (`allowsDragSelection`, default false) |
| Re-tap selected | Optional callback only if `allowsReselect` (default false) |
| Keyboard | Not required v1 |
| Haptic | Optional on change (`FKFormControlHaptic`) |

### 5.7 Accessibility

- Container trait `.tabBar` or `.segmentedControl` if available; else `.button` group
- Each segment: adjustable label = title + badge + selected state
- `accessibilityValue` on control = selected segment title

### 5.8 Edge cases

- Empty segments array → hidden zero intrinsic size
- Single segment → display but no-op selection change
- All disabled → control disabled
- Dynamic segment insert/remove → preserve selection by `FKSegmentID` when possible

---

## 6. FKToggle

### 6.1 Purpose

Binary on/off switch for settings — FK-styled alternative to `UISwitch`.

### 6.2 Public API (sketch)

```swift
@MainActor
public final class FKToggle: UIControl {
  public var configuration: FKToggleConfiguration
  public var isOn: Bool { get set }
  public var isLoading: Bool { get set }
  public var onValueChanged: (@MainActor (Bool) -> Void)?
}
```

Optional label:

```swift
public struct FKToggleContentConfiguration: Sendable, Equatable {
  public var title: String?
  public var subtitle: String?
  public var labelPlacement: FKFormControlLabelPlacement  // leading default
}
```

### 6.3 Visual design

| Element | Requirement |
|---------|-------------|
| Track | Rounded rect; on/off colors from `FKButton`-aligned palette |
| Thumb | Circle with shadow optional; animates translate |
| Size presets | small (mini), medium (default), large |
| On-image / off-image | Optional SF Symbol inside thumb (advanced) |
| Loading | Replace thumb with spinner or dim track |

**Must** support tint overrides for brand colors (onTint, offTint, thumbTint).

### 6.4 Interaction

| Behavior | Requirement |
|----------|-------------|
| Tap track or thumb | Toggle if enabled and not loading |
| Drag thumb | Optional `allowsDragToToggle` (default true) |
| Programmatic set | `setOn(_:animated:)` with `sendActions` policy config |
| Haptic | Optional light impact on change (default off) |

### 6.5 Accessibility

- Trait `.switch`
- `accessibilityValue` = on/off localized
- Label from title or explicit `accessibilityLabel`
- Hint optional from config

### 6.6 FKListKit / settings row integration

Document pattern: `FKListPresetItem.switch` uses **FKToggle** internally when shipped (update FKListKit design cross-ref).

---

## 7. FKCheckbox

### 7.1 Purpose

Single boolean with **checkbox** affordance (not switch metaphor). Supports **indeterminate** state for "select all" parent rows.

### 7.2 Public API (sketch)

```swift
public enum FKCheckboxState: Equatable, Sendable {
  case unchecked
  case checked
  case indeterminate
}

@MainActor
public final class FKCheckbox: UIControl {
  public var configuration: FKCheckboxConfiguration
  public var state: FKCheckboxState { get set }
  public var onStateChanged: (@MainActor (FKCheckboxState) -> Void)?
}
```

### 7.3 Visual design

| State | Glyph |
|-------|-------|
| Unchecked | Empty rounded square border |
| Checked | Filled square + checkmark (SF Symbol) |
| Indeterminate | Filled square + minus/dash |

- Corner radius configurable (square vs slightly rounded)
- Size presets tied to `FKFormControlSize`
- Error state border color optional (forms)

### 7.4 Interaction

- Tap cycles: unchecked → checked → unchecked (indeterminate → checked on first tap per config)
- `indeterminateEnabled` config (default true for group headers, false for simple checkbox)
- Optional linked label tap area (entire row) via `contentConfiguration`

### 7.5 Accessibility

- Trait `.button` with `accessibilityTraits.insert(.selected)` when checked
- Value string: "checked" / "unchecked" / "mixed"
- Group header: `accessibilityHint` for bulk selection

### 7.6 Group semantics (documentation)

FKCheckbox alone is single control. **Multi-checkbox** lists use multiple instances; **FKRadioGroup** handles exclusive choice. Document "select all" recipe with indeterminate parent checkbox.

---

## 8. FKRadioGroup

### 8.1 Purpose

Exactly **one** selected option from a small set (2–6 typical). Vertical list or horizontal chip-like row.

### 8.2 Public API (sketch)

```swift
public struct FKRadioOption: Hashable, Sendable, Identifiable {
  public var id: FKRadioOptionID
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool
}

@MainActor
public final class FKRadioGroup: UIControl {
  public var configuration: FKRadioGroupConfiguration
  public var options: [FKRadioOption] { get set }
  public var selectedOptionID: FKRadioOptionID? { get set }
  public var onSelectionChanged: (@MainActor (FKRadioOptionID) -> Void)?
}
```

### 8.3 Layout modes

| Mode | Description |
|------|-------------|
| `.vertical` | Options stacked; radio indicator leading |
| `.horizontal` | Inline row wrap or scroll |
| `.compact` | Segmented-like but radio semantics (circle indicators) |

Spacing, insets, minimum row height 44pt vertical.

### 8.4 Radio indicator

- Outer ring + inner fill when selected
- Animation: inner fill scale (respect Reduce Motion)
- Colors from appearance config

### 8.5 Interaction

- Tap option selects; previous deselects
- Tapping selected again: no-op (default) or fire callback if `allowsReselect`
- Disabled options skip selection
- **Must enforce single selection** in control logic

### 8.6 Accessibility

- Group label via `accessibilityLabel` on container
- Each option: `accessibilityTraits` includes `.button` and `.selected` when active
- Rotor custom actions optional v2

### 8.7 vs FKSegmentedControl

| Use FKSegmentedControl | Use FKRadioGroup |
|------------------------|------------------|
| Compact filter, immediate mode switch | Labeled options with subtitles |
| Icons + badges in strip | Longer explanatory copy |
| 2–4 short labels | 2–6 form choices with descriptions |

---

## 9. FKSlider

### 9.1 Purpose

Continuous or stepped scalar value; optional **dual-thumb range** for filters (min–max price).

### 9.2 Public API (sketch)

```swift
public enum FKSliderMode: Sendable, Equatable {
  case single
  case range(lower: CGFloat, upper: CGFloat)
}

@MainActor
public final class FKSlider: UIControl {
  public var configuration: FKSliderConfiguration
  public var mode: FKSliderMode
  public var value: CGFloat { get set }                    // single mode
  public var lowerValue: CGFloat { get set }               // range mode
  public var upperValue: CGFloat { get set }
  public var onValueChanged: (@MainActor (FKSliderValue) -> Void)?
  public var onEditingDidEnd: (@MainActor (FKSliderValue) -> Void)?
}
```

### 9.3 Track & thumb

| Element | Capability |
|---------|------------|
| Track | Height, background color, corner radius |
| Fill | Tint between min and thumb (or lower–upper in range) |
| Thumb | Circle diameter min 28pt hit **44pt**; image optional |
| Ticks | Optional step tick marks |
| Labels | Min/max static labels; floating value bubble on drag optional |

### 9.4 Value mapping

```swift
public struct FKSliderValueMapping: Sendable, Equatable {
  public var minimum: CGFloat
  public var maximum: CGFloat
  public var step: CGFloat?           // nil = continuous
  public var snapToStep: Bool
}
```

- Clamp values on set
- Range mode: enforce `lowerValue <= upperValue` with min gap `minimumRange` config

### 9.5 Interaction

| Behavior | Requirement |
|----------|-------------|
| Pan thumb | Updates value; continuous `valueChanged` |
| Tap track | Jump to value (config `tapToSeek`, default true) |
| Range thumbs | Collision avoidance; z-order top thumb on overlap |
| Haptic | Optional step snap haptic (reuse `FKProgressBar` touch haptic pattern) |
| `isContinuous` | Fire callback every change vs only on end (config) |

### 9.6 Accessibility

- Trait `.adjustable`
- Increment/decrement accessibility actions for step sliders
- Value announced on end editing
- Range: accessibilityValue combines lower and upper

### 9.7 Vertical orientation (optional v1.1)

If time constrained, **horizontal only v1** — document deferral.

---

## 10. Cross-Control Comparison

### 10.1 When to use which control

| User task | Control |
|-----------|---------|
| Pick one of few short modes | `FKSegmentedControl` |
| Pick one of several explained options | `FKRadioGroup` |
| On/off setting | `FKToggle` |
| Agree / multi-select item | `FKCheckbox` |
| Adjust level or range | `FKSlider` |
| On/off inside modal sheet list | `FKActionSheet` toggle row |
| Tab navigation / paging header | `FKTabBar` |

### 10.2 Filter bar composition (Examples)

`FKSegmentedControl` + `FKSlider` range side-by-side or stacked — see §14.

---

## 11. SwiftUI Bridges

Ship per control in `FormControls/Public/Bridge/`:

| UIKit | Representable |
|-------|---------------|
| `FKSegmentedControl` | `FKSegmentedControlRepresentable` |
| `FKToggle` | `FKToggleRepresentable` |
| `FKCheckbox` | `FKCheckboxRepresentable` |
| `FKRadioGroup` | `FKRadioGroupRepresentable` |
| `FKSlider` | `FKSliderRepresentable` |

**Must:**

- `Binding` for primary value (`isOn`, `selectedIndex`, `state`, `selectedOptionID`, `value`/`lowerValue`/`upperValue`)
- `updateUIView` uses programmatic set with action suppression to avoid loops
- Configuration struct passed through

---

## 12. Global Defaults

```swift
public enum FKFormControlsDefaults {
  public static var segmentedControl: FKSegmentedControlConfiguration
  public static var toggle: FKToggleConfiguration
  public static var checkbox: FKCheckboxConfiguration
  public static var radioGroup: FKRadioGroupConfiguration
  public static var slider: FKSliderConfiguration
}
```

Mutate at app launch for brand-wide form styling.

---

## 13. Proposed Source Layout

> **Layout guidance (non-normative):** The directory tree below is a **recommended starting point**, not a mandatory template. Adjust folders and file grouping to fit component complexity and neighboring FKKit components, while keeping the layout **discoverable**, **documented** in the component `README.md`, and aligned with FKKit conventions (clear public vs internal boundaries, English `///`, Swift 6 concurrency). See [COMPONENT_ROADMAP.md — Component source layout policy](COMPONENT_ROADMAP.md#component-source-layout-policy).

```text
Sources/FKUIKit/Components/FormControls/
├── README.md
├── Public/
│   ├── Core/
│   │   ├── FKFormControlSharedTypes.swift
│   │   └── FKFormControlsDefaults.swift
│   ├── SegmentedControl/
│   │   ├── FKSegmentedControl.swift
│   │   ├── FKSegment.swift
│   │   └── Configuration/...
│   ├── Toggle/
│   │   ├── FKToggle.swift
│   │   └── Configuration/...
│   ├── Checkbox/
│   ├── RadioGroup/
│   ├── Slider/
│   └── Bridge/
│       └── *Representable.swift
├── Internal/
│   ├── FKSegmentedIndicatorAnimator.swift
│   ├── FKToggleThumbView.swift
│   ├── FKSliderTrackRenderer.swift
│   └── ...
└── Extension/
    └── Convenience factories
```

`Package.swift` exclude `Components/FormControls/README.md`.

**Phased files:** Segment + Toggle folders first release; expand folders in a later release.

---

## 14. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/FormControls/`

| # | Scenario | Controls |
|---|----------|----------|
| 1 | `SegmentedFilter` | FKSegmentedControl styles (pill/underline) |
| 2 | `SegmentBadgesIcons` | Icons + numeric badges |
| 3 | `ToggleSettings` | FKToggle rows with labels |
| 4 | `ToggleLoadingDisabled` | Loading + disabled states |
| 5 | `CheckboxAgreement` | Single + indeterminate parent |
| 6 | `RadioGroupVertical` | Subtitle options |
| 7 | `RadioGroupHorizontal` | Compact horizontal |
| 8 | `SliderSingle` | Step snapping + haptic |
| 9 | `SliderRange` | Dual-thumb price filter |
| 10 | `FilterBarComposite` | Segment + range slider |
| 11 | `SwiftUIBridge` | All representables |
| 12 | `ActionSheetComparison` | When to use sheet toggle vs FKToggle |

Hub: **FormControls** with grouped navigation.

---

## 16. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | One module folder vs five top-level? | Single `FormControls/` |
| Q2 | Share indicator code with TabBar internally? | Yes, private shared Internal |
| Q3 | FKToggle mimic UISwitch exactly vs custom thumb? | Custom FK look, UISwitch-sized metrics |
| Q4 | FKSlider vertical in v1? | Defer; horizontal only |
| Q5 | Checkbox tap cycles through indeterminate? | indeterminate → checked only |

---

## 17. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §1.4 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKListKit_DESIGN.md](FKListKit_DESIGN.md) — switch preset row
- [TabBar README](../Sources/FKUIKit/Components/TabBar/README.md) — segmented preset distinction
- [ActionSheet README](../Sources/FKUIKit/Components/ActionSheet/README.md)
- [FKRatingControl README](../Sources/FKUIKit/Components/RatingControl/README.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
