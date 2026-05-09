# Supported toolchain (FKKit)

FKKit is written in **Swift 6** and targets **iOS 15+** (`Package.swift`).

## Xcode / Swift

| Constraint | Value |
|------------|--------|
| **Minimum for consumers** | **Xcode 16.2** (Swift **6.0.x**) — aligns with `swift-tools-version: 6.0` and catches Swift 6 concurrency issues early. |
| **Package manifest** | `swift-tools-version: 6.0` — SPM resolves without requiring SwiftPM **6.2** tools on the host. |
| **CI gate** | GitHub Actions selects **Xcode 16.2** explicitly so merges are verified on the **oldest supported** Xcode, not only `latest-stable`. |

Newer Xcode releases remain supported; developing on the latest Xcode is fine if CI passes on **16.2**.

## Why CI pins an older Xcode

Apple ships **different Swift compilers** per Xcode. Patterns that compile on a bleeding-edge Xcode may **fail on Xcode 16.2** (stricter or different isolation checks). Pinning CI to **16.2** catches those regressions before consumers do.

## Local verification

Match CI when debugging integration issues:

```bash
sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer   # if installed
xcrun swift --version
./scripts/verify-podspec-versions.sh   # optional; CI runs this too
```

Then build/test the package the same way CI does (`FKKit-Package` scheme, iOS Simulator):

```bash
xcodebuild -scheme FKKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/FKKit-DD \
  CODE_SIGNING_ALLOWED=NO \
  test
```

CI uses that **name-based** destination so `xcodebuild` resolves a valid simulator for the active Xcode (avoiding exit **70** from a mismatched UDID when multiple iOS runtimes are installed).
