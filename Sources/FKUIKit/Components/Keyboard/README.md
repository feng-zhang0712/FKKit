# FKKeyboard

Opt-in **keyboard toolkit** for UIKit: observation, avoidance, focus scrolling, form navigation, accessory toolbar, tap-to-dismiss, and `keyboardLayoutGuide` helpers. No global swizzling — compose only what each screen needs.

## Requirements

- iOS 15+
- Swift 6
- `import FKUIKit` (depends on FKCoreKit)

## Source layout

Paths live under `Sources/FKUIKit/Components/Keyboard/`.

### `Public/`

| Folder / file | Role |
|---------------|------|
| `Core/FKKeyboard.swift` | Facade: animate-alongside, end editing |
| `Core/FKKeyboardInfo.swift` | Keyboard frame / animation snapshot |
| `Core/FKKeyboardObserver.swift` | Opt-in notification observer |
| `Types/FKKeyboardAvoidanceStrategy.swift` | Shared avoidance strategy enum (also used by Sheet) |
| `Configuration/*` | Sendable / Equatable configuration structs |
| `Avoidance/FKKeyboardAvoidanceController.swift` | Inset or translate avoidance |
| `Focus/FKKeyboardFormNavigator.swift` | Previous / next / done, Return handling, focus tracking |
| `Focus/FKKeyboardFocusScroller.swift` | Scroll first responder or ``alignBottom(of:)`` sticky cell into view |
| `Toolbar/FKKeyboardToolbar.swift` | `inputAccessoryView` toolbar + batch install |
| `Dismiss/FKKeyboardDismissController.swift` | Tap outside to dismiss |
| `Layout/FKKeyboardLayout.swift` | Pin bottoms to `keyboardLayoutGuide` |

### `Internal/`

| File | Role |
|------|------|
| `FKKeyboardNotificationParsing.swift` | `userInfo` → `FKKeyboardInfo` |
| `FKKeyboardEditingObservation.swift` | Begin-editing notifications for fields |
| `FKKeyboardScrollInsetApplier.swift` | Capture / restore scroll insets |
| `FKKeyboardVisibleRectScrolling.swift` | IQ-style inset-aware focus alignment + short-content top inset |
| `FKKeyboardScrollViewDiscovery.swift` | Primary scroll-view DFS |

## API overview

| Type | Purpose |
|------|---------|
| `FKKeyboardObserver` | Subscribe to keyboard frame changes |
| `FKKeyboardAvoidanceController` | Apply `.adjustContentInsets` (with focus scroll) / `.adjustContainer` / `.interactive` |
| `FKKeyboardFocusScroller` | Keep the focused field visible, or pin an arbitrary view with `alignBottom(of:)` |
| `FKKeyboardFormNavigator` + `FKKeyboardToolbar` | Field chaining + accessory bar |
| `FKKeyboardDismissController` | Tap-to-dismiss |
| `FKKeyboardLayout` | Auto Layout keyboard guide pins |
| `FKKeyboard.animate(alongside:)` | Match system keyboard animation |

### Threading

All controllers and UI helpers are **`@MainActor`**. `FKKeyboardInfo` is a `Sendable` value type.

### Design

Normative design: [`docs/FKKeyboard_DESIGN.md`](../../../../docs/FKKeyboard_DESIGN.md).

## Quick start

### Layout guide (preferred for new scroll UIs)

```swift
import UIKit
import FKUIKit

FKKeyboardLayout.pinScrollViewBottom(scrollView, toKeyboardTopOf: view)
```

### Content-inset avoidance

```swift
let avoidance = FKKeyboardAvoidanceController(
  hostView: view,
  configuration: .init(strategy: .adjustContentInsets)
)
avoidance.scrollView = scrollView
avoidance.start()
// viewWillDisappear:
avoidance.stop()
```

### Toolbar + form navigator

```swift
let navigator = FKKeyboardFormNavigator()
let toolbar = FKKeyboardToolbar()
toolbar.install(onFormRoot: formContainer, navigator: navigator)

// In UITextFieldDelegate.textFieldShouldReturn:
_ = navigator.handleReturn(from: textField)
return true
```

### Tap to dismiss

```swift
let dismiss = FKKeyboardDismissController(containerView: view)
dismiss.start()
```

### Avoidance notes

- **Scroll views** always use content-inset avoidance (even if you pass `.adjustContainer` / `.interactive`). Transforming a full-screen `UIScrollView` lifts the whole viewport and creates a blank band above the keyboard.
- **Fixed cards** should set `containerView` to the card and use `.adjustContainer` / `.interactive`; lift distance is based on the first responder when present.
- Focus scrolling defaults to **minimum movement**: only adjusts offset when the keyboard would cover the focused field (or violate `keyboardDistanceFromFocusedView`). Set `alignsFocusedViewToKeyboard = true` for IQKeyboardManager-like pinning. Short content still gets a temporary **top** inset when a reveal requires it. Overlap for bottom inset is measured in the **scroll view** bounds so a `FKKeyboardLayout`-pinned footer is not double-counted.
- **Comment / reply lists:** call ``FKKeyboardFocusScroller/alignContentRect(_:toKeyboardUsing:additionalBottomInset:)`` with `tableView.rectForRow(at:)` (preferred over a reusable cell). That keeps a sticky content rect so begin-editing on the composer does not steal the target. Prefer pinning the composer with ``FKKeyboardLayout`` and `appliesKeyboardBottomInset = false` so inset ownership stays clear.
- Prefer ``FKKeyboardAvoidanceController``’s built-in focus scroll for forms. Use ``FKKeyboardFocusScroller`` when you need focus scrolling **without** a separate avoidance owner — do not stack both on the same scroll view (they each manage insets).

## Notes

- **Not** a drop-in IQKeyboardManager replacement (no global install / swizzle) — hosts start/stop controllers explicitly. IQ-style pin is opt-in via `alignsFocusedViewToKeyboard` or `alignBottom(of:)`.
- Custom `inputView` keyboards are out of scope; attach them on TextField and reuse `FKKeyboardObserver` if needed.
- Sheet presentation continues to use `FKKeyboardAvoidanceStrategy`; a later migration will share Internal appliers.

## Examples

Entry: **FKKitExamples → FKUIKit → Keyboard** (`FKKeyboardExamplesHubViewController`).

| Section | Scenarios |
|---------|-----------|
| Observation | Observer & `FKKeyboardInfo` |
| Avoidance | Content insets, align to keyboard, container translate, interactive, external observer feed, disabled |
| Layout guide | Pin to `keyboardLayoutGuide` |
| Focus & form | Focus scroller, align cell to keyboard, navigator + toolbar, Return key, toolbar configuration |
| Dismiss | Tap to dismiss |
| Facade & recipes | Animate / endEditing, full form recipe |

## See also

- `FKTextField` — input traits and linkage
- `FKSheetPresentationController` — sheet-specific avoidance configuration
- FKBusinessKit `Base` — view-controller lifecycle glue (consumes these primitives over time)
