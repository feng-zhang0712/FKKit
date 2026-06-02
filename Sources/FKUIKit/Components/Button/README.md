# FKButton

UIKit control for production buttons: multi-state title and subtitle, optional leading/center/trailing images, custom embedded views, gradients, loading states, throttled primary actions, and optional haptics / sound / pointer feedback.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Source layout

Same layering as **`Badge`**: **`Public`** (types you configure from app code), **`Internal`** (layout helpers), **`Extension`** (builder chain and Interface Builder). Paths live under `Sources/FKUIKit/Components/Button/`.

### `Public/`

| Directory | Role |
|-----------|------|
| `Configuration/` | Content/element/state models and accessibility configuration |
| `Appearance/` | `FKButtonAppearance`, `FKButtonGlobalStyle` |
| `Feedback/` | Haptics, sound, pointer configuration structs |
| `Loading/` | `FKButtonLoadingPresentation`, indicator + transient result types |
| `Aliases/` | `FKButton.Content`, `FKButton.Appearance`, … short typealiases |
| `FKButton/` | `FKButton` control implementation (see subfolders below) |

#### `Public/Configuration/`

| File | Role |
|------|------|
| `FKButtonContentConfiguration.swift` | Content kind (text / image / text+image / custom) |
| `FKButtonElementConfiguration.swift` | `FKButtonLabelConfiguration`, `FKButtonImageConfiguration`, `FKButtonCustomContentConfiguration` |
| `FKButtonStateModel.swift` | Bundle model for `setModel(_:for:)` |
| `FKButtonAccessibilityConfiguration.swift` | Optional VoiceOver label/value/hint providers |

#### `Public/Appearance/`

| File | Role |
|------|------|
| `FKButtonAppearance.swift` | `FKButtonAppearance`, corners, border, shadow, gradient, `FKButtonStateAppearances` |
| `FKButtonGlobalStyle.swift` | Process-wide defaults for new instances |

#### `Public/Feedback/`

| File | Role |
|------|------|
| `FKButtonFeedbackConfigurations.swift` | Haptics, sound, pointer configuration structs |

#### `Public/Loading/`

| File | Role |
|------|------|
| `FKButtonLoadingPresentation.swift` | `FKButtonLoadingPresentation` + replacement options |
| `FKButtonLoadingIndicatorConfiguration.swift` | Built-in spinner style, scale, and tint |
| `FKButtonTransientResult.swift` | Brief success/failure/custom feedback types |

#### `Public/Aliases/`

| File | Role |
|------|------|
| `FKButtonAliases.swift` | `FKButton.Content`, `FKButton.Appearance`, … scoped typealiases |

#### `Public/FKButton/Foundation/`

| File | Role |
|------|------|
| `FKButton.swift` | Nested types, stored properties, inits, `deinit`, `isEnabled` / `isSelected` / `isHighlighted` |
| `FKButton+Setup.swift` | `commonInit()`, `prepareForInterfaceBuilder()`, global defaults |
| `FKButton+PublicAPI.swift` | `setModel`, labels, images, appearance, batch updates |
| `FKButton+Layout.swift` | Content alignment overrides, `intrinsicContentSize`, `layoutSubviews`, hit testing hook |
| `FKButton+LayoutEngine.swift` | Stack alignment, refresh pipeline, title/image/custom host lifecycle |
| `FKButton+StackContent.swift` | Arranged subview composition for `content.kind` |

#### `Public/FKButton/Presentation/`

| File | Role |
|------|------|
| `FKButton+ContentRendering.swift` | Text/image resolution, symbol effects (iOS 17+), padded symbols |
| `FKButton+AppearanceRendering.swift` | Background, border, shadow, pressed visuals, `activeImageElements` |
| `FKButton+Accessibility.swift` | VoiceOver traits and default label/value/hint |

#### `Public/FKButton/Interaction/`

| File | Role |
|------|------|
| `FKButton+ControlDispatch.swift` | `sendActions` / `sendAction`, primary-action throttling |
| `FKButton+InteractionGestures.swift` | Hit bounds helpers, long-press handler |
| `FKButton+Feedback.swift` | Haptics/sound dispatch, pointer hover sync |
| `FKButton+PointerInteraction.swift` | `UIPointerInteractionDelegate` |
| `FKButton+Loading.swift` | `setLoading`, `performWhileLoading`, `showTransientResult`, overlay views |

### `Internal/`

| File | Role |
|------|------|
| `FKButtonCustomContentHostView.swift` | Intrinsic sizing host for `.custom` content inside the stack |

### `Extension/`

| File | Role |
|------|------|
| `FKButton+Builder.swift` | `withMinimumTapInterval`, `withContent`, … fluent API |
| `FKButton+InterfaceBuilder.swift` | `fk_*` `@IBInspectable` properties |
| `FKButton+Badge.swift` | `configureBadge` convenience over `UIView.fk_badge` |

## Naming convention

- **Module-level types** use the `FKButton…` prefix (`FKButtonAppearance`, `FKButtonLabelConfiguration`, …). These names are stable in docs and binary-compatible evolution.
- **Scoped aliases** under `FKButton` (`FKButton.Appearance`, `FKButton.LabelAttributes`, …) are ergonomic shorthand; use either style consistently.

## Quick start

