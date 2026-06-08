# FKSmallComponents — 设计需求文档

FKKit **小型 UI 组件**（小组件库）的实现指导文档：轻量、单一职责的视图与控件，高频出现在列表、导航、筛选与资料区 —  scope 小于 **`FKEmptyState`**、**`FKActionSheet`**、**`FKListKit`**，但需要在 FK 视觉与行为上保持一致。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.2–2.3、Tier 3 `FKMarquee`  
**English version:** [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 何为小组件](#3-何为小组件)
- [4. 共享设计语言](#4-共享设计语言)
- [5. 尺寸、密度与点击区域](#5-尺寸密度与点击区域)
- [6. 组件目录](#6-组件目录)
- [7. FKAvatar](#7-fkavatar)
- [8. FKAvatarGroup](#8-fkavatargroup)
- [9. FKChip](#9-fkchip)
- [10. FKTag](#10-fktag)
- [11. FKChipGroup](#11-fkchipgroup)
- [12. FKStatusPill](#12-fkstatuspill)
- [13. FKPresenceIndicator](#13-fkpresenceindicator)
- [14. FKIconView](#14-fkiconview)
- [15. FKCopyChip](#15-fkcopychip)
- [16. FKMarqueeLabel](#16-fkmarqueelabel)
- [17. 已有小组件（参考）](#17-已有小组件参考)
- [18. 组合与集成模式](#18-组合与集成模式)
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
5. **复用 FKKit** — `FKButton`、`FKBadge`、`FKImageView`（发布后）、`FKLayerBorderStyle`、`FKUIKitI18n`。
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

### 6.1 选型决策树

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

## 7. FKAvatar

**路径：** `Sources/FKUIKit/Components/Widgets/Avatar/`  
### 7.1 职责

圆形或圆角矩形头像：远端/本地图、首字母兜底、加载/失败、可选点击。

### 7.2 形状

`FKAvatarShape`：`.circle`、`.squircle(cornerRadius:)`、`.roundedRectangle(cornerRadius:)`。

### 7.3 内容模式

| 模式 | 来源 |
|------|------|
| **Image** | `UIImage`、URL（`FKImageView`）、Asset |
| **Initials** | `displayName` 推导 1–2 字符（含 CJK 规则） |
| **Placeholder** | `person.fill` 等 |
| **Loading** | 圆形 `FKSkeleton` 或 spinner |

### 7.4 公开 API

```swift
@MainActor
public final class FKAvatar: UIControl {
  public var configuration: FKAvatarConfiguration
  public var displayName: String?
  public var imageURL: URL?
  public var image: UIImage?

  public func setImageURL(_ url: URL?, placeholder: UIImage?)
  public func setDisplayName(_ name: String?)
}
```

### 7.5 尺寸预设

`FKAvatarSize`：`.xs(24)` … `.xl(72)`、`.custom(diameter:)`。

### 7.6 描边 / 故事环

- `FKLayerBorderStyle` 可选
- **Story** 预设：渐变环（文档说明性能）

### 7.7 附件

| 附件 | 集成 |
|------|------|
| 在线状态 | **`FKPresenceIndicator`** 右下 |
| 未读数 | **`FKBadge`** |
| 认证标识 | 配置 `showsVerifiedBadge` |

### 7.8 无障碍

- 标签：「{name} 的头像」或「用户头像」
- 可点击时 trait `.button`

### 7.9 状态

加载中、已加载、失败（可选点击重试）、空首字母。

---

## 8. FKAvatarGroup

### 8.1 职责

「+3 位协作者」式重叠头像。

### 8.2 布局配置

- `maxVisible`（默认 4）
- `overlap` 负间距
- `showsOverflowCount` → 「+N」
- `direction`：叠放 z 序（RTL 镜像）

### 8.3 API

```swift
@MainActor
public final class FKAvatarGroup: UIView {
  public var avatars: [FKAvatarContent]
  public var onOverflowTap: (() -> Void)?
  public var onAvatarTap: ((Int) -> Void)?
}
```

---

## 9. FKChip

**路径：** `Sources/FKUIKit/Components/Widgets/Chip/`  
### 9.1 职责

紧凑**切换/筛选**控件：选中态、前导图标、可选移除。

### 9.2 模式

| `FKChipMode` | 行为 |
|--------------|------|
| `.filter` | 点击切换选中；用于 ChipGroup |
| `.input` | 可移除 token（✕）；无选中填充 |
| `.suggestion` | 点一次触发；不保持选中 |
| `.choice` | 组内互斥 |

### 9.3 公开类型

```swift
@MainActor
public final class FKChip: UIControl {
  public var configuration: FKChipConfiguration
  public var title: String
  public var isSelected: Bool
  public var leadingIcon: FKChipIcon?
  public var showsRemoveButton: Bool
  public var onRemove: (() -> Void)?
}
```

切换选中时发送 `UIControl.Event.valueChanged`。

### 9.4 外观状态

| 状态 | 视觉 |
|------|------|
| Normal | `secondarySystemFill` |
| Selected | `tintColor` 填充或描边+填充 |
| Disabled | 降不透明度 |
| Highlighted | 缩放 0.97 |

### 9.5 移除按钮

- 尾部 ✕；44pt 热区
- `onRemove` 不触发选中切换
- 无障碍：「移除 {title}」

---

## 10. FKTag

### 10.1 职责

**只读**元数据胶囊：分类、促销、「NEW」、角色名。v1 为 `UIView`。

### 10.2 变体

`FKTagVariant`：neutral、brand、success、warning、error、outline、custom。

### 10.3 Chip 与 Tag 对比（规范）

| 维度 | FKChip | FKTag |
|------|--------|-------|
| 交互 | 是 | 否 |
| 选中态 | 有 | 无 |
| 移除 | 可选 | 无 |
| 场景 | 筛选、输入 token | 卡片标签 |

---

## 11. FKChipGroup

### 11.1 职责

**`FKChip`** 的水平/垂直布局与选择策略。

### 11.2 选择模式

```swift
public enum FKChipGroupSelectionMode: Sendable, Equatable {
  case none
  case single
  case multiple(max: Int?)
}
```

### 11.3 布局

- 流式换行（`UICollectionView` 或 `FKFlowLayout`）
- 可横向滚动筛选条（隐藏滚动条）

### 11.4 API

```swift
@MainActor
public final class FKChipGroup: UIView {
  public var chips: [FKChipItem]
  public var selectionMode: FKChipGroupSelectionMode
  public var selectedIDs: Set<String>
  public var onSelectionChange: ((Set<String>) -> Void)?
}
```

---

## 12. FKStatusPill

### 12.1 职责

短**流程状态**文案：「进行中」「待审核」「失败」「已发货」。

### 12.2 与 FKTag 区别

StatusPill 映射**工作流语义色**；Tag 为**分类/营销**标签。

### 12.3 API

```swift
public enum FKStatusPillStyle: Sendable, Equatable {
  case success, warning, error, info, neutral, custom(...)
}

@MainActor
public final class FKStatusPill: UIView {
  public var title: String
  public var style: FKStatusPillStyle
  public var showsDot: Bool
  public var configuration: FKStatusPillConfiguration
}
```

可选可点时展示帮助 `FKCallout`（宿主接线）。

---

## 13. FKPresenceIndicator

### 13.1 职责

8–12pt 状态点：online、offline、busy、away、custom。

### 13.2 放置

- 通过 **`FKAvatar`** 配置附着
- 独立使用时加白边以提高在照片上的对比度

### 13.3 动效

`.online` 可选脉冲（Reduce Motion 关闭时）。

---

## 14. FKIconView

### 14.1 职责

固定尺寸（24/28/32pt）模板图标 + 可选圆形底，供列表行与 Chip 前导图标统一。

```swift
@MainActor
public final class FKIconView: UIView {
  public var symbolName: String?
  public var image: UIImage?
  public var configuration: FKIconViewConfiguration
}
```

支持现有 **`FKBadge`** 扩展附着。

---

## 15. FKCopyChip

### 15.1 职责

等宽或截断 ID + 复制（如「订单 #A1288… 📋」）。

### 15.2 行为

- 点击写入 `UIPasteboard`
- 可选 **`FKToast`** 成功提示
- 轻触觉反馈

```swift
@MainActor
public final class FKCopyChip: UIControl {
  public var text: String
  public var copyText: String?
  public var configuration: FKCopyChipConfiguration
}
```

---

## 16. FKMarqueeLabel

### 16.1 职责

单行公告 ticker；拖拽暂停；**Reduce Motion 时停止滚动**（静态截断 + 无障碍全文）。

```swift
@MainActor
public final class FKMarqueeLabel: UIView {
  public var text: String
  public var configuration: FKMarqueeLabelConfiguration
}
```

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

---

## 相关文档

- [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md) — 英文版
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md)
- [FKImageLoader-FKImageView_DESIGN.zh-CN.md](FKImageLoader-FKImageView_DESIGN.zh-CN.md)
