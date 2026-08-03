# FKDateTime

Production-grade date/time utilities for `FKCoreKit` — Moment.js–inspired workflows without third-party dependencies.

## Directory layout

| Path | Responsibility |
|------|----------------|
| `Public/` | ``FKDateTime`` value type, configuration, units, format presets, relative styles, arithmetic / parse / format / relative APIs |
| `Internal/` | Thread-safe formatter cache, ISO-8601 helpers, WeChat-like relative engines |

## Requirements

- Swift 6
- iOS 15+
- No third-party dependencies

## Features

- Immutable ``FKDateTime`` wrapping `Date` + ``FKDateTimeConfiguration`` (calendar / time zone / locale)
- Parse & format (custom patterns, presets, localized templates, ISO-8601, Unix seconds/ms)
- Calendar arithmetic (`adding` / `subtracting` / `startOf` / `endOf` / `replacing` / `setting`)
- Queries (`isToday`, `isPast` / `isFuture`, `isSameOrBefore`, `compare`, `age`, …)
- Diffs (`diff(to:)`, per-unit `diff(_:unit:)`, `daysUntil`) and span `durationDescription(to:)`
- Relative display:
  - `.chat` — WeChat conversation timestamps
  - `.feed` — WeChat Moments / social feed
  - `.standard` — “Just now” / “3 minutes ago” / future “In 2 hours”
  - `.system` — `RelativeDateTimeFormatter`
- Localized via `FKI18n` (`fkcore.datetime.*`) across shipped locales

## Usage

```swift
import FKCoreKit

let now = FKDateTime.now()
now.relative(style: .chat)          // e.g. "18:30" / "Yesterday 09:12" / "Mon 14:00"
now.relative(style: .feed)          // e.g. "Just now" / "5 minutes ago" / "08-03"
now.fromNow(style: .standard)

let parsed = FKDateTime.parse("2026-08-03 18:00:00", format: .dateTime)
let nextWeek = parsed?.adding(7, .day)
nextWeek?.format(.date)             // "2026-08-10"
FKDateTime.iso8601("2026-08-03T10:00:00Z")?.in(timeZone: .current)

Date().fk_dateTime.relative(style: .feed)
```

## Design notes

- Prefer one shared ``FKDateTimeConfiguration`` (for example `.utc` for wire formats) per feature surface.
- ``Equatable`` / ``Hashable`` / ``Codable`` use the absolute instant only; configuration is not part of equality or persistence.
- `relative(style:)` defaults to `.chat`; `fromNow(style:)` defaults to `.standard`.
- Existing lightweight `Date` extensions under `Components/Extension` remain for small call sites; use ``FKDateTime`` when you need Moment-like chaining, relative styles, or explicit calendar context.
- Formatters are cached and locked; safe for concurrent use.

## Examples

Interactive coverage lives under `Examples/FKKitExamples/.../FKCoreKit/DateTime/`:

| Scenario | Covers |
|----------|--------|
| Basics & Codable | `now`, unix s/ms, components, `Date.fk_dateTime`, `description`, JSON encode/decode |
| Configuration | `.default` / `.utc`, `with(…)`, `in(timeZone:)` / `in(locale:)` |
| Parse & format | All presets, multi-format parse, ISO-8601, `isValid`, styles, **localized `format(template:)`**, unix accessors |
| Arithmetic | All units add/subtract, `DateComponents`, `startOf` / `endOf`, **`replacing` / `setting`**, day bounds |
| Query & compare | Components, flags, `isSame` / **`compare` / `sameOr*` / `isPast`/`isFuture`** / between / age / min-max |
| Diff | Per-unit and multi-unit diffs, `daysUntil`, ``FKDateTimeDiff``, **`durationDescription(to:)`** |
| Relative · Chat / Feed / Standard | WeChat `.chat` / `.feed`, conversational `.standard`, `.system`, `fromNow` / `from(_:)` |

Entry: **FKCoreKit → DateTime** in the example app menu (`FKDateTimeExamplesHubViewController`).
