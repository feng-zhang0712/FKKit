# FKFormControls — 设计需求文档

FKKit **表单与筛选控件**的实现指导文档：**`FKSegmentedControl`**、**`FKToggle`**、**`FKCheckbox`**、**`FKRadioGroup`**、**`FKSlider`**。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.4  
**English version:** [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 共享设计语言](#4-共享设计语言)
- [5. FKSegmentedControl](#5-fksegmentedcontrol)
- [6. FKToggle](#6-fktoggle)
- [7. FKCheckbox](#7-fkcheckbox)
- [8. FKRadioGroup](#8-fkradiogroup)
- [9. FKSlider](#9-fkslider)
- [10. 控件横向对比](#10-控件横向对比)
- [11. SwiftUI 桥接](#11-swiftui-桥接)
- [12. 全局默认值](#12-全局默认值)
- [13. 建议源码目录结构](#13-建议源码目录结构)
- [14. FKKitExamples 场景](#14-fkkitexamples-场景)
- [16. 待决问题](#16-待决问题)
- [17. 修订历史](#17-修订历史)

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

均为 **`UIControl`** 子类（或发出 `UIControl` 事件的组合根），`@MainActor`，可选 SwiftUI `Representable`。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **统一 FK 视觉语言** — 非系统默认 `UISwitch` / `UISegmentedControl` / `UISlider` 裸样式。
2. **分层 `Sendable` 配置** — 各控件含 `layout` / `appearance` / `interaction` / `motion` / `accessibility`。
3. **HIG 基线** — 44pt 触控、Dynamic Type、VoiceOver、深色模式、RTL、减少动态效果。
4. **边界清晰** — 与 ActionSheet Toggle 行、TabBar segmented 预设区分使用场景。
5. **可组合** — 设置 VC、筛选工具栏、`FKListKit` Cell、SwiftUI 表单。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 完整表单构建/校验编排 | 未来 `FKForm`（路线图 Tier 3） |
| Stepper（+ / −） | 后续独立控件 |
| 滚轮 Picker | `FKDatePicker` 路线图 |
| 取色器 | 不在范围 |
| macOS / tvOS | 仅 iOS 15+ UIKit |

### 2.3 成功标准

- [ ] 交付 Segment + Toggle 与 Checkbox、Radio、Slider。
- [ ] 每控件：README、Examples、根 README 索引。
- [ ] 禁用/加载态全家一致。
- [ ] §10 决策树写入文档。

---

## 3. 背景与问题陈述

### 3.1 缺口

| 需求 | 现状 | 缺口 |
|------|------|------|
| 筛选 Tab（价格/评分/新品） | `FKTabBar` segmented **预设** | TabBar 偏**导航/分页**头，不宜作表单内 `UISegmentedControl` 替代 |
| 设置开关行 | ActionSheet Toggle **行** | 无法直接嵌入 Table/List |
| 协议多选 | — | 无 Checkbox |
| 支付方式单选 | — | 无 Radio |
| 价格区间 | 仅 Player 内 Slider | 无公开 Slider |

### 3.2 与 FKTabBar `segmentedControl` 预设

| 维度 | FKTabBar（segmented 预设） | FKSegmentedControl |
|------|---------------------------|-------------------|
| 角色 | Tab 头 / 分页条 | 行内筛选或设置控件 |
| 数据 | `FKTabBarItem` + 角标 | `FKSegment` |
| 分页 | `FKPagingController` | 无 |
| 滚动 | 可选横滚 | 可选；默认可均分不滚动 |

可**私有复用** TabBar 指示器动画数学，**公开 API 不依赖** `FKTabBar`。

### 3.3 与 ActionSheet Toggle 行

- **Sheet 内**开关列表 → ActionSheet Toggle 行  
- **设置页/自定义布局** → **FKToggle**

---

## 4. 共享设计语言

### 4.1 配置分层

各控件采用统一模式：

```swift
public struct FKSegmentedControlConfiguration: Sendable, Equatable {
  public var layout: ...
  public var appearance: ...
  public var interaction: ...
  public var motion: ...
  public var accessibility: ...
}
```

### 4.2 共享类型（`FormControls/Core/`）

| 类型 | 用途 |
|------|------|
| `FKFormControlEnabledState` | 正常 / 禁用 |
| `FKFormControlLoadingState` | 空闲 / 加载 |
| `FKFormControlHaptic` | 触觉（默认 **none**） |
| `FKFormControlSize` | small / medium / large |
| `FKFormControlLabelPlacement` | 标签前/后/隐藏 |

### 4.3 UIControl 事件

- 值变化发 `.valueChanged`
- 点击型（Checkbox/Radio）支持 `.touchUpInside`
- 文档说明 `addAction(_:for:)` 用法

### 4.4 动效

- 尊重 `UIAccessibility.isReduceMotionEnabled`
- 减少动态效果时：交叉淡入或瞬时切换

### 4.5 禁用与加载

| 状态 | 视觉 | 交互 |
|------|------|------|
| 禁用 | 降透明度（默认约 0.48） | 忽略触摸 |
| 加载 | 尾部菊花或覆盖层 | 默认禁止改值 |

---

## 5. FKSegmentedControl

### 5.1 用途

**2–8** 个互斥分段（软上限 8，可配置硬上限）。替代 `UISegmentedControl`，用于 FK 风格筛选与模式切换。

### 5.2 公开 API（草案）

```swift
@MainActor
public final class FKSegmentedControl: UIControl {
  public var configuration: FKSegmentedControlConfiguration
  public var segments: [FKSegment] { get set }
  public var selectedIndex: Int { get set }
  public var selectedSegmentID: FKSegmentID? { get set }
  public var onSelectionChanged: (@MainActor (Int, FKSegment) -> Void)?
}

public struct FKSegment: Hashable, Sendable, Identifiable {
  public var id: FKSegmentID
  public var title: String?
  public var icon: FKSegmentIcon?
  public var badge: FKSegmentBadge?
  public var isEnabled: Bool
  public var accessibilityLabel: String?
}
```

### 5.3 布局能力

| 能力 | 选项 |
|------|------|
| 宽度模式 | `.fillEqually`、`.intrinsic`、`.mixed` |
| 高度 | 紧凑 32pt / **默认 44pt** |
| 内边距 | 轨道内 padding |
| 分段间距 | 0（连体）或间隙（浮动胶囊） |
| 横滚 | intrinsic 溢出时可滚 |
| RTL | 分段顺序镜像 |

### 5.4 指示器样式

| 样式 | 说明 |
|------|------|
| `.pill` | 选中段后滑动胶囊（参考 TabBar pill） |
| `.underline` | 下划线（粗细、内缩可配） |
| `.filledSegment` | 选中段填充，无滑动 pill |
| `.none` | 仅文字/颜色变化 |

选中变化时**必须**动画移动指示器（默认 0.25s，可配置）。

### 5.5 外观

- 轨道背景色 / 可选材质模糊
- 选中/未选中字色字阶（Dynamic Type）
- 图标 tint 随文字状态
- 角标：点或数字
- 轨道圆角

### 5.6 交互

| 行为 | 要求 |
|------|------|
| 点击分段 | 启用则选中；`valueChanged` |
| 横向拖拽 | 可选 `allowsDragSelection`（默认 false） |
| 重复点当前项 | 默认无操作；`allowsReselect` 可开 |
| 触觉 | 可选 |

### 5.7 无障碍

- 容器 trait：`.tabBar` / 分段语义
- 每段：标题 + 角标 + 选中态
- `accessibilityValue` = 当前选中段标题

### 5.8 边界

- 空 segments → 零尺寸隐藏
- 单段 → 显示但选择不变
- 全禁用 → 整控件禁用
- 动态增删段 → 优先按 `FKSegmentID` 保留选中

---

## 6. FKToggle

### 6.1 用途

设置项**开/关** — FK 风格开关，替代裸 `UISwitch`。

### 6.2 公开 API（草案）

```swift
@MainActor
public final class FKToggle: UIControl {
  public var configuration: FKToggleConfiguration
  public var isOn: Bool { get set }
  public var isLoading: Bool { get set }
  public var onValueChanged: (@MainActor (Bool) -> Void)?
}
```

可选 `FKToggleContentConfiguration`：标题、副标题、`labelPlacement`（默认 leading）。

### 6.3 视觉

| 元素 | 要求 |
|------|------|
| 轨道 | 圆角矩形；on/off 色对齐 `FKButton` 色板 |
| 拇指 | 圆片；可选阴影；位移动画 |
| 尺寸 | small / medium（默认）/ large |
| 加载 | 拇指位菊花或轨道变暗 |

支持 onTint / offTint / thumbTint 品牌色覆盖。

### 6.4 交互

- 点轨道/拇指切换（非加载且启用）
- `allowsDragToToggle` 默认 true
- `setOn(_:animated:)` + 可配置是否 `sendActions`
- 触觉默认关

### 6.5 无障碍

- Trait `.switch`
- `accessibilityValue` 本地化 on/off
- 标签来自 title 或显式 label

### 6.6 与 FKListKit

`FKListPresetItem.switch` 内部应使用 **FKToggle**（发布后）— 见 FKListKit 设计交叉引用。

---

## 7. FKCheckbox

### 7.1 用途

**复选框**隐喻（非开关）。支持**半选**态（全选父行）。

### 7.2 公开 API（草案）

```swift
public enum FKCheckboxState: Equatable, Sendable {
  case unchecked, checked, indeterminate
}

@MainActor
public final class FKCheckbox: UIControl {
  public var state: FKCheckboxState { get set }
  public var onStateChanged: (@MainActor (FKCheckboxState) -> Void)?
}
```

### 7.3 视觉

| 状态 | 图形 |
|------|------|
| 未选 | 空方框圆角边框 |
| 已选 | 填充 + 勾 |
| 半选 | 填充 + 减号/横杠 |

尺寸随 `FKFormControlSize`；可选错误态边框色。

### 7.4 交互

- 点击：未选↔已选；半选→已选（可配置）
- `indeterminateEnabled` 控制是否使用半选
- 可选关联标签扩大点击区

### 7.5 无障碍

- `.button` + 选中时 `.selected`
- Value："已勾选"/"未勾选"/"部分选中"
- 全选头：hint 说明批量选择

---

## 8. FKRadioGroup

### 8.1 用途

**恰好一项**选中（通常 2–6 项）。纵向列表或横向排列。

### 8.2 公开 API（草案）

```swift
public struct FKRadioOption: Hashable, Sendable, Identifiable { ... }

@MainActor
public final class FKRadioGroup: UIControl {
  public var options: [FKRadioOption] { get set }
  public var selectedOptionID: FKRadioOptionID? { get set }
  public var onSelectionChanged: (@MainActor (FKRadioOptionID) -> Void)?
}
```

### 8.3 布局

| 模式 | 说明 |
|------|------|
| `.vertical` | 选项纵向；指示器 leading |
| `.horizontal` | 横排或横滚 |
| `.compact` | 紧凑横条 + 圆形指示器 |

纵向最小行高 44pt。

### 8.4 指示器

- 外环 + 选中内圆点
- 动画缩放（尊重 Reduce Motion）

### 8.5 交互

- 点选项 → 唯一选中；禁用项不可选
- 默认重复点已选项无操作

### 8.6 无障碍

- 容器 `accessibilityLabel` 作组名
- 选项：`.button` + 选中 `.selected`

### 8.7 与 FKSegmentedControl

| 用 Segment | 用 Radio |
|------------|----------|
| 短标签、紧凑筛选 | 带副标题的说明性选项 |
| 图标+角标条 | 表单 2–6 项详述 |

---

## 9. FKSlider

### 9.1 用途

连续或**步进**标量；可选**双拇指区间**（价格筛选）。

### 9.2 公开 API（草案）

```swift
public enum FKSliderMode: Sendable, Equatable {
  case single
  case range(lower: CGFloat, upper: CGFloat)
}

@MainActor
public final class FKSlider: UIControl {
  public var mode: FKSliderMode
  public var value: CGFloat { get set }
  public var lowerValue: CGFloat { get set }
  public var upperValue: CGFloat { get set }
  public var onValueChanged: (@MainActor (FKSliderValue) -> Void)?
  public var onEditingDidEnd: (@MainActor (FKSliderValue) -> Void)?
}
```

### 9.3 轨道与拇指

| 元素 | 能力 |
|------|------|
| 轨道 | 高度、背景色、圆角 |
| 填充 | 最小值到拇指（或 lower–upper） |
| 拇指 | 直径 ≥28pt，**点击区 44pt** |
| 刻度 | 可选步进 tick |
| 标签 | 最小/最大静态；拖拽浮层可选 |

### 9.4 数值映射

- `minimum` / `maximum` / `step` / `snapToStep`
- 区间模式：`lower <= upper`，`minimumRange` 最小间距
- set 时 clamp

### 9.5 交互

- 拖拇指连续 `valueChanged`
- `tapToSeek` 默认 true
- 双拇指碰撞与 z-order
- 步进可选触觉（参考 `FKProgressBar`）
- `isContinuous` 控制拖拽中是否持续回调

### 9.6 无障碍

- `.adjustable`
- 步进滑块：增减 accessibility action
- 结束编辑播报数值

### 9.7 纵向

v1 **仅横向** — 纵向延后。

---

## 10. 控件横向对比

### 10.1 选型表

| 用户任务 | 控件 |
|----------|------|
| 少量短模式互斥 | `FKSegmentedControl` |
| 带说明的单选 | `FKRadioGroup` |
| 开/关 | `FKToggle` |
| 勾选/多选 | `FKCheckbox` |
| 数值/区间 | `FKSlider` |
| Sheet 内开关行 | ActionSheet Toggle |
| Tab 分页头 | `FKTabBar` |

### 10.2 组合示例

筛选栏：`FKSegmentedControl` + `FKSlider` 区间 — 见 §14。

---

## 11. SwiftUI 桥接

| UIKit | Representable |
|-------|----------------|
| 各控件 | `FK*Representable` |

- `Binding` 同步主值
- `updateUIView` 用 suppress 防环路
- 传入 `configuration`

---

## 12. 全局默认值

```swift
public enum FKFormControlsDefaults {
  public static var segmentedControl: FKSegmentedControlConfiguration
  public static var toggle: FKToggleConfiguration
  // ...
}
```

App 启动时统一品牌表单样式。

---

## 13. 建议源码目录结构

```text
Sources/FKUIKit/Components/FormControls/
├── README.md
├── Public/
│   ├── Core/
│   ├── SegmentedControl/
│   ├── Toggle/
│   ├── Checkbox/
│   ├── RadioGroup/
│   ├── Slider/
│   └── Bridge/
├── Internal/
└── Extension/
```

先 Segment + Toggle；后续补全其余目录。

---

## 14. FKKitExamples 场景

| # | 场景 | 控件 |
|---|------|------|
| 1 | `SegmentedFilter` | 指示器样式对比 |
| 2 | `SegmentBadgesIcons` | 图标+角标 |
| 3 | `ToggleSettings` | 带标题开关 |
| 4 | `ToggleLoadingDisabled` | 加载/禁用 |
| 5 | `CheckboxAgreement` | 单选+半选父级 |
| 6 | `RadioGroupVertical` | 副标题选项 |
| 7 | `RadioGroupHorizontal` | 横向紧凑 |
| 8 | `SliderSingle` | 步进+触觉 |
| 9 | `SliderRange` | 双拇指价格 |
| 10 | `FilterBarComposite` | 分段+区间 |
| 11 | `SwiftUIBridge` | 全部 Representable |
| 12 | `ActionSheetComparison` | Sheet vs FKToggle |

Hub：**FormControls** 分组导航。

---

## 16. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | 单模块 vs 五个顶层目录？ | 单 `FormControls/` |
| Q2 | 与 TabBar 私有共享指示器？ | 是 |
| Q3 | FKToggle 外观？ | FK 自定义，尺寸对齐 UISwitch |
| Q4 | 纵向 Slider v1？ | 不做 |
| Q5 | 半选点击循环？ | 半选→已选 |

---

## 17. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.4 |

---

## 相关文档

- [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md) — 英文版
- [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md)
- [TabBar README](../Sources/FKUIKit/Components/TabBar/README.md)
- [ActionSheet README](../Sources/FKUIKit/Components/ActionSheet/README.md)
- [FKRatingControl README](../Sources/FKUIKit/Components/RatingControl/README.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
