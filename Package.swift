// swift-tools-version: 6.0

import PackageDescription

// MARK: - Module documentation excludes

/// Builds SwiftPM `exclude` entries for component README files under a target root.
///
/// SwiftPM treats every file under a target path as input; markdown docs must be excluded explicitly
/// (globs such as `**/README.md` are not supported). When adding a component README under
/// `Sources/FKCoreKit/Components/<Module>/` or `Sources/FKUIKit/Components/…/`, append its directory here.
private func readmeExcludes(moduleDirectories: [String]) -> [String] {
  moduleDirectories.sorted().map { "\($0)/README.md" }
}

/// FKCoreKit component docs (`Sources/FKCoreKit/Components/<name>/README.md`).
private let fkCoreKitModuleDocDirectories: [String] = [
  "Components/Async",
  "Components/BiometricAuth",
  "Components/BusinessKit",
  "Components/FileManager",
  "Components/I18n",
  "Components/ImageLoader",
  "Components/Logger",
  "Components/Network",
  "Components/Permissions",
  "Components/Pluggable",
  "Components/QRCode",
  "Components/Security",
  "Components/Storage",
  "Components/Extension",
]

/// FKUIKit Core docs (`Sources/FKUIKit/Core/…/README.md`).
private let fkUIKitCoreDocDirectories: [String] = [
  "Core/Theme",
]

/// FKUIKit component docs (`Sources/FKUIKit/Components/…/README.md`), including nested Player modules.
private let fkUIKitComponentDocDirectories: [String] = [
  "Components/ActionSheet",
  "Components/Alert",
  "Components/Badge",
  "Components/BlurView",
  "Components/Button",
  "Components/Carousel",
  "Components/Callout",
  "Components/CornerShadow",
  "Components/Divider",
  "Components/EmptyState",
  "Components/ExpandableText",
  "Components/FlowVisualization",
  "Components/ImageView",
  "Components/ListKit",
  "Components/PagingController",
  "Components/PhotoPicker",
  "Components/Player/AudioPlayer",
  "Components/Player/Core",
  "Components/Player/VideoPlayer",
  "Components/ProgressBar",
  "Components/QRCode",
  "Components/RatingControl",
  "Components/Refresh",
  "Components/SearchBar",
  "Components/SearchViewController",
  "Components/SheetPresentationController",
  "Components/Skeleton",
  "Components/TabBar",
  "Components/TextField",
  "Components/Toast",
  "Components/WebView",
  "Components/Widgets/Avatar",
  "Components/Widgets/Chip",
  "Components/Widgets/CopyChip",
  "Components/Widgets/IconView",
  "Components/Widgets/Marquee",
  "Components/Widgets/StatusPill",
]

// MARK: - Package

let package = Package(
  name: "FKKit",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(name: "FKUIKit", targets: ["FKUIKit"]),
    .library(name: "FKCoreKit", targets: ["FKCoreKit"]),
  ],
  targets: [
    .target(
      name: "FKUIKit",
      dependencies: ["FKCoreKit"],
      path: "Sources/FKUIKit",
      exclude: readmeExcludes(moduleDirectories: fkUIKitComponentDocDirectories)
        + readmeExcludes(moduleDirectories: fkUIKitCoreDocDirectories),
      resources: [
        .process("Resources"),
      ]
    ),
    .target(
      name: "FKCoreKit",
      path: "Sources/FKCoreKit",
      exclude: readmeExcludes(moduleDirectories: fkCoreKitModuleDocDirectories),
      resources: [
        .process("Resources"),
      ]
    ),
    .testTarget(
      name: "FKCoreKitTests",
      dependencies: ["FKCoreKit"],
      path: "Tests/FKCoreKitTests"
    ),
  ],
  /// Swift 6 language mode for all targets (region isolation; aligns with strict concurrency work).
  ///
  /// Default MainActor isolation is **not** enabled at the package level: ``FKCoreKit`` mixes networking and
  /// other background-safe code with UI helpers; forcing module-wide ``MainActor`` would fight that split.
  /// UI-heavy targets rely on UIKit’s own isolation plus explicit annotations instead (see CI strict concurrency).
  swiftLanguageModes: [.v6]
)
