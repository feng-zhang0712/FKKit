# FKSearchBar 与 FKSearchField — 设计需求文档

FKKit **搜索输入控件**的实现指导文档：可配置的 **`FKSearchBar`**（基于 `UIControl`）与可选紧凑型 **`FKSearchField`**，支持防抖文本事件、清除/取消 affordance，以及与 **FKDebouncer**、**FKListKit**、**FKEmptyState** 的集成。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.3  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 产品划分：FKSearchBar vs FKSearchField](#4-产品划分-fksearchbar-vs-fksearchfield)
- [5. 架构总览](#5-架构总览)
- [6. 视觉样式与布局模式](#6-视觉样式与布局模式)
- [7. 文本输入与键盘行为](#7-文本输入与键盘行为)
- [8. 防抖与事件模型](#8-防抖与事件模型)
- [9. 清除按钮 — 规则与行为](#9-清除按钮--规则与行为)
- [10. 取消按钮 — 规则与行为](#10-取消按钮--规则与行为)
- [11. 提交与 Return 键](#11-提交与-return-键)
- [12. 焦点、编辑与编程式文本](#12-焦点编辑与编程式文本)
- [13. 加载与进度态](#13-加载与进度态)
- [14. 外观与主题](#14-外观与主题)
- [15. 配置模型](#15-配置模型)
- [16. 回调与 Delegate API](#16-回调与-delegate-api)
- [17. 导航栏与工具栏承载](#17-导航栏与工具栏承载)
- [18. 与 FKListKit、FKEmptyState 集成](#18-与-fklistkitfkeemptystate-集成)
- [19. 无障碍](#19-无障碍)
- [20. SwiftUI 桥接](#20-swiftui-桥接)
- [21. 全局默认值](#21-全局默认值)
- [22. 性能与线程](#22-性能与线程)
- [23. 建议源码目录结构](#23-建议源码目录结构)
- [24. FKKitExamples 场景](#24-fkkitexamples-场景)
- [26. 待决问题](#26-待决问题)
- [27. 修订历史](#27-修订历史)

---

## 1. 概述

搜索是 iOS 应用最高频的 UI 模式之一（电商 catalog、社交、设置、消息）。FKKit 已有强大的 **`FKTextField`** 用于表单，但**缺少专用搜索控件**，无法开箱提供：

- 列表筛选的防抖 query 流
- 导航搜索的取消/结束编辑流程
- 针对搜索场景调优的清除按钮规则
- 导航栏/行内统一 FK 视觉语言

本设计交付：

| 类型 | 职责 |
|------|------|
| **`FKSearchBar`** | 全功能搜索：Leading 搜索图标、文本框、清除、可选取消、防抖回调、加载指示、导航/行内布局。 |
| **`FKSearchField`** | 紧凑变体：图标 + 字段 + 清除，**无**取消列 — 用于内容区嵌入式筛选。 |

二者均为 **`UIControl`**（或暴露 `UIControl` 事件的组合根），基于 **`UITextField`** 构建，**非** `UISearchBar` 薄封装，以保持 FKKit 样式自由度。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **覆盖 90% 搜索 UX** — 导航栏搜索、行内筛选、navigation `titleView`。
2. **内置防抖** — 使用 **`FKDebouncer`**（`FKCoreKit/Async`），间隔可配，可选即时预览。
3. **明确事件分类** — 文本变更（原始/防抖）、提交、取消、清除、开始/结束编辑。
4. **HIG 合规** — 最小 44pt 高度、Dynamic Type、VoiceOver、深色模式、RTL。
5. **可组合** — 独立使用、嵌入 `UINavigationItem`、配合 `FKDiffableTableViewController` 与 `FKEmptyState` 无结果场景。
6. **不并入 `FKTextField`** — 搜索专用取消语义与防抖默认值保持独立。

### 2.2 非目标（v1）

| 排除项 | 说明 |
|--------|------|
| 语音搜索 / Speech | 未来可选附件 |
| `UISearchController` 封装 | 宿主可单独使用系统 API |
| 搜索建议下拉 /  autocomplete UI | 宿主或未来 `FKSearchSuggestions` |
| 最近搜索持久化 | 宿主层（`FKStorage`） |
| 扫码 Leading 动作 | 不在范围 |
| Scope 条（搜索框下分段） | 第二阶段；可用 `FKSegmentedControl` |
| macOS / tvOS | 仅 iOS 15+ UIKit |

### 2.3 成功标准

- [ ] `FKSearchBar` + `FKSearchField` 分层配置 + 英文文档。
- [ ] 快速输入合并为一次防抖回调。
- [ ] 取消：按配置清空/恢复 + 失焦 + 触发 cancel。
- [ ] 导航栏嵌入在 SE / Pro Max、浅深色下布局正确。
- [ ] SwiftUI `FKSearchBarRepresentable` 与 Binding 双向同步无环路。
- [ ] FKKitExamples 覆盖 §24 全部场景。

---

## 3. 背景与问题陈述

### 3.1 为何不用 `FKTextField`？

`FKTextField` 面向：

- 校验、格式化、错误文案、OTP、计数、密码切换
- 表单装饰（边框、下划线）

搜索需要不同默认：

| 关注点 | 表单（`FKTextField`） | 搜索（`FKSearchBar`） |
|--------|----------------------|------------------------|
| 自动大写 | 视场景 | 默认 **关** |
| 自动更正 | 常开 | 默认 **关** |
| Return | `.done` / `.next` | 默认 **`.search`** |
| 尾部控件 | 编辑时清除 | 清除 + **取消列** |
| 变更频率 | 每键可接受 | **防抖** 筛列表/调 API |
| 取消语义 | 无 | 失焦 + 可选恢复文本 |

合并会膨胀 `FKTextFieldConfiguration` 并混淆集成方。

### 3.2 为何不封装 `UISearchBar`？

- 各 iOS 版本内部子视图样式难统一
- 难与 `FKButton` / `FKCornerShadow` / 材质模糊对齐
- Delegate 模型不利于「原始 + 防抖」双流

FKKit 采用 **容器 + `UITextField`** — 与多数生产 App 一致。

### 3.3 现有复用点

| API | 模块 | 搜索中的用途 |
|-----|------|--------------|
| `FKDebouncer` | FKAsync | 防抖 `searchQueryChanged` |
| Clear 配置模式 | FKTextField | 清除按钮 a11y/文案 |
| `FKCornerShadow` / `FKBlurView` | FKUIKit | 可选条背景 |
| `FKUIKitI18n` | FKUIKit | 取消/清除/搜索提示 |
| `FKEmptyState` `.noSearchResult` | FKUIKit | 文档化配对 |

### 3.4 FKCoreKit 复用要求（强制）

SearchBar/SearchField **必须**使用 **`FKDebouncer`**（`FKCoreKit/Components/Async`）实现防抖；**禁止**自写 `Timer` 防抖。查询规范化、trim 使用 **`String.fk_trimmed`** 等 Extension。详见 [COMPONENT_ROADMAP.zh-CN.md — 勿重复造轮子](COMPONENT_ROADMAP.zh-CN.md#勿重复造轮子--复用对照表)。

---

## 4. 产品划分：FKSearchBar vs FKSearchField

### 4.1 FKSearchBar（主控件）

| 元素 | 包含 |
|------|------|
| Leading 搜索图标 | ✓（可隐藏/自定义） |
| `UITextField` | ✓ |
| 清除按钮 | ✓ |
| 取消按钮 | ✓（可见性可配） |
| 加载指示 | ✓ |
| 原始 + 防抖事件 | ✓ |
| 导航布局辅助 | ✓ |

### 4.2 FKSearchField（紧凑）

| 元素 | 包含 |
|------|------|
| Leading 搜索图标 | ✓ |
| 文本框 | ✓ |
| 清除 | ✓ |
| 取消 | **✗**（用清除重置） |
| 加载 | 可选 |
| 防抖 | ✓ |

**实现说明：** 内部可共享 `FKSearchInputCoordinator`；公开类型保持独立。

### 4.3 文档命名

- 导航搜索、取消流程 → **`FKSearchBar`**
- 行内/筛选 → **`FKSearchField`**
- 模块目录：`SearchBar/`

---

## 5. 架构总览

```text
┌─────────────────────────────────────────────────────────────┐
│ FKSearchBar（UIControl，@MainActor）                          │
│  ┌──────────┐ ┌─────────────────────┐ ┌───────┐ ┌────────┐ │
│  │ 搜索图标 │ │ UITextField         │ │ 清除  │ │ 取消   │ │
│  └──────────┘ └─────────────────────┘ └───────┘ └────────┘ │
│                         │                                     │
│              FKSearchInputCoordinator                         │
│                · FKDebouncer                                  │
│                · 编程设文事件门控                             │
│                · loading 态                                   │
└─────────────────────────────────────────────────────────────┘
                             │
           原始/防抖/提交/取消/清除
                             ▼
              宿主（筛列表、API、FKListKit）
```

---

## 6. 视觉样式与布局模式

### 6.1 布局预设（`FKSearchBarLayoutStyle`）

| 预设 | 说明 | 典型位置 |
|------|------|----------|
| `.navigationBar` | 激活时展开；聚焦显示取消 | `navigationItem.titleView` |
| `.inlineCard` | 全宽圆角条，固定高度 | 导航下、Table 上 |
| `.compactToolbar` | 更矮、更紧 | 工具栏、Bottom Sheet |
| `.minimal` | 无外壳；可选下划线 | 密集管理界面 |

### 6.2 FKSearchBar 结构

```text
[ 搜索图标 | 文本框(flex) | 加载? | 清除? | 取消? ]
```

**必须支持：**

| 能力 | 要求 |
|------|------|
| 最小高度 | **44pt**（含可点区域） |
| 水平内边距 | 可配置 |
| 胶囊圆角 | `.inlineCard` 默认 `height/2` |
| 图标间距 | 默认 8pt |
| 取消宽度 |  intrinsic + 内边距；支持长文案语言 |
| 导航宽度 | 可压缩；文本尾部省略 |

### 6.3 FKSearchField 结构

```text
[ 搜索图标 | 文本框(flex) | 加载? | 清除? ]
```

### 6.4 RTL

**必须**镜像 Leading/Trailing 与取消位置；搜索图标在 RTL 下位于语义 trailing。

### 6.5 宽度与安全区

- 行内：对齐 Safe Area / readable content guide
- 导航：`sizeThatFits` 辅助；宽度 ≤ 导航栏可用宽度

---

## 7. 文本输入与键盘行为

### 7.1 UITextField 默认（规范）

| 特性 | FKSearchBar | FKSearchField |
|------|-------------|---------------|
| `autocorrectionType` | `.no` | `.no` |
| `autocapitalizationType` | `.none` | `.none` |
| `spellCheckingType` | `.no` | `.no` |
| `smartQuotesType` | `.no` | `.no` |
| `returnKeyType` | `.search` | `.search` |
| `keyboardType` | `.default` | `.default` |
| 系统 clearButtonMode | `.never` | `.never` |

均可通过 `FKSearchTextInputTraitsConfiguration` 覆盖。

### 7.2 文本规范化

```swift
public enum FKSearchTextNormalization: Sendable, Equatable {
  case none
  case trimWhitespaceAndNewlines
  case collapseInternalWhitespace
  case maxLength(Int)
}
```

在防抖 emit 与 submit 前应用（若配置）。

### 7.3 安全输入

不支持 `isSecureTextEntry`（Debug assert）。

---

## 8. 防抖与事件模型

### 8.1 FKDebouncer

内部：

```swift
private let debouncer: FKDebouncer
```

| 配置项 | 默认 | 用途 |
|--------|------|------|
| `debounceInterval` | `0.35` s | 静默期 |
| `isDebounceEnabled` | `true` | false 则直通 |
| `debounceQueue` | `.main` | 执行队列 |

### 8.2 事件通道

| 事件 | 触发时机 | 防抖？ |
|------|----------|--------|
| **`textChanged`** | 每次 `editingChanged` | 否 |
| **`searchQueryChanged`** | 防抖静默后 | 是 |
| **`submit`** | Return `.search` | 否（立即） |
| **`clear`** | 点清除 | 否 |
| **`cancel`** | 点取消 | 否 |
| **`editingDidBegin` / `End`** | 焦点变化 | 否 |

```swift
public struct FKSearchBarCallbacks {
  public var onTextChanged: (@MainActor (String) -> Void)?
  public var onSearchQueryChanged: (@MainActor (String) -> Void)?
  public var onSubmit: (@MainActor (String) -> Void)?
  public var onClear: (@MainActor () -> Void)?
  public var onCancel: (@MainActor () -> Void)?
  public var onEditingDidBegin: (@MainActor () -> Void)?
  public var onEditingDidEnd: (@MainActor () -> Void)?
}
```

### 8.3 合并规则

**必须：**

- 每键重置 debouncer 计时；
- `deinit` 取消 pending；
- `setText(..., suppressEvents: true)` 不触发回调；
- 清除：`flushDebounceOnClear` 默认 **true**，立即 emit 空 query。

### 8.4 最小 query 长度

`minimumQueryLengthForSearchCallback` 默认 **0** — 未达长度仍 fire `textChanged`，跳过 `searchQueryChanged`。

---

## 9. 清除按钮 — 规则与行为

### 9.1 可见性（`FKSearchClearButtonVisibility`）

| 模式 | 显示条件 |
|------|----------|
| `.whileEditingNonEmpty` | 第一响应者且非空（**默认**） |
| `.whileNonEmpty` | 任意非空 |
| `.never` | 隐藏 |

### 9.2 点击行为

**必须：**

1. 文本置 `""`；
2. `onClear`；
3. 原始 `textChanged("")`；
4. 按配置 flush 防抖；
5. `clearResignsFirstResponder` 默认 **false**；
6. 可选 VoiceOver「已清除」。

### 9.3 外观

- 默认 SF Symbol `xmark.circle.fill`；
- 最小点击区 44×44pt；
- i18n：`fkuikit.search.clear_label`。

---

## 10. 取消按钮 — 规则与行为

*（仅 FKSearchBar）*

### 10.1 可见性（`FKSearchCancelButtonVisibility`）

| 模式 | 行为 |
|------|------|
| `.whileEditing` | 聚焦前隐藏（**导航默认**） |
| `.always` | 常显 |
| `.never` | 隐藏（行内模式） |

### 10.2 点击行为

**必须：**

1. `onCancel`；
2. 按 `FKSearchCancelPolicy`：
   - `.clearAndResign` — 清空 + 失焦（**导航默认**）
   - `.resignOnly` — 保留文本
   - `.revertAndResign` — 恢复 `textAtEditingBegin` + 失焦
3. 隐藏取消（`.whileEditing` 模式）；
4. 取消 debouncer pending。

### 10.3 标题

- 默认 `FKUIKitI18n` cancel；
- 可配置 `cancelButtonTitle`。

### 10.4 动画

取消显隐宽度动画 0.25s；Reduce Motion →  instant。

---

## 11. 提交与 Return 键

### 11.1 Return `.search`

**必须：**

1. 规范化文本；
2. `onSubmit`；
3. **立即 flush** `searchQueryChanged`；
4. `submitResignsFirstResponder` 默认 **false**（筛选 UX）；目录式可设 true。

### 11.2 空提交

`allowsEmptySubmit` 默认 **false** — 空串忽略 submit。

---

## 12. 焦点、编辑与编程式文本

```swift
public var text: String { get set }
public var isEditing: Bool { get }
public func setText(_ text: String, options: FKSearchTextUpdateOptions)

public struct FKSearchTextUpdateOptions: Sendable, Equatable {
  public var suppressEvents: Bool
  public var triggerSearchQueryChanged: Bool
}
```

`editingDidBegin` 保存 `textAtEditingBegin` 供 `.revertAndResign`。

---

## 13. 加载与进度态

| 模式 | UI |
|------|-----|
| `.none` | 默认 |
| `.activityIndicator` | 尾部菊花；loading 时可隐藏 clear |
| `.disabledInput` | 禁用输入 + 菊花 |

```swift
func setLoading(_ isLoading: Bool, animated: Bool)
```

Loading 不阻塞取消（用户可中止搜索）。

---

## 14. 外观与主题

### 14.1 分层外观

- 背景色 / 材质（`FKBlurView`）/ 圆角 / 边框
- Leading 图标、正文/占位字阶
- Tint、取消标题样式
- 状态：normal / focused / disabled / loading

### 14.2 深色模式

- 默认背景 `.secondarySystemBackground` 或 `.tertiarySystemFill`
- Examples 验证浅/深

### 14.3 Dynamic Type

- `UIFontMetrics` 缩放；
- `growsWithDynamicType` 默认 **true**；XL+ 可增高，仍 ≥ 44pt。

---

## 15. 配置模型

```swift
public struct FKSearchBarConfiguration: Sendable, Equatable {
  public var layout: FKSearchBarLayoutConfiguration
  public var appearance: FKSearchBarAppearanceConfiguration
  public var textInput: FKSearchTextInputTraitsConfiguration
  public var debounce: FKSearchDebounceConfiguration
  public var clearButton: FKSearchClearButtonConfiguration
  public var cancelButton: FKSearchCancelButtonConfiguration
  public var loading: FKSearchLoadingConfiguration
  public var submit: FKSearchSubmitConfiguration
  public var accessibility: FKSearchAccessibilityConfiguration
}

public enum FKSearchBarDefaults {
  public static var defaultConfiguration: FKSearchBarConfiguration
  public static func navigationBar() -> FKSearchBarConfiguration
  public static func inlineCard() -> FKSearchBarConfiguration
}
```

`FKSearchFieldConfiguration` 无 `cancelButton`；共享类型放 `SearchBar/Shared/`。

---

## 16. 回调与 Delegate API

```swift
@MainActor
public protocol FKSearchBarDelegate: AnyObject { ... }
```

协议方法可选。**callbacks 为主，delegate 为辅** — 避免双发；文档说明 precedence。

---

## 17. 导航栏与工具栏承载

```swift
public enum FKSearchBarNavigationHosting {
  public static func install(
    _ searchBar: FKSearchBar,
    in navigationItem: UINavigationItem,
    placeholder: String? = nil
  )
}
```

**必须：** 正确 `sizeThatFits`；README 给出宽度约束示例。

大标题模式：Examples 演示行内/search 区布局（非 `UISearchController` 必选）。

---

## 18. 与 FKListKit、FKEmptyState 集成

### 18.1 筛选配方（规范）

```swift
searchBar.callbacks.onSearchQueryChanged = { query in
  listVC.applySnapshot(filteredSnapshot(query), animatingDifferences: true)
}
```

query 非空且结果为空 → `FKEmptyStateConfiguration.scenario(.noSearchResult)`。

### 18.2 空态

搜索模块**不内嵌** EmptyState — 宿主在 Table 上驱动。

### 18.3 外置防抖

可关闭内置防抖，仅用 `textChanged` + 外部 `FKDebouncer`。

---

## 19. 无障碍

| 元素 | 要求 |
|------|------|
| 输入框 | label 来自 placeholder 或显式配置 |
| 搜索图标 | 装饰则 hidden，或并入 label |
| 清除/取消 | 本地化 accessibilityLabel |
| Trait | iOS 13+ `.searchField` |
| Reduce Motion | 取消动画 instant |

---

## 20. SwiftUI 桥接

`FKSearchBarRepresentable` / `FKSearchFieldRepresentable`：

- `Binding<String>` 同步用 `suppressEvents` 防环路；
- `isLoading` → `setLoading`。

---

## 21. 全局默认值

```swift
FKSearchBarDefaults.defaultConfiguration.debounce.debounceInterval = 0.5
```

启动时一次性修改（对齐 `FKBlurView.defaultConfiguration` 模式）。

---

## 22. 性能与线程

- 公开 API：`@MainActor`；
- 防抖默认主队列；
- 大列表筛选：宿主负责后台过滤 + 主线程 apply snapshot。

---

## 23. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

```text
Sources/FKUIKit/Components/SearchBar/
├── README.md
├── Public/
│   ├── FKSearchBar.swift
│   ├── FKSearchField.swift
│   ├── Configuration/...
│   ├── Callbacks/...
│   ├── Hosting/...
│   └── Bridge/...
├── Internal/
│   ├── FKSearchInputCoordinator.swift
│   ├── FKSearchBarLayoutEngine.swift
│   └── FKSearchBarChromeView.swift
└── Extension/
```

`Package.swift` `readmeExcludes` 增加 `Components/SearchBar`。

---

## 24. FKKitExamples 场景

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `DebouncedFilter` | 防抖 + 间隔切换 |
| 2 | `SubmitOnReturn` | 回车提交 |
| 3 | `NavigationBarSearch` | titleView + 取消 |
| 4 | `InlineCard` | 行内圆角条 |
| 5 | `FKSearchFieldCompact` | 无取消紧凑版 |
| 6 | `LoadingSearch` | 异步 loading |
| 7 | `EmptyNoResults` | FKEmptyState 无结果 |
| 8 | `FKListKitIntegration` | 列表联动 |
| 9 | `SwiftUIHost` | Representable |
| 10 | `DarkDynamicType` | 深色 + 大字号 |

---

## 26. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 目录 `SearchBar/` vs `Search/`？ | `SearchBar/` |
| Q2 | 仅 callbacks 还是双 API？ | 双 API；callbacks 为主 |
| Q3 | 取消/清除用 `FKButton`？ | v1 `UIButton` |
| Q4 | 内置最近搜索？ | 延后 |
| Q5 | 只用公开 UITextField？ | 是 |

---

## 27. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.3 |

---

## 相关文档

- [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md) — 列表筛选集成
- [TextField README](../Sources/FKUIKit/Components/TextField/README.md)
- [FKDebouncer](../Sources/FKCoreKit/Components/Async/DebounceThrottle/Debouncer.swift)
