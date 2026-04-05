# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 计划中
- 单元测试 target 与 `Tests/` 目录
- 可选：`Examples` 示例 App（本地依赖本 Package）

## [0.2.0] - 2026-04-05

### 破坏性变更
- SwiftPM **Product / Target**：`FKPopover` 更名为 **`FKBarPresentation`**，源码目录为 `Sources/FKBarPresentation/`。
- 类型与协议：`FKPopover` → `FKBarPresentation`；`FKPopoverDelegate` → `FKBarPresentationDelegate`；`FKPopoverDataSource` → `FKBarPresentationDataSource`。
- 协议方法首参标签：`popover(_:…)` → **`barPresentation(_:…)`**（`shouldPresentFor` / `willPresentFor` / `didPresentFor` / 尺寸与内容提供等）。
- 闭包类型：`presentationContent` / `presentationViewController` 的首参类型由 `FKPopover` 改为 `FKBarPresentation`。
- 嵌套类型：如 `PresentationDismissReason` 等现位于 **`FKBarPresentation`** 命名空间下。

### 迁移说明
- 将 `import FKPopover` 改为 **`import FKBarPresentation`**，并在 Xcode 依赖中改选对应 Product。
- 全局替换公开类型名与协议实现中的方法签名；`delegate` / `dataSource` 属性名未变。

## [0.1.0] - 2026-04-04

### Added
- 多 Product 布局：`FKUIKitCore`、`FKButton`、`FKBar`、`FKPresentation`、`FKPopover`
- `Package.swift`：`platforms: [.iOS(.v15)]`、`swiftLanguageModes: [.v6]`
- `README.md`、`LICENSE`（MIT）、`CHANGELOG.md`、扩充后的 `.gitignore`

### Changed（为 SPM / Swift 6 可编译）
- 各配置类型上 `static let default` 使用 `nonisolated(unsafe)`，避免全局 `default` 的并发检查报错
- `FKBarConfigurationAssociatedKeys` 使用 `nonisolated(unsafe)` 关联对象 key
- `FKBar` / `FKPopover` 等补充 `import FKUIKitCore`、`FKButton`、`FKPresentation`、`FKBar` 等模块引用
- `FKPresentation` 标为 `@MainActor`；`FKBarDelegate`、`FKPresentationDelegate`、`FKPresentationDataSource` 标为 `@MainActor`
- `FKBar.Item.FKButtonSpec.apply(to:)` 标为 `@MainActor`
- `FKPopover.PresentationDismissReason` 遵循 `Sendable`

<!-- 发布到远程后，可将下方链接替换为实际仓库 URL -->
[Unreleased]: #
[0.2.0]: #
[0.1.0]: #
