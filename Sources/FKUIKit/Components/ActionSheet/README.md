# FKActionSheet

HIG-oriented action sheet for UIKit apps. Presentation (backdrop, bottom sheet sizing, tap/swipe dismiss) is delegated to **`FKPresentationController`**; this module owns the action list UI and configuration model.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

| Path | Role |
|------|------|
| `Public/FKActionSheet.swift` | `present`, `presentOnce`, `validate`, `isPresenting`, `dismissActive` |
| `Public/FKActionSheetHandle.swift` | Dismiss / reload / per-row updates |
| `Public/Core/FKActionSheetDelegate.swift` | Optional delegate callbacks |
| `Public/Configuration/` | Appearance, presentation, haptics, selection |
| `Public/Model/` | Actions, sections, header, toggle, host context, dismiss reasons |
| `Public/SwiftUI/` | `View.fkActionSheet` modifier |
| `Extension/` | Builder, handlers, toggle, SF Symbol, alert migration |
| `Internal/` | Content VC, table UI, cells, presentation mapping, session, validation |

## Quick start

```swift
import FKUIKit

let share = FKActionSheetAction(
  title: "Share",
  symbolName: "square.and.arrow.up"
) { /* share */ }

let delete = FKActionSheetAction(title: "Delete", style: .destructive) { /* delete */ }
let cancel = FKActionSheetAction(title: "Cancel", style: .cancel)

let configuration = FKActionSheetConfiguration(
  header: FKActionSheetHeader(title: "Photo", message: "Choose an action"),
  sections: [FKActionSheetSection(actions: [share, delete])],
  cancelAction: cancel,
  handlerTiming: .afterDismissAnimation
)

try FKActionSheet.present(configuration: configuration, from: self)
```

## Custom header and rows (Phase 2)

### Custom header

```swift
let header = FKActionSheetCustomHeader(
  preferredHeight: 120,
  provider: .init { context in
    let label = UILabel()
    label.text = "Custom header"
    return label
  }
)

var configuration = FKActionSheetConfiguration(
  header: .custom(header),
  sections: [...]
)
```

Or use `FKActionSheetBuilder().customHeader { context in ... }`.

### Custom row

```swift
struct ShareItem { let name: String }

let item = ShareItem(name: "Frank")

let action = FKActionSheetAction.custom(
  metadata: FKActionSheetMetadata(storage: ["item": item]),
  build: { context in
    let item = context.action.metadata?.value(ShareItem.self, forKey: "item")
    let label = UILabel()
    label.text = item?.name
    return label
  },
  handler: { /* ... */ }
)
```

Use `preferredHeight` on ``FKActionSheetCustomRow`` for fixed row height, or `nil` for self-sizing Auto Layout.

### Do you need framework-level generic models?

No. Prefer:

1. **`metadata`** on ``FKActionSheetAction`` for standard rows, or
2. **Capture your model** in the `build` / `update` closure for custom rows.

This keeps the public API simple while still letting you drive UI from your own types.

## Feature highlights

- Bottom sheet hosting with single `fitContent` detent (no grabber); short content hugs measured row/header height, tall content scrolls within `maximumPanelHeight` / `maximumFitContentHeightFraction` (default **50%** of screen)
- Bottom safe area: `shellExtendsToScreenBottomEdge` keeps the wrapper, content container, and `FKActionSheetView` bottom-aligned; a `tableFooterView` reserves the home-indicator area (works for non-scrollable sheets)
- Dismiss reasons: `actionSelected`, `userCancel`, `tapOutside`, `swipe` (when `allowsSwipeDismiss`), `programmatic`
- Default presentation: no swipe dismiss, no container corner radius, full-width plain rows
- `presentOnce(id:)` de-duplication, `validate(_:)`, `FKActionSheet.isPresenting`
- Dynamic Type scaling, minimum row height, row highlight, separator styling
- `FKActionSheetRowAlignment` (`.center` / `.leading`), appearance presets (`.system`, `.card`, `.plain`)
- Single-selection groups with optional stay-open behavior, `selectedActionID` restore on re-present, and `indicatorStyle` (check, radio, highlighted title, or combinations)
- Per-action `dismissesSheetWhenSelected`, haptics (off by default), delegate + hooks (kept in sync on `reload`)
- `presentationTransform` for advanced `FKPresentationConfiguration` tuning
- Reduce Motion uses fade preset when `presentation.respectsReduceMotion` is enabled

## Phase 3 APIs

### Handler with action parameter (28)

```swift
FKActionSheetAction(title: "Delete", style: .destructive) { action in
  print(action.id)
}
// or
FKActionSheetAction(title: "Delete", actionHandler: { action in ... })
```

When both `handler` and `actionHandler` are set, only `actionHandler` runs.

### UIAlertAction migration (29)

```swift
let config = FKActionSheetConfiguration(
  alertTitle: "Photo",
  message: "Choose an action",
  actions: [
    FKActionSheetAction(title: "Share", uiAlertActionStyle: .default) { ... }
  ]
)
```

### Window / scene hosting (27)

```swift
try FKActionSheet.present(
  configuration: config,
  hostContext: FKActionSheetPresentationHostContext(windowScene: windowScene)
)
```

### SwiftUI (23)

```swift
.fkActionSheet(
  isPresented: $showSheet,
  configuration: config,
  onDismiss: { reason in ... },
  onPresentFailure: { error in ... }
)
```

The modifier retains its own `FKActionSheetHandle` and reloads when `configuration` changes while presented.

### Toggle row (24)

```swift
FKActionSheetAction.toggle(title: "Delete attachments", isOn: true) { isOn in
  // ...
}
```

Toggle changes update in place without reloading the full table.

## FKKitExamples

Entry: **FKUIKit → ActionSheet** → `FKActionSheetExamplesHubViewController`

| Scenario | Covers |
|----------|--------|
| Basics | `present`, convenience API, `validate` |
| Many Actions | No header, long list, `maximumPanelHeight`, selection memory |
| Appearance & Layout | Presets, alignment, separators, sections |
| Symbols & Row States | SF Symbols, disabled/loading, stay-open rows |
| Single Selection | `selectedActionID`, `indicatorStyle` (check / radio / highlight), stay-open selection |
| Custom Header & Rows | Custom header/row, metadata, non-selectable row |
| Toggle Rows | `FKActionSheetAction.toggle` |
| Handlers & Lifecycle | Timing, `actionHandler`, haptics, delegate, hooks |
| Live Updates | `reload`, `updateAction`, `presentOnce`, `isPresenting` |
| Presentation | Swipe/backdrop dismiss, presentation configuration |
| Builder & Alert Migration | `FKActionSheetBuilder`, alert-style config |
| SwiftUI Bridge | `View.fkActionSheet` |

## Notes and limitations

- **`FKActionSheet.isPresenting` / `dismissActive()`** track the most recently presented sheet. Retain a ``FKActionSheetHandle`` for instance-scoped dismiss and updates.
- **`reload(configuration:)`** validates before applying; invalid configurations are ignored (debug `assertionFailure`).
- **`FKActionSheetPresentationHostContext`** is not `Sendable`; resolve and present on the main actor.
- **`configuration.delegate`** is a weak reference on a struct; the delegate object must outlive the sheet.

## Related components

- **`FKPresentationController`** — generic sheets, center modals, anchors
- **`FKToast`** — transient banners, not contextual action lists
