# FKStepIndicator / FKTimeline — Design Requirements

Implementation guide for FKKit **flow visualization controls**: **`FKStepIndicator`** (horizontal step progress) and **`FKTimeline`** (vertical event timeline).

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.7  
**中文版本:** [FKStepIndicator-FKTimeline_DESIGN.zh-CN.md](FKStepIndicator-FKTimeline_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Shared Design Language](#4-shared-design-language)
- [5. Shared Data Model](#5-shared-data-model)
- [6. FKStepIndicator](#6-fkstepindicator)
- [7. FKTimeline](#7-fktimeline)
- [8. Node Rendering & Icons](#8-node-rendering--icons)
- [9. Connectors & Progress Rail](#9-connectors--progress-rail)
- [10. Layout Modes & Density](#10-layout-modes--density)
- [11. Interaction & Navigation](#11-interaction--navigation)
- [12. Configuration Model](#12-configuration-model)
- [13. Motion & Haptics](#13-motion--haptics)
- [14. Accessibility](#14-accessibility)
- [15. RTL & Dynamic Type](#15-rtl--dynamic-type)
- [16. SwiftUI Bridges](#16-swiftui-bridges)
- [17. Component Boundaries](#17-component-boundaries)
- [18. Proposed Source Layout](#18-proposed-source-layout)
- [19. FKKitExamples Scenarios](#19-fkkitexamples-scenarios)
- [21. Open Questions](#21-open-questions)
- [22. Revision History](#22-revision-history)

---

## 1. Executive Summary

Checkout wizards, onboarding, KYC flows, shipment tracking, and audit histories all need **multi-step visual progress**. Teams repeatedly build custom `UIStackView` + `CAShapeLayer` timelines with inconsistent states, icons, connectors, and accessibility.

FKKit ships **`FKProgressBar`** for scalar 0…1 progress and **`FKTabBar`** for navigation headers — but **no** dedicated step or timeline widgets.

| Control | Orientation | Primary use |
|---------|-------------|-------------|
| **`FKStepIndicator`** | Horizontal | Checkout steps, onboarding wizard header, form section progress |
| **`FKTimeline`** | Vertical | Logistics tracking, order history, audit trail, activity feed |

Both live under `Sources/FKUIKit/Components/FlowVisualization/` (or split `StepIndicator/` + `Timeline/` sharing `FlowVisualization/Core/`).

They share **`FKFlowStepItem`**, **`FKFlowStepState`**, node appearance tokens, and connector styling — aligned with **`FKButton`**, **`FKRatingControl`**, and **`FKProgressBar`** configuration layering.

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Production-ready state model** — completed, current, upcoming, error, skipped, disabled; per-step overrides.
2. **Custom icons** — SF Symbols, template images, optional numeric index, checkmark for completed.
3. **Rich labels** — title, subtitle, optional caption/timestamp; compact and expanded density.
4. **Connectors** — solid/dashed rails; partial fill showing progress between nodes.
5. **Optional interaction** — tap step to navigate wizard (when host allows); read-only by default.
6. **HIG baseline** — 44pt touch targets when interactive, Dynamic Type, VoiceOver, Dark Mode, RTL, Reduce Motion.
7. **Layered `Sendable` configuration** — `layout`, `appearance`, `interaction`, `motion`, `accessibility`.
8. **SwiftUI** — `UIViewRepresentable` wrappers with binding-friendly APIs.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|-------|
| Full wizard / page controller orchestration | Host owns VC paging; indicator is display + optional tap |
| Branching DAG flows (multiple next steps) | Linear sequences only v1; document fork as host logic |
| Animated SVG Lottie paths | Static UIKit layers + optional UIViewPropertyAnimator |
| macOS / tvOS | iOS 15+ UIKit |
| Infinite scroll social feed | Timeline is bounded item lists |
| Gantt chart / calendar scheduling UI | Out of scope |
| Auto-layout inside `UITableView` self-sizing without host height hint | Provide `systemLayoutSizeFitting` + intrinsic height helpers |

### 2.3 Success Criteria

- [ ] Horizontal 4-step checkout indicator with completed/current/upcoming renders correctly.
- [ ] Vertical logistics timeline with timestamps and error state on failed delivery step.
- [ ] Custom per-step SF Symbol icons demonstrated in Examples.
- [ ] VoiceOver reads position ("Step 2 of 4: Payment, current").
- [ ] RTL mirrors horizontal indicator; vertical timeline keeps rail on trailing side per config.
- [ ] README documents vs `FKProgressBar` / `FKTabBar` decision tree.

---

## 3. Background & Problem Statement

### 3.1 Gap analysis

| Need | Current FKKit | Gap |
|------|---------------|-----|
| Checkout "Cart → Address → Pay → Done" | — | No step indicator |
| Shipment status list | `FKListKit` plain cells | No rail + node semantics |
| Scalar download % | `FKProgressBar` | Wrong abstraction for named steps |
| Top filter tabs | `FKTabBar` segmented | Navigation, not completion state |

### 3.2 Repeated pain

| Pain | Impact |
|------|--------|
| Connector misalignment when titles wrap | Broken visual polish |
| No shared `StepState` enum across app | Divergent colors/icons |
| Tapping future steps in wizard | Accidental navigation without policy |
| Timelines without accessibility position | App Store accessibility failures |
| Hard-coded 4 steps in one screen | Cannot reuse component |

---

## 4. Shared Design Language

Both controls follow FKUIKit conventions:

| Layer | Responsibility |
|-------|----------------|
| **Models** | `Sendable` step items, states, icon descriptors |
| **Configuration** | Nested structs: layout, appearance, interaction, motion, accessibility |
| **Control** | `@MainActor` `UIView` subclass (read-only display) or `UIControl` when interactive |
| **Internal** | Layout engine, node views, connector layers |
| **Bridge** | SwiftUI representable |

Reuse:

- **`FKLayerBorderStyle`**, **`FKLayerShadowStyle`** from `FKUIKit/Core/Appearance/`
- Color resolution via `UIColor` dynamic providers (same as `FKProgressBar`)
- Label fonts via text styles supporting Dynamic Type

---

## 5. Shared Data Model

### 5.1 Step state

```swift
/// Semantic state of one step/node in a linear flow.
public enum FKFlowStepState: Sendable, Equatable {
  case completed
  case current
  case upcoming
  case error
  case skipped
  case disabled
}
```

| State | Visual semantics |
|-------|------------------|
| `.completed` | Filled node, checkmark or custom completed icon, connector to next filled |
| `.current` | Emphasized node (ring/pulse), active title weight |
| `.upcoming` | Muted node and connector |
| `.error` | Destructive color, optional error icon |
| `.skipped` | Muted or strikethrough label; connector still advances |
| `.disabled` | Non-interactive; reduced opacity |

### 5.2 Step item

```swift
/// One node in FKStepIndicator or FKTimeline.
public struct FKFlowStepItem: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var subtitle: String?
  public var caption: String?           // tertiary line (timeline body)
  public var timestamp: Date?           // timeline primary use
  public var formattedTimestamp: String? // pre-formatted override (timezone control)
  public var state: FKFlowStepState
  public var icon: FKFlowStepIcon?
  public var accessibilityHint: String?
  public var isInteractive: Bool?       // nil → use control default
}
```

### 5.3 Icon descriptor

```swift
public enum FKFlowStepIcon: Sendable, Equatable {
  case number(Int)                      // 1-based index in circle
  case systemName(String)
  case imageAsset(name: String, bundle: Bundle?)
  case template(UIImage)                // host-provided; not Sendable UIImage — use asset name preferred
  case none                               // dot node
}
```

**Normative:** Prefer `systemName` / `imageAsset` for `Sendable` purity. `template(UIImage)` only on main actor via builder closure if needed (document pattern).

### 5.4 Derived current index

```swift
public enum FKFlowProgressResolver {
  /// Returns index of `.current`, or first `.upcoming`, or last `.completed`.
  public static func activeIndex(in items: [FKFlowStepItem]) -> Int?
}
```

Host may set explicit `state` per item **or** provide `currentStepIndex` API on controls to auto-derive states (see §6.4).

---

## 6. FKStepIndicator

### 6.1 Role

**Horizontal** linear step header for wizards and checkout. Nodes arranged on one axis with connectors between.

```text
  (1)──────(2)──────(3)──────(4)
 Cart    Address   Pay     Done
```

### 6.2 Public type

```swift
@MainActor
public final class FKStepIndicator: UIControl {
  public static var defaultConfiguration: FKStepIndicatorConfiguration { get set }

  public var configuration: FKStepIndicatorConfiguration
  public var items: [FKFlowStepItem] {
    didSet { reloadItems() }
  }

  /// When set, overrides per-item `state` by index (0 = first).
  public var currentStepIndex: Int?

  public weak var delegate: FKStepIndicatorDelegate?
  public var onStepSelected: ((Int, FKFlowStepItem) -> Void)?

  public func setCurrentStep(_ index: Int, animated: Bool)
  public func setItems(_ items: [FKFlowStepItem], animated: Bool)
}
```

**Default:** read-only display (`isUserInteractionEnabled = false`) unless `configuration.interaction.allowsSelection == true`.

### 6.3 Layout axes

| `FKStepIndicatorLayout` | Description |
|-------------------------|-------------|
| `.horizontalTopLabels` | Nodes on rail; titles below nodes (default) |
| `.horizontalBottomLabels` | Titles above nodes |
| `.horizontalInline` | Title beside node (2–3 steps only) |
| `.compactDots` | Small nodes, short titles, scrollable |

### 6.4 State assignment modes

| Mode | Behavior |
|------|----------|
| **Explicit** | Host sets `state` on each `FKFlowStepItem` |
| **Index-driven** | Host sets `currentStepIndex`; control derives completed/upcoming |

When both provided, **explicit per-item `state` wins** for that index; document in README.

### 6.5 Connectors (horizontal)

- Segment between node *i* and *i+1*:
  - **Filled** when step *i* is `.completed` (or `.skipped` if config treats skipped as done)
  - **Muted** when *i* is `.current` or `.upcoming`
  - **Error stripe** optional when step *i+1* is `.error`

### 6.6 Scrolling

When `items.count > configuration.layout.maxVisibleSteps` or intrinsic width exceeds bounds:

- Embed in horizontal `UIScrollView` (internal)
- Auto-scroll to keep `current` node visible with `scrollToStep(_:animated:)`
- Show leading/trailing fade masks (optional, appearance config)

### 6.7 Minimum / maximum steps

- **Minimum:** 2 steps (degenerate 1-step hides connectors)
- **Maximum:** No hard cap; performance target 20 steps with scrolling

### 6.8 Intrinsic content size

Must implement `intrinsicContentSize` and `sizeThatFits` for embedding in stack views and navigation headers.

---

## 7. FKTimeline

### 7.1 Role

**Vertical** list of events with left (or trailing) rail, nodes, and multi-line content.

```text
  ●  Shipped
  │  Mar 8, 10:00
  │  Warehouse departed
  │
  ○  In transit        ← current
  │  Expected Mar 10
  │
  ○  Delivered
```

### 7.2 Public type

```swift
@MainActor
public final class FKTimeline: UIView {
  public static var defaultConfiguration: FKTimelineConfiguration { get set }

  public var configuration: FKTimelineConfiguration
  public var items: [FKFlowStepItem]

  public weak var delegate: FKTimelineDelegate?
  public var onItemSelected: ((Int, FKFlowStepItem) -> Void)?

  public func setItems(_ items: [FKFlowStepItem], animated: Bool)
  public func scrollToStep(id: String, animated: Bool)
}
```

Timeline is **`UIView`** by default (read-only). When `configuration.interaction.allowsSelection`, enable taps and use optional highlight.

### 7.3 Layout variants

| `FKTimelineLayout` | Description |
|--------------------|-------------|
| `.verticalLeadingRail` | Rail on leading; content on trailing (default LTR) |
| `.verticalTrailingRail` | Mirror rail |
| `.verticalAlternating` | Odd/even content on opposite sides of rail (optional v1.1) |
| `.embeddedInList` | Reduced padding for `FKListKit` / `UITableView` cells |

### 7.4 Timestamp presentation

| Mode | Source |
|------|--------|
| `.relative` | `RelativeDateTimeFormatter` via `FKI18n` locale |
| `.absolute` | `DateFormatter` short date + time |
| `.custom` | `formattedTimestamp` on item |
| `.hidden` | No timestamp row |

### 7.5 Section headers (optional)

```swift
public struct FKTimelineSection: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var items: [FKFlowStepItem]
}
```

`FKTimeline.sections` replaces flat `items` when non-empty — grouped audit/logistics days.

### 7.6 Last item tail

| `FKTimelineTailStyle` | Behavior |
|-----------------------|----------|
| `.none` | No connector below last node |
| `.dotted` | Fade-out tail (in-progress shipment) |
| `.toFuture` | Dashed line to placeholder "next event" |

### 7.7 Expandable detail (optional v1)

When `configuration.interaction.allowsExpansion`:

- Tap item toggles `caption` expansion with animation
- Chevron accessory on rows with non-nil `caption`

---

## 8. Node Rendering & Icons

### 8.1 Node shapes

| `FKFlowNodeShape` | Use |
|-------------------|-----|
| `.circle` | Default |
| `.roundedSquare` | Audit logs |
| `.pin` | Map-style tracking |

### 8.2 State → default icon

| State | Default icon when `icon == nil` |
|-------|--------------------------------|
| `.completed` | Checkmark SF Symbol |
| `.current` | Number or filled dot |
| `.upcoming` | Hollow circle |
| `.error` | `xmark` or `exclamationmark` |
| `.skipped` | `forward.fill` or dash |
| `.disabled` | Muted hollow |

All overridable per item via `FKFlowStepIcon`.

### 8.3 Node sizes

`FKFlowNodeSize`: `.small` (20pt), `.medium` (28pt, default), `.large` (36pt). Touch padding expands to 44pt when interactive.

### 8.4 Appearance per state

```swift
public struct FKFlowNodeAppearance: Sendable, Equatable {
  public var fillColor: UIColor
  public var border: FKLayerBorderStyle
  public var iconTint: UIColor
  public var shadow: FKLayerShadowStyle?
}
```

`FKFlowAppearanceConfiguration` maps `FKFlowStepState` → `FKFlowNodeAppearance` with dynamic colors.

---

## 9. Connectors & Progress Rail

### 9.1 Connector style

```swift
public struct FKFlowConnectorStyle: Sendable, Equatable {
  public var thickness: CGFloat
  public var completedColor: UIColor
  public var upcomingColor: UIColor
  public var dashPattern: [CGFloat]?   // nil = solid
  public var capStyle: CAShapeLayerLineCap
}
```

### 9.2 Partial progress (advanced)

Optional `configuration.appearance.showsPartialConnectorFill`:

- Between `.current` and next `.upcoming`, draw gradient or 50% fill when host sets `currentStepProgress: CGFloat` (0…1) on `FKStepIndicator` only — for sub-step upload within one wizard page.

### 9.3 Rail alignment

Layout engine ensures connector centers align with node anchor points across Dynamic Type size changes.

---

## 10. Layout Modes & Density

### 10.1 Density

| `FKFlowDensity` | Effect |
|-----------------|--------|
| `.regular` | Full titles, default spacing |
| `.compact` | Single-line titles, tighter rail |
| `.spacious` | Extra vertical gap (timeline) |

### 10.2 Label line limits

- `titleNumberOfLines` / `subtitleNumberOfLines` in layout config (default 2 / 2)
- Truncation tail; full text in accessibility label

### 10.3 Width constraints

`FKStepIndicator` in navigation bar: host sets height constraint (~56–80pt); width from superview.

`FKTimeline`: width from superview; height grows with content or scrolls internally when `configuration.layout.scrollable == true`.

---

## 11. Interaction & Navigation

### 11.1 Selection policy

```swift
public struct FKFlowInteractionConfiguration: Sendable, Equatable {
  public var allowsSelection: Bool
  public var selectableStates: Set<FKFlowStepState>  // default [.completed] only
  public var allowsExpansion: Bool                  // timeline captions
  public var hapticOnSelect: Bool
}
```

**Normative defaults:**

- Wizard: only `.completed` steps tappable to go back
- Checkout: read-only (no selection)
- Timeline logistics: selection optional for copy tracking number

### 11.2 Delegate

```swift
@MainActor
public protocol FKStepIndicatorDelegate: AnyObject {
  func stepIndicator(_ indicator: FKStepIndicator, shouldSelectStepAt index: Int) -> Bool
  func stepIndicator(_ indicator: FKStepIndicator, didSelectStepAt index: Int)
}
```

Return `false` from `shouldSelect` to block navigation.

### 11.3 UIControl events

When `FKStepIndicator` is interactive:

- Emit `UIControl.Event.valueChanged` or custom `.stepSelected` via delegate (document one primary pattern — **delegate + closure**)

### 11.4 Loading state

`configuration.interaction.isLoading == true`:

- Current step shows indeterminate spinner overlay on node (reuse motion patterns from `FKProgressBar`)
- Disable selection

---

## 12. Configuration Model

### 12.1 FKStepIndicatorConfiguration

```swift
public struct FKStepIndicatorConfiguration: Sendable, Equatable {
  public var layout: FKStepIndicatorLayoutConfiguration
  public var appearance: FKFlowAppearanceConfiguration
  public var interaction: FKFlowInteractionConfiguration
  public var motion: FKFlowMotionConfiguration
  public var accessibility: FKFlowAccessibilityConfiguration
}
```

### 12.2 FKTimelineConfiguration

Same nesting; timeline-specific fields in `FKTimelineLayoutConfiguration` (timestamp style, tail, section header fonts).

### 12.3 Presets

```swift
public enum FKStepIndicatorPresets {
  public static func checkout() -> FKStepIndicatorConfiguration
  public static func onboarding() -> FKStepIndicatorConfiguration
}

public enum FKTimelinePresets {
  public static func logistics() -> FKTimelineConfiguration
  public static func auditLog() -> FKTimelineConfiguration
}
```

| Preset | Traits |
|--------|--------|
| `checkout` | Read-only, 3–5 steps, top labels, checkmarks |
| `onboarding` | Interactive completed steps, compact dots |
| `logistics` | Vertical, timestamps, current emphasized |
| `auditLog` | Monospace-friendly captions, no selection |

### 12.4 Global defaults

```swift
public enum FKStepIndicatorDefaults {
  public static var configuration: FKStepIndicatorConfiguration
}
public enum FKTimelineDefaults {
  public static var configuration: FKTimelineConfiguration
}
```

---

## 13. Motion & Haptics

### 13.1 Animations

| Trigger | Animation |
|---------|-----------|
| `currentStepIndex` change | Connector fill slide; node scale emphasis |
| Item state → `.completed` | Checkmark cross-fade |
| Timeline insert item | Fade + slide (when `animated: true`) |

### 13.2 Reduce Motion

When `UIAccessibility.isReduceMotionEnabled`:

- Disable pulse on current node
- Instant state changes only

### 13.3 Haptics

Optional `UIImpactFeedbackGenerator` on step selection when `hapticOnSelect == true`.

---

## 14. Accessibility

### 14.1 Step indicator

Each node: `accessibilityElement` OR container with combined label:

> "Step 2 of 4, Payment, current step"

Connectors: `accessibilityTraits = .notEnabled` or hidden from VO.

### 14.2 Timeline

Each row:

> "Shipped, March 8 10:00 AM, Warehouse departed, completed"

### 14.3 Hints

Use `accessibilityHint` from item or configuration template for interactive steps.

### 14.4 Rotor / adjustable

Read-only — not adjustable. Document that wizard navigation should expose dedicated buttons for VoiceOver users when steps are not selectable.

---

## 15. RTL & Dynamic Type

### 15.1 RTL

- `FKStepIndicator`: reverse node order visually; connectors follow
- `FKTimeline`: `.verticalLeadingRail` maps to trailing in RTL unless `respectInterfaceLayoutDirection == false`

### 15.2 Dynamic Type

- Title: `UIFont.TextStyle.subheadline` or config
- Scale node size slightly at AX5 if `scalesNodeWithContentSize == true`
- Re-layout on `traitCollectionDidChange` and `UIContentSizeCategory.didChangeNotification`

---

## 16. SwiftUI Bridges

```swift
public struct FKStepIndicatorRepresentable: UIViewRepresentable {
  public var items: [FKFlowStepItem]
  public var currentStepIndex: Int?
  public var configuration: FKStepIndicatorConfiguration
  public var onStepSelected: ((Int) -> Void)?
}

public struct FKTimelineRepresentable: UIViewRepresentable {
  public var items: [FKFlowStepItem]
  public var sections: [FKTimelineSection]?
  public var configuration: FKTimelineConfiguration
}
```

**Must** update when `items` or `currentStepIndex` change without recreating unnecessary animations.

---

## 17. Component Boundaries

| Use | Component |
|-----|-----------|
| Named steps with completion | **FKStepIndicator** / **FKTimeline** |
| Single scalar progress | **FKProgressBar** |
| Tab navigation without completion semantics | **FKTabBar** |
| Plain list of strings | **FKListKit** |
| Date picking | **FKDatePicker** (roadmap) |

---

## 18. Proposed Source Layout

> **Layout guidance (non-normative):** The directory tree below is a **recommended starting point**, not a mandatory template. Adjust folders and file grouping to fit component complexity and neighboring FKKit components, while keeping the layout **discoverable**, **documented** in the component `README.md`, and aligned with FKKit conventions (clear public vs internal boundaries, English `///`, Swift 6 concurrency). See [COMPONENT_ROADMAP.md — Component source layout policy](COMPONENT_ROADMAP.md#component-source-layout-policy).

```text
Sources/FKUIKit/Components/FlowVisualization/
├── README.md
├── Core/
│   ├── Public/
│   │   ├── FKFlowStepItem.swift
│   │   ├── FKFlowStepState.swift
│   │   ├── FKFlowStepIcon.swift
│   │   ├── FKFlowConnectorStyle.swift
│   │   ├── FKFlowNodeAppearance.swift
│   │   └── Configuration/
│   │       ├── FKFlowAppearanceConfiguration.swift
│   │       ├── FKFlowInteractionConfiguration.swift
│   │       ├── FKFlowMotionConfiguration.swift
│   │       └── FKFlowAccessibilityConfiguration.swift
│   └── Internal/
│       ├── FKFlowNodeView.swift
│       ├── FKFlowConnectorLayer.swift
│       └── FKFlowLayoutMetrics.swift
├── StepIndicator/
│   ├── Public/
│   │   ├── FKStepIndicator.swift
│   │   ├── FKStepIndicatorDelegate.swift
│   │   ├── FKStepIndicatorConfiguration.swift
│   │   └── Bridge/FKStepIndicatorRepresentable.swift
│   └── Internal/
│       ├── FKStepIndicatorLayoutEngine.swift
│       └── FKStepIndicatorScrollContainer.swift
└── Timeline/
    ├── Public/
    │   ├── FKTimeline.swift
    │   ├── FKTimelineSection.swift
    │   ├── FKTimelineDelegate.swift
    │   ├── FKTimelineConfiguration.swift
    │   └── Bridge/FKTimelineRepresentable.swift
    └── Internal/
        ├── FKTimelineLayoutEngine.swift
        └── FKTimelineRowView.swift
```

---

## 19. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/FlowVisualization/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `CheckoutSteps` | 4-step horizontal, read-only, index-driven |
| 2 | `OnboardingWizard` | Interactive back navigation on completed steps |
| 3 | `CustomIcons` | Per-step SF Symbols |
| 4 | `ErrorStep` | Failed payment step styling |
| 5 | `CompactScrollable` | 8+ steps horizontal scroll |
| 6 | `LogisticsTimeline` | Vertical timestamps, current in transit |
| 7 | `AuditLog` | Sections by day, captions |
| 8 | `SkippedStep` | KYC skip scenario |
| 9 | `DarkModeRTL` | Appearance + layout direction |
| 10 | `SwiftUIBinding` | Representable + current index binding |
| 11 | `DynamicType` | AX5 layout |
| 12 | `ReduceMotion` | No pulse when enabled |

---

## 21. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Single folder vs `StepIndicator/` + `Timeline/`? | Shared `FlowVisualization/Core/` |
| Q2 | `FKStepIndicator` subclass `UIControl` or `UIView`? | `UIControl` when interactive |
| Q3 | Alternating timeline in v1? | Defer to v1.1 |
| Q4 | `UIImage` in icon enum? | Asset names only in Sendable model |
| Q5 | Partial connector fill in v1? | Optional `currentStepProgress` on indicator |

---

## 22. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §2.7 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
- [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md)
