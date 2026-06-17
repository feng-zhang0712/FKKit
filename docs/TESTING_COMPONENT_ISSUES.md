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
| T-002 | 2026-06-17 | FKUIKit | `FKMediaFormatProbe.probe(url:headers:)` / `descriptorFromMIME` | HLS MIME ignored for extensionless URLs | `Content-Type: application/vnd.apple.mpegurl` on `https://cdn.example.com/playlist` yields HLS + AVFoundation | Falls back to extension probe; returns `.unknown` / `.extended` | `Tests/FKUIKitTests/Player/FKMediaFormatProbeTests.swift` | Fixed |
| T-003 | 2026-06-17 | FKCoreKit | `FKImageLoaderEngine.load` / `dataTask` error mapping | Task / URLSession cancel reported as network error | `FKImageLoaderError.cancelled` | `.network(underlyingDescription: "已取消")` or `NSURLErrorCancelled` treated as generic network | `Tests/FKCoreKitTests/ImageLoader/FKImageLoaderTests.swift` | Fixed |
| T-004 | 2026-06-17 | FKCoreKit | `FKPermissionPrePromptPresenter.findTopViewController()` | Pre-prompt alert never presents in xctest (fail-open) | Pre-prompt shows on key window when host VC exists | `foregroundActive` scene only; xctest often has no active scene → `nil` → skip alert | `Tests/FKCoreKitTests/Permissions/FKPermissionPrePromptPresenterTests.swift` | Fixed |
| T-005 | 2026-06-17 | FKUIKit | `FKToastQueueActor.enqueue` / `.dropNew` | First toast silently dropped | `.dropNew` ignores arrivals only while waiting or displaying; first request should enqueue | `.dropNew` always `break` — even empty queue discards the request | `Tests/FKUIKitTests/Toast/FKToastQueueActorTests.swift` | Fixed |

#### T-005 — `.dropNew` discarded the first toast request

- **Location:** `Sources/FKUIKit/Components/Toast/Internal/FKToastQueue.swift` — `enqueue(_:)` / `FKToastArrivalPolicy.dropNew`
- **Root cause:** `dropNew` unconditionally skipped enqueueing, even when both `waiting` and `displaying` were empty.
- **Downstream effect:** A toast configured with `.dropNew` never appeared unless another arrival policy was used first; `FKToastCenter.presentNextIfNeeded()` had nothing to claim.
- **Resolution (2026-06-17):** Append the request when the queue is idle; continue dropping only while a toast is waiting or on screen.

#### T-004 — Pre-prompt presenter could not resolve host in xctest

- **Location:** `Sources/FKCoreKit/Components/Permissions/Service/FKPermissionPrePromptPresenter.swift` — `findTopViewController()`
- **Root cause:** Only consulted `UIWindowScene.activationState == .foregroundActive`; xctest host often has no foreground-active scene, so `presentIfNeeded` fail-open returned `true` without showing the guide.
- **Downstream effect:** Custom pre-prompt never appeared in tests (and could fail silently in edge launch states).
- **Resolution (2026-06-17):** Align with `FKAlertCoordinator`: fall back to `scenes.first` and `windows.first` when no key window. Add optional `presentingViewController` on `presentIfNeeded` / `FKPermissions.request(_:presentingFrom:)`. Add injectable `presentAlert` closure on presenter for deterministic unit tests.

#### T-003 — Image load cancellation mapped to `.network`

- **Location:** `Sources/FKCoreKit/Components/ImageLoader/Internal/FKImageLoaderEngine.swift` — `load()` / `dataTask` completion
- **Root cause:** `CancellationError`, `URLError.cancelled`, and `NSURLErrorCancelled` were wrapped as `.network(underlyingDescription:)`.
- **Downstream effect:** Callers checking `FKImageLoaderError.cancelled` could not distinguish user cancellation from transport failures.
- **Resolution (2026-06-17):** Added `mapTransportError(_:)` to normalize cancellation errors to `.cancelled`.

#### T-002 — MIME-based HLS probe dropped Content-Type

- **Location:** `Sources/FKUIKit/Components/Player/Core/Public/Services/FKMediaFormatProbe.swift` — `descriptorFromMIME`
- **Root cause:** For `mpegurl` / `m3u8` MIME types, the helper re-invoked `probe(url:headers: nil)`, which ignored the Content-Type and fell back to URL extension (empty for extensionless playlist URLs).
- **Downstream effect:** Remote HLS endpoints without `.m3u8` in the path were misclassified as unknown/extended-only formats.
- **Resolution (2026-06-17):** Return an explicit `.m3u8` / HLS descriptor from `descriptorFromMIME` instead of re-probing without headers.

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
