# FKCoreKit Extension (historical note)

**Status:** `Components/Utils/` (`FKUtils.*`) was merged into **`Components/Extension/`** in favor of a single API surface.

## Current policy

- Add new helpers under **`Sources/FKCoreKit/Components/Extension/`**.
- Prefer **`fk_*`** methods and properties on the natural receiver type (`String`, `Date`, `UIView`, …).
- Use **`Toolbox/`** only when there is no reasonable receiver (`FKDeviceInfo`, `FKValueParsing`).
- Put shared caches, bridges, and provider stores in **`Internal/`**.
- Do **not** reintroduce parallel `FKUtils.*` namespaces.

See **`Sources/FKCoreKit/Components/Extension/README.md`** for the directory map and usage examples.

## Migration (from `FKUtils`)

| Former API | Replacement |
|------------|-------------|
| `FKUtils.DateTime.string(from:format:)` | `date.fk_formatted(_:)` |
| `FKUtils.Regex.isValidEmail(_:)` | `"…".fk_isValidEmail` |
| `FKUtils.String.trim(_:)` | `"…".fk_trimmed` |
| `FKUtils.Collection.unique(_:)` | `array.fk_uniqued` |
| `array[safe:]` | `array[fk_safe:]` |
| `FKUtils.Device.modelIdentifier()` | `FKDeviceInfo.modelIdentifier()` |
| `FKUtils.UI.color(hex:)` | `UIColor(fk_hexString:)` |
| `FKUtils.Common.documentsDirectory()` | `FileManager.fk_documentsDirectory` |
| `FKUtils.DateTime.register(provider:)` | `FKDateFormatting.register(provider:)` |
| `FKUtils.Regex.register(provider:)` | `FKRegexMatching.register(provider:)` |

Breaking removals are documented in **`CHANGELOG.md`**.
