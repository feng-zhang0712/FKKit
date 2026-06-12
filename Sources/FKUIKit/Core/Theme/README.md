# FKTheme

Design-token and theme registry for FKUIKit: semantic colors, typography, spacing, shadows, and opt-in synchronization with component defaults.

## Directory layout

| Folder / file | Role |
|---------------|------|
| `Public/FKTheme.swift` | Top-level `FKTheme` snapshot |
| `Public/FKThemeColor*.swift` | Light/dark color pairs and semantic palette |
| `Public/FKThemeTypography.swift` | Text ramp and Dynamic Type scaling |
| `Public/FKThemeMetrics.swift` | Spacing, radii, hit targets |
| `Public/FKThemeShadowTokens.swift` | Elevation presets (`FKLayerShadowStyle`) |
| `Public/FKThemeRegistry.swift` | Active theme, notifications, registration |
| `Public/FKThemeResolver.swift` | Trait-aware token resolution |
| `Public/FKThemeComponentIntegration.swift` | Opt-in `FKButton` / `FKToast` / `FKDivider` defaults; `makeBackdropStyle` |
| `Public/Bridge/FKTheme+SwiftUI.swift` | SwiftUI `EnvironmentValues.fkTheme` |
| `Internal/FKThemeDefaultFactory.swift` | Built-in default palettes |

## Quick start

```swift
import FKUIKit

// Optional brand theme at launch
var brand = FKTheme.default
brand.id = "brand-2026"
brand.colors.primary = FKThemeColor(fixed: .systemTeal)
FKThemeRegistry.register(brand)

// Read tokens in UI code
let primary = FKThemeResolver.color(.primary, traitCollection: traitCollection)
```

## Integration with FKButtonGlobalStyle

- Calling `FKThemeRegistry.register` with a **non-default** theme updates `FKButtonGlobalStyle.defaultAppearances` (primary filled style), `FKToast.defaultConfiguration`, and `FKDivider.defaultConfiguration` (outline color).
- Registering the built-in `FKTheme.default` or `FKTheme.defaultDark` **snapshots** (value-equal to the presets) restores factory button/toast/divider defaults. Custom themes copied from a preset keep component integration even if the `id` string is unchanged.
- Per-instance `FKButton` configuration still overrides theme defaults.
- Sheet presentations can use `theme.makeBackdropStyle(traitCollection:)` to map the scrim token to `FKBackdropStyle`.

## SwiftUI

```swift
ContentView()
  .fkTheme(FKThemeRegistry.current)
```

The environment value is read-only; mutate `FKThemeRegistry` from the UIKit host when the theme changes.

## Examples (FKKitExamples)

| Entry | Path |
|-------|------|
| Hub | `Examples/FKUIKit/Theme/Hub/FKThemeExamplesHubViewController.swift` |
| Scenarios | `Examples/FKUIKit/Theme/Scenarios/` (grouped: Getting started, Design tokens, Registry, Integration, SwiftUI) |

## Requirements

- iOS 15+
- `@MainActor` for `FKThemeRegistry` and component integration entry points

## License

MIT — see repository root `LICENSE`.
