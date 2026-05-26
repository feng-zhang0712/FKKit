# FKActionSheet

HIG-oriented action sheet for UIKit apps. The sheet is a modal `UIViewController` (`FKActionSheet`) with custom transitions for bottom/centered styles and UIKit popover support. This module owns the action list UI and configuration model.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

| Path | Role |
|------|------|
| `Public/FKActionSheet.swift` | Modal container VC (panel + table), `reload`, `updateAction`, `dismiss` |
| `Internal/FKActionSheet+Presentation.swift` | `present(from:)`, static conveniences, action handling |
| `Internal/FKActionSheet+Layout.swift` | Bottom / centered / popover panel constraints |
| `Public/Core/FKActionSheetDelegate.swift` | Optional delegate callbacks |
| `Public/Configuration/` | Appearance, presentation, haptics, selection |
| `Public/Model/FKActionSheetPresentationStyle.swift` | `.bottom`, `.centered`, `.popover` |
| `Public/Model/` | Actions, sections, header, toggle, dismiss reasons |
| `Public/SwiftUI/` | `View.fkActionSheet` modifier |
| `Extension/` | Builder, handlers, toggle, SF Symbol, alert migration, selection scope |
| `Internal/FKActionSheet*Transition*.swift` | Custom modal presentation and animation |
| `Internal/` | Table UI, cells, session, validation |

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

### Instance API (recommended)

```swift
let sheet = try FKActionSheet(configuration: configuration)
try sheet.present(from: self)
// later
sheet.reload(configuration: updated)
sheet.dismiss(reason: .programmatic)
```

### Centered card

```swift
var config = FKActionSheetConfiguration(
  sections: [...],
  presentation: .centered
)
try FKActionSheet.present(configuration: config, from: self)
```

### Popover (iPad / anchored)

```swift
try FKActionSheet.present(
  configuration: config,
  from: self,
  anchoredTo: anchorButton
)

// or on an existing instance
let sheet = try FKActionSheet(configuration: config)
try sheet.present(from: self, anchoredTo: anchorButton)
```

## Custom header and rows

See existing examples in FKKitExamples for custom header/row builders and metadata patterns.

## Feature highlights

- Three presentation styles: **`.bottom`** (default), **`.centered`** (dimmed card), **`.popover`** (anchored at present time)
- Short content hugs measured height; tall content scrolls within `maximumPanelHeight` / `maximumFitContentHeightFraction`
- Dismiss reasons: `actionSelected`, `userCancel`, `tapOutside`, `programmatic`
- Tap the dimmed backdrop when `presentation.allowsTapOutsideDismiss` is `true` (default)
- `presentOnce(id:)`, `validate(_:)`, `FKActionSheet.isPresenting`, `dismissActive()`
- Dynamic Type, appearance presets, single-selection, toggles, haptics, delegate + hooks

## SwiftUI

```swift
.fkActionSheet(
  isPresented: $showSheet,
  configuration: config,
  popoverSourceView: anchorView, // optional
  onDismiss: { reason in ... },
  onPresentFailure: { error in ... }
)
```

The modifier retains the presented `FKActionSheet` and reloads when `configuration` changes while visible.

## FKKitExamples

Entry: **FKUIKit → ActionSheet** → `FKActionSheetExamplesHubViewController`

## Notes

- Retain the returned `FKActionSheet` (or your own reference) for instance-scoped dismiss, `reload`, and `updateAction`.
- **`FKActionSheet.isPresenting` / `dismissActive()`** apply to the most recent sheet from static convenience APIs.
- **`configuration.delegate`** is a weak reference on a struct; the delegate object must outlive the sheet.

## Related components

- **`FKPresentationController`** — generic sheets and detents (not used by ActionSheet)
- **`FKToast`** — transient banners
