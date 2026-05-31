// swift-tools-version: 6.0

import PackageDescription

// MARK: - Module documentation excludes

/// Builds SwiftPM `exclude` entries for component README files under a target root.
///
/// SwiftPM treats every file under a target path as input; markdown docs must be excluded explicitly
/// (globs such as `**/README.md` are not supported). When adding a component README under
/// `Sources/FKCoreKit/<Module>/` or `Sources/FKUIKit/Components/…/`, append its directory here.
private func readmeExcludes(moduleDirectories: [String]) -> [String] {
  moduleDirectories.sorted().map { "\($0)/README.md" }
}

/// Top-level FKCoreKit module docs (`Sources/FKCoreKit/<name>/README.md`).
private let fkCoreKitModuleDocDirectories: [String] = [
  "Async",
  "BusinessKit",
  "FileManager",
  "Logger",
  "Network",
  "Permissions",
  "Pluggable",
  "Security",
  "Storage",
  "Utils",
]

/// FKUIKit component docs (`Sources/FKUIKit/Components/…/README.md`), including nested Player modules.
private let fkUIKitComponentDocDirectories: [String] = [
  "Components/ActionSheet",
  "Components/Badge",
  "Components/Base",
  "Components/BlurView",
  "Components/Button",
  "Components/Callout",
  "Components/CornerShadow",
  "Components/Divider",
  "Components/EmptyState",
  "Components/ExpandableText",
  "Components/PagingController",
  "Components/Player/AudioPlayer",
  "Components/Player/Core",
  "Components/Player/VideoPlayer",
  "Components/ProgressBar",
  "Components/RatingControl",
  "Components/Refresh",
  "Components/SheetPresentationController",
  "Components/Skeleton",
  "Components/TabBar",
  "Components/TextField",
  "Components/Toast",
]

// MARK: - Package

let package = Package(
  name: "FKKit",
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
      exclude: readmeExcludes(moduleDirectories: fkUIKitComponentDocDirectories),
      resources: [
        .process("Resources"),
      ]
    ),
    .target(
      name: "FKCoreKit",
      path: "Sources/FKCoreKit",
      exclude: readmeExcludes(moduleDirectories: fkCoreKitModuleDocDirectories)
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
