# FKI18n

In-app localization for FKCoreKit: language switching, bundle resolution, typed keys, dictionary backends, and locale-aware formatters — independent of the system locale when needed.

## Table of contents

- [Overview](#overview)
- [Repository layout](#repository-layout)
- [Features](#features)
- [Requirements](#requirements)
- [Basic usage](#basic-usage)
- [Configuration](#configuration)
- [Dictionary backends](#dictionary-backends)
- [Integration](#integration)
- [API reference](#api-reference)
- [Notes](#notes)

## Overview

`FKI18n` centralizes localization for FKKit libraries and host apps:

- Resolve strings from `.lproj` bundles (app bundle or any `Bundle`, e.g. FKUIKit resources)
- Persist and switch in-app language without changing system settings
- Observe language changes for UI refresh
- Interpolate `{token}` placeholders, `String(format:)` templates, and plural rules
- Provide locale-aware Foundation formatters bound to the active language

## Repository layout

Sources under `Sources/FKCoreKit/Components/I18n/`:

| Area | Role |
|------|------|
| `Core/` | `FKI18nManager`, `FKI18nConfiguration`, `FKI18nSettings`, protocols |
| `Model/` | `FKI18nLanguage`, `FKI18nKey`, `FKI18nObservationToken` |
| `Service/` | `FKI18nBundleResolver`, `FKI18nLocaleMatcher` |
| `Implementation/` | `FKI18nDictionaryLocalizer`, `FKI18nStaticDictionaryTranslator` |
| `Tool/` | `FKI18nMessageFormat`, `FKI18nFormatterProvider` |
| `Extension/` | `FKI18n`, `FKI18n+Convenience`, `String.fk_localized`, `FKLocalizing` conformance |

## Features

- BCP-47 language codes with progressive fallback (`zh-Hans-CN` → `zh-Hans` → `en`; region codes such as `zh-CN` map to script folders via ``FKI18nLocaleMatcher/canonicalize(_:)``)
- ``FKI18nRecommendedLanguages`` — documented starter set for global apps and FKKitExamples
- Optional UserDefaults persistence
- Dictionary translator hook (tests, previews, remote copy)
- Typed keys via ``FKI18nKey``
- RTL detection via ``FKI18nManager/isRightToLeft``
- Conforms to ``FKLocalizing`` (Pluggable boundary)

## Requirements

- Swift 6, iOS 15+
- Foundation only (no third-party dependencies)

## Basic usage

```swift
import FKCoreKit

// Bootstrap once at launch (matches iOS app preferred language when nothing is persisted)
var config = FKI18nConfiguration(
  defaultLanguageCode: "en",
  supportedLanguageCodes: ["en", "zh-Hans", "ja"],
  bundle: .main
)
FKI18nManager.shared.configure(config)

// Resolve copy
let title = FKI18nManager.shared.localized("settings.title")
let greeting = FKI18nString("home.greeting", table: nil)

// Switch language
FKI18nManager.shared.setLanguageCode("zh-Hans")

// Observe changes
let token = FKI18nManager.shared.observeLanguageChange { language in
  reloadVisibleScreens(for: language.code)
}
```

## Configuration

| Property | Purpose |
|----------|---------|
| `defaultLanguageCode` | Initial and ultimate fallback language |
| `supportedLanguageCodes` | Languages exposed in in-app pickers |
| `fallbackLanguageCodes` | Extra bundle lookup fallbacks |
| `bundle` | Container hosting `.lproj` directories |
| `persistSelection` | Write selected language to UserDefaults |
| `storageKey` | UserDefaults key for persisted language |
| `enforceSupportedLanguages` | Reject unsupported `setLanguageCode` values |

Global defaults: ``FKI18nSettings/defaultConfiguration``.

## Dictionary backends

```swift
let translator = FKI18nStaticDictionaryTranslator(
  flatDictionary: [
    "en": ["demo.title": "Hello"],
    "zh-Hans": ["demo.title": "你好"],
  ],
  fallbackLanguageCode: "en"
)
FKI18nManager.shared.setDictionaryTranslator(translator)
```

Use ``FKI18nDictionaryLocalizer`` when you need a standalone in-memory provider (previews, unit tests).

## Integration

| Consumer | Integration |
|----------|-------------|
| **Pluggable** | ``FKI18nManager`` conforms to ``FKLocalizing`` |
| **BusinessKit** | ``FKBusinessI18nManager`` wraps ``FKI18nManager`` for ``FKBusinessLocalizing`` |
| **FKUIKit** | Point ``FKI18nConfiguration/bundle`` at `Bundle.module` for library strings |

## Recommended languages

``FKI18nRecommendedLanguages`` defines the starter BCP-47 set FKKit targets for demos and global products:

| Code | Locale | Notes |
|------|--------|-------|
| `en` | English | Base / ultimate fallback |
| `zh-Hans` | Simplified Chinese | Accepts system aliases such as `zh-CN` |
| `zh-Hant` | Traditional Chinese | Taiwan, Hong Kong, Macau (`zh-TW`, `zh-HK`, …) |
| `ja` | Japanese | |
| `ko` | Korean | High App Store traffic |
| `es` | Spanish | |
| `fr` | French | Western Europe |
| `de` | German | Western Europe |
| `pt-BR` | Portuguese (Brazil) | Latin America |
| `ar` | Arabic | RTL layout validation |
| `ru` | Russian | Eastern Europe / CIS |

Trim or extend for your market. Production apps typically ship `.lproj` / `.xcstrings` for the subset they support.

## Examples

FKKitExamples → **FKCoreKit → I18n** hub (`Examples/FKCoreKit/I18n/`):

- **Language Switcher** — all recommended locales with live preview and RTL badge
- **Bundle Strings** — `.lproj` lookup via `FKI18nConfiguration.bundle`
- **Format & Variables** — interpolation, `localizedFormat`, formatters, plural counts
- **Dictionary Backend** — `FKI18nStaticDictionaryTranslator`
- **Observers** — `observeLanguageChange` + `NotificationCenter`
- **RTL Layout** — Arabic semantic content and leading/trailing
- **Integration** — `FKLocalizing` and `FKBusinessI18nManager`

Demo strings: `Examples/FKCoreKit/I18n/Support/Resources/Localization/<code>.lproj/FKI18nDemo.strings`.

## API reference

- ``FKI18n`` — FKCoreKit bundle string resolver
- ``FKI18nManager``, ``FKI18nConfiguration``, ``FKI18nSettings``
- ``FKI18nLocalizing``, ``FKI18nDictionaryTranslating``
- ``FKI18nLanguage``, ``FKI18nKey``, ``FKI18nObservationToken``
- ``FKI18nRecommendedLanguages``
- ``FKI18nBundleResolver``, ``FKI18nLocaleMatcher`` (including ``FKI18nLocaleMatcher/canonicalize(_:)``)
- ``FKI18nMessageFormat``, ``FKI18nFormatterProvider``
- ``FKI18nDictionaryLocalizer``, ``FKI18nStaticDictionaryTranslator``
- ``FKI18nString(_:)``, ``String/fk_localized(table:using:)``

## Notes

- Library modules should store `.strings` / `.xcstrings` in their resource bundle and set `FKI18nConfiguration.bundle` accordingly.
- ``FKI18nManager/shared`` is the recommended app-wide entry point; create dedicated instances for tests or isolated subsystems.
- On first launch (no persisted selection), ``FKI18nManager`` picks the best match from `Locale.preferredLanguages` (device preference) and `Bundle.main.preferredLocalizations` against ``supportedLanguageCodes``. iOS **Settings → General → Language & Region** therefore drives FKUIKit/FKCoreKit copy after ``configure(_:)`` at launch.
- Explicit in-app language selection (``setLanguageCode(_:)``) is persisted and overrides system preference on subsequent launches.
- ``FKBusinessI18nManager`` keeps BusinessKit compatibility; prefer ``FKI18nManager`` for new code.

## License

Part of FKKit; same license as this repository.
