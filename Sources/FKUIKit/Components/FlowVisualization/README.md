# FlowVisualization

Shared flow models plus **`FKStepIndicator`** (horizontal step progress) and **`FKTimeline`** (vertical event timeline) for checkout wizards, onboarding headers, logistics tracking, and audit history.

## Contents

- [Overview](#overview)
- [Module layout](#module-layout)
- [When to use](#when-to-use)
- [Shared models](#shared-models)
- [FKStepIndicator](#fkstepindicator)
- [FKTimeline](#fktimeline)
- [Configuration](#configuration)
- [Accessibility](#accessibility)
- [SwiftUI](#swiftui)
- [Examples](#examples)

## Overview

| Control | Axis | Typical use |
|---------|------|-------------|
| **`FKStepIndicator`** | Horizontal | Checkout steps, wizard headers, segmented form progress |
| **`FKTimeline`** | Vertical | Shipment tracking, order history, audit trails |

Both controls share **`FKFlowStepItem`**, **`FKFlowStepState`**, node appearance tokens, and connector styling — aligned with **`FKProgressBar`** and **`FKTabBar`** configuration layering.

## Module layout

Path: `Sources/FKUIKit/Components/FlowVisualization/`

| Path | Contents |
|------|-----------|
| `Core/Public/` | Shared models (`FKFlowStepItem`, `FKFlowStepState`, `FKFlowStepIcon`, `FKFlowConnectorStyle`, `FKFlowNodeAppearance`, configuration structs). |
| `Core/Internal/` | Node view, connector layer, layout metrics, icon/state/accessibility helpers. |
| `StepIndicator/Public/` | `FKStepIndicator`, configuration, delegate, presets, SwiftUI bridge. |
| `StepIndicator/Internal/` | Horizontal layout engine and step row views. |
| `Timeline/Public/` | `FKTimeline`, `FKTimelineSection`, configuration, presets, SwiftUI bridge. |
| `Timeline/Internal/` | Vertical layout engine, row views, timestamp formatting. |

## When to use

| Scenario | Component |
|----------|-----------|
| Named steps with completion states | **FKStepIndicator** / **FKTimeline** |
| Scalar 0…1 progress | **FKProgressBar** |
| Tab navigation without completion semantics | **FKTabBar** |
| Plain string lists | **FKListKit** |

## Shared models

- **`FKFlowStepState`** — `.completed`, `.current`, `.upcoming`, `.error`, `.skipped`, `.disabled`
- **`FKFlowStepItem`** — `id`, `title`, optional `subtitle` / `caption` / timestamps, `state`, optional `icon`
- **`FKFlowStepIcon`** — `.number`, `.systemName`, `.imageAsset`, `.template`, `.none`
- **`FKFlowProgressResolver.activeIndex(in:)`** — derives the active index from explicit states

## FKStepIndicator

Horizontal linear steps with connectors. Default interaction is **read-only** unless `configuration.interaction.allowsSelection == true`.

```swift
import FKUIKit

var config = FKStepIndicatorPresets.checkout()
let indicator = FKStepIndicator(configuration: config)
indicator.items = [
  FKFlowStepItem(id: "cart", title: "Cart"),
  FKFlowStepItem(id: "address", title: "Address"),
  FKFlowStepItem(id: "pay", title: "Payment"),
  FKFlowStepItem(id: "done", title: "Done"),
]
indicator.currentStepIndex = 1
```

**State modes:** set each item’s `state` explicitly, or assign **`currentStepIndex`** to derive completed/upcoming states. Explicit `state` at the current index always wins.

**Layouts:** `.horizontalTopLabels` (default), `.horizontalBottomLabels`, `.horizontalInline`, `.compactDots`.

Defaults: **`FKStepIndicator.defaultConfiguration`** or **`FKStepIndicatorDefaults.configuration`**.

## FKTimeline

Vertical rail with multi-line content and optional grouped **`sections`**.

```swift
let timeline = FKTimeline(configuration: FKTimelinePresets.logistics())
timeline.items = [
  FKFlowStepItem(
    id: "shipped",
    title: "Shipped",
    caption: "Left warehouse",
    timestamp: Date(),
    state: .completed
  ),
  FKFlowStepItem(
    id: "transit",
    title: "In transit",
    subtitle: "Estimated Mar 10",
    state: .current
  ),
]
```

**Timestamp modes:** `.relative`, `.absolute`, `.custom` (`formattedTimestamp`), `.hidden`.

Defaults: **`FKTimeline.defaultConfiguration`** or **`FKTimelineDefaults.configuration`**.

## Configuration

Both controls use grouped **`Sendable`** configuration:

| Member | Role |
|--------|------|
| `layout` | Control-specific layout, scrolling, line limits |
| `appearance` | Shared node, connector, typography, and density tokens |
| `interaction` | Selection, expansion (timeline), haptics, touch targets |
| `motion` | Animation duration, reduced motion, current-node pulse |
| `accessibility` | VoiceOver label templates |

Presets: **`FKStepIndicatorPresets`**, **`FKTimelinePresets`**.

## Accessibility

- Step indicator nodes expose per-step labels (`Step {index} of {count}, {title}, {state}` by default).
- Timeline rows combine title, timestamp, caption, and state.
- Connectors are hidden from VoiceOver by default (`accessibility.hidesConnectorsFromAccessibility`).

## SwiftUI

When SwiftUI is linked:

- **`FKStepIndicatorRepresentable`**
- **`FKTimelineRepresentable`**

## Examples

Demo scenarios live under `Examples/FKKitExamples/.../FKUIKit/FlowVisualization/` (hub + one screen per major capability).

## Requirements

- **Swift** 6
- **iOS 15+**
