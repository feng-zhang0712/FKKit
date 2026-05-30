# FKCallout

Anchored speech-bubble overlays for UIKit: one layout engine and chrome layer, with **`FKTooltip`** and **`FKPopover`** convenience entry points.

This module is **not** `UIPopoverPresentationController` (see `FKActionSheet` popover presentation) and not the removed legacy `FKBarPresentation` product formerly named `FKPopover`.

## Requirements

- Swift 6, iOS 15+
- `import FKUIKit`

## When to use which API

| Need | Recommended API |
|------|-----------------|
| Short hint near a control, auto-dismiss | `FKTooltip` |
| Rich card, menu, coach mark, custom panel | `FKPopover` / `FKCallout` |
| In-hierarchy dropdown with z-order / mask policies | `FKAnchor` (Sheet module) |
| Global status, queue, keyboard bar inset | `FKToast` |
| System `UIPopoverPresentationController` | `FKActionSheet` popover presentation |

## Configuration defaults

| Global store | Role |
|--------------|------|
| `FKCallout.defaultConfiguration` | Baseline for `FKCallout.show` when not overridden; initialized to `popoverDefault()` |
| `FKTooltip.defaultConfiguration` | Tooltip preset store |
| `FKPopover.defaultConfiguration` | Popover preset store |
| `FKPopover.menuConfiguration` | Menu/select preset store |

Prefer `FKCalloutConfiguration.tooltipDefault()`, `popoverDefault()`, or `menuDefault()` over the bare `FKCalloutConfiguration()` initializer unless you need fully custom defaults.

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
| `FKCallout.swift` | Core `show` / `showOrUpdate` / `dismiss` / `update` APIs |
| `FKCalloutHandle.swift` | Stable handle for an active callout |
| `FKCalloutDismissReason.swift` | Why a callout was dismissed |
| **Public/Configuration/** | |
| `FKCalloutConfiguration.swift` | Per-request options and tooltip/popover presets |
| `FKCalloutKeyboardAvoidance.swift` | Keyboard relayout or dismiss behavior |
| `FKCalloutPresentationPolicy.swift` | Replace active vs concurrent presentations |
| `FKCalloutBackdropStyle.swift` | Dimmed scrim and anchor spotlight |
| `FKCalloutAppearance.swift` | Bubble chrome (fill, shadow, beak, frosted glass) |
| `FKCalloutPlacement.swift` | Twelve anchor-relative placements |
| `FKCalloutAnchorAlignment.swift` | Leading/center/trailing along anchor edge |
| `FKCalloutBeakOffset.swift` | Beak position (bubble edge or anchor-relative) |
| `FKCalloutBeakStyle.swift` | Beak shape (isosceles, equilateral, right angle, polygon) |
| **Public/Content/** | |
| `FKCalloutContent.swift` | Content variants + `FKCalloutBuilder` |
| `FKCalloutMenu.swift` | Sectioned menu model (icons, subtitles, selection, disabled rows) |
| `FKCalloutAction.swift` | Footer action descriptor (`id` + `title` handler keys) |
| `FKCalloutIcon.swift` | Tooltip icon payload |
| `FKCalloutHeaderPanel.swift` | Colored header strip model |
| `FKCalloutCoachMarkContent.swift` | Onboarding card copy + CTA labels |
| **Public/Presets/** | |
| `FKTooltip.swift` | Tooltip preset (compact, auto-dismiss) |
| `FKPopover.swift` | Popover preset (rich content, menu, coach mark) |
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

```swift
import FKUIKit

FKTooltip.show("Tooltip on the top", anchoredTo: infoButton, placement: .top)

var config = FKCalloutConfiguration.tooltipDefault(placement: .topLeading)
config.appearance.beakStyle = .rightAngle(corner: .leading, apexAlongBase: 1)
config.beakOffset = .fraction(0.25, reference: .anchor)
config.maxContentHeight = 240
config.keyboardAvoidance = .relayout

var builder = FKCalloutBuilder(content: .message("Updated in place"), configuration: config)
builder.anchorView = helpAnchor
FKCallout.showOrUpdate(builder: builder)

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
```

## Examples

FKKitExamples → **FKUIKit → Callout** hub (`Examples/FKUIKit/Callout/`).
