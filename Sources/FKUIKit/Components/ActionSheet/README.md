# FKActionSheet

HIG-oriented action sheet for UIKit apps. The sheet is a modal `UIViewController` (`FKActionSheet`) with custom transitions for bottom/centered styles and UIKit popover support. This module owns the action list UI and configuration model.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

| Path | Role |
|------|------|
| `Public/FKActionSheet.swift` | Modal container VC, lifecycle, `reload`, `updateAction`, `dismiss` |
| `Public/FKActionSheet+Presentation.swift` | Instance `present(from:)`, popover anchors, selection handling |
| `Internal/FKActionSheet+Layout.swift` | Bottom / centered / popover panel constraints and sizing |
| `Public/Configuration/` | Appearance, presentation, haptics, selection |
| `Public/Model/` | Actions, sections, header, toggle, dismiss reasons, validation errors, lifecycle hooks |
| `Public/SwiftUI/FKActionSheetModifier.swift` | `View.fkActionSheet` modifier |
| `Extension/` | Builder, handlers, toggle, SF Symbol, alert migration, selection scope |
| `Internal/FKActionSheetTransitioningDelegate.swift` | Custom modal presentation delegate |
| `Internal/FKActionSheetAnimator.swift` | Bottom/centered transition animations |
| `Internal/FKActionSheetUIKitPresentationController.swift` | Dimmed backdrop (tap handled on sheet view) |
| `Internal/` | Table UI, cells, session, validation, haptics |

## Quick start

```swift
import FKUIKit

let configuration = FKActionSheetConfiguration(
  header: FKActionSheetHeader(title: "Photo", message: "Choose an action"),
  sections: [FKActionSheetSection(actions: [share, delete])],
  cancelAction: cancel
)

let sheet = try FKActionSheet(configuration: configuration)
try sheet.present(from: self)
```

Retain the `FKActionSheet` instance for `reload`, `updateAction`, and programmatic `dismiss`.

## Presentation styles

| Style | API |
|-------|-----|
| `.bottom` | `present(from:)` |
| `.centered` | Set `presentation: .centered`, then `present(from:)` |
| `.popover` | `present(from:anchoredTo:)` |

Window/scene hosting: `try sheet.present(in: windowScene)`.

## Callbacks

Use `FKActionSheetLifecycleHooks` on `FKActionSheetConfiguration` for lifecycle and row selection (`didSelect`). Action rows invoke `actionHandler` according to `handlerTiming`.

## SwiftUI

```swift
.fkActionSheet(
  isPresented: $showSheet,
  configuration: config,
  popoverSourceView: anchorView,
  onDismiss: { reason in ... }
)
```

## FKKitExamples

**FKUIKit → ActionSheet** — covers instance present, popover anchors, window scene, backdrop dismiss, reload/updateAction, builder, SwiftUI bridge.

## Notes

- Presenting the same instance twice throws `FKActionSheetValidationError.alreadyPresented`.
- Use `sheet.isPresented` on a retained instance to check on-screen state.

## Related components

- **`FKPresentationController`** — generic sheets and detents (separate from ActionSheet)
- **`FKToast`** — transient banners
