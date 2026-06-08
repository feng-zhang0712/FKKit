# FKAlert — Design Requirements

Implementation guide for FKKit **`FKAlert`**: a styled **centered confirmation dialog** built on **`FKSheetPresentationController`** (`.center` mode), replacing visual and UX limitations of raw `UIAlertController` while preserving familiar alert semantics (title, message, actions, optional text field).

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.5  
**中文版本:** [FKAlert_DESIGN.zh-CN.md](FKAlert_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. Background & Problem Statement](#3-background--problem-statement)
- [4. Architectural Overview](#4-architectural-overview)
- [5. Component Boundaries](#5-component-boundaries)
- [6. Content Model](#6-content-model)
- [7. Action Buttons & Styling](#7-action-buttons--styling)
- [8. Text Input Variant](#8-text-input-variant)
- [9. Dangerous Action Patterns](#9-dangerous-action-patterns)
- [10. Presentation & Sheet Integration](#10-presentation--sheet-integration)
- [11. Queue, Stack & De-duplication](#11-queue-stack--de-duplication)
- [12. Public API Surface](#12-public-api-surface)
- [13. FKBusinessAlertManager Migration](#13-fkbusinessalertmanager-migration)
- [14. Configuration Model](#14-configuration-model)
- [15. Lifecycle & Dismissal](#15-lifecycle--dismissal)
- [16. Keyboard & Focus](#16-keyboard--focus)
- [17. Accessibility](#17-accessibility)
- [18. Motion & Haptics](#18-motion--haptics)
- [19. SwiftUI Bridge](#19-swiftui-bridge)
- [20. Security & Content Safety](#20-security--content-safety)
- [21. Proposed Source Layout](#21-proposed-source-layout)
- [22. FKKitExamples Scenarios](#22-fkkitexamples-scenarios)
- [24. Open Questions](#24-open-questions)
- [25. Revision History](#25-revision-history)

---

## 1. Executive Summary

Centered alerts are used for **destructive confirmations**, **blocking errors**, **rename prompts**, and **compliance acknowledgements**. FKKit today offers:

| Existing | Role | Gap |
|----------|------|-----|
| **`FKBusinessAlertManager`** | `UIAlertController` + `presentOnce` dedupe | Not FK-styled; limited layout |
| **`FKActionSheet`** | Bottom / migration from action sheets | Wrong paradigm for centered confirm + compact input |
| **`FKSheetPresentationController.centerAlert`** | Presentation infra | No alert content assembly |

**`FKAlert`** (`Sources/FKUIKit/Components/Alert/`) composes:

- **`FKAlertViewController`** — content root (title, message, optional `FKTextField`, buttons)
- **`FKAlertPresenter`** — presents via `FKSheetPresentationController` with `centerAlert` preset
- **`FKAlertCoordinator`** — queue, `presentOnce(id:)`, stacking policy

| Deliverable | Role |
|-------------|------|
| **`FKAlertContent`** | Sendable declarative model |
| **`FKAlertAction`** | Reuse **`FKCoreKit`** `FKAlertAction` descriptors (BusinessKit) |
| **`FKAlertPresenter`** | `present`, `presentOnce`, `dismiss` |
| **`FKAlertConfiguration`** | Visual + interaction + queue policy |

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **FK visual language** — `FKButton` primary/secondary/destructive; typography and spacing aligned with `FKActionSheet` headers (not row renderer).
2. **Center modal** — `FKSheetPresentationConfiguration.centerAlert` defaults; fitted height for content.
3. **Action sets** — up to 3 visible actions (primary, secondary, cancel/destructive) with HIG ordering.
4. **Optional single-line input** — `FKTextField` embedded (rename, feedback snippet).
5. **Danger UX** — destructive prominence; optional confirmation checkbox gating destructive tap.
6. **Queue / dedupe** — port `FKBusinessAlertManager.presentOnce` semantics; optional FIFO queue.
7. **`async` API** — `await FKAlert.present(...)` returning tapped action index / identifier.
8. **Accessibility** — VoiceOver order, keyboard, Dynamic Type.
9. **Do not duplicate** `FKActionSheet` row/stack rendering — alert uses vertical button column layout only.

### 2.2 Non-Goals (v1)

| Excluded | Notes |
|----------|------|
| Bottom action sheet UI | Use `FKActionSheet` |
| Multi-line text area alert | Use `FKCountTextView` in custom sheet |
| Arbitrary SwiftUI alert content | v1 optional `customView` UIView only |
| `UIAlertController` drop-in for every edge case | Document migration limits |
| Toast / banner | `FKToast` |
| Multi-step wizard inside alert | Host navigates VCs |
| macOS / Catalyst | iOS 15+ UIKit |

### 2.3 Success Criteria

- [ ] Delete confirmation with destructive button matches FK styling.
- [ ] Text field alert returns trimmed string on primary tap.
- [ ] `presentOnce(id:)` suppresses duplicate while visible.
- [ ] Queued second alert shows after first dismisses.
- [ ] Checkbox-gated destructive disables button until checked.
- [ ] README decision tree vs ActionSheet / Toast / BusinessAlertManager.

---

## 3. Background & Problem Statement

### 3.1 `FKBusinessAlertManager` limitations

```swift
// Current: system chrome only
let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
```

- Cannot apply `FKButton` styles or brand corner radius consistently.
- Text field styling mismatches `FKTextField`.
- Dedupe exists (`presentOnce`) but no queue or styled replacement path.

### 3.2 `FKActionSheet` boundaries

`FKActionSheet+AlertMigration` maps **action sheet** style alerts to **bottom** sheets — appropriate for "Choose photo source", not for "Delete account?".

**Normative split (roadmap R6):**

| Pattern | Component |
|---------|-----------|
| Bottom list of actions | `FKActionSheet` |
| Centered blocking confirm | **`FKAlert`** |
| Brief non-blocking message | `FKToast` |

### 3.3 Available presentation preset

`FKSheetPresentationConfiguration.centerAlert` already defines:

- Fixed width ~320, fitted height margins
- Dim backdrop 0.45 alpha
- Swipe-to-dismiss with threshold 0.28

FKAlert **must** use this preset as default (tunable via configuration).

---

## 4. Architectural Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│ Host App                                                        │
│  FKAlertPresenter.present(content:from:)                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertCoordinator (@MainActor)                                   │
│  dedupe by id │ queue │ active alert registry                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertViewController                                           │
│  title / message / icon / FKTextField? / checkbox? / FKButtons  │
└────────────────────────────┬────────────────────────────────────┘
                             │ embedded in
┌────────────────────────────▼────────────────────────────────────┐
│ FKSheetPresentationController (.center / centerAlert preset)      │
│  backdrop │ keyboard │ lifecycle │ dismiss gestures               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Component Boundaries

| Concern | FKAlert | FKActionSheet | FKBusinessAlertManager |
|---------|---------|---------------|------------------------|
| Layout | Vertical button stack | Sections + rows | System alert |
| Position | Center | Bottom / popover | Center system |
| Text field | Single-line `FKTextField` | Limited row types | `UIAlertController` field |
| Dedupe API | `presentOnce` | Separate | `presentOnce` today |
| Module | FKUIKit | FKUIKit | FKCoreKit |

FKAlert depends on: `FKSheetPresentationController`, `FKButton`, `FKTextField`, `FKCoreKit` (`FKAlertAction`, `FKI18n`).

---

## 6. Content Model

### 6.1 Core content

```swift
/// Declarative alert content. Sendable for builder APIs.
public struct FKAlertContent: Sendable, Equatable {
  public var id: String?                    // dedupe / queue key
  public var title: String?
  public var message: String?
  public var attributedMessage: Data?        // optional NSAttributedString archive; nil uses message
  public var icon: FKAlertIcon?
  public var actions: [FKAlertAction]      // FKCoreKit BusinessKit type
  public var textInput: FKAlertTextInput?
  public var dangerousAction: FKAlertDangerousActionOptions?
  public var accessibilityIdentifier: String?
}
```

### 6.2 Icon (optional)

```swift
public enum FKAlertIcon: Sendable, Equatable {
  case none
  case systemName(String, tint: FKAlertIconTint?)
  case asset(name: String, bundle: Bundle?)
}

public enum FKAlertIconTint: Sendable, Equatable {
  case primary
  case warning
  case destructive
  case custom(UIColor)  // resolved on main actor via configuration
}
```

### 6.3 Message rendering

- Title: `UIFont.TextStyle.headline` or config
- Message: `body`; supports multiline `UILabel` or `FKExpandableText` for long legal copy (config flag, default `UILabel` 5 lines max then scroll internal `UIScrollView`)

### 6.4 Empty content rules

- At least one of `title`, `message`, `icon`, `textInput` must be non-empty
- Actions empty → inject default OK action (`FKI18n` `fkcore.common.ok`) — same as `FKBusinessAlertManager`

---

## 7. Action Buttons & Styling

### 7.1 Mapping `FKAlertAction.Style` → `FKButton`

| `FKAlertAction.Style` | `FKButton` role |
|-----------------------|-----------------|
| `.default` | `.primary` or `.secondary` based on position |
| `.cancel` | `.secondary` / ghost; separate row when `showsCancelSeparately` |
| `.destructive` | `.destructive` |

### 7.2 Layout order (normative, LTR)

Vertical stack (alert convention):

1. Optional icon
2. Title
3. Message
4. Optional text field / checkbox
5. **Primary** (non-cancel, non-destructive) — if any
6. **Destructive** — full width
7. **Cancel** — bottom-most when `cancelPlacement == .bottom` (default)

When only two actions (Cancel + Delete): destructive above cancel.

### 7.3 Maximum actions

- **Visible:** up to 3 action buttons (+ checkbox is not a button)
- More than 3 in model → debug assertion; trim to cancel + destructive + first default (document)

### 7.4 Horizontal button pairs (optional config)

`FKAlertButtonLayout`:

| Mode | Use |
|------|-----|
| `.vertical` | Default; full-width buttons |
| `.horizontalPair` | Exactly 2 non-destructive actions side-by-side (rare) |

Destructive actions **never** in horizontal pair v1.

### 7.5 Disabled state

Primary/destructive disabled until:

- Text validation passes (§8)
- Dangerous checkbox checked (§9)
- `isLoading` on presenter (spinner on primary)

---

## 8. Text Input Variant

### 8.1 Model

```swift
public struct FKAlertTextInput: Sendable, Equatable {
  public var placeholder: String?
  public var initialText: String?
  public var isSecure: Bool
  public var keyboardType: UIKeyboardType
  public var textContentType: UITextContentType?
  public var autocapitalization: UITextAutocapitalizationType
  public var returnKeyType: UIReturnKeyType
  public var maxLength: Int?
  public var validation: FKAlertTextValidation?
}

public struct FKAlertTextValidation: Sendable {
  public var validate: @Sendable (String) -> Bool
  public var failureMessage: String?
}
```

`validate` runs on main actor before dismiss; failure shows inline `FKTextField` error state (reuse field error API).

### 8.2 FKTextField integration

- Single-line only v1
- Configuration from `FKAlertConfiguration.textField` overrides (appearance subset)
- On present: auto-focus field when `textInput != nil` after short delay (0.1s) for transition completion

### 8.3 Return value

`async` present API:

```swift
public enum FKAlertResult: Sendable, Equatable {
  case action(index: Int, action: FKAlertAction)
  case cancelled
  case dismissed  // swipe / backdrop if allowed
}
```

When text input present, associated `String` via:

```swift
case action(index: Int, action: FKAlertAction, text: String?)
```

---

## 9. Dangerous Action Patterns

### 9.1 Destructive styling

- Destructive button uses `FKButton` destructive preset
- Optional top **warning** icon (`.warning` tint)
- Message copy should be explicit (host responsibility); optional `dangerousAction.messageHighlight` substring styling

### 9.2 Confirmation checkbox

```swift
public struct FKAlertDangerousActionOptions: Sendable, Equatable {
  public var requiresConfirmationCheckbox: Bool
  public var checkboxTitle: String       // e.g. "I understand this cannot be undone"
  public var destructiveActionIndex: Int?  // nil = first .destructive action
}
```

- Destructive button `isEnabled = false` until checked
- Checkbox: `UISwitch` or `FKCheckbox` when shipped (if FKCheckbox includes checkbox, use it; else `UISwitch` v1 with FK colors)

### 9.3 Two-step destructive (optional v1.1)

Document pattern: first alert explains → second alert confirms. v1 single alert with checkbox is sufficient.

### 9.4 Rate limiting

Optional `minimumDismissInterval` after destructive tap before handler fires (anti-mis-tap) — default 0; document for finance apps.

---

## 10. Presentation & Sheet Integration

### 10.1 Default sheet configuration

```swift
public struct FKAlertPresentationConfiguration: Sendable, Equatable {
  public var sheet: FKSheetPresentationConfiguration  // default .centerAlert
  public var allowsBackdropTapToDismiss: Bool         // default false for confirms
  public var allowsSwipeToDismiss: Bool               // from sheet center config
  public var cornerRadius: CGFloat?
}
```

**Normative defaults for destructive alerts:**

- `allowsBackdropTapToDismiss = false`
- `allowsSwipeToDismiss = false` when `dangerousAction != nil`

### 10.2 Presenter

```swift
@MainActor
public final class FKAlertPresenter {
  public static let shared: FKAlertPresenter

  public func present(
    _ content: FKAlertContent,
    from presenter: UIViewController? = nil,
    configuration: FKAlertConfiguration = .init()
  ) async -> FKAlertResult

  public func presentOnce(
    _ content: FKAlertContent,
    from presenter: UIViewController? = nil,
    configuration: FKAlertConfiguration = .init()
  ) async -> FKAlertResult?

  public func dismiss(animated: Bool)
}
```

`presentOnce`: if `content.id` already presenting → return `nil` immediately (match BusinessKit).

### 10.3 FKAlertViewController

- Subclass or compose `UIViewController` with intrinsic content size
- Installed as sheet content child per `FKSheetPresentationController` patterns (read neighbor sheet content VCs)

---

## 11. Queue, Stack & De-duplication

### 11.1 Policies

```swift
public enum FKAlertQueuePolicy: Sendable, Equatable {
  case singleActive          // new alert waits in FIFO queue
  case replaceCurrent        // dismiss active, show new
  case allowStack            // multiple center alerts (discouraged)
  case presentOnceByID       // skip if same id active (no queue)
}
```

| Policy | Behavior |
|--------|----------|
| `singleActive` | Queue pending `FKAlertContent` until dismiss |
| `replaceCurrent` | Dismiss without calling handlers; show new |
| `allowStack` | Multiple modals (debug only flag) |
| `presentOnceByID` | Same as `FKBusinessAlertManager.presentOnce` |

Default: **`singleActive`** for `present`; **`presentOnceByID`** for `presentOnce`.

### 11.2 Coordinator state

```text
idle → presenting(content A) → dismissing → presenting(content B from queue)
```

Track `activeID: String?`, `queue: [FKAlertRequest]`.

### 11.3 Handler invocation

- Button tap → dismiss animated → then `FKAlertAction.handler`
- Cancel/swipe → `FKAlertResult.cancelled` / `.dismissed`; **no** destructive handler
- Order: dismiss completes before handler (avoid re-entrant present)

---

## 12. Public API Surface

### 12.1 Builder (ergonomic)

```swift
public enum FKAlert {
  public static func confirm(
    title: String,
    message: String?,
    confirmTitle: String,
    cancelTitle: String = FKI18n.string("fkcore.common.cancel"),
    isDestructive: Bool = false,
    from presenter: UIViewController? = nil
  ) async -> Bool

  public static func prompt(
    title: String?,
    message: String?,
    placeholder: String?,
    confirmTitle: String,
    from presenter: UIViewController? = nil
  ) async -> String?
}
```

### 12.2 Configuration root

```swift
public struct FKAlertConfiguration: Sendable, Equatable {
  public var presentation: FKAlertPresentationConfiguration
  public var appearance: FKAlertAppearanceConfiguration
  public var interaction: FKAlertInteractionConfiguration
  public var textField: FKAlertTextFieldConfiguration
  public var queue: FKAlertQueuePolicy
  public var buttonLayout: FKAlertButtonLayout
  public var motion: FKAlertMotionConfiguration
  public var accessibility: FKAlertAccessibilityConfiguration
}
```

### 12.3 Presets

```swift
public enum FKAlertPresets {
  public static func destructiveConfirm() -> FKAlertConfiguration
  public static func informational() -> FKAlertConfiguration
  public static func textPrompt() -> FKAlertConfiguration
}
```

---

## 13. FKBusinessAlertManager Migration

### 13.1 Coexistence (v1)

- **`FKBusinessAlertManager`** remains in FKCoreKit for apps not yet on FKUIKit styling.
- Add optional backend flag (future BusinessKit):

```swift
public enum FKBusinessAlertBackend {
  case systemAlert
  case fkAlert  // routes to FKAlertPresenter when FKUIKit linked
}
```

Document in FKAlert README; implementation of flag is **optional v1.1** — design reserves path.

### 13.2 API mapping

| BusinessKit | FKAlert |
|-------------|---------|
| `FKAlertAction` | Same type |
| `presentOnce(id:title:message:actions:)` | `FKAlertPresenter.presentOnce(FKAlertContent(id:...))` |
| `UIAlertController` styles | N/A — FKAlert single style |

### 13.3 Deprecation story

Long-term: encourage `FKAlertPresenter` for UI apps; keep `FKAlertAction` model in FKCoreKit as shared descriptor.

---

## 14. Configuration Model

### 14.1 Appearance

```swift
public struct FKAlertAppearanceConfiguration: Sendable, Equatable {
  public var titleTextStyle: UIFont.TextStyle
  public var messageTextStyle: UIFont.TextStyle
  public var contentInsets: NSDirectionalEdgeInsets
  public var buttonSpacing: CGFloat
  public var iconSize: CGFloat
  public var maxMessageHeight: CGFloat?  // scroll beyond
}
```

### 14.2 Interaction

```swift
public struct FKAlertInteractionConfiguration: Sendable, Equatable {
  public var autoFocusTextField: Bool
  public var dismissOnPrimaryAction: Bool  // default true
  public var hapticOnDestructive: Bool
}
```

---

## 15. Lifecycle & Dismissal

### 15.1 Events

```swift
@MainActor
public protocol FKAlertDelegate: AnyObject {
  func alertWillPresent(_ alert: FKAlertViewController)
  func alertDidDismiss(_ alert: FKAlertViewController, result: FKAlertResult)
}
```

### 15.2 Rotation / size class

Sheet center mode reflows; alert content uses auto layout; width capped by `centerAlert` preset on iPad.

### 15.3 Memory

Weak presenter reference; coordinator clears on dismiss. No retain cycle with action handlers — use `[weak presenter]` pattern in docs.

---

## 16. Keyboard & Focus

- Reuse `FKSheetPresentationController` keyboard avoidance for center mode
- Text field alerts: sheet shifts up when keyboard visible
- `return` key on field triggers primary validation path

---

## 17. Accessibility

- Announce title + message on appear (`UIAccessibility.post`)
- Focus first element: field if present, else title
- Buttons have traits `.button`; destructive has custom hint optional
- Checkbox linked via `accessibilityLabel` to destructive button enablement state

---

## 18. Motion & Haptics

- Present/dismiss: inherit sheet animation preset `.systemLike`
- Reduce Motion: cross-fade only
- Destructive confirm: optional `UINotificationFeedbackGenerator.warning` on success validation before dismiss

---

## 19. SwiftUI Bridge

```swift
public struct FKAlertModifier: ViewModifier {
  public var isPresented: Binding<Bool>
  public var content: FKAlertContent
  public var onResult: (FKAlertResult) -> Void
}

public extension View {
  func fkAlert(isPresented: Binding<Bool>, content: FKAlertContent, onResult: @escaping (FKAlertResult) -> Void) -> some View
}
```

Uses `UIViewControllerRepresentable` presenter anchor or `UIHostingController` bridge pattern consistent with `FKActionSheetModifier`.

---

## 20. Security & Content Safety

- Do not log text field secure content
- Host must not put secrets in `message` logs
- Destructive actions should require explicit user tap (no auto-dismiss timers v1)

---

## 21. Proposed Source Layout

```text
Sources/FKUIKit/Components/Alert/
├── README.md
├── Public/
│   ├── FKAlert.swift                    // builder enums
│   ├── FKAlertPresenter.swift
│   ├── FKAlertViewController.swift
│   ├── FKAlertContent.swift
│   ├── FKAlertResult.swift
│   ├── FKAlertTextInput.swift
│   ├── FKAlertDangerousActionOptions.swift
│   ├── FKAlertConfiguration.swift
│   ├── FKAlertPresets.swift
│   ├── FKAlertDelegate.swift
│   └── Bridge/
│       └── FKAlertModifier.swift
├── Internal/
│   ├── FKAlertCoordinator.swift
│   ├── FKAlertContentView.swift
│   ├── FKAlertButtonStackView.swift
│   └── FKAlert+SheetHosting.swift
└── Extension/
    └── FKAlertContent+FKAlertAction.swift
```

---

## 22. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/Alert/`

| # | Scenario | Validates |
|---|----------|-----------|
| 1 | `DestructiveDelete` | Delete account copy + destructive button |
| 2 | `TextFieldRename` | Prompt returns string |
| 3 | `PresentOnceDedup` | Same id suppressed |
| 4 | `QueuedAlerts` | Second shows after first |
| 5 | `CheckboxGatedDelete` | Destructive disabled until checked |
| 6 | `ValidationFailure` | Inline field error |
| 7 | `InformationalOK` | Single OK |
| 8 | `LongLegalMessage` | Scrollable message area |
| 9 | `SwiftUIModifier` | Binding present |
| 10 | `iPadCenterSizing` | centerAlert margins |
| 11 | `BackdropDismissPolicy` | non-destructive allows tap |
| 12 | `VoiceOverOrder` | accessibility audit |

---

## 24. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Reuse `FKAlertAction` from FKCoreKit? | Yes |
| Q2 | Checkbox control v1? | `UISwitch` until `FKCheckbox` ships |
| Q3 | `FKBusinessAlertManager` backend flag? | Document only; later release |
| Q4 | Max 3 buttons enforced? | Yes |
| Q5 | Horizontal button pair in v1? | Optional config, off default |

---

## 25. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial design requirements from COMPONENT_ROADMAP §1.5 |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKSheetPresentationController README](../Sources/FKUIKit/Components/SheetPresentationController/README.md)
- [FKActionSheet README](../Sources/FKUIKit/Components/ActionSheet/README.md)
- [FKBusinessKit README](../Sources/FKCoreKit/Components/BusinessKit/README.md)
- [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md) — `FKCheckbox` timing
