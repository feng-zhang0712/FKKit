# FKProgressBar

`FKProgressBar` is a **UIKit** `UIControl` subclass: a determinate and indeterminate progress indicator with **linear** and **ring** presentations, optional **buffer** fill, **segmented** tracks, **gradient** fills, built-in **value labels**, optional **button** interaction, **accessibility** support, and an optional **SwiftUI** bridge. It targets toolbars, media controls, download actions, and onboarding flows without third-party dependencies.

## Table of contents

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Progress-as-button (interactive control)](#progress-as-button-interactive-control)
- [Configuration](#configuration)
- [Migrating from 0.44.0](#migrating-from-0440)
- [Progress and buffer](#progress-and-buffer)
- [Indeterminate modes](#indeterminate-modes)
- [Labels and formatting](#labels-and-formatting)
- [Accessibility](#accessibility)
- [Delegate](#delegate)
- [SwiftUI](#swiftui)
- [Interface Builder](#interface-builder)
- [Layout and intrinsic size](#layout-and-intrinsic-size)
- [Examples](#examples)
- [API reference](#api-reference)
- [Best practices](#best-practices)
- [License](#license)

## Overview

- **Variants**: `FKProgressBarVariant.linear` (horizontal or vertical axis) and `FKProgressBarVariant.ring` (stroke-based circular progress).
- **Determinate API**: normalized `0...1` values via `setProgress(_:animated:)`, `setBufferProgress(_:animated:)`, and `setProgress(_:buffer:animated:)`.
- **Motion**: `CAMediaTimingFunction`-style timing, optional **spring** animation for determinate changes, and **reduced motion** awareness.
- **Threading**: UI-bound; the view is `@MainActor` and must be updated on the main queue.

## Repository layout

Sources under `Sources/FKUIKit/Components/ProgressBar/`:

| Area | Role |
|------|------|
| `Public/Core/` | `FKProgressBar` |
| `Public/Configuration/` | `FKProgressBarConfiguration` (root snapshot) and **`FKProgressBarLayoutConfiguration`**, **`FKProgressBarAppearanceConfiguration`**, **`FKProgressBarMotionConfiguration`**, **`FKProgressBarLabelConfiguration`**, **`FKProgressBarAccessibilityConfiguration`**, **`FKProgressBarInteractionConfiguration`**; **`FKProgressBarDefaults`** |
| `Public/Models/` | `FKProgressBarVariant`, `FKProgressBarAxis`, caps, fill style, indeterminate style, label placement/format/content, interaction & touch haptics, timing, completion haptics (`FKProgressBarEnums.swift`, `FKProgressBarProgressButtonModels.swift`) |
| `Public/` | `FKProgressBarDelegate` |
| `Public/Bridge/` | `FKProgressBarView` (`UIViewRepresentable`, when SwiftUI is available) |
| `Extension/` | `FKProgressBar` Interface Builder helpers |
| `Internal/Layout/` | `FKProgressBarLayoutEngine` (pure geometry; not public API) |
| `Internal/Rendering/` | `FKProgressBarLayerStack` (Core Animation layers) |
| `Internal/` | `FKProgressBarIndeterminateAnimator`, `FKProgressBarLabelFormatting` |

## Features

- Linear track with configurable thickness, corners, caps, borders, and **segment count** (chunked installers / stepped UX).
- Optional **buffer** layer behind primary progress (streaming / download semantics).
- **Solid** or **gradient-along-progress** fills (ring gradient is approximated on the stroke for stability).
- **Indeterminate**: linear **marquee** capsule, linear **breathing** opacity, ring **rotating arc** marquee, ring **breathing**.
- Optional **center / above / below / leading / trailing** value label with percent, fractional percent, normalized `0...1`, or **logical range** mapping (`label.logicalMinimum`…`label.logicalMaximum`).
- **Completion haptic** when crossing full progress (configurable intensity or none).
- **Progress-as-button**: `UIControl` target/action, optional touch haptics, minimum hit target, custom title modes (`FKProgressBarLabelContentMode`).
- **`@IBDesignable`** entry points for Storyboards and XIBs (see `Extension/FKProgressBar+InterfaceBuilder.swift`).

## Requirements

- **Swift** 6 language mode (see the `FKKit` package manifest).
- **iOS 15+** for the current `FKUIKit` product (UIKit).
- No additional runtime packages.

## Installation

Add the **`FKUIKit`** product from this repository, then:

```swift
import FKUIKit
```

## Quick start

```swift
let bar = FKProgressBar()
bar.configuration.layout.trackThickness = 6
bar.configuration.appearance.showsBuffer = true
view.addSubview(bar)
// Layout with Auto Layout or frames, then:
bar.setProgress(0.42, buffer: 0.78, animated: true)
```

## Progress-as-button (interactive control)

`FKProgressBar` subclasses **`UIControl`**, so you can use standard target/action APIs when ``FKProgressBarInteractionConfiguration/interactionMode`` is ``FKProgressBarInteractionMode/button``:

- **`addTarget(_:action:for:)`** — typical events: ``UIControl/Event/touchUpInside`` and ``UIControl/Event/primaryActionTriggered`` (VoiceOver / keyboard activation).
- **`isEnabled`** — dims track + label using ``FKProgressBarInteractionConfiguration/disabledContentAlpha``.
- **`isHighlighted`** — brief opacity feedback via ``FKProgressBarInteractionConfiguration/buttonHighlightedContentAlphaMultiplier``.
- **`FKProgressBarInteractionConfiguration/minimumTouchTargetSize`** — optional minimum hit area (centered), aligned with the **44×pt** HIG minimum.
- **`FKProgressBarInteractionConfiguration/touchHaptic`** — optional light impact or selection feedback on touch-down.

### Custom label copy (button title)

``FKProgressBarLabelConfiguration/labelContentMode`` selects how the visible label is built while ``FKProgressBarLabelConfiguration/labelPlacement`` remains the layout anchor:

| Mode | Behavior |
|------|-----------|
| ``formattedProgress`` | Same as legacy: formatted from ``progress`` / ``label.labelFormat``. |
| ``customTitleOnly`` | Always shows ``label.customTitle`` (progress only in the fill). |
| ``customTitleWhenIdle`` | Shows ``label.customTitle`` when idle or indeterminate with a non-empty title; otherwise formatted progress. |
| ``customTitleWithProgressSubtitle`` | Two lines: ``label.customTitle`` + newline + formatted progress. |

SwiftUI: pass **`onPrimaryAction`** to ``FKProgressBarView`` to mirror ``primaryActionTriggered``.

## Configuration

Use **`FKProgressBarConfiguration`** on **`bar.configuration`**. It groups related settings into nested structs:

| Property | Type | Notes |
|----------|------|--------|
| **`layout`** | `FKProgressBarLayoutConfiguration` | `variant`, `axis`, `trackThickness`, `trackCornerRadius`, `ringLineWidth`, `ringDiameter`, `contentInsets`, `segmentCount`, `segmentGapFraction`, `linearCapStyle`. |
| **`appearance`** | `FKProgressBarAppearanceConfiguration` | Colors, `fillStyle`, `progressGradientEndColor`, borders, **`showsBuffer`**. |
| **`motion`** | `FKProgressBarMotionConfiguration` | Determinate timing/spring, **`indeterminateStyle`**, **`indeterminatePeriod`**, **`playsIndeterminateAnimation`** (when `false`, indeterminate state updates label/a11y but does not run marquee/breathing/ring rotation), **`respectsReducedMotion`**, **`completionHaptic`**. |
| **`label`** | `FKProgressBarLabelConfiguration` | Placement, format, fonts, colors, padding, prefix/suffix, logical range, **`numberFormatter`**. |
| **`accessibility`** | `FKProgressBarAccessibilityConfiguration` | Custom label/hint, frequent-updates trait. |
| **`interaction`** | `FKProgressBarInteractionConfiguration` | Indicator vs button, touch target, haptics, disabled/highlight opacity. |

Global defaults: **`FKProgressBar.defaultConfiguration`** or **`FKProgressBarDefaults.configuration`**.

### Migrating from 0.44.0

`FKProgressBarConfiguration` no longer exposes a flat list of fields. Map each former property to the nested struct below (examples use `var c = bar.configuration` or a local `var c = FKProgressBarConfiguration()`).

| Former (0.44.0) | Now |
|-----------------|-----|
| `c.variant`, `c.axis`, `c.trackThickness`, `c.trackCornerRadius`, `c.ringLineWidth`, `c.ringDiameter`, `c.contentInsets`, `c.linearCapStyle`, `c.segmentCount`, `c.segmentGapFraction` | `c.layout.*` |
| `c.trackColor`, `c.progressColor`, `c.bufferColor`, borders, `c.fillStyle`, `c.progressGradientEndColor`, `c.showsBuffer` | `c.appearance.*` |
| `c.animationDuration`, `c.timing`, spring fields, `c.indeterminateStyle`, `c.indeterminatePeriod`, `c.respectsReducedMotion`, `c.completionHaptic` | `c.motion.*` (see **`playsIndeterminateAnimation`** below) |
| `c.labelContentMode`, `c.customTitle`, label placement/format/font/color/padding, logical range, prefix/suffix, `c.numberFormatter` | `c.label.*` |
| `c.accessibilityCustomLabel`, `c.accessibilityCustomHint`, `c.accessibilityTreatAsFrequentUpdates` | `c.accessibility.*` |
| `c.interactionMode`, button/highlight/disabled alpha, `c.minimumTouchTargetSize`, `c.touchHaptic` | `c.interaction.*` |

**`@IBInspectable`** properties on **`FKProgressBar`** (`ibVariant`, `ibTrackColor`, …) still work; they read and write the nested configuration.

## Progress and buffer

- **Primary** progress is always clamped to **`0...1`**.
- **Buffer** progress is clamped the same way; it is shown only when **`appearance.showsBuffer`** is `true`.
- Use **`setProgress(_:buffer:animated:)`** for a single animated transaction.

## Indeterminate modes

Set **`isIndeterminate = true`** and choose **`motion.indeterminateStyle`**. Set **`motion.playsIndeterminateAnimation`** to `false` if you want the indeterminate *state* (label / VoiceOver) without marquee, breathing, or rotating-arc animations:

| Style | Linear | Ring |
|--------|--------|------|
| **`.marquee`** | Capsule travels along the track (clipped to track bounds). | Short arc rotates around the ring. |
| **`.breathing`** | Opacity pulse on the track. | Pulse on track + progress strokes. |
| **`.none`** | No automatic animation; host may drive `progress` manually. | Same. |

Call **`startIndeterminate()`** / **`stopIndeterminate()`** for convenience, or toggle **`isIndeterminate`** directly.

## Labels and formatting

- **`label.labelPlacement`**: `.none`, `.above`, `.below`, `.leading`, `.trailing`, `.centeredOnTrack` (typical for rings).
- **`label.labelFormat`**: `.percentInteger`, `.percentFractional`, `.normalizedValue`, `.logicalRangeValue`.
- **`label.logicalMinimum` / `label.logicalMaximum`**: map `0...1` to a displayed range for `.logicalRangeValue`.

The visible string is built by **`FKProgressBarLabelFormatting`**; customize digits and **`label.numberFormatter`** as needed. For long titles or percent strings, **`label`** placement **`.above`**, **`.below`**, and **`.centeredOnTrack`** give the text layer the full usable width so values like `100%` are less likely to ellipsize.

## Accessibility

- The control is an accessibility element with **`accessibilityValue`** derived from progress, buffer, and format.
- Optional **`accessibility.accessibilityCustomLabel`** / **`accessibility.accessibilityCustomHint`** override or extend defaults.
- **`accessibility.accessibilityTreatAsFrequentUpdates`** controls **`UIAccessibilityTraits.updatesFrequently`** together with indeterminate / animation state.

## Delegate

Implement **`FKProgressBarDelegate`** for analytics or coordination. All methods have **default empty implementations** in a **`public extension`**, so you only override what you need:

- `progressBar(_:willAnimateProgress:to:duration:)`
- `progressBar(_:didAnimateProgressTo:)`
- `progressBar(_:didChangeIndeterminate:)`
- `progressBar(_:didUpdateBufferProgress:)`

## SwiftUI

When SwiftUI is available, use **`FKProgressBarView`**:

```swift
FKProgressBarView(
  progress: $progress,
  bufferProgress: $buffer,
  isIndeterminate: $isIndeterminate,
  configuration: myConfiguration,
  animateChanges: true
)
```

Bindings mirror **`FKProgressBar`** state; **`updateUIView`** applies configuration, indeterminate flag, and progress together. Pass **`onPrimaryAction`** for **`primaryActionTriggered`** when using button interaction mode.

## Interface Builder

`FKProgressBar` is **`@IBDesignable`**. Inspectable shortcuts live in **`FKProgressBar+InterfaceBuilder`** (e.g. variant, axis, colors, thickness). Prefer **`configuration`** in code for full control.

## Layout and intrinsic size

- **Linear horizontal**: intrinsic **height** combines track thickness, insets, and label band; width is **`noIntrinsicMetric`** (stretch in Auto Layout).
- **Linear vertical**: intrinsic **width**; height is flexible.
- **Ring**: intrinsic **width and height** from diameter, insets, and optional centered-label band.

Stroke and shadow may extend slightly outside bounds; **`clipsToBounds`** defaults to **`false`** so rings are not clipped—host containers may set clipping if required.

## Examples

The **FKKitExamples** app (see `Examples/FKKitExamples/…/ProgressBar/`) includes:

- Hub and **Preset gallery** (`UITableView`-driven configurations; row heights account for labels and vertical layouts).
- Playground-style controls, delegate logging, environment (RTL / accessibility), and a **SwiftUI** host screen.

These are reference integrations only; they are not required at runtime for **`FKProgressBar`**.

## API reference

### Primary types

- **`FKProgressBar`** — `UIControl` subclass: `setProgress`, `setBufferProgress`, `startIndeterminate` / `stopIndeterminate`, `intrinsicContentSize`, target/action when ``FKProgressBarInteractionMode/button``.
- **`FKProgressBarConfiguration`** — root snapshot; use **`layout`**, **`appearance`**, **`motion`**, **`label`**, **`accessibility`**, **`interaction`**.
- **`FKProgressBarLayoutConfiguration`**, **`FKProgressBarAppearanceConfiguration`**, **`FKProgressBarMotionConfiguration`**, **`FKProgressBarLabelConfiguration`**, **`FKProgressBarAccessibilityConfiguration`**, **`FKProgressBarInteractionConfiguration`** — grouped settings (each with a documented memberwise initializer).
- **`FKProgressBarDelegate`** — optional lifecycle hooks.
- **`FKProgressBarView`** — SwiftUI `UIViewRepresentable` (conditional compilation).

### Key enums

- **`FKProgressBarVariant`**: `.linear`, `.ring`
- **`FKProgressBarAxis`**: `.horizontal`, `.vertical` (linear only)
- **`FKProgressBarIndeterminateStyle`**: `.none`, `.marquee`, `.breathing`
- **`FKProgressBarLabelPlacement`**, **`FKProgressBarLabelFormat`**, **`FKProgressBarTiming`**, **`FKProgressBarCompletionHaptic`**, etc. (see `Public/Models/FKProgressBarEnums.swift`)

## Best practices

- Mutate **`configuration`** on the **main thread**; the type is documented as a main-thread snapshot (`@unchecked Sendable` only for stored `UIColor` / `UIFont` / `NumberFormatter`).
- After large **`configuration`** changes, rely on **`invalidateIntrinsicContentSize()`** (handled by the view) before layout passes.
- For **rings** in stacked layouts, give the view enough **height and width** for `ringDiameter` plus **stroke** slop and optional **centered** label.
- Respect **`UIAccessibility.isReduceMotionEnabled`** via **`motion.respectsReducedMotion`** for product-consistent motion.

## License

`FKProgressBar` is part of **FKKit** and is distributed under the **same license** as this repository.
