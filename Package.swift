// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "FKKit",
  platforms: [
    .iOS(.v15),
  ],
  products: [
    .library(name: "FKUIKit", targets: ["FKUIKit"]),
    .library(name: "FKEmptyStateCoreLite", targets: ["FKEmptyStateCoreLite"]),
    .library(name: "FKCoreKit", targets: ["FKCoreKit"]),
  ],
  targets: [
    .target(
      name: "FKUIKit",
      dependencies: ["FKEmptyStateCoreLite", "FKCoreKit"],
      path: "Sources/FKUIKit",
      exclude: [
        "Components/EmptyState/CoreLite",
        // Module docs only — avoids SwiftPM “unhandled file” warnings for README.md
        "Components/Badge/README.md",
        "Components/Base/README.md",
        "Components/BlurView/README.md",
        "Components/Button/README.md",
        "Components/CornerShadow/README.md",
        "Components/Divider/README.md",
        "Components/EmptyState/README.md",
        "Components/ExpandableText/README.md",
        "Components/MultiPicker/README.md",
        "Components/SheetPresentationController/README.md",
        "Components/ProgressBar/README.md",
        "Components/Refresh/README.md",
        "Components/Player/Core/README.md",
        "Components/Player/VideoPlayer/README.md",
        "Components/Player/AudioPlayer/README.md",
        "Components/Skeleton/README.md",
        "Components/TabBar/README.md",
        "Components/TextField/README.md",
        "Components/Toast/README.md",
        "Components/ActionSheet/README.md",
      ],
      resources: [
        .process("Resources"),
      ]
    ),
    .target(
      name: "FKEmptyStateCoreLite",
      path: "Sources/FKUIKit/Components/EmptyState/CoreLite"
    ),
    .target(
      name: "FKCoreKit",
      path: "Sources/FKCoreKit",
      exclude: [
        "Async/README.md",
        "BusinessKit/README.md",
        "FileManager/README.md",
        "Logger/README.md",
        "Network/README.md",
        "Permissions/README.md",
        "Security/README.md",
        "Storage/README.md",
        "Utils/README.md",
        "Pluggable/README.md",
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
