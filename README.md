# FKKit

[![iOS](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](https://swift.org/)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-supported-ee3322.svg)](https://cocoapods.org/)
[![CI](https://github.com/feng-zhang0712/FKKit/actions/workflows/ci.yml/badge.svg)](https://github.com/feng-zhang0712/FKKit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Module Structure](#module-structure)
- [Core Components](#core-components)
  - [FKCoreKit](#fkcorekit)
  - [FKCoreKit: Extension vs Utils](#fkcorekit-extension-vs-utils)
  - [FKUIKit](#fkuikit)
- [Requirements](#requirements)
- [Installation (SPM)](#installation-spm)
- [Installation (CocoaPods)](#installation-cocoapods)
- [Usage](#usage)
- [Contributing](#contributing)
- [Support](#support)
- [Security](#security)
- [Branching & Collaboration (Recommended)](#branching--collaboration-recommended)
- [License](#license)
- [Changelog](#changelog)

## Overview
FKKit is a modular, pure-native Swift component library for iOS applications.  
It is built on Apple system frameworks and distributed via **Swift Package Manager (SPM)** and **CocoaPods** (see root `*.podspec` files), with no third-party runtime dependencies.

The repository ships two library products:
- **`FKCoreKit`** — infrastructure, utilities, and `Pluggable/` protocol contracts (networking, analytics, storage, routing, and related seams).
- **`FKUIKit`** — reusable UIKit components and shared UI helpers under `Core/`.

Each module targets a different layer of app development: from networking and storage to controls, overlays, and composite presentation flows.

## Features
- Pure Swift implementation (Swift 6 language mode in `Package.swift`).
- No third-party runtime dependencies.
- Swift Package Manager and CocoaPods integration (published pod names mirror SPM products).
- Continuous integration via **GitHub Actions**: builds and runs **unit tests** for the Swift package on **iOS Simulator** on `main`, `develop`, and pull requests (see `.github/workflows/ci.yml`).
- Modular architecture with clear package products.
- Protocol-oriented design in multiple components for extensibility and testability.
- Example app under [`Examples/FKKitExamples`](Examples/FKKitExamples) demonstrating public APIs per component.

## Module Structure

```text
FKKit/
├─ Package.swift
├─ FKCoreKit.podspec
├─ FKUIKit.podspec
├─ docs/
├─ scripts/
├─ Tests/
│  └─ FKCoreKitTests/
├─ Sources/
│  ├─ FKCoreKit/
│  │  ├─ Components/
│  │  │  ├─ Async/
│  │  │  ├─ BusinessKit/
│  │  │  ├─ Extension/
│  │  │  ├─ FileManager/
│  │  │  ├─ I18n/
│  │  │  ├─ Logger/
│  │  │  ├─ Network/
│  │  │  ├─ Permissions/
│  │  │  ├─ Pluggable/
│  │  │  ├─ Security/
│  │  │  ├─ Storage/
│  │  │  └─ Utils/
│  │  ├─ Core/
│  │  └─ Resources/
│  └─ FKUIKit/
│     ├─ Components/
│     │  ├─ ActionSheet/
│     │  ├─ Badge/
│     │  ├─ BlurView/
│     │  ├─ Button/
│     │  ├─ Callout/
│     │  ├─ CornerShadow/
│     │  ├─ Divider/
│     │  ├─ EmptyState/
│     │  ├─ ExpandableText/
│     │  ├─ PagingController/
│     │  ├─ Player/
│     │  ├─ ProgressBar/
│     │  ├─ RatingControl/
│     │  ├─ Refresh/
│     │  ├─ SheetPresentationController/
│     │  ├─ Skeleton/
│     │  ├─ TabBar/
│     │  ├─ TextField/
│     │  └─ Toast/
│     ├─ Core/
│     └─ Resources/
└─ Examples/
   └─ FKKitExamples/
```

## Core Components

### FKCoreKit
`FKCoreKit` provides foundational capabilities under `Components/` used across app layers:

- `Pluggable`: protocol-only contracts for dependency injection (networking, analytics, storage, session, routing, logging, images, list cells). See [`Sources/FKCoreKit/Components/Pluggable/README.md`](Sources/FKCoreKit/Components/Pluggable/README.md).
- `Network`: URLSession-based networking stack (request models, interceptors, caching, upload/download helpers).
- `Storage`: multi-backend storage abstraction (UserDefaults, Keychain, file, memory) with Codable support.
- `Logger`: structured logging, formatting, file persistence, and diagnostics helpers.
- `Permissions`: unified iOS permission management and status/request flow.
- `Security`: crypto/security utilities (hash, AES/RSA helpers, encoding, signature helpers).
- `FileManager`: file I/O, directory utilities, and transfer-oriented helpers.
- `Async`: concurrency utilities (queues, cancellable task wrappers, debounce/throttle helpers).
- `BusinessKit`: app/business infrastructure (version, deeplink, lifecycle, analytics, i18n helpers).
- `Extension`: cross-cutting `public` extensions for **Foundation**, **CoreGraphics**, and **UIKit** (UIKit files use `#if canImport(UIKit)`); members use an `fk_` prefix to reduce name clashes with app and SDK code.
- `Utils`: high-frequency utility APIs for date/string/number/device/UI/collection/common operations.

### FKCoreKit: Extension vs Utils

Use **`Components/Extension/`** for receiver-oriented helpers (`value.fk_*`). Use **`Components/Utils/`** (`FKUtils.*` static namespaces) for toolbox-style or multi-argument operations that are not naturally expressed as a single-type extension. Avoid introducing **new** duplicate semantics across both layers; legacy overlap is documented and may be consolidated on a major version. Full policy: [`docs/EXTENSION_VS_UTILS.md`](docs/EXTENSION_VS_UTILS.md).

### FKUIKit
`FKUIKit` contains reusable UIKit components for modern iOS interfaces. Each folder under `Components/` is a self-contained module; most ship a colocated **`README.md`** with layout maps, configuration defaults, and usage snippets. The list below is a high-level index only.

| Component | Summary |
|-----------|---------|
| **ActionSheet** | HIG-oriented modal action sheet (`FKActionSheet`) with bottom/centered/popover presentation, selection, toggles, validation, and SwiftUI modifier — see [`ActionSheet/README.md`](Sources/FKUIKit/Components/ActionSheet/README.md). |
| **Badge** | Flexible badge display for views, bar items, and tab items, with corner/center anchoring and customizable styles/animations. |
| **BlurView** | High-performance blur component with system/custom pipelines, UIKit/SwiftUI adapters, image/view snapshot blur APIs, and IB/global-configuration support. |
| **Button** | Configurable button system with style/content/loading behavior. |
| **Callout** | Anchored tooltip/popover bubbles (`FKCallout`, `FKTooltip`, `FKPopover`) with beak placement and shared layout engine — see [`Callout/README.md`](Sources/FKUIKit/Components/Callout/README.md). |
| **CornerShadow** | Rounded-rect masks, borders, gradient fill/stroke, and explicit-path shadows (`Public` / `Internal` / `Extension`) — see [`CornerShadow/README.md`](Sources/FKUIKit/Components/CornerShadow/README.md). |
| **Divider** | Hairline separator (`FKDivider` / `FKDividerView`); dashed and gradient strokes; `FKDivider.defaultConfiguration`. |
| **EmptyState** | Loading/empty/error overlay (`Public` / `Internal` / `Extension` / `CoreLite` resolver + i18n) — see [`EmptyState/README.md`](Sources/FKUIKit/Components/EmptyState/README.md). |
| **ExpandableText** | Long attributed text expand/collapse for `UILabel` / `UITextView` plus SwiftUI `FKExpandableTextView`; `FKExpandableText.defaultConfiguration` and layout cache. |
| **PagingController** | **`FKPagingController`** coordinates swipe paging between child view controllers and **`FKTabBar`** selection/progress — see [`PagingController/README.md`](Sources/FKUIKit/Components/PagingController/README.md). |
| **Player** | Shared media playback kernel (`FKMediaPlaybackCoordinator`) plus **`FKVideoPlayer`** and **`FKAudioPlayer`** facades (PiP, subtitles, queues, Now Playing) — see [`Player/Core/README.md`](Sources/FKUIKit/Components/Player/Core/README.md). |
| **ProgressBar** | Determinate/indeterminate linear and ring progress control with buffer, segments, gradient, label, accessibility, and SwiftUI wrapper — see [`ProgressBar/README.md`](Sources/FKUIKit/Components/ProgressBar/README.md). |
| **RatingControl** | Configurable read-only/interactive rating control (`FKRatingControl`) with icon presets, half-step snapping, caption, haptics, accessibility, and SwiftUI `FKRatingControlRepresentable` — see [`RatingControl/README.md`](Sources/FKUIKit/Components/RatingControl/README.md). |
| **Refresh** | Pull-to-refresh and load-more controls for scroll views. |
| **SheetPresentationController** | Modal/overlay presentation infrastructure (bottom/top/center sheets, anchor dropdowns, detents, keyboard/safe-area/interaction configuration) — see [`SheetPresentationController/README.md`](Sources/FKUIKit/Components/SheetPresentationController/README.md). |
| **Skeleton** | Skeleton loading system for views/lists/containers with animation options. |
| **TabBar** | High-performance UIKit tab header (UICollectionView-based) with indicator, badges, data source, and paging progress linkage (UI-only) — see [`TabBar/README.md`](Sources/FKUIKit/Components/TabBar/README.md). |
| **TextField** | One-stop formatted input components (`FKTextField`, `FKCodeTextField`, `FKCountTextView`) with validation, counters, OTP slots, and shake feedback. |
| **Toast** | Unified Toast / HUD / Snackbar presenter with queueing, priority, keyboard-aware placement, accessibility, optional material blur, custom content, and SwiftUI hosting — see [`Toast/README.md`](Sources/FKUIKit/Components/Toast/README.md). |

`FKUIKit` depends on **`FKCoreKit`**. For API details, defaults, and migration notes, prefer each component **`README.md`** over this root index.

## Requirements
- **iOS 15.0+** (declared in `Package.swift`; all package products are **iOS-only**)
- Swift toolchain **6.0+** / **Xcode 16.2+** (`swift-tools-version` in `Package.swift` is **6.0** so SPM resolves on Xcode 16.2; newer Xcode remains supported)

## Installation (SPM)

### Xcode
1. Open `File` → `Add Package Dependencies...`
2. Enter repository URL:
   - `https://github.com/feng-zhang0712/FKKit.git`
3. Select one or more products:
   - `FKCoreKit`
   - `FKUIKit`

### Package.swift
```swift
dependencies: [
  .package(url: "https://github.com/feng-zhang0712/FKKit.git", from: "0.62.0")
],
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      .product(name: "FKCoreKit", package: "FKKit"),
      .product(name: "FKUIKit", package: "FKKit")
    ]
  )
]
```

## Installation (CocoaPods)

The repository ships **one podspec per Swift product**, aligned with SPM (`FKCoreKit`, `FKUIKit`). Each podspec's **`s.version`** must match a **published Git tag** (for example `0.62.0`).

**Maintainers:** version bump script (`scripts/bump-version.sh`), drift check (`scripts/verify-podspec-versions.sh`, also run in CI), and full release checklist — [`docs/RELEASING.md`](docs/RELEASING.md).

### Podfile (Git tag)

```ruby
platform :ios, '15.0'

pod 'FKCoreKit', :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => '0.62.0'
pod 'FKUIKit',   :git => 'https://github.com/feng-zhang0712/FKKit.git', :tag => '0.62.0'
```

Order does not matter; CocoaPods resolves dependencies (`FKUIKit` → `FKCoreKit`).

### Podfile (local path, for development)

Point `pod` to a **checkout that contains the podspec files at its root** (same layout as this repository):

```ruby
platform :ios, '15.0'

pod 'FKCoreKit', :path => '../FKKit'
pod 'FKUIKit',   :path => '../FKKit'
```

### Linting podspecs (maintainers)

```text
pod spec lint FKCoreKit.podspec --allow-warnings
pod spec lint FKUIKit.podspec --allow-warnings
```

## Usage

Import only what you need:

```swift
import FKCoreKit
import FKUIKit
```

Example quick integrations:

```swift
// FKCoreKit
let isEmail = FKUtils.Regex.isValidEmail("dev@example.com")
let trimmed = "  hello  ".fk_trimmed

// FKUIKit
someView.fk_showSkeleton()
```

For complete usage and advanced APIs, refer to each module README under `Sources/`.

## Contributing

Pull requests are welcome. Open PRs against **`develop`**, keep changes focused, and ensure **`FKCoreKit`** tests pass (locally with Xcode / `xcodebuild`, or via CI). Branch naming, git hooks, commit message conventions, and release flow: [Branching & Collaboration (Recommended)](#branching--collaboration-recommended).

## Support

File bug reports and feature requests in [GitHub Issues](https://github.com/feng-zhang0712/FKKit/issues).

## Security

Please report security vulnerabilities through [GitHub private security advisories](https://github.com/feng-zhang0712/FKKit/security/advisories/new) instead of public issues.

## Branching & Collaboration (Recommended)

- **Optional Git hooks:** after cloning, run `./scripts/install-git-hooks.sh` so **`git push`** runs **`scripts/verify-podspec-versions.sh`** first (podspec version alignment). See [`docs/GIT_HOOKS.md`](docs/GIT_HOOKS.md).
- Use `develop` as the integration branch.
- Create feature branches from `develop` (for example: `feature/Callout`).
- Keep commits focused and use clear conventional-style messages.
- Follow this commit format:
  - `<type>(<scope>): <subject>`
  - Example: `feat(Callout): add anchored tooltip and popover overlays`
- Recommended commit types:
  - `feat`: new feature
  - `fix`: bug fix
  - `refactor`: internal refactor without behavior change
  - `perf`: performance improvement
  - `docs`: documentation updates
  - `test`: tests added or updated
  - `build`: build/dependency/tooling changes
  - `chore`: maintenance tasks
- Commit message rules:
  - Use present tense and imperative mood (`add`, `fix`, `refactor`).
  - Keep the subject concise (recommended ≤ 72 characters).
  - Reference module scope whenever possible (for example: `Callout`, `RatingControl`, `core`, `uikit`, `examples`, `docs`).
  - Add a body when context is needed (why, impact, migration notes).
- Open pull requests into `develop` with:
  - change summary
  - test/verification notes
  - migration notes when APIs change
- Tag stable releases with semantic versions (for example: `0.62.0`), then merge release work back into `develop`.

## License
This repository is licensed under the MIT License.  
See [`LICENSE`](LICENSE) for details.

## Changelog
Release history and migration details are maintained in [`CHANGELOG.md`](CHANGELOG.md).
