# FKFormControls — 设计需求文档

FKKit **表单与筛选控件**的实现指导文档：**`FKSegmentedControl`**、**`FKToggle`**、**`FKCheckbox`**、**`FKRadioGroup`**、**`FKSlider`**。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案（分阶段交付 — 见 [§15 分阶段实现与交付计划](#15-分阶段实现与交付计划)）  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.4  

> **给 Cursor / 实施者：** 打开本文后 **先读 §15**，确认当前要实现的 **Phase**；仅实现该 Phase「本阶段交付」范围，**不得**越界做后续 Phase 的控件。每 Phase 结束须通过该 Phase 的 **验收 Gate** + `xcodebuild` BUILD SUCCEEDED。

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 共享设计语言](#5-共享设计语言)
- [6. FKSegmentedControl](#6-fksegmentedcontrol)
- [7. FKToggle](#7-fktoggle)
- [8. FKCheckbox](#8-fkcheckbox)
- [9. FKRadioGroup](#9-fkradiogroup)
- [10. FKSlider](#10-fkslider)
- [11. 控件横向对比](#11-控件横向对比)
- [12. SwiftUI 桥接](#12-swiftui-桥接)
- [13. 全局默认值](#13-全局默认值)
- [14. 建议源码目录结构](#14-建议源码目录结构)
- [15. 分阶段实现与交付计划](#15-分阶段实现与交付计划)
- [16. FKKitExamples 场景](#16-fkkitexamples-场景)
- [17. 下游依赖与迁移契约](#17-下游依赖与迁移契约)
- [18. 设计决策记录](#18-设计决策记录)
- [19. 修订历史](#19-修订历史)

---

## 1. 概述

设置页、筛选面板、引导页与播放器需要**二元、枚举与区间**输入。FKKit 已有 **`FKTextField`** 与 **`FKActionSheet`** 内的 Toggle **行**，但缺少可独立嵌入布局的 **`UIControl` 族**：分段选择、开关、复选框、单选组、滑块。

**FKFormControls**（`Sources/FKUIKit/Components/FormControls/`）交付五个公开控件，配置分层对齐 **`FKButton`**、**`FKRatingControl`**。

| 控件 | 主要场景 |
| ------ | ---------- |
| **FKSegmentedControl** | 2–N 个互斥选项（筛选、视图模式） |
| **FKToggle** | 开/关设置 |
| **FKCheckbox** | 多选、协议勾选、全选 |
| **FKRadioGroup** | 少量选项中必选其一 |
| **FKSlider** | 标量或区间调节（价格、音量） |

均为 **`UIControl`** 子类（或发出 `UIControl` 事件的组合根），`@MainActor`，Phase B 起提供 SwiftUI `Representable`。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **统一 FK 视觉语言** — 非系统默认 `UISwitch` / `UISegmentedControl` / `UISlider` 裸样式。
2. **分层配置** — 各控件含 `layout` / `appearance` / `interaction` / `motion` / `accessibility`；含 `UIColor` 的子配置标 `@unchecked Sendable`（对齐 `FKProgressBar`）。
3. **HIG 基线** — 44pt 触控、Dynamic Type、VoiceOver、深色模式、RTL、减少动态效果。
4. **边界清晰** — 与 ActionSheet Toggle 行、TabBar segmented 预设区分使用场景。
5. **可组合** — 设置 VC、筛选工具栏、`FKListKit` preset 行、SwiftUI 表单。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 完整表单构建/校验编排 | 未来 `FKForm`（路线图 Tier 3） |
| Stepper（+ / −） | 后续独立控件 |
| 滚轮 Picker | `FKDatePicker` 路线图 |
| 取色器 | 不在范围 |
| 抽取 Player 进度条为公共 API | Player 内 `UISlider` 保持私有；`FKSlider` 独立实现 |
| macOS / tvOS | 仅 iOS 15+ UIKit |

### 2.3 成功标准

**全量（Phase B 完成后）：**

- [ ] 五个控件 + Core + Bridge + README + Examples Hub 全覆盖。
- [ ] 禁用/加载态全家一致（§5.5）。
- [ ] §11 选型表写入组件 README。
- [ ] 根 README 索引与 CHANGELOG 发版条目（发版时补齐）。

**分阶段 Gate 以 §15.4–§15.6 为准**（禁止用本节勾选替代 Phase 验收）。

---

## 3. 背景与问题陈述

### 3.1 缺口

| 需求 | 现状 | 缺口 |
|------|------|------|
| 筛选 Tab（价格/评分/新品） | `FKTabBar` segmented **预设** | TabBar 偏**导航/分页**头，不宜作表单内分段控件 |
| 设置开关行 | ActionSheet Toggle **行** | 无法直接嵌入 Table/List |
| 协议多选 | — | 无 Checkbox |
| 支付方式单选 | — | 无 Radio |
| 价格区间 | 仅 Player 内 `UISlider` | 无公开 Slider |
| Search scope 条 | [FKSearchBar 设计](FKSearchBar-FKSearchField_DESIGN.md) 第二阶段 | 依赖 `FKSegmentedControl` |

### 3.2 与 FKTabBar `segmentedControl` 预设

| 维度 | FKTabBar（segmented 预设） | FKSegmentedControl |
|------|---------------------------|-------------------|
| 角色 | Tab 头 / 分页条 | 行内筛选或设置控件 |
| 数据 | `FKTabBarItem` + 角标 | `FKSegment` |
| 分页 | `FKPagingController` | 无 |
| 滚动 | 可选横滚 | 可选；默认可均分不滚动 |

可**私有复用** `FKTabBarIndicatorFrameCalculator` 等指示器数学，**公开 API 不依赖** `FKTabBar`。

### 3.3 与 ActionSheet Toggle 行

- **Sheet 内**开关列表 → ActionSheet Toggle 行（**不强制**替换为 `FKToggle`）  
- **设置页/自定义布局** → **FKToggle**

### 3.4 FKCoreKit 复用要求（强制）

| 能力 | 必须使用（路径） | 禁止 |
|------|------------------|------|
| 数值 clamp / lerp | `Extension/Foundation/Comparable.swift`（`fk_clamped`）、`FloatingPoint.swift` | 自写 clamp |
| 本地化 | `Components/I18n/` **`FKI18n`** | 硬编码按钮/状态文案 |
| 动画 / Reduce Motion | `Extension/UIKit/UIView.swift`、`UIAccessibility.isReduceMotionEnabled` | 忽略 AX |
| 触觉 | 对齐 **`FKButton`** / `FKProgressBar` 模式 | 散落 `UIFeedbackGenerator` |
| 布局 | `Extension/UIKit/UIStackView.swift`、`CGRect` 扩展 | 重复 layout 辅助 |
| 加载指示 | 复用 **`FKButton`** loading 覆盖语义 | 各控件自造 spinner API |

表单控件**不得**复制 **`FKTextField`** 校验逻辑；与文本输入组合时由宿主编排。

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ FKFormControlsDefaults（@MainActor 全局默认）                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ Public/Core/                                                    │
│  FKFormControlSize · LoadingState · Haptic · LabelPlacement     │
└────────────────────────────┬────────────────────────────────────┘
                             │
     ┌───────────┬───────────┼───────────┬───────────┐
     ▼           ▼           ▼           ▼           ▼
 Segment    Toggle     Checkbox    RadioGroup    Slider
 (UIControl) (UIControl) (UIControl) (UIControl)  (UIControl)
     │           │           │           │           │
     └───────────┴───────────┴───────────┴───────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ Public/Bridge/ — FK*Representable（Phase B）                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ 下游：ListKit preset · FKAlert 门控 · SearchBar scope │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 共享设计语言

### 5.1 配置分层（对齐 FKRatingControl）

| 子配置 | 职责 | RatingControl 对照 |
|--------|------|---------------------|
| `layout` | 尺寸、间距、label 位置、宽度模式 | `FKRatingLayoutConfiguration` |
| `appearance` | 颜色、字体、轨道/指示器样式 | `FKRatingAppearanceConfiguration` |
| `interaction` | 拖拽、触觉、重复选择 | `FKRatingInteractionConfiguration` |
| `motion` | 动画时长、Reduce Motion | `FKRatingMotionConfiguration` |
| `accessibility` | 播报、hint、组名 | `FKRatingAccessibilityConfiguration` |

根配置示例：

```swift
public struct FKSegmentedControlConfiguration: @unchecked Sendable {
  public var layout: FKSegmentedControlLayoutConfiguration
  public var appearance: FKSegmentedControlAppearanceConfiguration
  public var interaction: FKSegmentedControlInteractionConfiguration
  public var motion: FKFormControlMotionConfiguration
  public var accessibility: FKFormControlAccessibilityConfiguration
}
```

`FKFormControlMotionConfiguration` / `FKFormControlAccessibilityConfiguration` 在 `Core/` **跨控件共享**。

### 5.2 共享类型（`Public/Core/`）

| 类型 | 用途 |
|------|------|
| `FKFormControlEnabledState` | 正常 / 禁用 |
| `FKFormControlLoadingState` | 空闲 / 加载 |
| `FKFormControlHaptic` | 无 / 轻触 / 选择（默认 **none**） |
| `FKFormControlSize` | `.small` / `.medium` / `.large` |
| `FKFormControlLabelPlacement` | `.leading` / `.trailing` / `.hidden` |
| `FKFormControlMotionConfiguration` | `respectsReduceMotion`、默认动画时长 |
| `FKFormControlAccessibilityConfiguration` | 组名、hint 模板 |

### 5.3 UIControl 事件矩阵

| 控件 | `.valueChanged` | `.touchUpInside` | 结束编辑 |
|------|-----------------|------------------|----------|
| `FKSegmentedControl` | 选中 index/id 变化 | — | — |
| `FKToggle` | `isOn` 变化 | — | — |
| `FKCheckbox` | `state` 变化 | 可选（扩大点击区时） | — |
| `FKRadioGroup` | `selectedOptionID` 变化 | 点选项 | — |
| `FKSlider` | 拖拽中（`isContinuous` 控制） | — | `onEditingDidEnd` 回调 |

文档与 README 说明 `addAction(_:for:)` 与 `onValueChanged` 闭包等价用途。

### 5.4 布局与尺寸契约

- 各控件实现 `intrinsicContentSize`；高度随 `FKFormControlSize` 与 Dynamic Type 缩放。
- **带标题控件**（`FKToggle`、`FKCheckbox` 可选 label）：使用内置 `contentConfiguration` 或子 `UIStackView`，**不**强制单独 `*Row` 包装类型（见 §18 Q8）。
- `FKRadioGroup`：`.vertical` 模式下 `sizeThatFits` 返回选项累加高度；嵌入 Table 时由宿主提供宽度。
- `FKSegmentedControl`：`.fillEqually` 时宽度填满父视图；`.intrinsic` 溢出启用横滚。
- 最小触控目标 **44×44pt**（Slider 拇指视觉可 28pt，hit area 扩展至 44pt）。

### 5.5 动效

- 尊重 `UIAccessibility.isReduceMotionEnabled`
- 减少动态效果时：交叉淡入或瞬时切换（Segment 指示器、Toggle 拇指位移）

### 5.6 禁用与加载

| 状态 | 视觉 | 交互 |
|------|------|------|
| 禁用 | 降透明度（默认约 0.48） | 忽略触摸；不发 `valueChanged` |
| 加载 | 尾部/覆盖 `UIActivityIndicator` 或 `FKButton` 式 overlay | 默认禁止改值 |

---

## 6. FKSegmentedControl

### 6.1 用途

**2–8** 个互斥分段（软上限 8，可配置 `maximumSegmentCount`）。替代 `UISegmentedControl`，用于 FK 风格筛选与模式切换。

### 6.2 公开 API（草案）

```swift
public typealias FKSegmentID = String

public enum FKSegmentIcon: Hashable, Sendable {
  case systemName(String)
  case asset(name: String, bundle: Bundle?)
}

public enum FKSegmentBadge: Hashable, Sendable {
  case dot
  case count(Int)
}

public struct FKSegment: Hashable, Sendable, Identifiable {
  public var id: FKSegmentID
  public var title: String?
  public var icon: FKSegmentIcon?
  public var badge: FKSegmentBadge?
  public var isEnabled: Bool
  public var accessibilityLabel: String?
}

@MainActor
public final class FKSegmentedControl: UIControl {
  public var configuration: FKSegmentedControlConfiguration
  public var segments: [FKSegment] { get set }
  public var selectedIndex: Int { get set }
  public var selectedSegmentID: FKSegmentID? { get set }
  public var onSelectionChanged: (@MainActor (Int, FKSegment) -> Void)?
}
```

### 6.3 配置要点

**Layout：** `widthMode`（`.fillEqually` / `.intrinsic` / `.mixed`）、`height`（32 / 44pt）、`segmentSpacing`、`contentInsets`、`isScrollable`、`maximumSegmentCount`。

**Appearance：** `indicatorStyle`（`.pill` / `.underline` / `.filledSegment` / `.none`）、轨道背景、选中/未选中字色字阶、图标 tint、角标样式、圆角。

**Interaction：** `allowsDragSelection`（默认 false）、`allowsReselect`（默认 false）、`haptic`。

### 6.4 指示器样式

| 样式 | 说明 |
|------|------|
| `.pill` | 选中段后滑动胶囊（参考 TabBar pill） |
| `.underline` | 下划线（粗细、内缩可配） |
| `.filledSegment` | 选中段填充，无滑动 pill |
| `.none` | 仅文字/颜色变化 |

选中变化时**必须**动画移动指示器（默认 0.25s，可配置）；Reduce Motion 时瞬时切换。

### 6.5 预设

```swift
public enum FKSegmentedControlPresets {
  public static func filterStrip() -> FKSegmentedControlConfiguration
  public static func settingsInline() -> FKSegmentedControlConfiguration
}
```

`filterStrip()` 视觉对齐 `FKTabBarPresets.filterStrip()`，**无** API 依赖。

### 6.6 无障碍

- 容器：分段语义；`accessibilityValue` = 当前选中段标题
- 每段：标题 + 角标 + 选中态

### 6.7 边界

- 空 `segments` → 零尺寸隐藏
- 单段 → 显示但选择不变
- 全禁用 → 整控件禁用
- 动态增删段 → 优先按 `FKSegmentID` 保留选中

---

## 7. FKToggle

### 7.1 用途

设置项**开/关** — FK 风格开关，替代裸 `UISwitch`。

### 7.2 公开 API（草案）

```swift
public struct FKToggleContentConfiguration: Sendable, Equatable {
  public var title: String?
  public var subtitle: String?
  public var labelPlacement: FKFormControlLabelPlacement  // 默认 .leading
}

@MainActor
public final class FKToggle: UIControl {
  public var configuration: FKToggleConfiguration
  public var content: FKToggleContentConfiguration
  public var isOn: Bool { get set }
  public var isLoading: Bool { get set }
  public var onValueChanged: (@MainActor (Bool) -> Void)?

  public func setOn(_ isOn: Bool, animated: Bool, sendActions: Bool)
}
```

### 7.3 视觉

| 元素 | 要求 |
|------|------|
| 轨道 | 圆角矩形；on/off 色对齐 `FKButton` 色板（v1）；`FKTheme` 就绪后接 token |
| 拇指 | 圆片；可选阴影；位移动画 |
| 尺寸 | `FKFormControlSize`：small / medium（默认）/ large |
| 加载 | 拇指位菊花或轨道 overlay（对齐 `FKButton` loading） |

### 7.4 交互

- 点轨道/拇指切换（非加载且启用）
- `allowsDragToToggle` 默认 true
- 触觉默认关

### 7.5 预设

`FKTogglePresets.settingsRow()` — 带 leading 标题、medium 尺寸。

---

## 8. FKCheckbox

### 8.1 用途

**复选框**隐喻（非开关）。支持**半选**态（全选父行）。

### 8.2 公开 API（草案）

```swift
public enum FKCheckboxState: Equatable, Sendable {
  case unchecked, checked, indeterminate
}

public struct FKCheckboxContentConfiguration: Sendable, Equatable {
  public var title: String?
  public var subtitle: String?
  public var labelPlacement: FKFormControlLabelPlacement
}

@MainActor
public final class FKCheckbox: UIControl {
  public var configuration: FKCheckboxConfiguration
  public var content: FKCheckboxContentConfiguration
  public var state: FKCheckboxState { get set }
  public var showsError: Bool { get set }
  public var onStateChanged: (@MainActor (FKCheckboxState) -> Void)?
}
```

### 8.3 视觉

| 状态 | 图形 |
|------|------|
| 未选 | 空方框圆角边框 |
| 已选 | 填充 + 勾 |
| 半选 | 填充 + 减号/横杠 |
| 错误 | 边框 destructive 色（`showsError`） |

### 8.4 交互

- 点击：未选↔已选；半选→已选（`indeterminateTapBehavior`，默认 `.promoteToChecked`）
- `indeterminateEnabled` 控制是否使用半选
- 关联 label 扩大点击区（整行点击切换）

### 8.5 无障碍

- `.button` + 选中时 `.selected`
- Value：本地化「已勾选」/「未勾选」/「部分选中」（`FKI18n`）
- 多选列表：宿主用 `UIAccessibilityContainer` 或 Table 行语义；独立控件不强制组容器

---

## 9. FKRadioGroup

### 9.1 用途

**恰好一项**选中（通常 2–6 项）。纵向列表或横向排列。

### 9.2 公开 API（草案）

```swift
public typealias FKRadioOptionID = String

public struct FKRadioOption: Hashable, Sendable, Identifiable {
  public var id: FKRadioOptionID
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool
  public var accessibilityLabel: String?
}

public enum FKRadioGroupLayoutMode: Sendable, Equatable {
  case vertical
  case horizontal
  case compact
}

@MainActor
public final class FKRadioGroup: UIControl {
  public var configuration: FKRadioGroupConfiguration
  public var options: [FKRadioOption] { get set }
  public var selectedOptionID: FKRadioOptionID? { get set }
  public var onSelectionChanged: (@MainActor (FKRadioOptionID) -> Void)?
}
```

### 9.3 布局

| 模式 | 说明 |
|------|------|
| `.vertical` | 选项纵向；指示器 leading；最小行高 44pt |
| `.horizontal` | 横排或横滚 |
| `.compact` | 紧凑横条 + 圆形指示器 |

### 9.4 与 FKSegmentedControl

| 用 Segment | 用 Radio |
|------------|----------|
| 短标签、紧凑筛选 | 带副标题的说明性选项 |
| 图标+角标条 | 表单 2–6 项详述 |

---

## 10. FKSlider

### 10.1 用途

连续或**步进**标量；可选**双拇指区间**（价格筛选）。**独立实现**，不复用 Player 内 `UISlider`。

### 10.2 公开 API（草案）

```swift
public enum FKSliderMode: Sendable, Equatable {
  case single
  case range
}

public struct FKSliderValue: Sendable, Equatable {
  public var single: CGFloat?
  public var lower: CGFloat?
  public var upper: CGFloat?
}

@MainActor
public final class FKSlider: UIControl {
  public var configuration: FKSliderConfiguration
  public var mode: FKSliderMode
  public var value: CGFloat { get set }           // single 模式
  public var lowerValue: CGFloat { get set }     // range 模式
  public var upperValue: CGFloat { get set }
  public var onValueChanged: (@MainActor (FKSliderValue) -> Void)?
  public var onEditingDidEnd: (@MainActor (FKSliderValue) -> Void)?
}
```

**Configuration 数值：** `minimum`、`maximum`、`step`、`snapToStep`、`minimumRange`（区间最小间距）；set 时 `fk_clamped`。

### 10.3 轨道与拇指

| 元素 | 能力 |
|------|------|
| 轨道 | 高度、背景色、圆角 |
| 填充 | 最小值到拇指（或 lower–upper） |
| 拇指 | 直径 ≥28pt，**点击区 44pt** |
| 刻度 | 可选步进 tick |
| 标签 | 最小/最大静态；拖拽浮层可选 |

### 10.4 交互

- `tapToSeek` 默认 true
- 双拇指碰撞与 z-order
- 步进可选触觉（参考 `FKProgressBar` interaction haptics）
- `isContinuous` 控制拖拽中是否持续 `valueChanged`

### 10.5 无障碍

- `.adjustable`
- 步进：增减 accessibility action
- `onEditingDidEnd` 时播报格式化数值

### 10.6 纵向

v1 **仅横向** — 纵向延后。

---

## 11. 控件横向对比

### 11.1 选型表

| 用户任务 | 控件 |
|----------|------|
| 少量短模式互斥 | `FKSegmentedControl` |
| 带说明的单选 | `FKRadioGroup` |
| 开/关 | `FKToggle` |
| 勾选/多选 | `FKCheckbox` |
| 数值/区间 | `FKSlider` |
| Sheet 内开关行 | `FKActionSheet` Toggle 行 |
| Tab 分页头 | `FKTabBar` |

### 11.2 组合示例

筛选栏：`FKSegmentedControl` + `FKSlider` 区间 — 见 §16 `FilterBarComposite`。

---

## 12. SwiftUI 桥接（Phase B）

| UIKit | Representable |
|-------|----------------|
| `FKSegmentedControl` | `FKSegmentedControlRepresentable` |
| `FKToggle` | `FKToggleRepresentable` |
| `FKCheckbox` | `FKCheckboxRepresentable` |
| `FKRadioGroup` | `FKRadioGroupRepresentable` |
| `FKSlider` | `FKSliderRepresentable` |

**模式（对齐 `FKAlertModifier` / `FKRatingControlRepresentable`）：**

- `UIViewRepresentable` + `Coordinator`
- `Binding` 同步主值；`Coordinator.isUpdating` 在 `updateUIView` 中 **suppress 环路**
- `configuration` 由宿主传入；默认值来自 `FKFormControlsDefaults`
- `FKSlider`：`isContinuous == false` 时仅在结束拖拽更新 Binding

---

## 13. 全局默认值

```swift
@MainActor
public enum FKFormControlsDefaults {
  public static var segmentedControl: FKSegmentedControlConfiguration
  public static var toggle: FKToggleConfiguration
  public static var checkbox: FKCheckboxConfiguration
  public static var radioGroup: FKRadioGroupConfiguration
  public static var slider: FKSliderConfiguration
}

@MainActor
public enum FKFormControls {
  public static var defaultSegmentedControlConfiguration: FKSegmentedControlConfiguration { get set }
  // … 各控件 mirror FKRating 命名
}
```

App 启动时可统一品牌表单样式。`Package.swift` `exclude:` 含 `Components/FormControls`（README 不参与 Swift 编译）。

---

## 14. 建议源码目录结构

> **目录结构说明（非强制）：** 须保持可发现性，在组件 `README.md` 中文档化。详见 [COMPONENT_ROADMAP — 组件源码目录规范](COMPONENT_ROADMAP.md#组件源码目录规范)。

```text
Sources/FKUIKit/Components/FormControls/
├── README.md
├── Public/
│   ├── Core/
│   │   ├── FKFormControlSharedTypes.swift
│   │   ├── FKFormControlMotionConfiguration.swift
│   │   └── FKFormControlsDefaults.swift
│   ├── SegmentedControl/
│   │   ├── FKSegmentedControl.swift
│   │   ├── FKSegmentedControlConfiguration.swift
│   │   └── FKSegmentedControlPresets.swift
│   ├── Toggle/
│   ├── Checkbox/
│   ├── RadioGroup/
│   ├── Slider/
│   └── Bridge/
├── Internal/
│   ├── SegmentedControl/   # 指示器、段视图
│   ├── Toggle/
│   └── …
└── Extension/
```

**Phase A** 仅创建 Core + SegmentedControl + Toggle 目录；Phase B 补全其余。

---

## 15. 分阶段实现与交付计划

FKFormControls **禁止**单次 PR 实现五个控件。与 [COMPONENT_ROADMAP 分阶段 C/D](COMPONENT_ROADMAP.md#分阶段发布计划) 对齐：

```text
Phase 0  Core + 共享配置 + README 骨架
    │
    └──► Phase A  FKSegmentedControl + FKToggle + 基础 Examples
              │
              └──► Phase B  Checkbox + RadioGroup + Slider + Bridge 全家 + Hub 完成
```

### 15.1 分阶段原则

1. **Phase 0 先行** — 共享 `Core/` 类型与 `FKFormControlsDefaults` 一次定稿，后续 Phase **扩展**不推翻。
2. **Examples 跟 Phase 走** — 无 Demo 不算交付完成。
3. **编译 Gate** — 每 Phase 结束 `xcodebuild` BUILD SUCCEEDED（`SWIFT_STRICT_CONCURRENCY=complete`）。
4. **不越界** — 各 Phase「本阶段不做」列表对 Agent 具约束力。
5. **下游迁移后置** — ListKit / Alert 替换 `UISwitch` 在 **Phase B 之后** 独立 PR（§17）。

### 15.2 阶段总览

| Phase | 名称 | 核心产出 | 路线图 |
|-------|------|----------|--------|
| **0** | 基础设施 | `Core/`、`Defaults`、README、目录骨架 | — |
| **A** | 基础控件 | `FKSegmentedControl`、`FKToggle`、Presets、6 Examples | 分阶段 **C** |
| **B** | 完整族 | Checkbox、Radio、Slider、Bridge、Hub 完成 | 分阶段 **D** |

---

### 15.3 Phase 0 — 基础设施

**本阶段交付：**

| 路径 | 内容 |
|------|------|
| `FormControls/README.md` | 目录表、选型树 §11、Phase 路线图 |
| `Public/Core/` | §5.2 共享类型 + `FKFormControlMotionConfiguration` + `FKFormControlsDefaults`（占位默认） |
| `Package.swift` | `exclude:` FormControls README |

**本阶段不做：** 任何可交互控件 UI、`Bridge/`。

**验收 Gate：**

- [ ] README 英文、含目录表与 Phase checklist
- [ ] `FKFormControlsDefaults` 可编译
- [ ] `xcodebuild` BUILD SUCCEEDED

---

### 15.4 Phase A — Segment + Toggle

**前置：** Phase 0 完成。

**本阶段交付：**

- `FKSegmentedControl` + Configuration + Presets + Internal 指示器
- `FKToggle` + Configuration + Presets + Internal 轨道/拇指
- Examples Hub 骨架 + §16 中 Phase A 场景（#1–#4、#12）

**本阶段不做：** Checkbox、Radio、Slider、SwiftUI Bridge、ListKit 迁移。

**验收 Gate：**

- [ ] Segment：4 种指示器样式、RTL、角标、空/单段边界
- [ ] Toggle：加载/禁用、带标题布局、`setOn(_:animated:sendActions:)`
- [ ] 禁用/加载语义符合 §5.6
- [ ] Examples Phase A 场景可运行
- [ ] `xcodebuild` BUILD SUCCEEDED

**建议 PR：** `feat(form-controls): Phase A — segmented control and toggle`

---

### 15.5 Phase B — Checkbox + Radio + Slider + Bridge

**前置：** Phase A 完成。

**本阶段交付：**

- `FKCheckbox`、`FKRadioGroup`、`FKSlider` 全套 Public/Internal
- `Public/Bridge/` 五个 Representable
- Examples Hub 完成 §16 全部场景
- 组件 README 选型树 §11

**本阶段不做：** ListKit preset 内嵌替换（另开 PR）、`FKTheme` 令牌接线。

**验收 Gate：**

- [ ] Checkbox 半选 + `showsError`；Radio 三布局；Slider 单值+区间+步进
- [ ] SwiftUI Bridge 五控件 Binding 无环路
- [ ] §2.3 全量成功标准（除根 README/CHANGELOG）可满足
- [ ] `xcodebuild` BUILD SUCCEEDED

**建议 PR：** `feat(form-controls): Phase B — checkbox, radio, slider, and SwiftUI bridge`

---

### 15.6 Cursor / Agent 实施指引

1. 用户指定 Phase → 只读 §15 对应小节 + 控件专章（§6–§10）。
2. 实现前 grep `FKCoreKit/Components/Extension/` 复用 clamp/layout。
3. Phase 结束运行 FKKit verify；**不要**提前改 ListKit/Alert 消费方。

---

## 16. FKKitExamples 场景

路径：`Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/FormControls/`  
Hub：`FKFormControlsExamplesHubViewController`

| 分组 | 场景 | Phase | 验证点 |
|------|------|-------|--------|
| Segment | `SegmentedFilter` | A | 指示器样式对比 |
| | `SegmentBadgesIcons` | A | 图标 + 角标 + RTL |
| Toggle | `ToggleSettings` | A | 带标题 `FKToggleContentConfiguration` |
| | `ToggleLoadingDisabled` | A | 加载/禁用 |
| Checkbox | `CheckboxAgreement` | B | 勾选 + 半选父级 |
| Radio | `RadioGroupVertical` | B | 副标题选项 |
| | `RadioGroupHorizontal` | B | 横向紧凑 |
| Slider | `SliderSingle` | B | 步进 + 触觉 |
| | `SliderRange` | B | 双拇指价格 |
| Composite | `FilterBarComposite` | B | Segment + Slider 区间 |
| Bridge | `SwiftUIBridge` | B | 五 Representable |
| Comparison | `ActionSheetComparison` | A | Sheet Toggle vs `FKToggle` |

---

## 17. 下游依赖与迁移契约

| 消费方 | 现状 | FormControls 就绪后 |
|--------|------|---------------------|
| **ListKit** `FKListPresetItem.switch` | 行内 `UISwitch` | **独立 PR**：trailing 嵌入 `FKToggle`；保留 `FKListSwitchHandlerRegistry` |
| **ListKit** `FKListPresetItem.checkbox` | 行点击 + SF Symbol | **独立 PR**：trailing `FKCheckbox`；**v1 不支持** `indeterminate` preset 行 |
| **ActionSheet** Toggle 行 | `UISwitch` | **保持**；文档对比即可 |
| **FKAlert** 危险勾选 | `UISwitch` | v1.1 可评估 `FKCheckbox`（[FKAlert 设计](FKAlert_DESIGN.md) §23） |
| **FKSearchBar** scope 条 | 未实现 | 第二阶段嵌入 `FKSegmentedControl` |

**ListKit 迁移不得与 FormControls Phase B 同 PR** — 避免双重回归面。

---

## 18. 设计决策记录

| ID | 问题 | **已决（草案默认）** |
|----|------|----------------------|
| Q1 | 单模块 vs 五个顶层目录？ | **单 `FormControls/`**，子目录 per 控件 |
| Q2 | 与 TabBar 私有共享指示器？ | **是** — Internal 复用 frame 计算，无公开依赖 |
| Q3 | FKToggle 外观？ | **FK 自定义**，尺寸对齐 `UISwitch` 命中区 |
| Q4 | 纵向 Slider v1？ | **不做** |
| Q5 | 半选点击循环？ | **半选 → 已选**（`indeterminateTapBehavior = .promoteToChecked`） |
| Q6 | ListKit switch 何时迁移？ | **FormControls Phase B 合并后**，独立 ListKit PR |
| Q7 | ListKit checkbox 半选？ | **v1 preset 不支持**；半选仅独立 `FKCheckbox` |
| Q8 | 带标题 Toggle 包装类型？ | **内置 `FKToggleContentConfiguration`**，无 `FKToggleRow` |
| Q9 | 颜色来源？ | **v1 `FKButton` 色板**；`FKTheme` 后续接 token |
| Q10 | `Sendable` 与 `UIColor`？ | 含 UIKit 颜色的配置标 **`@unchecked Sendable`** |

---

## 19. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.4 |
| 2026-06-13 | 增补 §4 架构、§15 分阶段交付、§17 迁移契约；补全 API/配置/SwiftUI/Examples；分阶段成功标准；设计决策扩展 Q6–Q10 |

---

## 相关文档

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) — §1.4、分阶段 C/D
- [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) — §7.2
- [FKListKit_DESIGN.md](FKListKit_DESIGN.md) — preset switch/checkbox 迁移
- [FKAlert_DESIGN.md](FKAlert_DESIGN.md) — 危险勾选门控
- [FKSearchBar-FKSearchField_DESIGN.md](FKSearchBar-FKSearchField_DESIGN.md) — scope 条依赖
- [TabBar README](../Sources/FKUIKit/Components/TabBar/README.md)
- [ActionSheet README](../Sources/FKUIKit/Components/ActionSheet/README.md)
- [FKRatingControl README](../Sources/FKUIKit/Components/RatingControl/README.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
