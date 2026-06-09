# FKChip / FKTag / FKChipGroup — 设计需求文档

FKKit **胶囊筛选与标签模块**的实现指导文档：三个公开类型 **`FKChip`**（可交互筛选/输入）、**`FKTag`**（只读元数据标签）、**`FKChipGroup`**（Chip 布局与选择编排），统一封装于 `Sources/FKUIKit/Components/Widgets/Chip/`。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.2  
**所属家族：** [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 模块架构与类型边界](#3-模块架构与类型边界)
- [4. FKCoreKit 复用要求（强制）](#4-fkcorekit-复用要求强制)
- [5. 共享设计语言](#5-共享设计语言)
- [6. FKChip](#6-fkchip)
- [7. FKTag](#7-fktag)
- [8. FKChipGroup](#8-fkchipgroup)
- [9. 选型决策树](#9-选型决策树)
- [10. SwiftUI 桥接](#10-swiftui-桥接)
- [11. 建议源码目录结构](#11-建议源码目录结构)
- [12. FKKitExamples 场景](#12-fkkitexamples-场景)
- [13. 待决问题](#13-待决问题)
- [14. 修订历史](#14-修订历史)

---

## 1. 概述

商品筛选、搜索 token、卡片促销标签、列表分类角标等场景需要**胶囊形 UI 原子**。团队反复自绘 Pill 时常见：

- 可交互 Chip 与只读 Tag 混用，VoiceOver 语义错误
- 筛选条单选/多选逻辑分散在 VC
- 移除按钮热区不足 44pt
- Chip/Tag/StatusPill 各自一套圆角测量代码

本模块交付 **三个独立公开类型**，共享 **`Widgets/Core/`** 胶囊布局与图标渲染，API 边界清晰、Internal 不重复。

| 交付物 | 基类 | 职责 |
|--------|------|------|
| **`FKChip`** | `UIControl` | 可切换/可移除的筛选与输入 token |
| **`FKTag`** | `UIView` | 只读分类/促销/角色标签（v1 不可点） |
| **`FKChipGroup`** | `UIView` | 多 Chip 流式/横滚布局 + 选择策略 |
| **`FKChipItem`** 等 | — | Group 数据模型 |
| **`Widgets/Core/`** | — | `FKCapsuleLayoutEngine`、`FKFlowLayoutView`、`FKWidgetIcon` |

**建议路径：** `Sources/FKUIKit/Components/Widgets/Chip/`

---

## 2. 目标、非目标与成功标准

### 2.1 模块目标

1. **三类型 API 独立** — 不合并为单一 `FKPill` + mode 枚举。
2. **共享 Internal** — 胶囊测量、流式布局、图标槽、语义色 token 一处实现。
3. **统一配置模式** — `Sendable` 分层配置、`defaultConfiguration`、预设、`@MainActor`。
4. **HIG** — 可交互时 44pt 热区；Dynamic Type；RTL；Reduce Motion。
5. **FKListKit 友好** — `FKChipGroup` 可作 supplementary header；`FKTag` 作 trailing。

### 2.2 非目标

| 排除 | 改用 |
|------|------|
| 工作流/订单状态词 | **`FKStatusPill`**（独立模块） |
| 数字角标 | **`FKBadge`** |
| 复制 ID | **`FKCopyChip`** |
| 下拉筛选面板 | **`FKCallout`** / **`FKActionSheet`** / FKBusinessKit **`TabBarFilter`** |
| 导航栏内 ChipGroup | 筛选放内容区独立行 |

### 2.3 成功标准

- [ ] 三类型均有 README 章节与 Examples 场景。
- [ ] Chip 四种 `FKChipMode`、Tag 全部 variant、Group 三种 selection 可演示。
- [ ] README 含 §9 决策树。
- [ ] 胶囊布局引擎仅一份实现（Core Internal）。

---

## 3. 模块架构与类型边界

```text
┌─────────────────────────────────────────────────────────┐
│ FKChipGroup（容器）                                      │
│  selection 编排 → 内部 FKChip 实例                       │
└───────────────────────────┬─────────────────────────────┘
                            │ 组合
┌───────────────────────────▼─────────────────────────────┐
│ FKChip（UIControl）          FKTag（UIView，只读）       │
└───────────────────────────┬─────────────────────────────┘
                            │ 共享
┌───────────────────────────▼─────────────────────────────┐
│ Widgets/Core：FKCapsuleLayoutEngine、FKWidgetIcon、     │
│ FKFlowLayoutView、FKWidgetLayoutMetrics                 │
└─────────────────────────────────────────────────────────┘
```

| 维度 | FKChip | FKTag | FKChipGroup |
|------|--------|-------|-------------|
| 交互 | 是 | v1 否 | 容器（选择策略） |
| 选中态 | 有 | 无 | 管理子 Chip 选中集 |
| 移除 ✕ | 可选 | 无 | — |
| 典型场景 | 筛选、搜索 token | 卡片「NEW」「VIP」 | 筛选条、多选标签 |

**与 FKBusinessKit `TabBarFilter`：** TabBarFilter 是**锚点 + Sheet 面板**的复合筛选 UX；本模块提供**行内胶囊原子**。Business 层可组合 TabBarFilter + ChipGroup，但 Chip/Tag 本体应在 **FKUIKit**（见 [FKSmallComponents — 仓库归属](FKSmallComponents_DESIGN.zh-CN.md#附录仓库归属fkuikit-vs-fkbusinesskit)）。

---

## 4. FKCoreKit 复用要求（强制）

实现前**必须先检索** `Sources/FKCoreKit`；**禁止**在 `Widgets/Chip/` 内重复实现同等逻辑。缺少通用能力时**向上游 FKCoreKit 补充 Extension**，而非模块内复制。

| 能力 | 必须使用 | 禁止自建 |
|------|----------|----------|
| 字符串截断/trim | **`String.fk_limitedPrefix`**、**`fk_trimmed`** | 自写截断 |
| 图标着色 | **`UIImage.fk_tinted`**、**`FKIconView`**（Widgets/Core） | 重复 Symbol 布局 |
| 字体缩放 | **`UIFont` Extension** / `UIFontMetrics` | 固定字号 |
| 触觉 | 与 **`FKButton`** 相同路径 | 散落 `UIImpactFeedbackGenerator` |
| 本地化 | **`FKUIKitI18n`** / **`FKI18n`** | 硬编码 |
| 动画 | **`UIView` Animation Extension**；Reduce Motion | 无限制 CA |
| 布局度量 | **`CGRect`/`CGSize` Extension** | 魔法数 |
| 流式布局 diff | **`FKCoreKit` Set/IndexPath Extension** | 全量闪烁 rebuild |
| 搜索联动防抖 | **`FKDebouncer`** | 裸 Timer |

**Capsule 布局：** `FKCapsuleLayoutEngine` 放 `Widgets/Core/Internal/`，Chip、Tag、以及 **`FKStatusPill`** 模块**共用**，禁止各写一套。

---

## 5. 共享设计语言

### 5.1 配置分层

```swift
// Chip — 含 interaction
public struct FKChipConfiguration: Sendable, Equatable {
  public var layout: FKChipLayoutConfiguration
  public var appearance: FKChipAppearanceConfiguration
  public var interaction: FKChipInteractionConfiguration
  public var accessibility: FKChipAccessibilityConfiguration
}

// Tag — v1 无 interaction 层
public struct FKTagConfiguration: Sendable, Equatable { ... }

// ChipGroup
public struct FKChipGroupConfiguration: Sendable, Equatable { ... }
```

### 5.2 全局默认

```swift
public enum FKChipDefaults {
  @MainActor public static var configuration: FKChipConfiguration
}
// FKTagDefaults、FKChipGroupDefaults 同理
```

对齐 **`FKBadge.defaultConfiguration`**；README 说明 App 启动时覆盖。

### 5.3 尺寸档位

| 档位 | 高度 (pt) | 用于 |
|------|-----------|------|
| XS | 20–24 | Tag 密集列表 |
| S | 28–32 | Chip 筛选、Tag 卡片 |
| M | 36–40 | 默认 Chip |

### 5.4 图标

`FKChipIcon` / `FKTagIcon` 可 typealias 或共享 **`FKWidgetIcon`**（`Widgets/Core/Public/`）：`.symbol(name:)`、`.image(UIImage)`。

---

## 6. FKChip

### 6.1 职责

紧凑**切换/筛选**控件：选中态、前导图标、可选移除；发出 `UIControl.Event.valueChanged`（filter/choice 模式）。

### 6.2 模式（`FKChipMode`）

| 模式 | 选中态 | 移除 | 典型场景 |
|------|--------|------|----------|
| `.filter` | 点击切换 | 否 | 筛选条多选 |
| `.input` | 无填充选中 | 可选 ✕ | 搜索 token |
| `.suggestion` | 不保持 | 否 | 搜索建议点选 |
| `.choice` | 组内互斥 | 否 | 单选筛选 |

**事件：** `suggestion` 发 `primaryActionTriggered`，**不**切换 `isSelected`（待决 Q1 默认）。

### 6.3 外观状态

| 状态 | 视觉（默认） |
|------|--------------|
| Normal | `secondarySystemFill` |
| Selected | `tintColor` 填充或描边+浅填充 |
| Disabled | 降不透明度 |
| Highlighted | scale 0.97，≤0.2s |

内边距：水平 12–16pt；图标与文字间距 4–6pt。

### 6.4 公开 API

```swift
@MainActor
public final class FKChip: UIControl {
  public var configuration: FKChipConfiguration
  public var mode: FKChipMode
  public var title: String
  public var isSelected: Bool { didSet { updateAppearance() } }
  public var leadingIcon: FKChipIcon?
  public var showsRemoveButton: Bool
  public var onRemove: (() -> Void)?
}
```

### 6.5 移除按钮

- 尾部 ✕；**44pt** 热区（`point(inside:with:)` 或子按钮）。
- `onRemove` **不**触发选中切换。
- VoiceOver：「移除 {title}」（FKI18n）。

### 6.6 无障碍

- `accessibilityTraits`: `.button`；selected 时 `.selected`。
- Filter：「{title}，筛选，已选中/未选中」。
- Dynamic Type：至少 2 档再 `truncatingTail`。

---

## 7. FKTag

### 7.1 职责

**只读**元数据胶囊：分类、促销、「NEW」、角色名。v1 为 **`UIView`**，非 `UIControl`。

### 7.2 变体（`FKTagVariant`）

| 变体 | 用途 | 默认色 |
|------|------|--------|
| `.neutral` | 通用分类 | secondary fill |
| `.brand` | 品牌强调 | tint |
| `.success` / `.warning` / `.error` | 正向/注意/错误（**非流程**） | 语义色 |
| `.outline` | 描边无填充 | label 描边 |
| `.custom(...)` | 完全自定义 | 宿主指定 |

**注意：** 订单/审核**流程状态**用 **`FKStatusPill`**，避免与 Tag 语义色混淆。

### 7.3 公开 API

```swift
@MainActor
public final class FKTag: UIView {
  public var configuration: FKTagConfiguration
  public var title: String
  public var variant: FKTagVariant
  public var leadingIcon: FKTagIcon?
}
```

### 7.4 视觉

- 胶囊圆角：`height / 2` 或配置固定 corner。
- outline：1pt 描边，透明底。

### 7.5 无障碍

- `accessibilityTraits`: **`.staticText`**（v1 **不得** `.button`）。
- Label：`title` 或宿主覆盖。

---

## 8. FKChipGroup

### 8.1 职责

**`FKChip`** 的水平/垂直布局与**选择策略**；内部创建/复用子 `FKChip`，**禁止**自绘 pill。

### 8.2 选择模式

```swift
public enum FKChipGroupSelectionMode: Sendable, Equatable {
  case none
  case single
  case multiple(max: Int?)
}
```

| 模式 | 行为 |
|------|------|
| `.none` | 各 Chip 独立 |
| `.single` | 最多一项 selected |
| `.multiple(max:)` | 集合选中；达 max 时 `ignoreTap`（默认）或 `notify` |

### 8.3 布局模式

| `FKChipGroupLayoutMode` | 说明 |
|-------------------------|------|
| `.flow(wrap:)` | 多行流式；≤~30 项（v1） |
| `.horizontalScroll` | 单行 UIScrollView，隐藏 indicator |

### 8.4 数据模型

```swift
public struct FKChipItem: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var leadingIcon: FKChipIcon?
  public var isSelected: Bool
  public var isEnabled: Bool
}
```

### 8.5 公开 API

```swift
@MainActor
public final class FKChipGroup: UIView {
  public var configuration: FKChipGroupConfiguration
  public var chips: [FKChipItem]
  public var selectionMode: FKChipGroupSelectionMode
  public var selectedIDs: Set<String> { get }
  public func setSelectedIDs(_ ids: Set<String>, animated: Bool)
  public var onSelectionChange: ((Set<String>) -> Void)?
}
```

### 8.6 数据流

```text
chips 更新 → diff 子 FKChip
用户点击 → 更新 selectedIDs → onSelectionChange
外部 setSelectedIDs → 同步 UI（documented：是否二次回调）
```

### 8.7 无障碍

- 容器：`accessibilityContainerType = .semanticGroup`。
- 多选：FKI18n 模板播报选中数量。

---

## 9. 选型决策树

```text
可切换/可删筛选？           → FKChip（+ FKChipGroup）
只读分类/促销？             → FKTag
流程状态词（已发货等）？   → FKStatusPill
数字角标？                 → FKBadge
复制 ID？                  → FKCopyChip
锚点 + 下拉筛选面板？      → FKBusinessKit TabBarFilter（组合本模块 Chip 作行内展示）
```

---

## 10. SwiftUI 桥接

| 类型 | 桥接 |
|------|------|
| `FKTag` | 优先原生 **`FKTagView`**（Capsule） |
| `FKChip` | `FKChipRepresentable` + `Binding<Bool>` |
| `FKChipGroup` | `FKChipGroupRepresentable` + `Binding<Set<String>>` |

参考 **`FKDividerView`** 双栈做法。

---

## 11. 建议源码目录结构

> **非强制：** 可按复杂度调整；须在 `Chip/README.md` 文档化。

```text
Sources/FKUIKit/Components/Widgets/
├── README.md
├── Core/
│   ├── Public/FKWidgetIcon.swift
│   └── Internal/
│       ├── FKCapsuleLayoutEngine.swift
│       ├── FKFlowLayoutView.swift
│       └── FKWidgetLayoutMetrics.swift
└── Chip/
    ├── README.md
    ├── Public/
    │   ├── FKChip.swift
    │   ├── FKChipMode.swift
    │   ├── FKChipConfiguration.swift
    │   ├── FKTag.swift
    │   ├── FKTagVariant.swift
    │   ├── FKChipGroup.swift
    │   ├── FKChipItem.swift
    │   └── Bridge/
    │       ├── FKChipRepresentable.swift
    │       ├── FKTagView.swift
    │       └── FKChipGroupRepresentable.swift
    └── Internal/
        ├── FKChipContentView.swift
        ├── FKTagRenderer.swift
        ├── FKChipGroupSelectionController.swift
        └── FKChipGroupFlowLayout.swift
```

---

## 12. FKKitExamples 场景

路径：`Examples/.../FKUIKit/Widgets/Chip/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `FilterChipBar` | ChipGroup single/multiple |
| 2 | `RemovableInputChips` | Chip input + ✕ |
| 3 | `SuggestionOnce` | suggestion 不保持选中 |
| 4 | `ProductTags` | Tag 全部 variant |
| 5 | `ListRowTrailing` | Tag + ListKit |
| 6 | `FlowWrapAX5` | 大字号换行 |
| 7 | `HorizontalScrollBar` | 横滚筛选 |
| 8 | `SwiftUIRepresentables` | Binding |
| 9 | `DarkModeRTL` | 全套 |

---

## 13. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | Tag 与 Chip 同目录？ | **是**（本文档模块） |
| Q2 | v1 Tag 可点？ | 否 |
| Q3 | suggestion 发 valueChanged？ | primaryActionTriggered only |
| Q4 | Group Flow 用 CollectionView？ | ≤20 项 FlowLayoutView |
| Q5 | Tag/Pill 色板共享？ | Widgets/Core status vs marketing token 分表 |
| Q6 | 溢出 AvatarGroup +N 用 Tag neutral？ | 是（Avatar 模块文档） |

---

## 14. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-10 | FKChip、FKTag、FKChipGroup 独立文档初版 |
| 2026-06-10 | 合并为单一模块设计文档 |

---

## 相关文档

- [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md)
- [FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md](FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md)
- [FKStatusPill_DESIGN.zh-CN.md](FKStatusPill_DESIGN.zh-CN.md)
- [FKIconView_DESIGN.zh-CN.md](FKIconView_DESIGN.zh-CN.md)
- [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md)
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