```swift
import UIKit
import FKUIKit

let button = FKButton()
button.content = .textOnly
button.setTitle(.init(text: "Continue", font: .boldSystemFont(ofSize: 17), color: .white), for: .normal)
button.setAppearances(.init(normal: .filled(backgroundColor: .systemBlue, cornerStyle: .init(corner: .fixed(12)))))
button.addAction(UIAction { _ in … }, for: .touchUpInside)
```

Text + leading symbol:

```swift
button.content = .textAndImage(.leading)
button.setLeadingImage(.init(systemName: "paperplane.fill", tintColor: .white), slot: .leading, for: .normal)
```

Use `setLeadingImage` / `setTrailingImage` / `setCenterImage` convenience APIs instead of `setImage(_:slot:for:)` when the slot is fixed.

## Control events

`FKButton` subclasses **`UIControl`**, not `UIButton`. UIKit’s default touch tracking delivers **`.touchUpInside`** on a successful finger tap. **`.primaryActionTriggered`** is a semantic event: on `UIButton` it mirrors `touchUpInside`, but on a plain `UIControl` it is **not** guaranteed for finger taps (it is used for accessibility activation, hardware keyboard, tvOS focus, and similar paths).

### What to register

| Input | Recommended event |
|-------|-------------------|
| Finger tap (iPhone / iPad touch) | **`.touchUpInside`** |
| VoiceOver activate, external keyboard, other non-touch primary actions | **`.primaryActionTriggered`** (in addition, not instead) |

**Default:** use **`.touchUpInside`** only — same as Quick start above and most FKUIKit components.

**Do not** register the same handler for **both** `.touchUpInside` and `.primaryActionTriggered` unless you intentionally want coverage for non-touch inputs *and* accept that some platforms may deliver both events for one gesture (duplicate callbacks). Prefer a single event when finger tap is enough.

**Do not** use **only** `.primaryActionTriggered` for touch-only UI (for example tab items); the handler may never run.

### Throttling and feedback

`minimumTapInterval` and primary-action haptics / sound apply to **either** `.touchUpInside` or `.primaryActionTriggered` (see `FKButton+ControlDispatch.swift`). Loading and transient-result presentation suppress **all** primary dispatches until cleared.

### Full input coverage (optional)

When a control must respond to both touch and accessibility / keyboard primary action, register **both** events with the **same** action only if you need that breadth. The ProgressBar button-mode example documents this pattern:

`Examples/FKKitExamples/.../FKUIKit/ProgressBar/Scenarios/FKProgressBarProgressButtonExampleViewController.swift`

```swift
button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
button.addAction(UIAction { _ in onTap() }, for: .primaryActionTriggered)
```

Internal library code (for example `FKTabBar` item cells) should use **`.touchUpInside`** unless a scenario explicitly requires the dual registration above.

## State resolution

- Register appearance and content per **exact** `UIControl.State` bit pattern.
- Default resolution order when `stateResolutionProvider` is `nil`: disabled (with selected variant if needed) → highlighted+selected → highlighted → selected → normal.
- **`setModel(nil, for: state)`** removes appearance, title, subtitle, all image slots, and custom content for that **exact** state key so fallbacks apply again.
- Non-`nil` **`setModel`** is **partial**: omitted fields (e.g. `images == nil`) do not clear existing slot registrations.

## Interaction notes

See **Control events** for which `UIControl.Event` to use with `addTarget` / `addAction`.

- **Throttling** applies only to primary actions (UIKit may call `sendAction` directly; `FKButton` intercepts that path).
- **Loading** forces interaction off and suppresses primary actions until cleared. Use `loadingIndicatorConfiguration`, `loadingPreservesIntrinsicWidth`, and `showTransientResult` for submit flows.
- **`minimumTouchTargetSize`** expands hit testing without changing layout (HIG 44×44); combine with `hitTestEdgeInsets` when needed.
- **Batch APIs** — `setTitles`, `setSubtitles`, `registerAppearances`, `setImages`, and slot conveniences register multiple states in one refresh. Use `setAppearances(StateAppearances)` for the standard four-state bundle.
- **Badges** — `configureBadge(anchor:offset:)` returns `FKBadgeController` (same storage as `UIView.fk_badge`).
- **Symbol effects** — set `symbolEffect` on `ImageAttributes` (iOS 17+).
- **Long press** uses a gesture recognizer with `cancelsTouchesInView = false` so normal taps still work.
- **Pointer** interaction is attached only on iPad / Mac idiom when enabled; call sites should not rely on hover where pointer APIs are unavailable.

## Global defaults

Set once at launch if desired:

```swift
FKButton.GlobalStyle.minimumTapInterval = 0.35
FKButton.GlobalStyle.defaultAppearances = …
FKButton.GlobalStyle.applyPerNewButton = { button in … }
```

Avoid relying on mutable global state across unrelated features without restoring previous values (see sample app “GlobalStyle snapshot”).

## Examples

Under `Examples/FKKitExamples/.../Examples/FKUIKit/Button/`:

| Location | Contents |
|----------|----------|
| Root | `FKButtonExamplesHubViewController.swift`, `FKButtonExampleSupport.swift` (layout helpers + shared scroll shell) |
| `Scenarios/` | One view controller per topic (basics, layout, interaction, appearance, loading, production patterns, advanced) |

## License

Same as the FKKit repository.
