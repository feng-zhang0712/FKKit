# FKTheme — 设计需求文档

FKKit **`FKTheme`** 的实现指导文档：在 `FKUIKit/Core` 层建立**设计令牌（Design Tokens）**与**主题应用**体系，统一各 UI 组件的颜色角色、字阶、间距、圆角与阴影，并支持浅色/深色模式、Dynamic Type 与可选 SwiftUI 桥接。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) Tier 3 `FKTheme`  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §9  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 令牌模型](#6-令牌模型)
- [7. 颜色系统](#7-颜色系统)
- [8. 字阶与排版](#8-字阶与排版)
- [9. 间距、圆角与阴影](#9-间距圆角与阴影)
- [10. 主题实例与切换](#10-主题实例与切换)
- [11. 与现有组件的集成策略](#11-与现有组件的集成策略)
- [12. 公开 API](#12-公开-api)
- [13. 配置模型](#13-配置模型)
- [14. Dynamic Type 与无障碍](#14-dynamic-type-与无障碍)
- [15. SwiftUI 桥接](#15-swiftui-桥接)
- [16. 迁移与兼容](#16-迁移与兼容)
- [17. 建议源码目录结构](#17-建议源码目录结构)
- [18. FKKitExamples 场景](#18-fkkitexamples-场景)
- [19. 待决问题](#19-待决问题)
- [20. 修订历史](#20-修订历史)

---

## 1. 概述

随着 FKUIKit 组件数量增长（Button、Toast、Chip、StatusPill、Sheet 等），各组件各自维护默认色值、字号与间距，导致：

- 品牌换肤需逐组件改配置；
- 深色模式语义不一致（有的用 `systemBlue`，有的硬编码 RGB）；
- 全局「主色 / 破坏性色 / 表面色」无单一来源。

**现状（`Sources/FKUIKit/Core/`）：**

| 已有 primitive | 说明 |
|----------------|------|
| `FKLayerBorderStyle` / `FKLayerShadowStyle` | CALayer 描边/阴影模型 |
| `FKButtonGlobalStyle` | 进程级 Button 默认外观 |
| `FKWidgetStatusColorTokens` | Widgets 工作流语义色（success/warning 等） |
| 各组件 `defaultConfiguration` | 分散在各组件 Public API |

**`FKTheme`**（建议 `Sources/FKUIKit/Core/Theme/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKTheme`** | 不可变主题快照（`Sendable`），聚合全部令牌 |
| **`FKThemeColorPalette`** | 语义颜色角色（primary、surface、destructive…） |
| **`FKThemeTypography`** | 字阶与文本样式 |
| **`FKThemeMetrics`** | 间距、圆角、最小触控尺寸 |
| **`FKThemeShadowTokens`** | 与 `FKLayerShadowStyle` 对齐的阴影预设 |
| **`FKThemeRegistry`** | 当前主题注册、切换通知、`@MainActor` 访问 |
| **`FKThemeResolver`** | 按 `UITraitCollection` 解析动态色 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **单一令牌来源** — App 启动时注入品牌主题；组件默认配置从 `FKThemeRegistry.current` 读取。
2. **语义化颜色** — 使用角色名（`primary`、`onPrimary`、`surfaceElevated`），禁止组件 README 推荐硬编码 RGB。
3. **浅色/深色/高对比度** — 颜色令牌基于 `UIColor` 动态 Provider 或 FKTheme 内建 light/dark 表。
4. **Dynamic Type** — 字阶随 `UIContentSizeCategory` 缩放；提供 `FKThemeTypography.scaled(_:)`。
5. **非破坏性接入** — 未设置全局主题时，各组件 `defaultConfiguration` 行为与 today **完全一致**。
6. **Swift 6** — 令牌结构体 `Sendable`；注册表与 UI 通知 `@MainActor`。
7. **文档化迁移路径** — README 说明 Button、Toast、Chip 等如何「 opt-in 」主题。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 运行时远程主题下发 | 可由宿主 App 拉取 JSON 后构造 `FKTheme` 注入；库内不提供 CDN 协议 |
| 自动重写所有既有组件内部硬编码 | v1 提供令牌 + 注册表 + 2–3 个示范组件接入；全量迁移分阶段 |
| macOS / Catalyst 独立主题 | 仅 iOS 15+ UIKit；SwiftUI macOS 不在范围 |
| 完整 Design System Figma 同步工具 | 不在范围 |
| 动画曲线令牌 | v2 可选 |
| 替换 `FKWidgetStatusColorTokens` | v1 **复用并纳入** `FKThemeColorPalette.status` |

### 2.3 成功标准

- [ ] `FKTheme.default` 与 `FKTheme.defaultDark` 内置可用。
- [ ] App 设置 `FKThemeRegistry.current = customTheme` 后，`FKButton` 新建实例默认主色跟随 `primary`。
- [ ] 系统切换深色模式时，已注册 `FKThemeResolver` 的视图收到 `themeDidChange` 并可刷新。
- [ ] Dynamic Type 最大档时，字阶不截断（配合现有组件 `adjustsFontForContentSizeCategory`）。
- [ ] README 含令牌表、集成步骤、与 `FKButtonGlobalStyle` 关系说明。
- [ ] Examples：默认主题、自定义品牌色、深色对比、Dynamic Type 预览。

---

## 3. 背景与问题陈述

### 3.1 分散配置的代价

| 组件 | 当前默认来源 | 问题 |
|------|--------------|------|
| `FKButton` | `FKButtonGlobalStyle.defaultAppearances` | 与 Toast/Chip 主色可能不一致 |
| `FKToast` | `FKToastConfiguration` 静态默认 | 语义色与 StatusPill 重复定义 |
| `FKChip` / `FKTag` | `FKChipConfiguration` / `FKTagConfiguration` | 营销色与工作流色边界已有，但缺全局 primary |
| `FKStatusPill` | `FKWidgetStatusColorTokens` | 仅覆盖 status 语义 |
| `FKSheetPresentationController` | 独立 dim/background 常量 | 与 Alert/ActionSheet 难统一 |

### 3.2 与 HIG 的关系

FKTheme **不替代** Apple Semantic Colors；默认主题应优先映射到 `UIColor.label`、`secondaryLabel`、`systemBackground`、`tintColor` 等，仅在品牌定制时覆盖 `primary` 等角色。

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 App @ launch                                               │
│  FKThemeRegistry.register(FKTheme.brand)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKThemeRegistry（@MainActor）                                   │
│  current: FKTheme │ themeDidChangeNotification                  │
└────────────────────────────┬────────────────────────────────────┘
                             │ read tokens
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   FKButton            FKToast              FKChip / FKTag
   FKTextField         FKEmptyState         FKSheet...
        │                    │                    │
        └────────────────────┴────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKTheme（Sendable 快照）                                        │
│  colors │ typography │ metrics │ shadows │ status               │
└─────────────────────────────────────────────────────────────────┘
```

**解析时机：**

1. **静态快照** — `FKTheme` 初始化时绑定 light/dark `UIColor` 动态 Provider；
2. **运行时** — 组件 `layoutSubviews` / `traitCollectionDidChange` 通过 `FKThemeResolver.color(_:for:)` 取色。

---

## 5. 模块边界

| 关注点 | FKTheme | FKButtonGlobalStyle | FKWidgetStatusColorTokens |
|--------|---------|---------------------|---------------------------|
| 全局主色/表面色 | **是** | 仅 Button | 否 |
| Button 交互参数（节流、长按） | 否 | **是** | 否 |
| 工作流 status 色 | 纳入 palette | 否 | **现有实现** |
| 模块 | FKUIKit Core | FKUIKit Button | FKUIKit Widgets |

**依赖：** 仅 `UIKit`；可读取 `FKUIKitI18n` 资源包。**不得**依赖 FKCoreKit（保持 FKUIKit 对 Core 的单向依赖 — Theme 在 FKUIKit 内，不反向）。

### 5.1 FKCoreKit / FKUIKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| Layer 样式 | 现有 **`FKLayerBorderStyle`**、**`FKLayerShadowStyle`** | 平行 Shadow 模型 |
| Status 语义色 | 迁移/包装 **`FKWidgetStatusColorTokens`** | 第三套 status 色表 |
| Button 全局钩子 | 扩展 **`FKButtonGlobalStyle.applyPerNewButton`** | 替换 Button 初始化链 |
| 设备/无障碍 | **`UITraitCollection`**、系统 Dynamic Type | 固定字号表无视 contentSize |

---

## 6. 令牌模型

### 6.1 顶层结构

```swift
public struct FKTheme: Sendable, Equatable {
  public var id: String
  public var colors: FKThemeColorPalette
  public var typography: FKThemeTypography
  public var metrics: FKThemeMetrics
  public var shadows: FKThemeShadowTokens

  public static let `default`: FKTheme
  public static let defaultDark: FKTheme  // 可选显式 dark 表；或与 dynamic 合并
}
```

### 6.2 设计原则

- **令牌只读** — 修改主题 = 替换整个 `FKTheme` 实例并 `register`；
- **组件不持有 Theme 副本** — 渲染时读 `FKThemeRegistry.current` 或注入的 `FKThemeProviding`；
- **Equatable** — 用于 diff 后刷新 UI。

---

## 7. 颜色系统

### 7.1 语义角色（v1 最小集）

| 角色 | 用途 |
|------|------|
| `primary` | 品牌主色、主按钮填充、链接 |
| `onPrimary` | primary 上的文本/图标 |
| `secondary` | 次要强调 |
| `onSecondary` | secondary 上的内容色 |
| `destructive` | 破坏性操作 |
| `onDestructive` | 破坏性按钮上的内容色 |
| `background` | 屏幕背景 |
| `surface` | 卡片、Sheet、Toast 容器 |
| `surfaceElevated` | 浮层、Popover |
| `onSurface` | 表面上的主文本 |
| `onSurfaceSecondary` | 副文本、说明 |
| `outline` | 边框、分隔（可与 Divider 默认对齐） |
| `scrim` | 模态 dim（Sheet/Alert 背景） |
| `statusSuccess` / `statusWarning` / `statusError` / `statusInfo` / `statusNeutral` | 对齐 `FKWidgetStatusSemantic` |

### 7.2 动态色

```swift
public struct FKThemeColor: Sendable, Equatable {
  public var light: UIColor
  public var dark: UIColor

  public func resolved(for traitCollection: UITraitCollection) -> UIColor
}
```

或使用 `UIColor { trait in ... }` 初始化器封装为 `FKThemeDynamicColor`。

### 7.3 对比度

- `onPrimary` / `onDestructive` 与底色对比度 **≥ 4.5:1**（WCAG AA 正文）；文档提供校验建议，库内 v1 不强制运行时计算。

---

## 8. 字阶与排版

### 8.1 字阶令牌

| 令牌 | 默认基准（Large 档） | 用途 |
|------|----------------------|------|
| `largeTitle` | 34 pt semibold | 极少；EmptyState 标题 |
| `title1` | 28 pt | 页面标题 |
| `title2` | 22 pt | Section 头 |
| `title3` | 20 pt | 卡片标题 |
| `headline` | 17 pt semibold | 列表主标题 |
| `body` | 17 pt regular | 正文 |
| `callout` | 16 pt | 次要正文 |
| `subheadline` | 15 pt | 副标题 |
| `footnote` | 13 pt | 辅助说明 |
| `caption1` / `caption2` | 12 / 11 pt | 角标、时间戳 |

### 8.2 API

```swift
public struct FKThemeTypography: Sendable, Equatable {
  public func font(for style: FKThemeTextStyle, contentSizeCategory: UIContentSizeCategory) -> UIFont
  public func scaledMetrics(for style: FKThemeTextStyle) -> FKThemeScaledMetrics
}
```

**必须**使用 `UIFontMetrics` 或现有 Extension 缩放模式，与 `FKTextField`、`FKExpandableText` 一致。

---

## 9. 间距、圆角与阴影

### 9.1 FKThemeMetrics

| 类别 | 令牌示例 | 默认 |
|------|----------|------|
| 间距 | `xxs`…`xxl` | 4, 8, 12, 16, 24, 32 pt |
| 圆角 | `radiusSmall`, `radiusMedium`, `radiusLarge`, `radiusFull` | 8, 12, 16, 胶囊 |
| 触控 | `minimumHitTarget` | **44 pt**（HIG） |
| 边框 | `hairline` | 1 px（对齐 `FKDivider`） |

### 9.2 FKThemeShadowTokens

映射到现有 `FKLayerShadowStyle`：

```swift
public struct FKThemeShadowTokens: Sendable, Equatable {
  public var elevationLow: FKLayerShadowStyle
  public var elevationMedium: FKLayerShadowStyle
  public var elevationHigh: FKLayerShadowStyle
}
```

---

## 10. 主题实例与切换

### 10.1 FKThemeRegistry

```swift
@MainActor
public enum FKThemeRegistry {
  public static var current: FKTheme { get set }
  public static var themeDidChangeNotification: Notification.Name { get }

  /// 注册并广播；可选 animated 刷新 key window
  public static func register(_ theme: FKTheme, notify: Bool = true)
}
```

### 10.2 可选协议（组件 opt-in）

```swift
public protocol FKThemeAware: AnyObject {
  func apply(theme: FKTheme)
}
```

组件在 `traitCollectionDidChange` 与 `themeDidChangeNotification` 时调用 `apply(theme:)`。

---

## 11. 与现有组件的集成策略

### 11.1 分阶段接入（v1 示范）

| 优先级 | 组件 | 接入方式 |
|--------|------|----------|
| P0 | `FKButton` | `FKButtonGlobalStyle.defaultAppearances` 从 `FKThemeRegistry.current` 构建默认 primary/secondary/destructive |
| P0 | `FKToast` | `FKToast.defaultConfiguration` 的 `textColor` / `backgroundColor` 语义映射 |
| P1 | `FKDivider` | `outline` 色 |
| P1 | `FKSheetPresentationController` | `scrim` 不透明度 |
| P2 | `FKChip` / `FKTag` | 选中态 `primary` |
| P2 | 全组件 | 文档列出 `defaultConfiguration` 与 Theme 字段对照表 |

### 11.2 不得破坏的行为

- 未调用 `FKThemeRegistry.register` 时，`FKThemeRegistry.current == FKTheme.default`，且各组件视觉与 **当前发版** 像素级一致（允许 ±1pt 浮点误差）。

---

## 12. 公开 API

```swift
// 构建自定义品牌主题
var brand = FKTheme.default
brand.id = "brand-2026"
brand.colors.primary = FKThemeColor(light: .systemTeal, dark: .systemTeal)
FKThemeRegistry.register(brand)

// 组件内（示意）
let primary = FKThemeRegistry.current.colors.primary.resolved(for: traitCollection)
```

**Builder（可选 v1.1）：**

```swift
public struct FKThemeBuilder {
  public mutating func primary(_ color: FKThemeColor) -> Self
  public func build() -> FKTheme
}
```

---

## 13. 配置模型

主题本身即配置；额外 **`FKThemeApplicationOptions`** 控制注册行为：

```swift
public struct FKThemeApplicationOptions: Sendable, Equatable {
  public var postsNotification: Bool
  public var refreshesVisibleWindows: Bool
}
```

---

## 14. Dynamic Type 与无障碍

- 所有字阶令牌 **必须** 支持 content size 变化；
- `FKThemeRegistry` 切换时，已展示组件应刷新字体（通过 notification + `setNeedsLayout`）；
- 颜色角色切换时，不依赖仅 `UILabel.textColor` 静态赋值 — 使用动态色或 `apply(theme:)` 重刷；
- Reduce Transparency 开启时，`scrim` / `surface` 应提高不透明度（可读 `UIAccessibility.isReduceTransparencyEnabled`）。

---

## 15. SwiftUI 桥接

### 15.1 v1 交付

```swift
public struct FKThemeEnvironmentKey: EnvironmentKey { ... }
public extension EnvironmentValues {
  var fkTheme: FKTheme { get set }
}
```

### 15.2 原则

- SwiftUI 侧只读 `FKTheme` 快照；
- 不写回 UIKit Registry（避免双源）；宿主在 SwiftUI 根 `environment(\.fkTheme, FKThemeRegistry.current)` 同步。

---

## 16. 迁移与兼容

| 场景 | 指引 |
|------|------|
| 已有 App 使用 `FKButtonGlobalStyle` | 继续有效；Theme 注册后 GlobalStyle 可被 Theme 覆盖默认值 |
| 组件级 `configuration` 覆盖 | **显式 configuration 优先于 Theme** |
| 单元测试 | 注入静态 `FKTheme` 快照，不依赖 `UITraitCollection` |

---

## 17. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为建议起点。详见 [COMPONENT_ROADMAP.md — 组件源码目录规范](COMPONENT_ROADMAP.md#组件源码目录规范)。

```text
Sources/FKUIKit/Core/Theme/
├── Public/
│   ├── FKTheme.swift
│   ├── FKThemeColorPalette.swift
│   ├── FKThemeTypography.swift
│   ├── FKThemeMetrics.swift
│   ├── FKThemeShadowTokens.swift
│   ├── FKThemeRegistry.swift
│   ├── FKThemeResolver.swift
│   └── Bridge/
│       └── FKTheme+SwiftUI.swift
├── Internal/
│   └── FKThemeDefaultFactory.swift
└── README.md
```

`Package.swift`：`Core/Theme/README.md` 加入 `exclude:`。

---

## 18. FKKitExamples 场景

路径：`Examples/.../FKUIKit/Theme/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `DefaultThemeBasics` | 未注册时与现网一致 |
| 2 | `CustomBrandPrimary` | 主色替换后 Button/Toast 联动 |
| 3 | `DarkModeToggle` | 系统深色切换 |
| 4 | `DynamicTypeRamp` | 字阶阶梯展示 |
| 5 | `StatusSemanticColors` | status 色与 StatusPill 一致 |
| 6 | `SheetScrimAndSurface` | Sheet dim 与 surface 色 |
| 7 | `SwiftUIEnvironment` | Environment 注入 |

---

## 19. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | `FKThemeRegistry` 放 Core 还是独立 Theme 文件夹？ | `Core/Theme/` |
| Q2 | v1 强制接入组件数量？ | Button + Toast + 文档 |
| Q3 | 是否提供 JSON 导入？ | v1.1 |
| Q4 | `FKWidgetStatusColorTokens`  deprecate？ | 否，Theme 内部委托 |
| Q5 | 高对比度独立主题？ | v1 跟随系统 increased contrast trait |

---

## 20. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版，源自 COMPONENT_ROADMAP Tier 3 与缺口分析 |

---

## 相关文档

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md)
- [FKButton README](../Sources/FKUIKit/Components/Button/README.md)
