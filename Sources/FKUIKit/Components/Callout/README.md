# FKCallout

Anchored speech-bubble overlays for UIKit: one shared layout engine and chrome layer, with **`FKTooltip`** and **`FKPopover`** as the **recommended** entry points.

This module is **not** `UIPopoverPresentationController` (see `FKActionSheet` popover presentation) and not the removed legacy `FKBarPresentation` product formerly named `FKPopover`.

## Requirements

- Swift 6, iOS 15+
- `import FKUIKit`

## API layers

| Layer | Types | When to use |
|-------|--------|-------------|
| **Recommended** | `FKTooltip`, `FKPopover` | Normal app integration. Presets set `kind`, default configuration, and semantic helpers (`showMenu`, `showCoachMark`, …). **Start here.** |
| **Advanced** | `FKCallout`, `FKCalloutBuilder`, `FKCalloutContent` | Custom content combinations, `showOrUpdate`, runtime `update`, or presentation logic that does not map cleanly to a preset overload. |
| **Shared models** | `FKCalloutConfiguration`, `FKCalloutHandle`, menu/action/coach-mark models | Used by both presets and advanced APIs. |

`FKTooltip` and `FKPopover` delegate to the same internal presenter as `FKCallout`. Prefer presets so `kind` and defaults stay consistent; reach for `FKCallout` only when a preset cannot express your call site.

## When to use which API

| Need | Recommended API |
|------|-----------------|
| Short hint near a control, auto-dismiss | `FKTooltip` |
| Rich card, menu, coach mark, custom panel | `FKPopover` |
| Arbitrary `FKCalloutContent`, builder hooks, or in-place update | `FKCallout` (advanced) |
| In-hierarchy dropdown with z-order / mask policies | `FKAnchor` (Sheet module) |
| Global status, queue, keyboard bar inset | `FKToast` |
| System `UIPopoverPresentationController` | `FKActionSheet` popover presentation |

## Configuration defaults

Each preset owns its global default store. Avoid mixing stores across tooltip vs popover call sites.

| Global store | Role |
|--------------|------|
| `FKTooltip.defaultConfiguration` | Tooltip preset store (`kind: .tooltip`) |
| `FKPopover.defaultConfiguration` | Popover preset store (`kind: .popover`) |
| `FKPopover.menuConfiguration` | Menu/select preset store |
| `FKCallout.defaultConfiguration` | Baseline for **`FKCallout.show`** only; initialized to `popoverDefault()`. Prefer `FKTooltip.defaultConfiguration` or `FKPopover.defaultConfiguration` in application code. |

For per-request options, prefer `FKCalloutConfiguration.tooltipDefault()`, `popoverDefault()`, or `menuDefault()` over the bare `FKCalloutConfiguration()` initializer unless you need fully custom defaults.

### Preset `placement` vs `configuration`

`FKTooltip.show` / `FKPopover.show` always set `kind` on the resolved configuration. When the facade `placement` parameter is not `.automatic`, it **overrides** `configuration.placement` even when you pass a custom `configuration`. Use `.automatic` on the facade when you want full control via `configuration` only.

### `FKCalloutBuilder` vs direct `show`

| API | When |
|-----|------|
| `FKTooltip.show` / `FKPopover.show` | Default integration; merges global preset store + facade `placement`. |
| `FKCallout.show(content:…)` | Same as presets but you supply `FKCalloutContent` and configuration directly. |
| `FKCallout.show(builder:)` | Menu selection, footer `actionHandlers`, coach-mark `closeHandler`, or `customBeakViewProvider`. |
| `FKCallout.showOrUpdate(builder:)` | Same anchor already showing — updates content in place; otherwise presents. |

`FKCalloutBuilder` defaults `configuration` to a bare `FKCalloutConfiguration()`; prefer `tooltipDefault` / `popoverDefault` in the builder initializer for consistent chrome.

### Lifecycle hooks

