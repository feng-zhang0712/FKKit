# FKProgressBar

`FKProgressBar` is a **UIKit** determinate and indeterminate progress indicator with **linear** and **ring** presentations, optional **buffer** fill, **segmented** tracks, **gradient** fills, built-in **value labels**, **accessibility** support, and an optional **SwiftUI** bridge. It targets product-quality toolbars, media controls, and onboarding flows without third-party dependencies.

## Table of contents

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Configuration](#configuration)
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
| `Public/Configuration/` | `FKProgressBarConfiguration`, defaults |
| `Public/Models/` | `FKProgressBarVariant`, `FKProgressBarAxis`, caps, fill style, indeterminate style, label placement/format, timing, haptics |
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
- Optional **center / above / below / leading / trailing** value label with percent, fractional percent, normalized `0...1`, or **logical range** mapping (`logicalMinimum`…`logicalMaximum`).
- **Completion haptic** when crossing full progress (configurable intensity or none).
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
bar.configuration.trackThickness = 6
bar.configuration.showsBuffer = true
view.addSubview(bar)
// Layout with Auto Layout or frames, then:
bar.setProgress(0.42, buffer: 0.78, animated: true)
```

## Configuration

Use **`FKProgressBarConfiguration`** (struct) on **`bar.configuration`**. Important groups:

| Group | Notes |
|-------|--------|
| **Variant & axis** | `variant`, `axis` (linear only). |
| **Geometry** | `trackThickness`, `trackCornerRadius`, `ringLineWidth`, `ringDiameter`, `contentInsets`, `segmentCount`, `segmentGapFraction`, `linearCapStyle`. |
| **Colors & borders** | `trackColor`, `progressColor`, `bufferColor`, `fillStyle`, `progressGradientEndColor`, track/progress border widths and colors. |
| **Motion** | `animationDuration`, `timing`, `prefersSpringAnimation`, `springDampingRatio`, `springVelocity`, `indeterminateStyle`, `indeterminatePeriod`, `respectsReducedMotion`, `completionHaptic`. |
| **Buffer** | `showsBuffer` — when `false`, buffer APIs are ignored visually. |
| **Label** | `labelPlacement`, `labelFormat`, fonts, colors, padding, prefix/suffix, `numberFormatter` for logical values. |
| **Accessibility** | `accessibilityCustomLabel`, `accessibilityCustomHint`, `accessibilityTreatAsFrequentUpdates`. |

Global defaults: **`FKProgressBar.defaultConfiguration`** or **`FKProgressBarDefaults.configuration`**.

## Progress and buffer

- **Primary** progress is always clamped to **`0...1`**.
- **Buffer** progress is clamped the same way; it is shown only when **`showsBuffer`** is `true`.
- Use **`setProgress(_:buffer:animated:)`** for a single animated transaction.

## Indeterminate modes

Set **`isIndeterminate = true`** and choose **`indeterminateStyle`**:

| Style | Linear | Ring |
|--------|--------|------|
| **`.marquee`** | Capsule travels along the track (clipped to track bounds). | Short arc rotates around the ring. |
| **`.breathing`** | Opacity pulse on the track. | Pulse on track + progress strokes. |
| **`.none`** | No automatic animation; host may drive `progress` manually. | Same. |

Call **`startIndeterminate()`** / **`stopIndeterminate()`** for convenience, or toggle **`isIndeterminate`** directly.

## Labels and formatting

- **`labelPlacement`**: `.none`, `.above`, `.below`, `.leading`, `.trailing`, `.centeredOnTrack` (typical for rings).
- **`labelFormat`**: `.percentInteger`, `.percentFractional`, `.normalizedValue`, `.logicalRangeValue`.
- **`logicalMinimum` / `logicalMaximum`**: map `0...1` to a displayed range for `.logicalRangeValue`.

The visible string is built by **`FKProgressBarLabelFormatting`**; customize digits and **`numberFormatter`** as needed.

## Accessibility

- The control is an accessibility element with **`accessibilityValue`** derived from progress, buffer, and format.
- Optional **`accessibilityCustomLabel`** / **`accessibilityCustomHint`** override or extend defaults.
- **`accessibilityTreatAsFrequentUpdates`** controls **`UIAccessibilityTraits.updatesFrequently`** together with indeterminate / animation state.

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

Bindings mirror **`FKProgressBar`** state; **`updateUIView`** applies configuration, indeterminate flag, and progress together.

## Interface Builder

`FKProgressBar` is **`@IBDesignable`**. Inspectable shortcuts live in **`FKProgressBar+InterfaceBuilder`** (e.g. variant, axis, colors, thickness). Prefer **`configuration`** in code for full control.

## Layout and intrinsic size

- **Linear horizontal**: intrinsic **height** combines track thickness, insets, and label band; width is **`noIntrinsicMetric`** (stretch in Auto Layout).
- **Linear vertical**: intrinsic **width**; height is flexible.
- **Ring**: intrinsic **width and height** from diameter, insets, and optional centered-label band.

Stroke and shadow may extend slightly outside bounds; **`clipsToBounds`** defaults to **`false`** so rings are not clipped—host containers may set clipping if required.

## Examples

The **FKKitExamples** app (see `Examples/FKKitExamples/…/ProgressBar/`) includes:

- Hub and **Preset gallery** (`UITableView`-driven configurations).
- Playground-style controls, delegate logging, environment (RTL / accessibility), and a **SwiftUI** host screen.

These are reference integrations only; they are not required at runtime for **`FKProgressBar`**.

## API reference

### Primary types

- **`FKProgressBar`** — UIKit view, `setProgress`, `setBufferProgress`, `startIndeterminate` / `stopIndeterminate`, `intrinsicContentSize`.
- **`FKProgressBarConfiguration`** — all visual and behavioral knobs.
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
- Respect **`UIAccessibility.isReduceMotionEnabled`** via **`respectsReducedMotion`** for product-consistent motion.

## License

`FKProgressBar` is part of **FKKit** and is distributed under the **same license** as this repository.
