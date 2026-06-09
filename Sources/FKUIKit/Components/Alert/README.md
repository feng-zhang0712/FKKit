# FKAlert

Centered confirmation dialog for UIKit apps, built on ``FKSheetPresentationController`` (`.center` / `centerAlert` preset). Use it for destructive confirmations, blocking errors, rename prompts, and compliance acknowledgements — not for bottom action lists (`FKActionSheet`) or transient status (`FKToast`).

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit` (depends on `FKCoreKit` for ``FKAlertAction``)

## Source layout

| Path | Role |
|------|------|
| `Public/FKAlert.swift` | Ergonomic `confirm` / `prompt` helpers |
| `Public/FKAlertPresenter.swift` | Shared presenter: `present`, `presentOnce`, `dismiss` |
| `Public/FKAlertViewController.swift` | Sheet content root |
| `Public/FKAlertContent.swift` | Declarative content, icon, text input, dangerous-action options |
| `Public/FKAlertResult.swift` | Async result model |
| `Public/FKAlertConfiguration.swift` | Presentation, appearance, interaction, queue policy |
| `Public/FKAlertPresets.swift` | `destructiveConfirm`, `informational`, `textPrompt` |
| `Public/FKAlertDelegate.swift` | Optional lifecycle delegate |
| `Public/Bridge/FKAlertModifier.swift` | SwiftUI `View.fkAlert` |
| `Internal/FKAlertCoordinator.swift` | Queue, de-duplication, presentation orchestration |
| `Internal/FKAlertContentView.swift` | Adaptive body + pinned button layout; body scroll only on overflow |
| `Internal/FKAlertButtonStackView.swift` | Vertical (default) or horizontal pair button stack |
| `Internal/FKAlertActionResolver.swift` | Action trimming, ordering, sheet preset resolution |

## Quick start

```swift
import FKUIKit

let confirmed = await FKAlert.confirm(
  title: "Delete item?",
  message: "This cannot be undone.",
  confirmTitle: "Delete",
  isDestructive: true,
  configuration: FKAlertPresets.destructiveConfirm()
)
```

Full control:

```swift
let result = await FKAlertPresenter.shared.present(
  FKAlertContent(
    title: "Rename",
    message: nil,
    actions: [
      FKAlertAction(title: "Save", style: .default),
      FKAlertAction(title: "Cancel", style: .cancel),
    ],
    textInput: FKAlertTextInput(placeholder: "Name")
  ),
  from: self,
  configuration: FKAlertPresets.textPrompt()
)
```

De-duplication (BusinessKit-compatible id semantics):

```swift
let result = await FKAlertPresenter.shared.presentOnce(
  FKAlertContent(id: "network-error", title: "Error", message: "Try again.", actions: [okAction])
)
// Returns `nil` when the same id is already visible.
```

## Component selection

| Pattern | Component |
|---------|-----------|
| Bottom action list | `FKActionSheet` |
| Centered blocking confirm / prompt | **`FKAlert`** |
| Brief non-blocking message | `FKToast` |
| System chrome only (no FKUIKit styling) | `FKBusinessAlertManager` |

## Related docs

- Design: `docs/FKAlert_DESIGN.md`
- Examples: `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Alert/`
- Sheet infra: `SheetPresentationController/README.md`
- BusinessKit alerts: `FKCoreKit/Components/BusinessKit/README.md`
