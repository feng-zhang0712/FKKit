# FKSmallComponents — 设计需求文档

FKKit **小型 UI 组件**（小组件库）的实现指导文档：轻量、单一职责的视图与控件，高频出现在列表、导航、筛选与资料区 —  scope 小于 **`FKEmptyState`**、**`FKActionSheet`**、**`FKListKit`**，但需要在 FK 视觉与行为上保持一致。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.2–2.3、Tier 3 `FKMarquee`  
**定位：** 小组件库 **umbrella** 文档；各组件详细设计见 §6.1 独立文档链接。

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 何为小组件](#3-何为小组件)
- [4. 共享设计语言](#4-共享设计语言)
- [5. 尺寸、密度与点击区域](#5-尺寸密度与点击区域)
- [6. 组件目录](#6-组件目录)
- [7. 各组件设计文档（详细规范）](#7-各组件设计文档详细规范)
- [17. 已有小组件（参考）](#17-已有小组件参考)
- [19. SwiftUI 桥接策略](#19-swiftui-桥接策略)
- [20. 建议源码目录结构](#20-建议源码目录结构)
- [21. FKKitExamples 场景](#21-fkkitexamples-场景)
- [23. 待决问题](#23-待决问题)
- [24. 修订历史](#24-修订历史)

---

## 1. 概述

FKKit 大型模块解决**整屏与流程**；小组件解决**高频视觉原子**：

- 导航栏与评论行的用户头像
- 商品列表上方的筛选 Chip
- 卡片上的「VIP」「Beta」「缺货」标签
- 头像上的在线状态点
- 可复制订单号

部分原子已发布（**`FKBadge`**、**`FKDivider`**、**`FKCornerShadow`**）。**FKSmallComponents** 家族为其余组件统一设计契约：可预期的配置、默认值、无障碍与 SwiftUI 桥接。

| 计划新增 | 职责 |
| ---------- | ------ |
| **`FKAvatar`** | 图片 / 首字母 / 占位头像 |
| **`FKAvatarGroup`** | 重叠头像堆叠 +N |
| **`FKChip`** | 可选中 / 可移除筛选 Chip |
| **`FKTag`** | 只读元数据标签 |
| **`FKChipGroup`** | 单选/多选 Chip 容器 |
| **`FKStatusPill`** | 语义状态胶囊 |
| **`FKPresenceIndicator`** | 在线/忙碌/离线点 |
| **`FKIconView`** | 固定尺寸 SF Symbol 容器 |
| **`FKCopyChip`** | 截断文本 + 复制 |
| **`FKMarqueeLabel`** | 横向滚动公告文字 |

**已生产（同家族约定）：** `FKBadge`、`FKDivider`、`FKCornerShadow`、`FKExpandableText`。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **单一职责、小 API** — 每个类型一份 README 即可讲清；不做迷你框架。
2. **统一配置模式** — `Sendable` 嵌套配置、`defaultConfiguration`、预设、`@MainActor` UIKit。
3. **可组合** — 嵌入 `FKListKit`、导航栏、`FKButton` 附件，无特殊分支。
4. **HIG 基线** — 可交互时 44pt 点击区；Dynamic Type；RTL；深色模式；减少动态效果。
5. **复用 FKCoreKit / FKUIKit（强制）** — 实现前检索 `Sources/FKCoreKit`（Extension、Utils、Pluggable、Async、I18n 等），**禁止重复造轮子**；UI 层复用 `FKButton`、`FKBadge`、`FKImageView`、`FKLayerBorderStyle`、`FKUIKitI18n` 等。详见 [§4.6 FKCoreKit 复用要求](#46-fkcorekit-复用要求强制)。
6. **SwiftUI** — 薄 `Representable` 或简单原生 View（参考 `FKDividerView`）。

### 2.2 非目标

| 排除 | 改用 |
|------|------|
| 整页空态/加载 | `FKEmptyState`、`FKSkeleton` |
| 表单控件 | `FKFormControls` |
| Toast / 横幅 | `FKToast`、`FKBanner` |
| 主题令牌系统 | 未来 `FKTheme` |

### 2.3 成功标准

- [ ] 每个新小组件：README、Examples Hub、根索引条目。
- [ ] Chip/Tag/StatusPill 与 Avatar 系交付。
- [ ]  umbrella README 说明统一 `defaultConfiguration`。
- [ ] 目录决策树：Chip vs Tag vs StatusPill vs Badge。

---

## 3. 何为小组件

### 3.1 判定启发式

| 维度 | 小组件 | 非小组件 |
|------|--------|----------|
| 主要职责 | 一种视觉原子 | 多原子 + 状态机编排 |
| 实现规模（约） | 200–800 LOC | 2000+ |
| 配置 struct | 1–4 层 | 8+ 层 |
| 独立 Example | 2–4 个 | 10+ 个 |

### 3.2 与路线图关系

- **Tier 2** §2.2–2.3：Chip/Tag、Avatar。
- **Tier 3** `FKMarquee` 纳入本文 compact 文本动效类。
- **Tier 1**（ListKit、SearchBar）**不在**本文范围。

---

## 4. 共享设计语言

### 4.1 配置分层

```swift
public struct FK<Component>Configuration: Sendable, Equatable {
  public var layout: FK<Component>LayoutConfiguration
  public var appearance: FK<Component>AppearanceConfiguration
  public var interaction: FK<Component>InteractionConfiguration  // UIControl 时
  public var accessibility: FK<Component>AccessibilityConfiguration
}
```

只读组件（如 `FKTag`）可省略 `interaction`。

### 4.2 全局默认

```swift
public enum FK<Component>Defaults {
  @MainActor public static var configuration: FK<Component>Configuration
}
```

对齐 **`FKBadge.defaultConfiguration`**；文档说明启动时覆盖。

### 4.3 Control 与 View

| 类型 | 基类 | 示例 |
|------|------|------|
| 可交互 | `UIControl` | `FKChip`、`FKCopyChip`、`FKAvatar`（可点时） |
| 仅展示 | `UIView` | `FKTag`、`FKStatusPill`、`FKPresenceIndicator` |
| 叠加附着 | Controller | `FKBadgeController` |

### 4.4 视觉令牌（`FKTheme` 之前）

- 语义色：`label`、`secondaryLabel`、`systemFill`
- 状态色：绿/橙/红
- 圆角：Chip/Tag/Pill 用**胶囊**；头像用**圆**；小矩形 8–12pt

### 4.5 动效

- 选中：短缩放或填充交叉（≤0.2s）
- 尊重 **Reduce Motion**
- Chip 切换可选轻触觉（对齐 `FKButton`）

### 4.6 FKCoreKit 复用要求（强制）

本家族所有组件在实现前**必须先检索** `Sources/FKCoreKit`，优先使用已有能力；**禁止**在 FKUIKit 组件目录内重复实现 Extension/Utils 已有或应上提的通用逻辑。若某能力适合多个组件复用但 FKCoreKit 尚未提供，应**在 FKCoreKit 补充 API**，而非在单个 Widget 内复制。

| 通用能力 | 必须使用（FKCoreKit / 邻域 FKUIKit） | 禁止 |
|----------|--------------------------------------|------|
| 字符串 trim/截断/遮罩 | `String.fk_trimmed`、`fk_limitedPrefix`、`fk_masked*` | 组件内自写 |
| 位图缩放/圆角/着色 | `UIImage.fk_resized`、`fk_roundingCorners`、`fk_tinted` | 重复 UIGraphics |
| 布局度量 | `CGRect`/`CGSize`/`CGFloat` Extension | 魔法数散落 |
| 防抖/可取消工作 | `FKDebouncer`、`CancellableWork`（Async） | 裸 Timer |
| 本地化 | `FKI18n`、`FKUIKitI18n` | 硬编码文案 |
| 图层/描边 | `CALayer` Extension、`FKLayerBorderStyle` | 自写 border |
| 远端图片 | `FKImageLoader` + `FKImageView` | 自建 URLSession 管线 |
| 胶囊/流式布局 | `Widgets/Core/` 共享引擎 | Chip/Tag/Pill 各写一套 |

各组件**强制复用表**见对应独立设计文档（§6.1）。路线图总表：[COMPONENT_ROADMAP.zh-CN.md — 勿重复造轮子](COMPONENT_ROADMAP.zh-CN.md#勿重复造轮子--复用对照表)。

---

## 5. 尺寸、密度与点击区域

### 5.1 尺寸档位

| 档位 | 高度 (pt) | 场景 |
|------|-----------|------|
| **XS** | 20–24 | 密集列表内 Tag |
| **S** | 28–32 | 筛选 Chip、状态 Pill |
| **M** | 36–40 | 行内头像、标准 Chip |
| **L** | 48–56 | 资料页头像 |
| **XL** | 64–80 | 资料页大图 |

### 5.2 点击扩展

可交互组件**必须**通过 `point(inside:with:)` 或内边距将热区扩至 **44×44pt**（视觉尺寸不变）。

### 5.3 Dynamic Type

- Chip/Tag 文字至少支持 **2** 档字号再截断
- 头像首字母随配置档位缩放

---

## 6. 组件目录

| 组件 | 可交互 | 主要内容 | 与 Badge |
|------|--------|----------|----------|
| **FKAvatar** | 可选 | 图/首字母 | Badge、Presence |
| **FKAvatarGroup** | 可选 | 堆叠头像 | — |
| **FKChip** | 是 | 标题+图标 | 移除 ✕ |
| **FKTag** | 否* | 标题+图标 | — |
| **FKChipGroup** | 容器 | — | — |
| **FKStatusPill** | 可选 | 状态词 | — |
| **FKPresenceIndicator** | 否 | 色点 | — |
| **FKIconView** | 可选 | Symbol | Badge |
| **FKCopyChip** | 是 | ID 文本 | 复制图标 |
| **FKMarqueeLabel** | 否 | 滚动文 | — |

\* v1 `FKTag` 只读；v1.1 可评估可点。

### 6.1 设计文档索引

| 模块 / 组件 | 设计文档 |
|-------------|----------|
| **Chip 模块**（FKChip + FKTag + FKChipGroup） | [FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md](FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md) |
| **Avatar 模块**（FKAvatar + FKAvatarGroup + FKPresenceIndicator） | [FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md](FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md) |
| **FKStatusPill** | [FKStatusPill_DESIGN.zh-CN.md](FKStatusPill_DESIGN.zh-CN.md) |
| **FKIconView** | [FKIconView_DESIGN.zh-CN.md](FKIconView_DESIGN.zh-CN.md) |
| **FKCopyChip** | [FKCopyChip_DESIGN.zh-CN.md](FKCopyChip_DESIGN.zh-CN.md) |
| **FKMarqueeLabel** | [FKMarqueeLabel_DESIGN.zh-CN.md](FKMarqueeLabel_DESIGN.zh-CN.md) |

### 6.2 选型决策树

```text
图标/Tab 上数字角标？        → FKBadge
分割线？                    → FKDivider
用户头像？                  → FKAvatar（+ Presence）
可切换/可删筛选？           → FKChip（+ ChipGroup）
只读分类标签？              → FKTag
成功/警告/失败状态词？      → FKStatusPill
复制 ID？                   → FKCopyChip
滚动公告？                  → FKMarqueeLabel
```

---

## 7. 各组件设计文档（详细规范）

实现时以**模块级设计文档**为准（合并模块内各公开类型的完整 API 与 FKCoreKit 复用表）：

| 模块 | 包含公开类型 | 设计文档 |
|------|--------------|----------|
| **Chip** | FKChip、FKTag、FKChipGroup | [FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md](FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md) |
| **Avatar** | FKAvatar、FKAvatarGroup、FKPresenceIndicator | [FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md](FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md) |
| **StatusPill** | FKStatusPill | [FKStatusPill_DESIGN.zh-CN.md](FKStatusPill_DESIGN.zh-CN.md) |
| **IconView** | FKIconView | [FKIconView_DESIGN.zh-CN.md](FKIconView_DESIGN.zh-CN.md) |
| **CopyChip** | FKCopyChip | [FKCopyChip_DESIGN.zh-CN.md](FKCopyChip_DESIGN.zh-CN.md) |
| **Marquee** | FKMarqueeLabel | [FKMarqueeLabel_DESIGN.zh-CN.md](FKMarqueeLabel_DESIGN.zh-CN.md) |

---

## 17. 已有小组件（参考）

**禁止**重复实现；通过配置扩展：

| 组件 | 职责 |
|------|------|
| **FKBadge** | 角标叠加 |
| **FKDivider** | 分割线 |
| **FKCornerShadow** | 圆角阴影 |
| **FKExpandableText** | 截断展开 |

Avatar **必须**用 **`FKBadge`**，不在 Avatar 内重做角标渲染。

---

## 18. 组合与集成模式

### 18.1 FKListKit

- Leading：`FKAvatar` + 标题栈；Trailing：`FKTag` / `FKStatusPill`
- 筛选头：`FKChipGroup` supplementary view

### 18.2 导航栏

- `leftBarButtonItem` 内嵌 `.s` 头像
- 不在导航栏放 `FKChipGroup`（筛选放下方独立行）

### 18.3 图片加载

- **`FKAvatar`** 在 **`FKImageView`** 发布后接入；之前文档说明 `UIImage`/URL 占位 API

---

## 19. SwiftUI 桥接策略

| 组件 | 桥接 |
|------|------|
| FKTag、FKStatusPill、FKPresenceIndicator | 可选原生 SwiftUI |
| FKChip、FKAvatar | Representable |
| FKChipGroup | Representable + `Binding<Set<String>>` |
| FKMarqueeLabel | Representable |

简单布局参考 **`FKDividerView`** 双栈做法。

---

## 20. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

本家族**统一**放在 `Sources/FKUIKit/Components/Widgets/`（应用内 UI 小组件，**非** WidgetKit 扩展）。各类型以**子目录**划分，共享能力放在 `Widgets/Core/`。

```text
Sources/FKUIKit/Components/Widgets/
├── README.md                         # 小组件库总 catalog + 共享约定
├── Core/
│   ├── Public/
│   │   └── FKWidgetIcon.swift        # Chip/Tag 等共用的图标描述（如需要）
│   └── Internal/
│       ├── FKCapsuleLayoutEngine.swift
│       ├── FKFlowLayoutView.swift
│       └── FKWidgetLayoutMetrics.swift
├── Avatar/
│   ├── Public/                       # FKAvatar, FKAvatarGroup, FKAvatarConfiguration
│   └── Internal/
├── Chip/
│   ├── Public/                       # FKChip, FKTag, FKChipGroup
│   └── Internal/
├── StatusPill/
│   ├── Public/
│   └── Internal/
├── PresenceIndicator/
│   ├── Public/
│   └── Internal/
├── IconView/
│   ├── Public/
│   └── Internal/
├── CopyChip/
│   ├── Public/
│   └── Internal/
└── Marquee/
    ├── Public/                       # FKMarqueeLabel
    └── Internal/
```

**命名说明：** 目录名 **`Widgets`** 表示可复用的轻量 UI 原子，与 FKKit 其他 `Components/<Name>/` 模块并列；不在 `Components/` 根下再拆多个顶级文件夹（如单独的 `Avatar/`、`Chip/`）。

---

## 21. FKKitExamples 场景

路径：`Examples/.../FKUIKit/Widgets/`

| # | 场景 | 组件 |
|---|------|------|
| 1 | `FilterChipBar` | ChipGroup 单/多选 |
| 2 | `RemovableInputChips` | Chip input 模式 |
| 3 | `ProductTags` | Tag 变体 |
| 4 | `OrderStatusPills` | StatusPill |
| 5 | `ProfileAvatar` | Avatar + Presence + Badge |
| 6 | `AvatarGroupRow` | AvatarGroup +N |
| 7 | `CopyOrderID` | CopyChip + Toast |
| 8 | `ListRowComposition` | 组合行 |
| 9 | `DarkModeRTL` | 全套 |
| 10 | `DynamicType` | AX5 |
| 11 | `SwiftUIRepresentables` | Binding |
| 12 | `MarqueeAnnouncement` | Marquee |

---

## 23. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | Tag 与 Chip 同目录？ | 是，均在 `Widgets/Chip/`，共享 Core |
| Q2 | v1 Tag 可点？ | 否 |
| Q3 | 尚无 ImageView 时 Avatar？ | UIImage 占位；FKImageView 发布后完整集成 |
| Q4 | StatusPill 与 Tag 合并？ | 保持独立类型 |
| Q5 | 全部做 SwiftUI 双栈？ | 先做 Tag/Divider 级简单件 |

---

## 24. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 小组件库 umbrella 设计初版 |
| 2026-06-10 | 拆分为模块级设计文档；Chip/Avatar 各合并为三类型一份 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md)
- [FKImageLoader-FKImageView_DESIGN.zh-CN.md](FKImageLoader-FKImageView_DESIGN.zh-CN.md)
- §6.1 各模块设计文档

---

## 附录：仓库归属（FKUIKit vs FKBusinessKit）

**规范结论：本家族全部落在 `Sources/FKUIKit/Components/Widgets/`，不放入 FKBusinessKit。**

| 判据 | FKUIKit | FKBusinessKit |
|------|---------|---------------|
| 职责 | 可复用 **UI 原子/控件**，无特定业务域 | **复合业务场景**（VC 基类、锚点筛选条等） |
| 依赖方向 | FKUIKit → FKCoreKit | FKBusinessKit → FKKit（re-export） |
| 开源定位 | 全球 iOS 开发者通用组件库 | 基于 FKKit 的业务层扩展仓库 |
| 先例 | `Badge`、`Divider`、`Button` | `Base` VC、`TabBarFilter` |
| 本家族 | Chip/Avatar/Tag 等 **任意 App 可用** | 不适用 |

FKBusinessKit 可在业务层 **组合** FKUIKit Widgets（例如 `FKBaseViewController` 列表行内嵌 `FKAvatar` + `FKTag`；`TabBarFilter` 面板旁用 `FKChipGroup`），但 **不应**把 `FKAvatar`/`FKChip` 源码迁入 BusinessKit — 否则破坏依赖层次、重复维护，且与 COMPONENT_ROADMAP 中 Tier 2 条目归属不一致。

**组合用法详细设计片段：**

- FKBusinessKit 仓库：[FKWidgets-Integration_DESIGN.zh-CN.md](https://github.com/feng-zhang0712/FKBusinessKit/blob/main/docs/FKWidgets-Integration_DESIGN.zh-CN.md)
- FKKit 索引：[FKBusinessKit-Widgets-Integration_DESIGN.zh-CN.md](FKBusinessKit-Widgets-Integration_DESIGN.zh-CN.md)