Pass `FKCalloutLifecycleHooks` to any `show` overload (`willShow`, `didShow`, `willDismiss`, `didDismiss`). Hooks run on the main actor for the session `UUID`.

### Concurrent presentations

Default `presentationPolicy` is `.replaceActive` (one bubble). Set `presentationPolicy = .allowConcurrent` on the configuration to stack multiple callouts (see FKKitExamples **FKCallout advanced**). `dismissActive()` dismisses **all** active sessions.

### SwiftUI

```swift
import SwiftUI
import FKUIKit

@StateObject private var anchorBox = FKCalloutSwiftUIAnchorBox()

FKCalloutSwiftUIAnchorButton(title: "Anchor", anchorBox: anchorBox)

// On tap:
if let anchor = anchorBox.view {
  FKTooltip.show("Hint", anchoredTo: anchor, placement: .top)
}
```

`FKCalloutSwiftUIAnchorButton` uses demo-friendly indigo styling; use your own representable in production if branding differs.

## Source layout

```
Callout/
├── Public/
│   ├── Core/              # Presentation API and lifecycle
│   ├── Configuration/     # Placement, appearance, beak, keyboard, backdrop
│   ├── Content/           # Payload models (text, menu, coach mark, builder)
│   ├── Presets/           # FKTooltip and FKPopover entry points
│   └── Bridge/            # SwiftUI anchor helpers
├── Internal/
│   ├── Presentation/      # Window host, overlay, anchor tracking, animation
│   ├── Layout/            # Frame placement, beak geometry
│   └── Views/             # Bubble chrome, menu, coach mark, backdrop
└── README.md
```

| Path | Role |
|------|------|
| **Public/Core/** | |
| `FKCallout.swift` | **Advanced** presenter: `show` / `showOrUpdate` / `dismiss` / `update` |
| `FKCalloutHandle.swift` | Stable handle for an active callout (returned by presets and `FKCallout`) |
| `FKCalloutDismissReason.swift` | Why a callout was dismissed |
| **Public/Configuration/** | |
| `FKCalloutConfiguration.swift` | Per-request options, `FKCalloutKind`, tooltip/popover presets |
| `FKCalloutKeyboardAvoidance.swift` | Keyboard relayout or dismiss behavior |
| `FKCalloutPresentationPolicy.swift` | Replace active vs concurrent presentations |
| `FKCalloutBackdropStyle.swift` | Dimmed scrim and anchor spotlight |
| `FKCalloutAppearance.swift` | Bubble chrome (fill, shadow, beak, frosted glass) |
| `FKCalloutPlacement.swift` | Twelve anchor-relative placements |
| `FKCalloutAnchorAlignment.swift` | Leading/center/trailing along anchor edge |
| `FKCalloutBeakOffset.swift` | Beak position (bubble edge or anchor-relative) |
| `FKCalloutBeakStyle.swift` | Beak shape (isosceles, equilateral, right angle, polygon) |
| **Public/Content/** | |
| `FKCalloutContent.swift` | Content variants, `FKCalloutBuilder`, `FKCalloutLifecycleHooks` |
| `FKCalloutMenu.swift` | Sectioned menu model (icons, subtitles, selection, disabled rows) |
| `FKCalloutAction.swift` | Footer action descriptor (`id` + `title` handler keys) |
| `FKCalloutIcon.swift` | Tooltip icon payload |
| `FKCalloutHeaderPanel.swift` | Colored header strip model |
| `FKCalloutCoachMarkContent.swift` | Onboarding card copy + CTA labels |
| **Public/Presets/** | |
| `FKTooltip.swift` | **Recommended** tooltip preset (compact, auto-dismiss) |
| `FKPopover.swift` | **Recommended** popover preset (rich content, menu, coach mark) |
| **Public/Bridge/** | |
| `FKCalloutSwiftUIBridge.swift` | `FKCalloutSwiftUIAnchorBox` + `FKCalloutSwiftUIAnchorButton` |
| **Internal/Presentation/** | |
| `FKCalloutCenter.swift` | Window presentation, timers, keyboard, concurrent sessions |
| `FKCalloutPresentation.swift` | Active session state |
| `FKCalloutOverlayView.swift` | Backdrop, hit testing, outside tap |
| `FKCalloutAnchorObserver.swift` | Debounced relayout when anchor moves |
| `FKCalloutAnimator.swift` | Enter/exit motion (Reduce Motion aware) |
| **Internal/Layout/** | |
| `FKCalloutLayoutEngine.swift` | Frame + beak alignment beside anchor |
| `FKCalloutBeakGeometry.swift` | Unified bubble/beak paths |
| `FKCalloutPlacement+Geometry.swift` | Placement → beak edge helpers |
| **Internal/Views/** | |
| `FKCalloutBubbleView.swift` | Content hosts and layout |
| `FKCalloutBubbleChromeRenderer.swift` | Beak path, shadow, border, frosted fill |
| `FKCalloutBackdropView.swift` | Dim scrim and anchor cutout |
| `FKCalloutMenuView.swift` | Dropdown/action menu rendering |
| `FKCalloutCoachMarkView.swift` | Title/close/body/primary action layout |

## Content types

| `FKCalloutContent` | Design use |
|--------------------|------------|
| `.message` | Tooltip copy |
| `.titleSubtitle` | Simple popover |
| `.iconMessage` | Icon + tip row |
| `.messageWithActions` | Tip + footer button(s) |
| `.headerPanel` | Colored header + body |
| `.coachMark` | Onboarding card (title, close, CTA) |
| `.menu` | Dropdown / action / account menus |
| `.customView` | Fully custom UI |

## Quick start

### Recommended (presets)

```swift
import FKUIKit

// Tooltip
FKTooltip.show("Tooltip on the top", anchoredTo: infoButton, placement: .top)

// Popover
FKPopover.show(
  title: "Popover on the top",
  message: "Body copy inside the card.",
  anchoredTo: anchor,
  placement: .bottom
)

FKPopover.showMenu(
  menu,
  anchoredTo: optionsButton,
  onSelect: { item in /* … */ }
)

