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
| `Public/Model/` | Actions, sections, header, toggle, dismiss reasons, validation errors, lifecycle hooks, loading content |
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

## Loading content (deferred data)

When action rows are not available at present time (for example network-backed options), set
`contentMode` to `.loading(...)` instead of pre-filling placeholder rows.

```swift
var config = FKActionSheetConfiguration.loading(
  .standard(
    FKActionSheetStandardLoadingContent(
      title: "Loading options",
      message: "Fetching from the server…"
    )
  ),
  preferredPanelHeight: 196,
  cancelAction: cancel,
  hooks: hooks // lifecycle, logging, analytics
)

let sheet = try FKActionSheet(configuration: config)
try sheet.present(from: self)
self.sheet = sheet // weak retain for async updates

Task { @MainActor in
  let actions = try await fetchShareTargets()
  guard let sheet = self.sheet, sheet.isPresented else { return }

  sheet.finishLoading(
    sections: [FKActionSheetSection(actions: actions)],
    header: .text(FKActionSheetHeader(title: "Share"))
  )
}
```

### `finishLoading` merges configuration

`finishLoading(_:)` keeps the **presented** sheet's `appearance`, `presentation`, `hooks`, `selection`, `haptics`, and handler timing. Only `header`, `sections`, and `cancelAction` are copied from the argument.

Prefer the convenience overload when you only have new rows:

```swift
sheet.finishLoading(
  sections: [FKActionSheetSection(actions: actions)],
  header: .text(FKActionSheetHeader(title: "Share"))
)
// cancelAction: nil → keeps the existing cancel row
```

Or mutate a copy of the current configuration:

```swift
sheet.finishLoading { config in
  config.sections = [FKActionSheetSection(actions: actions)]
  config.header = .text(FKActionSheetHeader(title: "Share"))
}
```

### Lifecycle and cancellation

- Retain the `FKActionSheet` with a `weak` reference.
- Check `sheet.isPresented` before `finishLoading` / `setLoading`.
- Cancel in-flight work in `hooks.didDismiss` (and optionally start the request in `hooks.didPresent`).

### Failure and retry (stay on the sheet)

Keep `contentMode = .loading` for failures. Swap the loading body with custom content (for example an embedded ``FKEmptyStateView`` with a Retry button) via `setLoading(_:)` — do **not** use an action row for Retry unless you set `dismissesSheetWhenSelected = false`.

```swift
sheet.setLoading(
  FKActionSheetLoadingConfiguration(
    content: .custom(/* FKEmptyStateView with Retry */),
    preferredPanelHeight: 196
  )
)

// Retry handler:
sheet.setLoading(standardLoadingConfiguration)
// …then fetch again
```

For hard failures where the sheet should close, `dismiss` + `FKToast` remains appropriate.

### Accessibility

After loading transitions to action rows, the sheet posts a VoiceOver `screenChanged` notification and focuses the first actionable row when available.

### API summary

| API | Role |
|-----|------|
| `FKActionSheetContentMode.loading` | Shows centered loading UI; sections may be empty |
| `FKActionSheetStandardLoadingContent` | Optional spinner, title, and/or message (any subset); fonts and colors |
| `FKActionSheetCustomLoadingContent` | Host-provided loading view via build/update provider |
| `FKActionSheetLoadingConfiguration.preferredPanelHeight` | Panel body height while loading |
| `showsCancelWhileLoading` | Keeps the separated cancel row visible during fetch |
| `finishLoading(sections:header:cancelAction:)` | Merge rows into the presented sheet |
| `finishLoading(updating:)` | Merge via in-place configuration mutation |
| `setLoading(_:)` | Show loading again (for example before retry) |

Validation allows empty sections while `contentMode` is `.loading`. Standard loading requires at least one of: spinner (`showsActivityIndicator`), `title`, or `message`.

Spinner-only:

```swift
.standard(FKActionSheetStandardLoadingContent(showsActivityIndicator: true))
```

Title-only (no spinner):

```swift
.standard(FKActionSheetStandardLoadingContent(
  showsActivityIndicator: false,
  title: "Loading…"
))
```

### SwiftUI

Keep `isPresented` true and replace the bound `configuration` when data arrives (same merge rules apply if you rebuild from the presented sheet's settings):

```swift
@State private var config = FKActionSheetConfiguration.loading(...)

// After fetch:
config = sheetEquivalentConfig.finishingLoading(mergingContentFrom: loadedContent)
// or rebuild config with contentMode = .actions and new sections
```

The modifier reloads an already-presented sheet when `configuration` changes.

## Presentation styles

| Style | API |
|-------|-----|
| `.bottom` | `present(from:)` |
| `.centered` | Set `presentation: .centered`, then `present(from:)` |
| `.popover` | `present(from:anchoredTo:)` |

Window/scene hosting: `try sheet.present(in: windowScene)`.

## Callbacks

Use `FKActionSheetLifecycleHooks` on `FKActionSheetConfiguration` for lifecycle and row selection (`didSelect`). For single- and multiple-selection modes, `didSelect` receives `action.isSelected` **after** the tap. Action rows invoke `actionHandler` according to `handlerTiming`.

## Selection

| Mode | API |
|------|-----|
| Single | `selection.mode = .single(scope: .allSections)` + `selectedActionID` |
| Multiple | `selection.mode = .multiple(MultipleSelection(...))` + `selectedActionIDs` |

Multiple selection supports `maxSelectionCount` and `disablesUnselectedRowsAtMax` (dims and blocks unselected rows when the max is reached). Read `selection.selectedCount` for the current number of selected rows.

When the list scrolls inside the sheet, set `selectedActionID` / `selectedActionIDs` and leave `scrollsToSelectionOnPresent` at its default (`true`) to scroll the restored selection near the vertical center of the visible list on present (single: that row; multiple: the last selected row in table order). Set `scrollsToSelectionOnPresent` to `false` to disable.

`present` and `init` throw `FKActionSheetValidationError` for invalid configurations. Empty sections are allowed when `contentMode` is `.loading`. `reload(configuration:)` and `updateAction(_:)` return `false` when validation fails (and emit `assertionFailure` in debug). Use `FKActionSheetValidationError.localizedMessage` for user-facing copy.

## Panel height

Scrollable height is capped by `min(screenHeight × maximumFitContentHeightFraction, maximumPanelHeight)` when `maximumPanelHeight` is set; otherwise the fraction alone applies.

## SwiftUI

```swift
.fkActionSheet(
  isPresented: $showSheet,
  configuration: config,
  popoverSourceView: anchorView,
  onDismiss: { reason in ... }
)
```

See **Loading content → SwiftUI** for deferred data with the same `configuration` binding.

## FKKitExamples

**FKUIKit → ActionSheet** — covers instance present, centered card hub, loading (bottom + centered), popover anchors, reload/updateAction, builder, SwiftUI bridge.

## Notes

- Presenting the same instance twice throws `FKActionSheetValidationError.alreadyPresented`.
- Use `sheet.isPresented` on a retained instance to check on-screen state.

## Related components

- **`FKToast`** — transient banners
