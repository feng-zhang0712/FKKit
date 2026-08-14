# FKCheckbox / FKRadioButton / FKRadioGroup — 设计需求文档

FKKit **离散选择控件**的实现指导文档：公开类型 **`FKCheckbox`**（多选）、**`FKRadioButton`**（单项单选指示器）、**`FKRadioGroup`**（互斥单选组）。视觉与行为以 [§5](#5-视觉规范设计稿对齐) 文字规格为 **v1 最低交付标准**（源自产品设计稿说明，仓库不存放设计截图）。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**模块：** `FKUIKit`  
**建议路径：** `Sources/FKUIKit/Components/SelectionControl/`  
**相关文档：** [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md)（表单控件家族总览；Checkbox / Radio **以本文为准**）  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §1.4 / FormControls

> **给 Cursor / 实施者：** 实现前通读全文；公开 API、状态机、尺寸与色板不得弱于 [§5–§8](#5-视觉规范设计稿对齐)。英文 `///` DocComment；Examples 全覆盖；交付前 `xcodebuild` BUILD SUCCEEDED。

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与选型边界](#3-背景与选型边界)
- [4. 模块架构](#4-模块架构)
- [5. 视觉规范（设计稿对齐）](#5-视觉规范设计稿对齐)
- [6. FKCheckbox](#6-fkcheckbox)
- [7. FKRadioButton](#7-fkradiobutton)
- [8. FKRadioGroup](#8-fkradiogroup)
- [9. 共享类型与配置分层](#9-共享类型与配置分层)
- [10. 交互、事件与状态机](#10-交互事件与状态机)
- [11. 校验、协议勾选与全选辅助](#11-校验协议勾选与全选辅助)
- [12. 文案、副标题、链接与富文本](#12-文案副标题链接与富文本)
- [13. 布局度量与指示器位置](#13-布局度量与指示器位置)
- [14. 列表 / ListKit 集成](#14-列表--listkit-集成)
- [15. 边界情况与并发](#15-边界情况与并发)
- [16. 无障碍、本地化与 RTL](#16-无障碍本地化与-rtl)
- [17. SwiftUI 桥接](#17-swiftui-桥接)
- [18. FKCoreKit / FKUIKit 复用要求](#18-fkcorekit--fkuikit-复用要求)
- [19. 建议源码目录结构](#19-建议源码目录结构)
- [20. 模块内分阶段交付](#20-模块内分阶段交付)
- [21. FKKitExamples 场景](#21-fkkitexamples-场景)
- [22. 验收清单](#22-验收清单)
- [23. 待决问题](#23-待决问题)
- [24. 修订历史](#24-修订历史)

---

## 1. 概述

iOS 无与 Material / Web 同构的原生方框 Checkbox、圆点 Radio。业务表单、权限列表、协议勾选、周期选择等场景反复手写，导致：

- 指示器尺寸 / 圆角 / 色板不一致
- 禁用态未同步灰化文案
- 缺少 **Indeterminate（半选）** 与 **Disabled+On**
- Radio 互斥逻辑散落在 VC
- VoiceOver 语义错误（把 Checkbox 当成 Switch）

本模块交付 **三个公开类型**，共享指示器渲染与色板，嵌入任意布局（Stack / Table / 自定义卡片列表）。

| 交付物 | 基类 | 职责 |
|--------|------|------|
| **`FKCheckbox`** | `UIControl` | 多选；三态；可选标题 / 协议富文本 |
| **`FKRadioButton`** | `UIControl` | 单项圆形指示器 + 可选标题 / 图标 |
| **`FKRadioGroup`** | `UIControl` | 互斥单选组；卡片列表 chrome |
| **`FKSelectionListChrome`** | `UIView` | 圆角卡片 + 分隔线，包装多行 Checkbox 等 |
| **`FKCheckboxStateAggregator`** | — | 由子项勾选推导父级三态 |
| **Shared Internal** | — | 指示器绘制、尺寸表、色板、命中扩展、链接命中 |

**设计稿规格摘要（文字还原，无配图）：**

| 控件 | 规格要点 |
|------|----------|
| **Checkbox** | 圆角方框；状态 Default / Checked（实心+白勾）/ Indeterminate（实心+白横杠）/ Disabled / Disabled+On；尺寸 SM 16 / MD 22 / LG 28；Checked 填充色可换蓝/绿/红/橙/紫；列表中指示器在左、标题在右，禁用行指示器与文案同步变灰 |
| **Radio** | 圆形；状态 Default（灰环空心）/ Selected（彩色外环+同色实心内点，环与点之间留白）/ Disabled / Disabled+On；同五色主题；**无**半选 |
| **Radio Group** | 圆角浅描边卡片内纵向多行；每行「左 Radio + 右标题」；行间浅灰分隔线；组内互斥仅一项 Selected |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **对齐设计稿** — 状态、尺寸（16 / 22 / 28）、主题色（蓝/绿/红/橙/紫）、列表用法完整落地。
2. **语义正确** — Checkbox = 多选（可同时多项）；RadioGroup = 组内恰好一项（或可配置为空）。
3. **可嵌入** — 支持「仅指示器」与「指示器 + 标题」；整行可点；热区 ≥ 44pt。
4. **配置分层** — 对齐 `FKButton` / `FKRatingControl`：`layout` / `appearance` / `interaction` / `motion` / `accessibility`。
5. **HIG 基线** — Dynamic Type（标题）、VoiceOver、Dark Mode、RTL、Reduce Motion。
6. **英文 API** — 公开符号与 DocComment 仅英文；Examples 文案英文。
7. **表单友好** — 校验错误态、协议富文本链接、全选聚合辅助、副标题与选项图标。
8. **可定制指示器** — 自定义勾号 / 半选图、描边宽度、按压反馈、只读展示。
9. **列表友好** — 文档化 Table / ListKit 复用；可选 trailing 指示器位置。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 完整表单校验 / Form builder | 未来 `FKForm`；本模块只提供控件级 `showsError` 与辅助 API |
| 筛选胶囊多选 | 使用 **`FKChip` / `FKChipGroup`** |
| 开/关开关 | 使用系统 `UISwitch` 或后续 `FKToggle`（FormControls） |
| 分段条筛选 | **`FKSegmentedControl`**（FormControls） |
| 完整 `FKCheckboxGroup` 容器（自动管理子项互相同步） | v1 提供 **聚合辅助**（§11）；卡片组容器 v1.1 |
| macOS / tvOS | 仅 iOS 15+ |
| 拖拽多选、框选 | 超出离散点击控件范围 |

### 2.3 成功标准

- [ ] 设计稿五种 Checkbox 状态、四种 Radio 状态均可演示。
- [ ] SM / MD / LG 三档指示器尺寸与设计稿一致（±0.5pt）。
- [ ] 五种预设 tint + 自定义 `UIColor`。
- [ ] `FKRadioGroup` 卡片列表：圆角容器、行分隔、互斥选择。
- [ ] Disabled 时指示器与标题同步降对比度。
- [ ] `showsError`、协议链接标题、全选聚合辅助、Radio 选项图标可演示。
- [ ] Examples Hub 覆盖 §21 全部场景；组件 README 含目录图。
- [ ] `Package.swift` `exclude:` 含新 README；`xcodebuild` BUILD SUCCEEDED（`SWIFT_STRICT_CONCURRENCY=complete`）。

---

## 3. 背景与选型边界

### 3.1 与原生 / 现有组件

| 需求 | 不要用 | 用 |
|------|--------|-----|
| 协议勾选、权限多选 | `UISwitch`、`FKChip` | **`FKCheckbox`** |
| 支付方式 / 周期单选（带说明） | `UISegmentedControl`、Chip single | **`FKRadioGroup`** |
| 紧凑 2–4 短标签互斥 | RadioGroup | Segmented / Chip |
| 开/关设置 | Checkbox | Switch / Toggle |
| 筛选 token | Checkbox | **`FKChip`** |

### 3.2 与 FKFormControls

[FKFormControls_DESIGN.md](FKFormControls_DESIGN.md) 将 Checkbox / Radio 列为 FormControls Phase B。**实现归属以本文 `SelectionControl/` 为准**（独立可发现模块，避免与尚未落地的 Segment/Toggle/Slider 强耦合）。FormControls 文档 §8–§9 改为指向本文；若日后合并目录，仅搬迁路径，**不改公开类型名**。

### 3.3 类型拆分理由

| 类型 | 为何独立 |
|------|----------|
| `FKCheckbox` | 三态 + 方框隐喻；可单独使用 |
| `FKRadioButton` | 可嵌入自定义 cell；Group 内部复用同一渲染 |
| `FKRadioGroup` | 互斥编排 + 设计稿「卡片列表」容器；不是 Checkbox 的 mode |

**禁止**用单一 `FKSelectionControl` + `mode: checkbox/radio` 合并公开 API（VoiceOver 与文档成本更高）。

---

## 4. 模块架构

```text
┌────────────────────────────────────────────────────────────┐
│ FKRadioGroup（UIControl）                                   │
│  options → 行视图；互斥 selectedOptionID                     │
│  可选卡片 chrome（圆角边框 + 分隔线）                        │
└───────────────────────────┬────────────────────────────────┘
                            │ 组合 / 复用绘制
┌───────────────────────────▼────────────────────────────────┐
│ FKRadioButton（UIControl）     FKCheckbox（UIControl）      │
│  圆指示器 + 可选标题            方指示器 + 可选标题          │
└───────────────────────────┬────────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────────┐
│ SelectionControl/Shared（internal）                         │
│  IndicatorView · Size metrics · Tint palette · Hit slop    │
└────────────────────────────────────────────────────────────┘
```

| 维度 | FKCheckbox | FKRadioButton | FKRadioGroup |
|------|------------|---------------|--------------|
| 选择语义 | 多选（独立） | 单项（宿主或 Group 管互斥） | 组内单选 |
| 指示器 | 圆角方框 | 圆环 + 内点 | 每行一个 Radio |
| 半选 | 有 | 无 | 无 |
| 典型场景 | 权限列表、协议、全选父行 | 自定义 cell | 周期/支付方式 |

所有 UI 类型 `@MainActor`。配置结构体 `Sendable` / `Equatable`；含 `UIColor` 的 appearance 使用 `@unchecked Sendable`（对齐 `FKProgressBar` / `FKRatingControl`）。

---

## 5. 视觉规范（设计稿对齐）

本节为 **硬性视觉契约**（由产品设计稿文字还原）。实现可用 Core Animation / 矢量绘制 / SF Symbol，但观感须匹配下列规格。

### 5.1 指示器尺寸

| `FKSelectionControlSize` | 指示器边长（Checkbox）/ 直径（Radio） | 设计稿 |
|--------------------------|----------------------------------------|--------|
| `.small`（SM） | **16 × 16 pt** | ✓ |
| `.medium`（MD） | **22 × 22 pt** | ✓（默认） |
| `.large`（LG） | **28 × 28 pt** | ✓ |

- 标题行最小高度：**max(44, indicator + vertical insets)**，保证热区。
- Checkbox 圆角：相对边长约 **20%–25%**（视觉「软方角」）；提供 `cornerRadius` 覆盖，默认按 size 表计算。
- Radio 外环线宽：随 size 缩放（建议 SM 1.5 / MD 2 / LG 2.5 pt，可配置）。
- Radio **Selected**：彩色外环 + 透明/白底间隙 + **同色实心内圆**（非「实心大圆挖白点」）。内圆直径约为外径的 **45%–55%**。

### 5.2 主题色（Tint）

设计稿展示五种填充/描边色。v1 提供预设枚举 + 任意 `UIColor`：

| `FKSelectionControlTint` | 语义用途（文档提示，非强制） |
|--------------------------|------------------------------|
| `.blue`（默认） | 品牌主色 / 通用 |
| `.green` | 成功、同意 |
| `.red` | 强调、风险相关选项 |
| `.orange` | 警告相关 |
| `.purple` | 品牌扩展 |
| `.custom(UIColor)` | 宿主品牌色 |

- **Checked / Selected / Indeterminate**：指示器使用 tint；勾号 / 减号 / 内点为 **白色**（或 `checkmarkColor`，默认白）。
- **Default（未选）**：浅灰描边 + 透明/白底；**不**使用 tint。
- Dark Mode：未选描边与禁用色走动态 `UIColor`；tint 使用可适配的语义色或宿主传入动态色。

### 5.3 Checkbox 状态视觉

| 状态 | 视觉（对齐设计稿 STATES） |
|------|-------------------------|
| **Default** | 白/透明底 + 浅灰描边空心圆角方框 |
| **Checked** | tint 实心填充 + 白色勾号（✓） |
| **Indeterminate** | tint 实心填充 + 白色短横（−） |
| **Disabled** | 极浅灰描边空心；整体低对比；不可点 |
| **Disabled + On** | 浅化 tint 实心 + 白色勾号；不可点 |

`isEnabled == false` 且 `state == .checked` → **Disabled+On**。  
`isEnabled == false` 且 `state == .indeterminate` → 浅化 tint + 白色短横（设计稿未单独画出，行为对齐 Disabled+On）。

### 5.4 Radio 状态视觉

| 状态 | 视觉（对齐设计稿 STATES） |
|------|-------------------------|
| **Default** | 浅灰圆环，空心 |
| **Selected** | tint 外环 + tint 内圆（中间留白环） |
| **Disabled** | 极浅灰圆环；不可点 |
| **Disabled + On** | 浅化 tint 外环 + 浅化 tint 内圆；不可点 |

Radio **无** Indeterminate。

### 5.5 标题与列表（IN LIST / RADIO GROUP）

**行结构（Checkbox 列表 & Radio Group 行）：**

```text
┌─────────────────────────────────────────┐
│  [指示器]  标题文案                      │  ← 垂直居中；指示器 leading
│─────────── 分隔线（inset）──────────────│
│  [指示器]  标题文案                      │
└─────────────────────────────────────────┘
```

| 规则 | 要求 |
|------|------|
| 指示器位置 | 默认 **leading**（LTR 左侧）；RTL 镜像 |
| 指示器与标题间距 | 默认 **10–12 pt**（可配） |
| 标题字体 | 默认 `UIFont.preferredFont(forTextStyle: .body)`；Dynamic Type |
| 禁用行 | 指示器为 Disabled / Disabled+On，**标题同步**使用 secondary / quaternary 灰（设计稿禁用列表示意） |
| 分隔线 | 细浅灰；左右 inset（不要贴满容器边缘）；首行上无线、末行下无线 |
| 卡片容器（Group） | 圆角矩形（建议 10–12 pt）+ 浅灰描边；背景 secondarySystemGroupedBackground 或 white（Light） |

`FKCheckbox` / `FKRadioButton` **内置**可选 title。`FKRadioGroup` 自带卡片 chrome；Checkbox 列表示意用公开 **`FKSelectionListChrome`**（§14）包装多个 Checkbox，**不**做自动同步的 `FKCheckboxGroup`（v1.1）。

### 5.6 按压（Highlighted）反馈

对齐 `FKButton` 轻量反馈（默认开启 alpha）：

| 项 | 默认 |
|----|------|
| `pressedAlpha` | 0.72（整行：指示器 + 文案） |
| `pressedScale` | 1.0（默认可关缩放；可配 0.96–0.98） |
| 禁用 / 只读 | 不进入 highlighted 视觉 |

### 5.7 动效

| 场景 | 默认 |
|------|------|
| 选中切换 | `FKSelectionControlSelectionAnimation`：`.crossfade`（默认）/ `.scalePop` / `.none`；时长 ≤ 0.2s |
| Reduce Motion | 强制瞬时（等价 `.none`） |
| 触觉 | **默认关闭**；`interaction.haptic` 可开（`.light` / `.selection`） |

### 5.8 错误态（校验）

设计稿未单独画出；表单场景高频，v1 **纳入**：

| 控件 | `showsError == true` |
|------|----------------------|
| Checkbox | 未选/半选描边 → `errorBorderColor`（默认 systemRed）；已选默认保持 tint |
| RadioButton | 未选外环 → error 色 |
| RadioGroup | 卡片描边 → error |

`showsError` 不阻止交互；宿主在用户改正后清除。

---

## 6. FKCheckbox

### 6.1 用途

多项选择：权限、通知偏好、协议同意、树形全选父节点（半选）等。

### 6.2 状态模型

```swift
public enum FKCheckboxState: Equatable, Sendable {
  case unchecked
  case checked
  case indeterminate
}

public enum FKSelectionControlInteractionMode: Sendable, Equatable {
  case interactive
  /// Renders state; ignores toggle taps (links may still fire).
  case readOnly
}
```

| 状态 | `isSelected`（UIControl） | 说明 |
|------|---------------------------|------|
| `.unchecked` | `false` | Default |
| `.checked` | `true` | Checked |
| `.indeterminate` | `false` | 半选；以 `state` / accessibility value 为准 |

```swift
public var isChecked: Bool { state == .checked }
```

### 6.3 公开 API（草案）

```swift
public struct FKCheckboxContentConfiguration: @unchecked Sendable, Equatable {
  public var title: String?
  /// Preferred over `title` when set. Link taps: see §12.
  public var attributedTitle: AttributedString?
  public var subtitle: String?
  public var isRequired: Bool  // trailing "*"; default false
}

@MainActor
public final class FKCheckbox: UIControl {
  public var configuration: FKCheckboxConfiguration
  public var content: FKCheckboxContentConfiguration

  public var state: FKCheckboxState { get set }
  public var showsError: Bool { get set }
  public var interactionMode: FKSelectionControlInteractionMode { get set }

  public var onStateChanged: (@MainActor (FKCheckboxState) -> Void)?
  public var onLinkActivated: (@MainActor (URL) -> Void)?

  public init(configuration: FKCheckboxConfiguration = .init(), content: FKCheckboxContentConfiguration = .init())
  public convenience init(title: String?, state: FKCheckboxState = .unchecked)

  public func setState(_ state: FKCheckboxState, animated: Bool, sendActions: Bool)
  public func toggle(animated: Bool = true, sendActions: Bool = true)
  public func apply(_ configuration: FKCheckboxConfiguration)
}
```

```swift
public enum FKCheckboxPresets {
  public static func settingsRow() -> FKCheckboxConfiguration
  public static func indicatorOnly(size: FKSelectionControlSize = .medium) -> FKCheckboxConfiguration
  /// Multi-line title spacing for Terms of Service rows.
  public static func agreement() -> FKCheckboxConfiguration
}
```

### 6.4 配置要点

**Layout**

| 字段 | 默认 | 说明 |
|------|------|------|
| `size` | `.medium` | 16 / 22 / 28 |
| `labelPlacement` | `.trailing` | `.hidden` = 仅指示器 |
| `indicatorEdge` | `.leading` | `.trailing` = HIG 列表侧（v1 支持） |
| `indicatorTitleSpacing` | 12 | |
| `titleSubtitleSpacing` | 4 | |
| `contentInsets` | 见 §13 | |
| `expandsHitTargetToMinimum` | `true` | |
| `titleNumberOfLines` | 0 | |
| `subtitleNumberOfLines` | 2 | |

**Appearance**

| 字段 | 默认 | 说明 |
|------|------|------|
| `tint` | `.blue` | §5.2 |
| `uncheckedBorderColor` | 动态浅灰 | |
| `uncheckedBorderWidth` | 按 size 表 | |
| `checkmarkColor` | `.white` | |
| `checkmarkImage` / `indeterminateImage` | `nil` = 内置 | 自定义 glyph |
| `cornerRadius` | `nil` = 推导 | |
| `titleColor` / `subtitleColor` / `disabledTitleColor` | label / secondary / tertiary | |
| `titleFont` / `subtitleFont` | body / footnote | |
| `errorBorderColor` | `.systemRed` | |
| `disabledAlpha` | 0.48 | |
| `pressedAlpha` | 0.72 | |

**Interaction**

| 字段 | 默认 | 说明 |
|------|------|------|
| `mode` | `.interactive` | |
| `togglesOnTouch` | `true` | |
| `indeterminateTapBehavior` | `.promoteToChecked` | `.cycle` / `.promoteToUnchecked` |
| `allowsIndeterminate` | `true` | `false` 时半选 clamp → `.unchecked` |
| `linkTapTogglesCheckbox` | `false` | 点链接只回调 `onLinkActivated` |
| `haptic` | `.none` | |

### 6.5 交互规则

1. `isEnabled == false` 或 `mode == .readOnly` → 不切换；不发 `valueChanged`（readOnly 仍可激活链接）。
2. 默认切换：未选↔已选；半选按 `indeterminateTapBehavior`。
3. 点非链接文字与点指示器等效。
4. `setState` / `toggle`（`sendActions: true`）发 `.valueChanged` 与 `onStateChanged`。
5. `showsError` 只影响绘制与 accessibility。

### 6.6 无障碍

- Traits：`.button`；checked 时 `.selected`；error 时通告 Invalid
- Value：`Checked` / `Unchecked` / `Mixed`
- Label：title；`isRequired` 附加 required
- Hint：可配置 “Double tap to toggle”

---

## 7. FKRadioButton

### 7.1 用途

单个圆形单选项；自定义 cell 或 `FKRadioGroup` 内部复用。

### 7.2 公开 API（草案）

```swift
public struct FKRadioButtonContentConfiguration: @unchecked Sendable, Equatable {
  public var title: String?
  public var attributedTitle: AttributedString?
  public var subtitle: String?
  /// Drawn between indicator and title when `indicatorEdge == .leading`.
  public var image: UIImage?
  public var imageSize: CGSize?  // nil → 24×24
}

@MainActor
public final class FKRadioButton: UIControl {
  public var configuration: FKRadioButtonConfiguration
  public var content: FKRadioButtonContentConfiguration

  public var isSelected: Bool { get set }
  public var showsError: Bool { get set }
  public var interactionMode: FKSelectionControlInteractionMode { get set }

  public var onSelectionChanged: (@MainActor (Bool) -> Void)?
  public var onLinkActivated: (@MainActor (URL) -> Void)?

  public func setSelected(_ selected: Bool, animated: Bool, sendActions: Bool)
  public func apply(_ configuration: FKRadioButtonConfiguration)
}
```

### 7.3 交互

- **独立实例不互斥**；互斥必须用 Group 或宿主。
- 点击未选 → 选中；已选再点默认保持（取消选中仅 Group `allowsDeselection`）。
- `readOnly` / disabled：不切换。

### 7.4 配置

共享 size / tint / spacing / hit / pressed / disabledAlpha；另含：

| 字段 | 说明 |
|------|------|
| `ringWidth` | 外环线宽 |
| `innerDotScale` | 默认 0.5 |
| `selectedFillStyle` | `.ringAndDot`（设计稿） |

### 7.5 无障碍

- Traits：`.button`；选中 `.selected`
- Value：`Selected` / `Not selected`
- `image` 为装饰，不单独暴露为 accessibility 元素

---

## 8. FKRadioGroup

### 8.1 用途

组内互斥单选。设计稿 RADIO GROUP：圆角卡片 + 行（指示器 + 标题）+ 分隔线。

### 8.2 数据模型

```swift
public typealias FKRadioOptionID = String

public struct FKRadioOption: Hashable, @unchecked Sendable, Identifiable {
  public var id: FKRadioOptionID
  public var title: String
  public var subtitle: String?
  public var image: UIImage?
  public var isEnabled: Bool
  public var accessibilityLabel: String?

  public init(
    id: FKRadioOptionID,
    title: String,
    subtitle: String? = nil,
    image: UIImage? = nil,
    isEnabled: Bool = true,
    accessibilityLabel: String? = nil
  )
}
```

### 8.3 公开 API（草案）

```swift
public enum FKRadioGroupLayoutStyle: Sendable, Equatable {
  case plain
  case insetGrouped
  case horizontal
}

@MainActor
public final class FKRadioGroup: UIControl {
  public var configuration: FKRadioGroupConfiguration
  public var options: [FKRadioOption] { get set }

  public var headerTitle: String?
  public var footerTitle: String?

  public var selectedOptionID: FKRadioOptionID? { get set }
  public var selectedOption: FKRadioOption? { get }
  public var showsError: Bool { get set }

  public var onSelectionChanged: (@MainActor (FKRadioOptionID?) -> Void)?

  public init(configuration: FKRadioGroupConfiguration = .init(), options: [FKRadioOption] = [])

  public func setSelectedOptionID(_ id: FKRadioOptionID?, animated: Bool, sendActions: Bool)
  public func selectOption(id: FKRadioOptionID, animated: Bool = true, sendActions: Bool = true)
  public func option(id: FKRadioOptionID) -> FKRadioOption?
  public func apply(_ configuration: FKRadioGroupConfiguration)
}
```

### 8.4 配置要点

**Layout**

| 字段 | 默认 | 说明 |
|------|------|------|
| `style` | `.insetGrouped` | |
| `size` | `.medium` | |
| `indicatorEdge` | `.leading` | 可 `.trailing` |
| `rowMinHeight` | 44 | |
| `separatorInset` | 见 §13 | |
| `cornerRadius` | 12 | |
| `axisSpacing` | 0 | |
| `headerFooterSpacing` | 8 | |
| `maximumVisibleOptions` | `nil` | 非 nil 时垂直滚动 |

**Appearance** — tint、border、background、separator、errorBorder、disabledAlpha、pressedAlpha。

**Interaction**

| 字段 | 默认 | 说明 |
|------|------|------|
| `allowsDeselection` | `false` | |
| `allowsEmptySelection` | `false` | |
| `reselectWhenSelectedOptionDisabled` | `false` | |
| `duplicateIDPolicy` | `.assertInDebug` | |
| `haptic` | `.none` | |

初始 `selectedOptionID == nil`：**保持 nil**，由宿主赋值；Examples 演示显式初始选中。

### 8.5 行为

1. 点击启用行 → 互斥更新 `selectedOptionID`。
2. 选中项变 disabled → 默认保持 Disabled+On；见 `reselectWhenSelectedOptionDisabled`。
3. `options` 更新：旧 id 仍在则保留；丢失时若允许空则 `nil`，否则选第一项启用选项。
4. `.valueChanged` 仅在 id 实际变化时发出。
5. 未知 id 的 `setSelectedOptionID`：**忽略并保持旧值**（Debug log）。

### 8.6 布局实现提示

- `insetGrouped`：圆角边框 + 行分隔；header/footer 默认在**卡片外**。
- 行：Internal row 或嵌入 `FKRadioButton`。
- `horizontal`：横向 stack，溢出可滚。
- `intrinsicContentSize` 高度累加。

### 8.7 与 FKSegmentedControl / FKChipGroup

| 用 RadioGroup | 用其他 |
|---------------|--------|
| 2–8 项、可读标题、可带图/副标题 | 短标签筛选 → Segment / Chip |
| 卡片列表视觉 | 导航顶部分段 → TabBar / Segment |

---

## 9. 共享类型与配置分层

### 9.1 共享枚举

```swift
public enum FKSelectionControlSize: String, Sendable, Equatable, CaseIterable {
  case small, medium, large
}

public enum FKSelectionControlTint: Equatable, Sendable {
  case blue, green, red, orange, purple
  case custom(UIColor)
}

public enum FKSelectionControlLabelPlacement: Sendable, Equatable {
  case trailing, leading, hidden
}

public enum FKSelectionControlIndicatorEdge: Sendable, Equatable {
  case leading
  case trailing
}

public enum FKSelectionControlHaptic: Sendable, Equatable {
  case none, light, selection
}

public enum FKSelectionControlSelectionAnimation: Sendable, Equatable {
  case crossfade, scalePop, none
}

public enum FKCheckboxIndeterminateTapBehavior: Sendable, Equatable {
  case promoteToChecked, promoteToUnchecked, cycle
}
```

SelectionControl v1 **自包含**尺寸枚举；日后可与 `FKFormControlSize` 映射。

### 9.2 配置根结构

```swift
public struct FKCheckboxConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKCheckboxLayoutConfiguration
  public var appearance: FKCheckboxAppearanceConfiguration
  public var interaction: FKCheckboxInteractionConfiguration
  public var motion: FKSelectionControlMotionConfiguration
  public var accessibility: FKSelectionControlAccessibilityConfiguration
}

public struct FKSelectionControlMotionConfiguration: Sendable, Equatable {
  public var animationDuration: TimeInterval  // 0.18
  public var selectionAnimation: FKSelectionControlSelectionAnimation
  public var respectsReducedMotion: Bool  // true
}

public struct FKSelectionControlAccessibilityConfiguration: Sendable, Equatable {
  public var customLabel: String?
  public var customHint: String?
  public var groupLabel: String?
}
```

`FKRadioButtonConfiguration` / `FKRadioGroupConfiguration` 同层结构。

### 9.3 全局默认

```swift
public enum FKSelectionControlDefaults {
  public static var checkbox: FKCheckboxConfiguration
  public static var radioButton: FKRadioButtonConfiguration
  public static var radioGroup: FKRadioGroupConfiguration
  public static var listChrome: FKSelectionListChromeConfiguration
}
```

### 9.4 Builder（可选 Extension）

```swift
extension FKCheckbox {
  @discardableResult public func tint(_ tint: FKSelectionControlTint) -> Self
  @discardableResult public func size(_ size: FKSelectionControlSize) -> Self
}
```

---

## 10. 交互、事件与状态机

### 10.1 UIControl 事件

| 类型 | `.valueChanged` | 其他 |
|------|-----------------|------|
| `FKCheckbox` | `state` 变化 | `onStateChanged`；链接 → `onLinkActivated` |
| `FKRadioButton` | `isSelected` 变化 | |
| `FKRadioGroup` | `selectedOptionID` 变化 | |

支持 `addAction(_:for: .valueChanged)` 与闭包等价。

### 10.2 Checkbox 状态机

```text
  unchecked ──tap──► checked
  checked   ──tap──► unchecked
  indeterminate ──tap──► checked   (promoteToChecked)
  cycle: unchecked → checked → indeterminate → unchecked
```

### 10.3 RadioGroup 状态机

```text
  selected = A ──tap B──► B
  selected = A ──tap A──► A (allowsDeselection false) | nil (true)
```

### 10.4 按压与取消

- `touchDown` → highlighted；`touchUpInside` → 提交；cancel / outside → 仅取消 highlighted。
- 动画中再次 set：取消旧动画，跳到终态。

---

## 11. 校验、协议勾选与全选辅助

### 11.1 校验错误态

```swift
func validate() -> Bool {
  let ok = checkbox.state == .checked
  checkbox.showsError = !ok
  return ok
}
```

RadioGroup：提交前若必须选且 `selectedOptionID == nil` → `showsError = true`。

### 11.2 全选聚合（无容器类型）

```swift
public enum FKCheckboxStateAggregator {
  public static func aggregate(checkedFlags: [Bool]) -> FKCheckboxState
  // all false → unchecked; all true → checked; else → indeterminate
}

public extension FKCheckbox {
  func applyAggregate(fromChildCheckedFlags flags: [Bool], sendActions: Bool = false)
}
```

宿主：子项变化 → `parent.applyAggregate`；父项点击 → 批量全选/全不选（Examples 给完整样例）。

### 11.3 协议勾选

- `attributedTitle` + link；`onLinkActivated` 打开条款。
- 预设 `agreement()`：多行、MD 指示器、与正文对齐。

---

## 12. 文案、副标题、链接与富文本

### 12.1 标题层级

```text
[indicator]  Title (body)
             Subtitle (footnote, secondary)
```

- `isRequired`：标题后红色 `*`；VoiceOver 读 required。

### 12.2 富文本与链接

| 规则 | 要求 |
|------|------|
| 公开类型 | 优先 `AttributedString` |
| 链接 | `.link` → `onLinkActivated` |
| 与切换 | 默认点链接**不**切换（`linkTapTogglesCheckbox == false`） |
| 链接色 | 默认 `.link` 或跟随 tint |

### 12.3 截断

- `numberOfLines` + tail truncation；优先保证指示器完整。

---

## 13. 布局度量与指示器位置

### 13.1 度量 Token

| Size | 边长/直径 | Checkbox 圆角 | Radio ringWidth |
|------|-----------|---------------|-----------------|
| SM | 16 | 3.5 | 1.5 |
| MD | 22 | 5 | 2 |
| LG | 28 | 6 | 2.5 |

| Token | 默认 pt |
|-------|---------|
| `indicatorTitleSpacing` | 12 |
| `titleSubtitleSpacing` | 4 |
| `rowMinHeight` | 44 |
| `contentInsets`（带标题） | `{10, 16, 10, 16}` |
| `contentInsets`（indicatorOnly） | `{8,8,8,8}` + hit-slop → 44 |
| `separatorHeight` | hairline |
| `separatorLeadingInset` | 对齐标题列 |
| `cardCornerRadius` | 12 |
| `cardBorderWidth` | 1 |
| `imageTitleSpacing` | 10 |
| `disabledAlpha` | 0.48 |
| `animationDuration` | 0.18 |

### 13.2 `indicatorEdge`

| 值 | 布局 |
|----|------|
| `.leading` | `[indicator][spacing][text]` — 设计稿 |
| `.trailing` | `[text][flexible][indicator]` — Settings 风 |

### 13.3 Auto Layout

- 指示器 horizontal hugging required；标题 low。
- `intrinsicContentSize` 必须有效。

---

## 14. 列表 / ListKit 集成

### 14.1 UITableView / UICollectionView

| 建议 | 说明 |
|------|------|
| Cell 内嵌单控 | `indicatorOnly` 或带 title |
| 复用 | `prepareForReuse` 重置 state / selection / showsError / 闭包 |
| 整行点击 | 转发 `toggle()` 或扩大 insets |
| 分隔线 | Table separator **或** chrome，勿双重 |

### 14.2 FKListKit

- 既有 checkbox preset 可迁到 `FKCheckbox`；v1 不强制改 ListKit。
- README 提供 sample cell。

### 14.3 `FKSelectionListChrome`（v1 公开）

对齐 Checkbox 设计稿 IN LIST 卡片：

```swift
@MainActor
public final class FKSelectionListChrome: UIView {
  public var configuration: FKSelectionListChromeConfiguration
  public func setArrangedControls(_ views: [UIView])
}
```

圆角、描边、行间分隔；可包装多个 `FKCheckbox` 或自定义行。

---

## 15. 边界情况与并发

| 场景 | 行为 |
|------|------|
| `options` 为空 | 仅 header/footer；选中 nil |
| 重复 option id | Debug assert；首个生效 |
| 未知 selected id | 忽略，保持旧值 |
| 半选写入但不允许 | clamp → `.unchecked` |
| 闭包 | 宿主 `[weak self]` |
| 线程 | 全部 `@MainActor` |
| VoiceOver 下改 options | 更新 accessibility 树 |

---

## 16. 无障碍、本地化与 RTL

| 项 | 要求 |
|----|------|
| VoiceOver | 子项可达；Group 提供 groupLabel |
| Adjustable | RadioGroup v1 加分；非必须 |
| Dynamic Type | 标题跟随；指示器默认不随字体放大 |
| RTL | directional `indicatorEdge` |
| Reduce Motion | 跳过选中动画 |
| 本地化 | `fkui.checkbox.*`、`fkui.radio.*`、`fkui.selection.error` |
| 对比度 | Light/Dark + error 可辨 |

---

## 17. SwiftUI 桥接

| UIKit | SwiftUI |
|-------|---------|
| `FKCheckbox` | `FKCheckboxRepresentable` |
| `FKRadioButton` | `FKRadioButtonRepresentable` |
| `FKRadioGroup` | `FKRadioGroupRepresentable` |
| `FKSelectionListChrome` | 可选 Representable |

`Binding` 绑定 `state` / `isSelected` / `selectedOptionID`；`showsError`、`onLinkActivated` 作参数。

---

## 18. FKCoreKit / FKUIKit 复用要求

| 能力 | 优先 | 禁止 |
|------|------|------|
| 动态色 | 系统动态色 / UIColor 扩展 | 仅 Light 硬编码 |
| 字体 | `UIFontMetrics` | 标题无视 Dynamic Type |
| 触觉 | `FKButton` 同路径 | 散落 generator |
| 分隔线 | 可复用 **`FKDivider`** | 重复造线 |
| 图标 | SF Symbol / 贝塞尔 | 第三方库 |
| Chip Internal | 可参考互斥思路 | 直接依赖 |

指示器绘制仅在 `SelectionControl/Shared`。

---

## 19. 建议源码目录结构

```text
Sources/FKUIKit/Components/SelectionControl/
├── README.md
├── Public/
│   ├── Shared/
│   │   ├── FKSelectionControlSize.swift
│   │   ├── FKSelectionControlTint.swift
│   │   ├── FKSelectionControlLabelPlacement.swift
│   │   ├── FKSelectionControlIndicatorEdge.swift
│   │   ├── FKSelectionControlMotionConfiguration.swift
│   │   ├── FKSelectionControlAccessibilityConfiguration.swift
│   │   ├── FKSelectionControlDefaults.swift
│   │   ├── FKCheckboxStateAggregator.swift
│   │   └── FKSelectionListChrome.swift
│   ├── Checkbox/
│   ├── Radio/
│   └── Bridge/
├── Internal/
│   ├── Shared/
│   │   ├── FKSelectionIndicatorView.swift
│   │   ├── FKSelectionControlMetrics.swift
│   │   ├── FKSelectionControlTintResolver.swift
│   │   ├── FKSelectionAttributedTextView.swift
│   │   └── FKSelectionRowLayout.swift
│   ├── Checkbox/
│   └── Radio/
└── Extension/   # optional builders
```

`Package.swift` `exclude:` README。**不**放入 `Widgets/`。

---

## 20. 模块内分阶段交付

| Phase | 范围 | Gate |
|-------|------|------|
| **S0** | Shared metrics / tint / indicator + README 骨架 | 编译 |
| **S1** | `FKCheckbox` 五态 + sizes + tints + title + disabled | checkbox 基础 Examples |
| **S2** | `FKRadioButton` + `FKRadioGroup` insetGrouped/plain | Radio 设计稿对齐 |
| **S3** | error、协议链接、聚合、`FKSelectionListChrome`、option image、trailing edge | §21 增强场景 |
| **S4** | SwiftUI Bridge + horizontal + 滚动裁切 | Bridge Examples |

禁止无障碍缺失的「半成品完成」。

---

## 21. FKKitExamples 场景

Hub：`FKKitExamples → FKUIKit → SelectionControl`。

### 21.1 Checkbox

| 场景 ID | 覆盖 |
|---------|------|
| `checkbox.states` | 五态 |
| `checkbox.sizes` | SM / MD / LG |
| `checkbox.tints` | 五色 |
| `checkbox.list` | IN LIST + `FKSelectionListChrome` |
| `checkbox.indicatorOnly` | |
| `checkbox.indeterminateTap` | promote / cycle |
| `checkbox.programmatic` | setState / toggle |
| `checkbox.error` | showsError |
| `checkbox.agreement` | 富文本链接 + required |
| `checkbox.selectAll` | 父半选聚合 |
| `checkbox.readOnly` | |
| `checkbox.trailingIndicator` | |
| `checkbox.customGlyph` | |

### 21.2 Radio

| 场景 ID | 覆盖 |
|---------|------|
| `radio.button.states` | 四态 |
| `radio.button.sizes` / `tints` | |
| `radio.group.insetGrouped` | 周期列表（英文） |
| `radio.group.plain` / `horizontal` | |
| `radio.group.disabledOption` | |
| `radio.group.allowsDeselection` | |
| `radio.group.images` | |
| `radio.group.subtitle` | |
| `radio.group.error` | |
| `radio.group.headerFooter` | |
| `radio.trailingIndicator` | |

Examples **English only**。

---

## 22. 验收清单

**视觉**

- [ ] 设计稿五态 / 四态；16/22/28；§13 Token
- [ ] 五色 tint；error / pressed / disabled
- [ ] RadioGroup insetGrouped；ListChrome
- [ ] Disabled 标题灰化

**行为**

- [ ] 切换、半选、聚合、链接不误触切换
- [ ] RadioGroup 互斥与空选策略
- [ ] readOnly / disabled 不发切换事件
- [ ] 热区 ≥ 44；RTL；Reduce Motion

**工程**

- [ ] 英文 `///`、README、Examples §21
- [ ] `exclude:` + BUILD SUCCEEDED
- [ ] Swift 6 严格并发；无第三方依赖

---

## 23. 待决问题

| ID | 问题 | 倾向 |
|----|------|------|
| Q1 | 公开 `FKSelectionListChrome`？ | **是（v1）** |
| Q2 | 勾号 Symbol 还是贝塞尔？ | Symbol 优先 |
| Q3 | indeterminate 时 `isSelected` | **false** |
| Q4 | 与 FormControls 目录合并 | 先独立 SelectionControl |
| Q5 | Theme token | v1 预设色 |
| Q6 | 公开 `AttributedString`？ | **是** |
| Q7 | RadioGroup VoiceOver adjustable | v1 加分 |
| Q8 | `FKCheckboxGroup` 自动同步 | **v1.1** |

---

## 24. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-08-14 | 初稿：设计稿对齐；SelectionControl |
| 2026-08-14 | 增补：错误态、协议链接、全选聚合、选项图标、副标题、按压反馈、readOnly、trailing 指示器、度量 Token、ListChrome、ListKit、边界情况、模块内分期、Examples/验收扩展 |
| 2026-08-14 | 移除设计截图文件；规格改为正文文字描述，不在仓库保存参考图 |