FKPopover.showCoachMark(
  FKCalloutCoachMarkContent(
    title: "Tap to switch profiles",
    message: "Switch between your profiles for unique app experiences"
  ),
  anchoredTo: profileControl,
  placement: .bottom,
  primaryAction: { /* continue */ }
)
// Coach marks enable backdrop.spotlightsAnchor by default.

// Dismiss
FKPopover.dismissActive()
FKTooltip.dismissActive()
```

### Advanced (`FKCallout`)

Use when you need an arbitrary `FKCalloutContent` value, `FKCalloutBuilder` hooks, or update-in-place behavior:

```swift
var config = FKCalloutConfiguration.tooltipDefault(placement: .topLeading)
config.appearance.beakStyle = .rightAngle(corner: .leading, apexAlongBase: 1)
config.beakOffset = .fraction(0.25, reference: .anchor)
config.maxContentHeight = 240
config.keyboardAvoidance = .relayout

var builder = FKCalloutBuilder(content: .message("Updated in place"), configuration: config)
builder.anchorView = helpAnchor
FKCallout.showOrUpdate(builder: builder)

// Dismiss by session id or handle:
FKCallout.dismiss(handle.id, reason: .manual)
FKPopover.dismiss(handle)

// Or present any content enum case directly:
FKCallout.show(
  content: .iconMessage(icon: FKCalloutIcon(symbolName: "info.circle"), message: "Hint"),
  anchoredTo: anchor,
  configuration: config
)
```

## Examples

FKKitExamples → **FKUIKit → Callout** hub (`Examples/FKUIKit/Callout/`).

Most scenarios use **`FKTooltip`** / **`FKPopover`**. Scenarios that exercise placement grids, beak styles, builders, or `showOrUpdate` call **`FKCallout`** directly and are labeled as advanced engine demos.
