# FKKit — Issues Found During Automated Testing

**Purpose:** Record **confirmed component bugs** discovered while writing or running unit tests.  
**Not for:** incorrect test expectations, missing entitlements in the test host, or deferred visual/system UI coverage.

When a test fails:

1. Reproduce with a minimal call path.
2. Decide: **test bug** (fix the test) vs **component bug** (log here, fix the test expectation only if documenting intended-but-wrong behavior is premature).
3. Add a row below before merging test code that encodes wrong behavior.

| ID | Date | Module | Component / API | Symptom | Expected | Actual | Test file | Status |
|----|------|--------|-----------------|---------|----------|--------|-----------|--------|
| T-001 | 2026-06-16 | FKCoreKit | `String.fk_isValidURLPattern` / `FKRegexMatching.Pattern.url` | HTTP(S) URLs never validate | `https://example.com/path` returns `true` | Always `false` — `NSRegularExpression` fails to compile the pattern (`NSInvalidValue` / error 2048) | `Tests/FKCoreKitTests/Extension/StringValidationExtensionTests.swift` | Fixed |

#### T-001 — Invalid URL regex pattern

- **Location:** `Sources/FKCoreKit/Components/Extension/Internal/FKRegexMatching.swift` — `Pattern.url`
- **Pattern (current):** `^https?://[\w.-]+(?:\.[\w\.-]+)+(?:[/\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+)?$`
- **Root cause:** The optional path character class contains an **unescaped `[`** after `#` (`.../?#[\]...`). In ICU/NSRegularExpression this starts a nested POSIX character class and makes the whole pattern invalid.
- **Downstream effect:** `FKRegexMatchingProvider.regex(pattern:)` returns `nil`; `isMatch` returns `false` for every input. Doc comment on `fk_isValidURLPattern` says "Validates an HTTP or HTTPS URL pattern" but the API is non-functional.
- **Suggested fix:** Escape the literal bracket in the path class (e.g. `\[` instead of `[`) or simplify the path segment (e.g. `[^\s]+` or reuse a well-tested URL regex).
- **Resolution (2026-06-17):** Escaped `[` as `\[` in `Pattern.url`; positive HTTP(S) tests re-enabled in `StringValidationExtensionTests`.

### Status values

- **Open** — not fixed in `Sources/`
- **Fixed** — resolved; keep row for history and link PR/commit in notes
- **Wontfix** — documented limitation; tests assert current behavior

### Template (copy for new rows)

```markdown
| T-001 | YYYY-MM-DD | FKCoreKit | `Type.method` | One-line symptom | Correct behavior | Observed behavior | `Tests/.../FileTests.swift` | Open |
```

**Maintenance:** Update this file in the same PR when a test documents a known bug intentionally (use `XCTExpectFailure` only with a linked row here — prefer fixing the component when scope allows).
