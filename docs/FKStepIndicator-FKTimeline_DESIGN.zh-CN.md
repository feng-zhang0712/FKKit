# FKStepIndicator / FKTimeline — 设计需求文档

FKKit **流程可视化控件**的实现指导文档：**`FKStepIndicator`**（横向步骤进度）与 **`FKTimeline`**（纵向事件时间线）。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.7  
**English version:** [FKStepIndicator-FKTimeline_DESIGN.md](FKStepIndicator-FKTimeline_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 共享设计语言](#4-共享设计语言)
- [5. 共享数据模型](#5-共享数据模型)
- [6. FKStepIndicator](#6-fkstepindicator)
- [7. FKTimeline](#7-fktimeline)
- [8. 节点渲染与图标](#8-节点渲染与图标)
- [9. 连接线与进度轨](#9-连接线与进度轨)
- [10. 布局模式与密度](#10-布局模式与密度)
- [11. 交互与导航](#11-交互与导航)
- [12. 配置模型](#12-配置模型)
- [13. 动效与触觉](#13-动效与触觉)
- [14. 无障碍](#14-无障碍)
- [15. RTL 与动态字号](#15-rtl-与动态字号)
- [16. SwiftUI 桥接](#16-swiftui-桥接)
- [17. 组件边界](#17-组件边界)
- [18. 建议源码目录结构](#18-建议源码目录结构)
- [19. FKKitExamples 场景](#19-fkkitexamples-场景)
- [21. 待决问题](#21-待决问题)
- [22. 修订历史](#22-修订历史)

---

## 1. 概述

结账向导、新手引导、KYC 流程、物流跟踪与审计历史都需要**多步骤可视化进度**。团队反复用 `UIStackView` + `CAShapeLayer` 拼时间线，导致状态、图标、连接线、无障碍不一致。

FKKit 已有 **`FKProgressBar`**（标量 0…1）与 **`FKTabBar`**（导航头）— **尚无**专用步骤条或时间线控件。

| 控件 | 方向 | 主要场景 |
|------|------|----------|
| **`FKStepIndicator`** | 横向 | 结账步骤、引导向导头、表单分段进度 |
| **`FKTimeline`** | 纵向 | 物流跟踪、订单历史、审计轨迹、活动流 |

建议路径：`Sources/FKUIKit/Components/FlowVisualization/`（或 `StepIndicator/` + `Timeline/` 共享 `FlowVisualization/Core/`）。

二者共享 **`FKFlowStepItem`**、**`FKFlowStepState`**、节点外观令牌与连接线样式 — 对齐 **`FKButton`**、**`FKRatingControl`**、**`FKProgressBar`** 的分层配置约定。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **完备状态模型** — 已完成、当前、待完成、错误、跳过、禁用；支持逐步覆盖。
2. **自定义图标** — SF Symbols、模板图、可选数字序号、完成态对勾。
3. **丰富文案** — 标题、副标题、可选说明/时间戳；紧凑与展开密度。
4. **连接线** — 实线/虚线轨道；按进度填充段间连接。
5. **可选交互** — 点击步骤回退向导（由宿主策略控制）；默认只读。
6. **HIG 基线** — 可交互时 44pt 点击区域、Dynamic Type、VoiceOver、深色模式、RTL、减少动态效果。
7. **分层 `Sendable` 配置** — `layout`、`appearance`、`interaction`、`motion`、`accessibility`。
8. **SwiftUI** — `UIViewRepresentable` 与 Binding 友好 API。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 完整向导 / 分页控制器编排 | 宿主拥有 VC 翻页；指示器负责展示 + 可选点击 |
| 分支 DAG 流程 | v1 仅线性序列；分叉由宿主逻辑处理 |
| Lottie / SVG 路径动画 | UIKit 图层 + 可选 `UIViewPropertyAnimator` |
| macOS / tvOS | 仅 iOS 15+ UIKit |
| 无限滚动社交流 | 时间线为有限条目列表 |
| 甘特图 / 日历排程 UI | 不在范围 |
| 无高度提示的 UITableView 自适配 | 提供 `systemLayoutSizeFitting` 与固有高度辅助 |

### 2.3 成功标准

- [ ] 横向 4 步结账：已完成/当前/待完成显示正确。
- [ ] 纵向物流时间线：时间戳 + 配送失败错误态。
- [ ] Examples 演示每步自定义 SF Symbol。
- [ ] VoiceOver 播报位置（「第 2 步，共 4 步：支付，当前」）。
- [ ] RTL 横向顺序镜像；纵向轨道可按配置贴 trailing。
- [ ] README 含与 `FKProgressBar` / `FKTabBar` 的选型说明。

---

## 3. 背景与问题陈述

### 3.1 缺口分析

| 需求 | FKKit 现状 | 缺口 |
|------|------------|------|
| 结账「购物车 → 地址 → 支付 → 完成」 | — | 无步骤条 |
| 物流状态列表 | 普通 `FKListKit` 单元格 | 无轨道 + 节点语义 |
| 下载百分比 | `FKProgressBar` | 不适合命名步骤 |
| 顶部分类 Tab | `FKTabBar` 分段 | 导航语义，非完成态 |

### 3.2 重复痛点

| 痛点 | 影响 |
|------|------|
| 标题换行后连接线错位 | 视觉不专业 |
| 无统一 `StepState` | 全 App 颜色/图标不一致 |
| 向导中误点未来步骤 | 无策略时错误导航 |
| 时间线无位置无障碍 | 审核风险 |
| 单页写死 4 步 | 无法复用组件 |

---

## 4. 共享设计语言

| 层级 | 职责 |
|------|------|
| **Models** | `Sendable` 步骤项、状态、图标描述 |
| **Configuration** | 嵌套：`layout`、`appearance`、`interaction`、`motion`、`accessibility` |
| **Control** | `@MainActor` `UIView`（只读）或 `UIControl`（可交互） |
| **Internal** | 布局引擎、节点视图、连接线图层 |
| **Bridge** | SwiftUI Representable |

复用：

- **`FKLayerBorderStyle`**、**`FKLayerShadowStyle`**（`FKUIKit/Core/Appearance/`）
- 动态色解析（同 `FKProgressBar`）
- 支持 Dynamic Type 的文本样式

---

## 5. 共享数据模型

### 5.1 步骤状态

```swift
/// 线性流程中单个步骤/节点的语义状态。
public enum FKFlowStepState: Sendable, Equatable {
  case completed
  case current
  case upcoming
  case error
  case skipped
  case disabled
}
```

| 状态 | 视觉语义 |
|------|----------|
| `.completed` | 实心节点、对勾或自定义完成图标；至下一步的连接线填充 |
| `.current` | 强调节点（描边/脉冲）、标题加粗 |
| `.upcoming` | 弱化节点与连接线 |
| `.error` | 破坏性配色、错误图标 |
| `.skipped` | 弱化或删除线标题；连接线仍前进 |
| `.disabled` | 不可交互、降低不透明度 |

### 5.2 步骤项

```swift
/// FKStepIndicator 或 FKTimeline 中的一个节点。
public struct FKFlowStepItem: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var subtitle: String?
  public var caption: String?            // 第三行（时间线正文）
  public var timestamp: Date?           // 时间线主用
  public var formattedTimestamp: String? // 预格式化（时区由宿主控制）
  public var state: FKFlowStepState
  public var icon: FKFlowStepIcon?
  public var accessibilityHint: String?
  public var isInteractive: Bool?       // nil → 控件默认
}
```

### 5.3 图标描述

```swift
public enum FKFlowStepIcon: Sendable, Equatable {
  case number(Int)                       // 圆圈内 1-based 序号
  case systemName(String)
  case imageAsset(name: String, bundle: Bundle?)
  case template(UIImage)                 // 主线程构建；优先 asset 名
  case none                              // 圆点节点
}
```

**规范：** 优先 `systemName` / `imageAsset` 保持 `Sendable` 纯净。

### 5.4 当前索引推导

```swift
public enum FKFlowProgressResolver {
  /// 返回 `.current` 下标，或首个 `.upcoming`，或最后 `.completed`。
  public static func activeIndex(in items: [FKFlowStepItem]) -> Int?
}
```

宿主可逐步设置 `state`，或使用控件的 `currentStepIndex` 自动推导（§6.4）。

---

## 6. FKStepIndicator

### 6.1 职责

**横向**线性步骤头，用于向导与结账。节点排成一行，段间有连接线。

```text
  (1)──────(2)──────(3)──────(4)
 购物车   地址     支付     完成
```

### 6.2 公开类型

```swift
@MainActor
public final class FKStepIndicator: UIControl {
  public static var defaultConfiguration: FKStepIndicatorConfiguration { get set }

  public var configuration: FKStepIndicatorConfiguration
  public var items: [FKFlowStepItem]

  /// 设置后按索引覆盖各 item 的 state（0 = 第一步）。
  public var currentStepIndex: Int?

  public weak var delegate: FKStepIndicatorDelegate?
  public var onStepSelected: ((Int, FKFlowStepItem) -> Void)?

  public func setCurrentStep(_ index: Int, animated: Bool)
  public func setItems(_ items: [FKFlowStepItem], animated: Bool)
}
```

**默认：** 只读（`isUserInteractionEnabled = false`），除非 `configuration.interaction.allowsSelection == true`。

### 6.3 布局变体

| `FKStepIndicatorLayout` | 说明 |
|-------------------------|------|
| `.horizontalTopLabels` | 轨道在上，标题在节点下方（**默认**） |
| `.horizontalBottomLabels` | 标题在节点上方 |
| `.horizontalInline` | 标题在节点旁（仅 2–3 步） |
| `.compactDots` | 小节点、短标题、可横向滚动 |

### 6.4 状态赋值模式

| 模式 | 行为 |
|------|------|
| **显式** | 宿主为每个 `FKFlowStepItem` 设置 `state` |
| **索引驱动** | 宿主设置 `currentStepIndex`；控件推导 completed/upcoming |

二者并存时，**该索引上显式 `state` 优先**（README 说明）。

### 6.5 横向连接线

- 节点 *i* 与 *i+1* 之间：
  - 步骤 *i* 为 `.completed`（或配置视 `.skipped` 为完成）→ **填充**
  - *i* 为 `.current` 或 `.upcoming` → **弱化**
  - 步骤 *i+1* 为 `.error` 时可选用错误条纹

### 6.6 横向滚动

当 `items.count > maxVisibleSteps` 或宽度超出边界：

- 内部 `UIScrollView`
- `scrollToStep(_:animated:)` 使当前步可见
- 可选首尾渐变遮罩（appearance 配置）

### 6.7 步骤数量

- **最少：** 2 步（1 步时隐藏连接线）
- **最多：** 无硬上限；20 步内滚动性能达标

### 6.8 固有尺寸

实现 `intrinsicContentSize` 与 `sizeThatFits`，便于嵌入 `UIStackView` 与导航栏。

---

## 7. FKTimeline

### 7.1 职责

**纵向**事件列表：轨道 + 节点 + 多行内容。

```text
  ●  已发货
  │  3月8日 10:00
  │  仓库已出库
  │
  ○  运输中          ← 当前
  │  预计 3月10日
  │
  ○  已签收
```

### 7.2 公开类型

```swift
@MainActor
public final class FKTimeline: UIView {
  public static var defaultConfiguration: FKTimelineConfiguration { get set }

  public var configuration: FKTimelineConfiguration
  public var items: [FKFlowStepItem]

  public weak var delegate: FKTimelineDelegate?
  public var onItemSelected: ((Int, FKFlowStepItem) -> Void)?

  public func setItems(_ items: [FKFlowStepItem], animated: Bool)
  public func scrollToStep(id: String, animated: Bool)
}
```

默认可读 **`UIView`**；`allowsSelection` 时启用点击与高亮。

### 7.3 布局变体

| `FKTimelineLayout` | 说明 |
|--------------------|------|
| `.verticalLeadingRail` | LTR 下轨道在 leading（**默认**） |
| `.verticalTrailingRail` | 轨道镜像 |
| `.verticalAlternating` | 奇偶行分列轨道两侧（可选 v1.1） |
| `.embeddedInList` | 减小内边距，适配 `FKListKit` / `UITableView` |

### 7.4 时间戳展示

| 模式 | 来源 |
|------|------|
| `.relative` | `RelativeDateTimeFormatter` + `FKI18n` locale |
| `.absolute` | 短日期 + 时间 |
| `.custom` | item 的 `formattedTimestamp` |
| `.hidden` | 不显示时间行 |

### 7.5 分组标题（可选）

```swift
public struct FKTimelineSection: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var items: [FKFlowStepItem]
}
```

`sections` 非空时替代扁平 `items` — 按日分组的审计/物流。

### 7.6 末项尾线

| `FKTimelineTailStyle` | 行为 |
|-----------------------|------|
| `.none` | 最后一节点下无连接线 |
| `.dotted` | 淡出尾线（运输进行中） |
| `.toFuture` | 虚线指向占位「下一事件」 |

### 7.7 可展开详情（v1 可选）

`allowsExpansion == true` 时：

- 点击切换 `caption` 展开动画
- 有 `caption` 的行显示 chevron

---

## 8. 节点渲染与图标

### 8.1 节点形状

| `FKFlowNodeShape` | 场景 |
|-------------------|------|
| `.circle` | 默认 |
| `.roundedSquare` | 审计日志 |
| `.pin` | 地图式跟踪 |

### 8.2 状态 → 默认图标

| 状态 | `icon == nil` 时默认 |
|------|----------------------|
| `.completed` | 对勾 SF Symbol |
| `.current` | 数字或实心点 |
| `.upcoming` | 空心圆 |
| `.error` | `xmark` / `exclamationmark` |
| `.skipped` | `forward.fill` 或短横线 |
| `.disabled` | 弱化空心 |

均可被 `FKFlowStepIcon` 覆盖。

### 8.3 节点尺寸

`FKFlowNodeSize`：`.small`（20pt）、`.medium`（28pt，默认）、`.large`（36pt）。可交互时触摸区扩展到 44pt。

### 8.4 分状态外观

```swift
public struct FKFlowNodeAppearance: Sendable, Equatable {
  public var fillColor: UIColor
  public var border: FKLayerBorderStyle
  public var iconTint: UIColor
  public var shadow: FKLayerShadowStyle?
}
```

`FKFlowAppearanceConfiguration` 将 `FKFlowStepState` 映射到 `FKFlowNodeAppearance`（动态色）。

---

## 9. 连接线与进度轨

### 9.1 连接线样式

```swift
public struct FKFlowConnectorStyle: Sendable, Equatable {
  public var thickness: CGFloat
  public var completedColor: UIColor
  public var upcomingColor: UIColor
  public var dashPattern: [CGFloat]?    // nil = 实线
  public var capStyle: CAShapeLayerLineCap
}
```

### 9.2 段内部分进度（进阶）

`showsPartialConnectorFill == true` 时：

- 在 `.current` 与下一 `.upcoming` 之间，若宿主设置 `currentStepProgress: CGFloat`（0…1），可绘渐变或半填充 — **仅 `FKStepIndicator`**，用于单页内子进度（如上传）。

### 9.3 轨道对齐

布局引擎在 Dynamic Type 变化时保持连接线与节点锚点对齐。

---

## 10. 布局模式与密度

### 10.1 密度

| `FKFlowDensity` | 效果 |
|-----------------|------|
| `.regular` | 完整标题、默认间距 |
| `.compact` | 单行标题、更密轨道 |
| `.spacious` | 更大纵向间距（时间线） |

### 10.2 行数限制

- `titleNumberOfLines` / `subtitleNumberOfLines`（默认 2 / 2）
- 尾部截断；完整文本进 accessibilityLabel

### 10.3 尺寸约束

- `FKStepIndicator` 在导航栏：宿主约束高度（约 56–80pt）
- `FKTimeline`：宽度跟随父视图；`scrollable == true` 时内部滚动，否则高度随内容增长

---

## 11. 交互与导航

### 11.1 选择策略

```swift
public struct FKFlowInteractionConfiguration: Sendable, Equatable {
  public var allowsSelection: Bool
  public var selectableStates: Set<FKFlowStepState>  // 默认仅 [.completed]
  public var allowsExpansion: Bool                   // 时间线 caption
  public var hapticOnSelect: Bool
}
```

**默认建议：**

- 向导：仅 `.completed` 可点回退
- 结账：只读
- 物流时间线：可选点击复制单号

### 11.2 Delegate

```swift
@MainActor
public protocol FKStepIndicatorDelegate: AnyObject {
  func stepIndicator(_ indicator: FKStepIndicator, shouldSelectStepAt index: Int) -> Bool
  func stepIndicator(_ indicator: FKStepIndicator, didSelectStepAt index: Int)
}
```

`shouldSelect` 返回 `false` 阻止导航。

### 11.3 UIControl 事件

可交互的 `FKStepIndicator` 通过 **delegate + 闭包** 通知选中（README 指定主路径）。

### 11.4 加载态

`isLoading == true`：

- 当前步节点上不确定进度指示（复用 `FKProgressBar` 动效模式）
- 禁用选择

---

## 12. 配置模型

### 12.1 FKStepIndicatorConfiguration

```swift
public struct FKStepIndicatorConfiguration: Sendable, Equatable {
  public var layout: FKStepIndicatorLayoutConfiguration
  public var appearance: FKFlowAppearanceConfiguration
  public var interaction: FKFlowInteractionConfiguration
  public var motion: FKFlowMotionConfiguration
  public var accessibility: FKFlowAccessibilityConfiguration
}
```

### 12.2 FKTimelineConfiguration

结构相同；时间线专有字段在 `FKTimelineLayoutConfiguration`（时间戳样式、尾线、分组标题字体）。

### 12.3 预设

```swift
public enum FKStepIndicatorPresets {
  public static func checkout() -> FKStepIndicatorConfiguration
  public static func onboarding() -> FKStepIndicatorConfiguration
}

public enum FKTimelinePresets {
  public static func logistics() -> FKTimelineConfiguration
  public static func auditLog() -> FKTimelineConfiguration
}
```

| 预设 | 特征 |
|------|------|
| `checkout` | 只读、3–5 步、标题在下、对勾完成 |
| `onboarding` | 已完成步可点、紧凑圆点 |
| `logistics` | 纵向、时间戳、强调当前 |
| `auditLog` | 等宽友好 caption、不可选 |

### 12.4 全局默认

```swift
public enum FKStepIndicatorDefaults {
  public static var configuration: FKStepIndicatorConfiguration
}
public enum FKTimelineDefaults {
  public static var configuration: FKTimelineConfiguration
}
```

---

## 13. 动效与触觉

### 13.1 动画

| 触发 | 动画 |
|------|------|
| `currentStepIndex` 变化 | 连接线填充滑动；节点缩放强调 |
| 状态 → `.completed` | 对勾交叉淡入 |
| 时间线插入项 | 淡入 + 滑动（`animated: true`） |

### 13.2 减少动态效果

`UIAccessibility.isReduceMotionEnabled` 时：

- 关闭当前节点脉冲
- 状态切换无动画

### 13.3 触觉

`hapticOnSelect == true` 时使用 `UIImpactFeedbackGenerator`。

---

## 14. 无障碍

### 14.1 步骤条

每节点为独立元素，或容器组合朗读：

> 「第 2 步，共 4 步，支付，当前步骤」

连接线对 VoiceOver 隐藏或标记为不可用。

### 14.2 时间线

每行示例：

> 「已发货，3月8日上午10点，仓库已出库，已完成」

### 14.3 提示

交互步骤使用 item 或配置模板的 `accessibilityHint`。

### 14.4 可调 rotor

只读控件非 adjustable；若步骤不可选，向导应提供独立 VoiceOver 导航按钮（README 说明）。

---

## 15. RTL 与动态字号

### 15.1 RTL

- `FKStepIndicator`：视觉顺序反转，连接线跟随
- `FKTimeline`：`.verticalLeadingRail` 在 RTL 下默认贴 trailing，除非 `respectInterfaceLayoutDirection == false`

### 15.2 Dynamic Type

- 标题使用 `UIFont.TextStyle` 或可配置样式
- `scalesNodeWithContentSize == true` 时在 AX5 略放大节点
- 监听 `traitCollectionDidChange` 与字号变更通知后重新布局

---

## 16. SwiftUI 桥接

```swift
public struct FKStepIndicatorRepresentable: UIViewRepresentable {
  public var items: [FKFlowStepItem]
  public var currentStepIndex: Int?
  public var configuration: FKStepIndicatorConfiguration
  public var onStepSelected: ((Int) -> Void)?
}

public struct FKTimelineRepresentable: UIViewRepresentable {
  public var items: [FKFlowStepItem]
  public var sections: [FKTimelineSection]?
  public var configuration: FKTimelineConfiguration
}
```

`items` / `currentStepIndex` 变化时更新视图，避免不必要重复动画。

---

## 17. 组件边界

| 场景 | 组件 |
|------|------|
| 具名步骤与完成态 | **FKStepIndicator** / **FKTimeline** |
| 单一标量进度 | **FKProgressBar** |
| 无完成语义的 Tab 导航 | **FKTabBar** |
| 纯字符串列表 | **FKListKit** |
| 日期选择 | **FKDatePicker**（路线图） |

---

## 18. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

```text
Sources/FKUIKit/Components/FlowVisualization/
├── README.md
├── Core/
│   ├── Public/
│   │   ├── FKFlowStepItem.swift
│   │   ├── FKFlowStepState.swift
│   │   ├── FKFlowStepIcon.swift
│   │   ├── FKFlowConnectorStyle.swift
│   │   ├── FKFlowNodeAppearance.swift
│   │   └── Configuration/...
│   └── Internal/
│       ├── FKFlowNodeView.swift
│       ├── FKFlowConnectorLayer.swift
│       └── FKFlowLayoutMetrics.swift
├── StepIndicator/
│   ├── Public/
│   │   ├── FKStepIndicator.swift
│   │   ├── FKStepIndicatorDelegate.swift
│   │   ├── FKStepIndicatorConfiguration.swift
│   │   └── Bridge/FKStepIndicatorRepresentable.swift
│   └── Internal/...
└── Timeline/
    ├── Public/
    │   ├── FKTimeline.swift
    │   ├── FKTimelineSection.swift
    │   └── Bridge/FKTimelineRepresentable.swift
    └── Internal/...
```

---

## 19. FKKitExamples 场景

路径：`Examples/.../FKUIKit/FlowVisualization/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `CheckoutSteps` | 4 步横向只读、索引驱动 |
| 2 | `OnboardingWizard` | 已完成步可点回退 |
| 3 | `CustomIcons` | 每步 SF Symbol |
| 4 | `ErrorStep` | 支付失败样式 |
| 5 | `CompactScrollable` | 8+ 步横向滚动 |
| 6 | `LogisticsTimeline` | 纵向时间戳、运输中 |
| 7 | `AuditLog` | 按日分组 + caption |
| 8 | `SkippedStep` | KYC 跳过 |
| 9 | `DarkModeRTL` | 外观与布局方向 |
| 10 | `SwiftUIBinding` | Representable + 当前索引 |
| 11 | `DynamicType` | AX5 布局 |
| 12 | `ReduceMotion` | 无脉冲 |

---

## 21. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 单目录还是 StepIndicator + Timeline？ | 共享 `FlowVisualization/Core/` |
| Q2 | `FKStepIndicator` 继承 `UIControl` 还是 `UIView`？ | 可交互时用 `UIControl` |
| Q3 | v1 是否做交替时间线？ | 推迟 v1.1 |
| Q4 | 图标枚举是否含 `UIImage`？ | Sendable 模型仅用 asset 名 |
| Q5 | v1 是否做连接线部分填充？ | 指示器可选 `currentStepProgress` |

---

## 22. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §2.7 |

---

## 相关文档

- [FKStepIndicator-FKTimeline_DESIGN.md](FKStepIndicator-FKTimeline_DESIGN.md) — 英文版
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
- [FKFormControls_DESIGN.zh-CN.md](FKFormControls_DESIGN.zh-CN.md)
