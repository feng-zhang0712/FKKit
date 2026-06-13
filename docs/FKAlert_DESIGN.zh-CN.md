# FKAlert — 设计需求文档

FKKit **`FKAlert`** 的实现指导文档：基于 **`FKSheetPresentationController`**（`.center` 模式）的**自定义居中确认框**，在保留 Alert 语义（标题、正文、按钮、可选输入）的同时，替代 `UIAlertController` 的样式与能力限制。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 已实现（v1，活文档 — 与 `Sources/FKUIKit/Components/Alert/` 对齐）  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.5  
**组件 README：** [Alert README](../Sources/FKUIKit/Components/Alert/README.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 组件边界](#5-组件边界)
- [6. 内容模型](#6-内容模型)
- [7. 操作按钮与样式](#7-操作按钮与样式)
- [8. 文本输入变体](#8-文本输入变体)
- [9. 危险操作模式](#9-危险操作模式)
- [10. 展示与 Sheet 集成](#10-展示与-sheet-集成)
- [11. 队列、堆叠与去重](#11-队列堆叠与去重)
- [12. 公开 API](#12-公开-api)
- [13. FKBusinessAlertManager 迁移](#13-fkbusinessalertmanager-迁移)
- [14. 配置模型](#14-配置模型)
- [15. 生命周期与关闭](#15-生命周期与关闭)
- [16. 键盘与焦点](#16-键盘与焦点)
- [17. 无障碍](#17-无障碍)
- [18. 动效与触觉](#18-动效与触觉)
- [19. SwiftUI 桥接](#19-swiftui-桥接)
- [20. 安全与内容](#20-安全与内容)
- [21. 源码目录结构（已实现）](#21-源码目录结构已实现)
- [22. FKKitExamples 场景](#22-fkkitexamples-场景)
- [23. 已知限制与后续演进](#23-已知限制与后续演进)
- [27. 设计决策记录](#27-设计决策记录)
- [28. 修订历史](#28-修订历史)

---

## 1. 概述

居中 Alert 用于**破坏性确认**、**阻塞式错误**、**重命名提示**、**合规确认**等。FKKit 在 v1 前：

| 现有能力 | 角色 | 缺口（v1 前） |
|----------|------|--------------|
| **`FKBusinessAlertManager`** | `UIAlertController` + `presentOnce` | 非 FK 样式；布局受限 |
| **`FKActionSheet`** | 底部表 / Action Sheet 迁移 | 不适合居中确认 + 紧凑输入 |
| **`FKSheetPresentationController.centerAlert`** | 展示基础设施 | 无 Alert 内容组装 |

**`FKAlert`**（`Sources/FKUIKit/Components/Alert/`）已交付：

| 交付物 | 职责 |
|--------|------|
| **`FKAlertContent`** | Sendable 声明式内容 |
| **`FKAlertAction`** | 复用 **FKCoreKit** BusinessKit 描述符 |
| **`FKAlertViewController`** | 标题、正文、图标、可选 `FKTextField`、勾选行、按钮列 |
| **`FKAlertPresenter`** | `present` / `presentOnce` / `dismiss` / `setLoading` |
| **`FKAlertCoordinator`** | 队列、`presentOnce(id:)`、堆叠策略、handler 时序 |
| **`FKAlertConfiguration`** | 视觉 + 交互 + 队列 + Sheet 策略 |
| **`FKAlertPresets`** | `destructiveConfirm` / `informational` / `textPrompt` |
| **`FKAlertModifier`** | SwiftUI `View.fkAlert` |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **FK 视觉语言** — `FKButton` 主/次/破坏性；间距与 `FKActionSheet` 头部一致（**不**复用 ActionSheet 行渲染器）。
2. **居中模态** — 默认 `FKSheetPresentationConfiguration.centerAlert`；高度随内容适配（`preferredContentSizePolicy = .strict`）。
3. **按钮组** — 最多 3 个可见操作（主、次、取消/破坏性），符合 HIG 顺序。
4. **可选单行输入** — 嵌入 `FKTextField`（重命名、短反馈）。
5. **危险操作 UX** — 破坏性强调；可选 `UISwitch` 确认门控。
6. **队列 / 去重** — 移植 `FKBusinessAlertManager.presentOnce`；可选 FIFO 队列。
7. **`async` API** — `await FKAlertPresenter.present(...)` / `FKAlert.confirm` / `FKAlert.prompt`。
8. **无障碍** — VoiceOver 顺序、键盘、Dynamic Type。
9. **不重复** `FKActionSheet` 行/分区 UI — Alert 仅为**纵向按钮列**布局（可选 `horizontalPair`）。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 底部操作表 UI | 用 `FKActionSheet` |
| 多行文本域 Alert | 自定义 Sheet + `FKCountTextView` |
| 任意 `UIView` / SwiftUI 自定义内容区 | v2+ 评估 |
| 覆盖所有 `UIAlertController` 场景 | 文档说明迁移边界 |
| Toast / 横幅 | `FKToast` |
| Alert 内多步向导 | 宿主自行导航 VC |
| macOS / Catalyst | 仅 iOS 15+ UIKit |

### 2.3 成功标准（v1 验收）

- [x] 删除确认破坏性按钮符合 FK 样式（Examples：`Destructive delete`）。
- [x] 带输入框 Alert 在主按钮点击时返回 trim 后字符串（`FKAlert.prompt` / `FKAlertResult`）。
- [x] `presentOnce(id:)` 展示期间抑制重复（Examples：`Present once`）。
- [x] 队列中第二条在第一条关闭后出现（Examples：`Queued alerts` · `singleActive`）。
- [x] 勾选门控破坏性按钮在未勾选前禁用（Examples：`Checkbox-gated delete`）。
- [x] README 含与 ActionSheet / Toast / BusinessAlertManager 选型树。
- [ ] 根 README 索引与 CHANGELOG 发版条目（发版时补齐）。

---

## 3. 背景与问题陈述

### 3.1 `FKBusinessAlertManager` 局限

当前实现仅包装系统 `UIAlertController`：

- 无法统一 `FKButton` 与圆角。
- 输入框样式与 `FKTextField` 不一致。
- 有 `presentOnce` 去重，但无队列与样式化替换路径。

### 3.2 `FKActionSheet` 边界

`FKActionSheet+AlertMigration` 将 **Action Sheet 风格**映射为**底部** Sheet — 适合「选择来源」，不适合「删除账户？」。

**规范划分（路线图 R6）：**

| 模式 | 组件 |
|------|------|
| 底部操作列表 | `FKActionSheet` |
| 居中阻塞确认 | **`FKAlert`** |
| 非阻塞短提示 | `FKToast` |

### 3.3 已有展示预设

`centerAlert` 提供居中 dim 背景、键盘避让与下滑关闭。FKAlert 默认在 `FKAlertActionResolver.makeDefaultSheet()` 上微调：

- 布局：`.center`，`size = .fitted(maxSize: CGSize(width: 320, height: 680))`
- `preferredContentSizeReporting = .contentOnly`
- `preferredContentSizePolicy = .strict`
- 默认 `allowsBackdropTap = false`（可通过 `FKAlertPresentationConfiguration` 覆盖）

含 `dangerousAction` 时：**强制**禁止背景点击与下滑关闭。

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 App                                                        │
│  FKAlertPresenter.present(content:from:)                         │
│  FKAlert.confirm / FKAlert.prompt                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertCoordinator（@MainActor）                                │
│  按 id 去重 │ FIFO 队列 │ activeSessions │ handler 时序         │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertActionResolver（internal）                               │
│  空 actions → OK │ 3 按钮裁剪 │ 角色排序 │ Sheet 配置解析       │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertViewController + FKAlertContentView                      │
│  图标 / 标题 / 正文(可滚动) / FKTextField? / UISwitch? / 按钮   │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKSheetPresentationController（.center / centerAlert）          │
│  背景 │ 键盘 │ 生命周期 │ 关闭手势                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 组件边界

| 关注点 | FKAlert | FKActionSheet | FKBusinessAlertManager |
|--------|---------|---------------|------------------------|
| 布局 | 纵向按钮栈（可选横向双按钮） | 分区 + 行 | 系统 Alert |
| 位置 | 居中 | 底部 / Popover | 系统居中 |
| 输入 | 单行 `FKTextField` | 有限行类型 | UIAlert 字段 |
| 去重 | `presentOnce` | 独立 | 现有 `presentOnce` |
| 模块 | FKUIKit | FKUIKit | FKCoreKit |

依赖：`FKSheetPresentationController`、`FKButton`、`FKTextField`、`FKCoreKit`（`FKAlertAction`、`FKI18n` / `FKUIKitI18n`）。

### 5.1 FKCoreKit 复用要求（强制）

| 能力 | 必须使用（FKCoreKit） | 禁止 |
|------|----------------------|------|
| Alert 操作模型 | **`FKAlertAction`**（BusinessKit） | 在 FKUIKit 重复定义 Action |
| 本地化 | **`FKI18n`** / **`FKUIKitI18n`** | 硬编码按钮文案 |
| 队列/去重 | 参考 **`FKBusinessAlertManager`** 模式 | 无 id 的重复弹窗 |

Alert **不得**复制 **`FKActionSheet`** 行渲染器；仅复用 Sheet **center** 展示基础设施。

---

## 6. 内容模型

### 6.1 核心内容

```swift
public struct FKAlertContent: Sendable {
  public var id: String?
  public var title: String?
  public var message: String?
  public var attributedMessage: Data?   // NSKeyedArchiver 归档的 NSAttributedString
  public var icon: FKAlertIcon?
  public var actions: [FKAlertAction] // FKCoreKit BusinessKit
  public var textInput: FKAlertTextInput?
  public var dangerousAction: FKAlertDangerousActionOptions?
  public var accessibilityIdentifier: String?
}
```

> **说明：** `FKAlertContent` 不含 `Equatable`（`FKAlertAction` 含 handler 闭包）。`FKAlertDangerousActionOptions` 为 `Equatable`。

### 6.2 图标（可选）

`FKAlertIcon`：`.none` / `.systemName(_:tint:)` / `.asset(name:bundle:)`。  
`FKAlertIconTint`：`.primary` / `.warning` / `.destructive`。

### 6.3 正文渲染

- 标题：默认 `UIFont.TextStyle.headline`（可配置）
- 正文：默认 `body`；`attributedMessage` 存在时覆盖 `message`
- **自适应高度：** 正文未超出视口时内联展示；超出时正文区进入 `UIScrollView`（约 12 行视口，按屏高上限），**按钮区始终固定底部**

### 6.4 空内容规则

`title`、`message`、`attributedMessage`、`icon`、`textInput` 至少一项非空（Debug `assert`）；`actions` 为空时由 `FKAlertActionResolver` 注入默认 OK（`FKI18n` `"fkcore.common.ok"`）。

---

## 7. 操作按钮与样式

### 7.1 `FKAlertAction.Style` → `FKButton`

| Style | FKButton 角色 |
|-------|---------------|
| `.default` | 主或次（按位置） |
| `.cancel` | 次/幽灵；可单独最底行 |
| `.destructive` | 破坏性 |

### 7.2 纵向顺序（规范）

由 `FKAlertActionResolver.resolvedActions` 排序：

1. 可选图标  
2. 标题  
3. 正文  
4. 可选输入框 / 勾选行  
5. **主操作**（所有 `.default`）  
6. **破坏性**（全宽）  
7. **取消**（默认最底）

两按钮（取消 + 删除）：破坏性在取消上方。

### 7.3 数量上限

可见最多 **3** 个按钮；超出 Debug `assertionFailure` 并裁剪为：第一个 `.default` + `.destructive` + `.cancel`。

### 7.4 横向并排（可选）

`FKAlertButtonLayout.horizontalPair`：仅 **恰好 2 个非破坏性** 操作并排；v1 **禁止**破坏性横向并排。  
Examples：`Appearance & layout`。

### 7.5 禁用条件

主/破坏性在以下情况禁用：

- 文本校验未通过（§8）  
- 危险勾选未勾选（§9）  
- `FKAlertPresenter.setLoading(true)` 展示加载态  

---

## 8. 文本输入变体

### 8.1 模型

```swift
public struct FKAlertTextInput: Sendable {
  public var placeholder: String?
  public var initialText: String?
  public var isSecure: Bool
  public var keyboardType: UIKeyboardType
  public var textContentType: UITextContentType?
  public var autocapitalization: UITextAutocapitalizationType
  public var returnKeyType: UIReturnKeyType
  public var maxLength: Int?
  public var validation: FKAlertTextValidation?
}

public struct FKAlertTextValidation: Sendable {
  public var validate: @Sendable (String) -> Bool
  public var failureMessage: String?
}
```

校验失败时复用 `FKTextField` 内联错误展示；**不关闭** Alert。

### 8.2 集成

- v1 仅单行 `FKTextField`  
- `FKAlertTextFieldConfiguration.usesCompactPreset = true`（默认）→ 约 40pt 紧凑高度  
- 展示后约 **0.1s** 自动聚焦（等转场结束，`Task.sleep`）

### 8.3 返回值

```swift
public enum FKAlertResult: Sendable, Equatable {
  case action(index: Int, action: FKAlertActionSnapshot, text: String?)
  case cancelled
  case dismissed
}

public struct FKAlertActionSnapshot: Sendable, Equatable {
  public let title: String
  public let style: FKAlertAction.Style
}
```

`FKAlertActionSnapshot` 为无 handler 的值类型快照，供 `Equatable` 结果传递；原始 `FKAlertAction.handler` 在关闭动画完成后由 Coordinator 调用。

---

## 9. 危险操作模式

### 9.1 破坏性样式

- `FKButton` 破坏性预设  
- 可选顶部警告图标（`FKAlertIconTint.warning` / `.destructive`）  
- 正文由宿主写清后果；可用 `attributedMessage` 高亮关键词

### 9.2 确认勾选框

```swift
public struct FKAlertDangerousActionOptions: Sendable, Equatable {
  public var requiresConfirmationCheckbox: Bool
  public var checkboxTitle: String   // 默认 FKUIKitI18n
  public var destructiveActionIndex: Int?
}
```

未勾选时破坏性按钮 `isEnabled = false`。v1 控件：**`UISwitch`**（`FKAlertContentView.confirmationSwitch`）。

### 9.3 两步确认

v1 单 Alert + 勾选足够；两步连弹由宿主编排（Examples 可演示）。

### 9.4 误触防护

`FKAlertInteractionConfiguration.destructiveHandlerDelay`（默认 `0`）：破坏性 handler 在关闭动画后额外延迟执行。

---

## 10. 展示与 Sheet 集成

### 10.1 默认配置

```swift
public struct FKAlertPresentationConfiguration: Sendable {
  public var sheet: FKSheetPresentationConfiguration?  // nil → makeDefaultSheet()
  public var allowsBackdropTapToDismiss: Bool         // 默认 false
  public var allowsSwipeToDismiss: Bool               // 默认 false（紧凑 Alert 上 center 下滑难发现且与按钮竞争；informational 用背景点击）
  public var cornerRadius: CGFloat?
}
```

含 `dangerousAction` 时：**强制**禁止点背景关闭与下滑关闭（覆盖上述布尔值）。

### 10.2 Presenter

```swift
@MainActor
public final class FKAlertPresenter {
  public static let shared: FKAlertPresenter
  public weak var delegate: FKAlertDelegate?

  func present(_ content: FKAlertContent, from: UIViewController?, configuration: FKAlertConfiguration) async -> FKAlertResult
  func presentOnce(_ content: FKAlertContent, from: UIViewController?, configuration: FKAlertConfiguration) async -> FKAlertResult?
  func dismiss(animated: Bool)
  func setLoading(_ isLoading: Bool)
}
```

| 行为 | 说明 |
|------|------|
| `presentOnce` | 强制 `queue = .presentOnceByID`；同非空 `id` 已在展示 → 立即返回 `nil` |
| `from: nil` | 沿前台 key window 的 `presentedViewController` 链解析顶层 VC |
| `setLoading` | 当前可见 Alert 的主/破坏性按钮进入 `FKButton` loading 覆盖态并禁用 |

---

## 11. 队列、堆叠与去重

### 11.1 策略

```swift
public enum FKAlertQueuePolicy: Sendable, Equatable {
  case singleActive       // FIFO 等待
  case replaceCurrent     // 关掉当前再显示新的
  case allowStack         // 多层（不推荐）
  case presentOnceByID    // 同 id 跳过
}
```

| 策略 | 行为 |
|------|------|
| `singleActive` | 排队；前一条关闭后 `pumpQueue` |
| `replaceCurrent` | 不调用旧 handler，直接 `dismiss` 后展示新 Alert |
| `allowStack` | 允许多层 `activeSessions` |
| `presentOnceByID` | 同 BusinessKit `presentOnce` |

默认：`present` 用 **`singleActive`**；`presentOnce` 用 **`presentOnceByID`**。

### 11.2 Handler 调用顺序

**默认路径：** 按钮点击 → 校验通过 → 关闭动画 → `FKAlertDelegate.alertDidDismiss` → `continuation.resume` → 执行 `FKAlertAction.handler`。

**例外：** `interaction.dismissOnPrimaryAction == false` 且点击 **primary** 时 — 仅调用 handler，**不关闭** Alert（用于内联多步或异步校验后继续编辑）。

取消 / 背景 / 下滑 / `dismiss()`：**不**调用 action handler。

---

## 12. 公开 API

### 12.1 便捷构建

```swift
@MainActor
public enum FKAlert {
  static func confirm(title:message:confirmTitle:cancelTitle:isDestructive:from:configuration:) async -> Bool
  static func prompt(title:message:placeholder:confirmTitle:cancelTitle:from:configuration:) async -> String?
}
```

- `confirm` → 主/破坏性 action 返回 `true`，取消/关闭返回 `false`
- `prompt` → 默认 `FKAlertPresets.textPrompt()`；返回 trim 后文本或 `nil`

### 12.2 根配置

`FKAlertConfiguration` 字段：`presentation`、`appearance`、`interaction`、`textField`、`queue`、`buttonLayout`、`motion`、`accessibility`（详见 §14）。

### 12.3 预设

| 预设 | 用途 | 关键覆盖 |
|------|------|----------|
| `destructiveConfirm()` | 删除类 | 禁止背景/下滑关闭；破坏性触觉 |
| `informational()` | 单 OK | 允许背景关闭；**禁止**下滑（v1.1 调整：center 下滑在紧凑按钮栈上不可靠） |
| `textPrompt()` | 重命名 | 自动聚焦；禁止下滑关闭 |

---

## 13. FKBusinessAlertManager 迁移

### 13.1 共存（v1）

- BusinessKit **保留**系统 Alert 路径。  
- 预留 `FKBusinessAlertBackend`：`systemAlert` / `fkAlert`（**v1.1+**，尚未实现）。

### 13.2 映射

| BusinessKit | FKAlert |
|-------------|---------|
| `FKAlertAction` | **同一类型** |
| `presentOnce(...)` | `FKAlertPresenter.presentOnce(FKAlertContent(id:...))` |

### 13.3 长期方向

UI 应用推荐 `FKAlertPresenter`；`FKAlertAction` 继续留在 FKCoreKit 作共享模型。BusinessKit 后端开关待 v1.1 决策（见 §27 Q3）。

---

## 14. 配置模型

### 14.1 `FKAlertAppearanceConfiguration`

| 字段 | 默认 / 说明 |
|------|-------------|
| `titleTextStyle` / `messageTextStyle` | `.headline` / `.body` |
| `contentInsets` | 20pt 四边 |
| `bodyItemSpacing` | 8pt（图标/标题/正文/输入/勾选间距） |
| `actionSectionSpacing` | 20pt（正文区与按钮区间距） |
| `buttonSpacing` | 8pt |
| `iconSize` | 40pt |
| `maxMessageHeight` | `nil` → 约 12 行视口 + 屏高上限后正文滚动 |
| `titleColor` / `messageColor` / `backgroundColor` | `.label` / `.secondaryLabel` / `.systemBackground` |

### 14.2 `FKAlertInteractionConfiguration`

| 字段 | 默认 | 说明 |
|------|------|------|
| `autoFocusTextField` | `true` | 有 `textInput` 时延迟聚焦 |
| `dismissOnPrimaryAction` | `true` | `false` 时 primary 仅调 handler 不关闭 |
| `hapticOnDestructive` | `false` | 破坏性校验通过后 warning 触觉 |
| `destructiveHandlerDelay` | `0` | 关闭后 handler 额外延迟 |

### 14.3 其他子配置

- **`FKAlertTextFieldConfiguration`**：`usesCompactPreset`（默认 `true`）
- **`FKAlertMotionConfiguration`**：`respectsReduceMotion`（默认 `true`）→ Reduce Motion 时 Sheet 动画降为 `.fade`
- **`FKAlertAccessibilityConfiguration`**：`announcesOnPresent`（默认 `true`）；`destructiveHint`（默认 FKUIKitI18n）

---

## 15. 生命周期与关闭

```swift
@MainActor
public protocol FKAlertDelegate: AnyObject {
  func alertWillPresent(_ alert: FKAlertViewController)
  func alertDidDismiss(_ alert: FKAlertViewController, result: FKAlertResult)
}
```

- `alertWillPresent`：Sheet `present` 动画开始前  
- `alertDidDismiss`：关闭动画完成后（含 handler 调度之前 resume continuation）  
- iPad 宽度受 `centerAlert` fitted 宽度限制  
- Presenter / Coordinator 对 VC 弱引用；handler 由宿主持有，避免循环引用

**关闭来源与 `FKAlertResult`：**

| 来源 | 结果 |
|------|------|
| 取消按钮 | `.cancelled` |
| 主/破坏性按钮（默认） | `.action(...)` |
| 背景点击 / 下滑 / `dismiss()` | `.dismissed` |

---

## 16. 键盘与焦点

复用 Sheet **center 模式**键盘避让；输入类 Alert 随键盘上移。  
Return 键走主按钮校验路径（`validateTextInput`）。  
无输入时 `focusPreferredElement()` 聚焦标题。

---

## 17. 无障碍

- `announcesOnPresent`：出现时播报「标题. 正文」  
- 优先聚焦：输入框 > 标题  
- 破坏性按钮附加 `destructiveHint`（可配置）  
- 勾选 `UISwitch` 状态与破坏性启用关联  

Examples：`Accessibility`（VoiceOver 顺序、播报、hint）。

---

## 18. 动效与触觉

继承 Sheet 转场；`respectsReduceMotion` 时交叉淡入淡出。  
`hapticOnDestructive` + `FKAlertPresets.destructiveConfirm()` 可在破坏性确认时触发 warning 触觉。

---

## 19. SwiftUI 桥接

```swift
extension View {
  func fkAlert(
    isPresented: Binding<Bool>,
    content: FKAlertContent,
    configuration: FKAlertConfiguration = .init(),
    onResult: @escaping (FKAlertResult) -> Void
  ) -> some View
}
```

实现：`FKAlertModifier` + 透明 `UIViewControllerRepresentable` 锚点；`isPresented = false` 时取消 Task 并 `dismiss()`。  
对齐 `FKActionSheetModifier` 的 presenter 锚点模式。  
Examples：`SwiftUI bridge`。

---

## 20. 安全与内容

- 不记录安全输入框内容  
- 破坏性操作禁止自动定时关闭（v1）  

---

## 21. 源码目录结构（已实现）

```text
Sources/FKUIKit/Components/Alert/
├── README.md
├── Public/
│   ├── FKAlert.swift                 # confirm / prompt 便捷 API
│   ├── FKAlertPresenter.swift
│   ├── FKAlertViewController.swift
│   ├── FKAlertContent.swift
│   ├── FKAlertResult.swift
│   ├── FKAlertConfiguration.swift
│   ├── FKAlertPresets.swift
│   ├── FKAlertDelegate.swift
│   └── Bridge/
│       └── FKAlertModifier.swift
├── Internal/
│   ├── FKAlertCoordinator.swift
│   ├── FKAlertActionResolver.swift   # 裁剪/排序/Sheet 解析/内容校验
│   ├── FKAlertContentView.swift      # 正文滚动 + 勾选 + 输入
│   └── FKAlertButtonStackView.swift  # vertical / horizontalPair
└── Extension/                        # （预留）
```

`Package.swift` `exclude:` 含 `Components/Alert`（README 不参与 Swift 编译）。

---

## 22. FKKitExamples 场景

路径：`Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/Alert/`  
Hub：`FKAlertExamplesHubViewController`

| 分组 | 场景 | 验证点 |
|------|------|--------|
| Getting started | Basics & helpers | `FKAlert.confirm` / `prompt`、informational、presets |
| | Destructive delete | 破坏性样式、图标 tint、`destructiveConfirm` |
| | SwiftUI bridge | `View.fkAlert` Binding + result |
| Content & input | Text field rename | trim 文本、`FKAlertResult` |
| | Validation failure | 内联 `FKTextField` 错误、不关闭 |
| | Long legal message | 自适应高度、正文区滚动 |
| | Appearance & layout | 图标、`attributedMessage`、`horizontalPair` |
| Queue & presentation | Present once (dedup) | `presentOnce(id:)` → `nil` |
| | Queued alerts | `singleActive` FIFO、`replaceCurrent` |
| | Presentation policy | 背景/下滑策略、iPad 居中尺寸 |
| | Checkbox-gated delete | `UISwitch` 门控破坏性按钮 |
| Advanced | Interaction & lifecycle | `setLoading`、`dismissOnPrimaryAction`、`FKAlertDelegate`、触觉 |
| | Accessibility | VoiceOver 顺序、播报、destructive hint |

---

## 23. 已知限制与后续演进

| 项 | v1 状态 | 计划 |
|----|---------|------|
| `FKBusinessAlertBackend` 开关 | 未实现 | v1.1：BusinessKit 可配置 `systemAlert` / `fkAlert` |
| `FKCheckbox` 替代 `UISwitch` | 使用 `UISwitch` | 待 FormControls 发布后再评估 |
| 自定义 `UIView` 内容区 | 非目标 | v2+ 按需 |
| 多行 `FKCountTextView` Alert | 非目标 | 自定义 Sheet |
| `allowStack` 多层堆叠 | API 存在，不推荐 | 文档化风险；默认 `singleActive` |
| 单元测试 | FKKit 默认不要求 | 按需补充 |

---

## 27. 设计决策记录

| ID | 问题 | **已决（v1）** |
|----|------|----------------|
| Q1 | 复用 FKCoreKit `FKAlertAction`？ | **是** — 同一类型，Resolver 注入默认 OK |
| Q2 | v1 勾选控件？ | **`UISwitch`** — `FKAlertContentView.confirmationSwitch` |
| Q3 | BusinessKit 后端开关？ | **v1 仅文档** — 长期共存；v1.1 实现 `FKBusinessAlertBackend` |
| Q4 | 最多 3 按钮？ | **是** — `maximumVisibleActions = 3` + assertion |
| Q5 | v1 横向双按钮？ | **已实现** `horizontalPair`，默认 `.vertical` |
| Q6 | 结果模型含 handler？ | **否** — `FKAlertActionSnapshot` + 关闭后调 handler |
| Q7 | 正文滚动策略？ | **正文区单独滚动**，按钮固定；约 12 行视口 |
| Q8 | Presenter `from: nil`？ | **自动解析** 顶层 presented VC |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.5 |
| 2026-06-13 | v1 实现对照修订：状态改为已实现、API/配置/布局/Examples 对齐代码、成功标准勾选、设计决策落定、新增 §23 已知限制 |
| 2026-06-13 | 交互调整：`allowsSwipeToDismiss` 默认改为 `false`；`informational()` 仅背景点击关闭；显式开启 swipe 时使用更低 center 阈值 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 项目路线图
- [Alert README](../Sources/FKUIKit/Components/Alert/README.md) — 公开 API 与选型树
- [FKSheetPresentationController README](../Sources/FKUIKit/Components/SheetPresentationController/README.md)
- [FKActionSheet README](../Sources/FKUIKit/Components/ActionSheet/README.md)
- [FKBusinessKit README](../Sources/FKCoreKit/Components/BusinessKit/README.md)
