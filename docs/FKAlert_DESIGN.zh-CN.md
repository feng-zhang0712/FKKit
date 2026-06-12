# FKAlert — 设计需求文档

FKKit **`FKAlert`** 的实现指导文档：基于 **`FKSheetPresentationController`**（`.center` 模式）的**自定义居中确认框**，在保留 Alert 语义（标题、正文、按钮、可选输入）的同时，替代 `UIAlertController` 的样式与能力限制。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.5  

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
- [21. 建议源码目录结构](#21-建议源码目录结构)
- [22. FKKitExamples 场景](#22-fkkitexamples-场景)
- [24. 待决问题](#24-待决问题)
- [25. 修订历史](#25-修订历史)

---

## 1. 概述

居中 Alert 用于**破坏性确认**、**阻塞式错误**、**重命名提示**、**合规确认**等。FKKit 现状：

| 现有能力 | 角色 | 缺口 |
|----------|------|------|
| **`FKBusinessAlertManager`** | `UIAlertController` + `presentOnce` | 非 FK 样式；布局受限 |
| **`FKActionSheet`** | 底部表 / Action Sheet 迁移 | 不适合居中确认 + 紧凑输入 |
| **`FKSheetPresentationController.centerAlert`** | 展示基础设施 | 无 Alert 内容组装 |

**`FKAlert`**（`Sources/FKUIKit/Components/Alert/`）组合：

- **`FKAlertViewController`** — 标题、正文、可选 `FKTextField`、按钮列
- **`FKAlertPresenter`** — 通过 `centerAlert` 预设展示
- **`FKAlertCoordinator`** — 队列、`presentOnce(id:)`、堆叠策略

| 交付物 | 职责 |
|--------|------|
| **`FKAlertContent`** | Sendable 声明式内容 |
| **`FKAlertAction`** | 复用 **FKCoreKit** BusinessKit 描述符 |
| **`FKAlertPresenter`** | `present` / `presentOnce` / `dismiss` |
| **`FKAlertConfiguration`** | 视觉 + 交互 + 队列策略 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **FK 视觉语言** — `FKButton` 主/次/破坏性；间距与 `FKActionSheet` 头部一致（**不**复用 ActionSheet 行渲染器）。
2. **居中模态** — 默认 `FKSheetPresentationConfiguration.centerAlert`；高度随内容适配。
3. **按钮组** — 最多 3 个可见操作（主、次、取消/破坏性），符合 HIG 顺序。
4. **可选单行输入** — 嵌入 `FKTextField`（重命名、短反馈）。
5. **危险操作 UX** — 破坏性强调；可选确认勾选框门控。
6. **队列 / 去重** — 移植 `FKBusinessAlertManager.presentOnce`；可选 FIFO 队列。
7. **`async` API** — `await FKAlert.present(...)` 返回所点操作。
8. **无障碍** — VoiceOver 顺序、键盘、Dynamic Type。
9. **不重复** `FKActionSheet` 行/分区 UI — Alert 仅为**纵向按钮列**布局。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 底部操作表 UI | 用 `FKActionSheet` |
| 多行文本域 Alert | 自定义 Sheet + `FKCountTextView` |
| 任意 SwiftUI 内容 | v1 可选 `UIView` customView |
| 覆盖所有 `UIAlertController` 场景 | 文档说明迁移边界 |
| Toast / 横幅 | `FKToast` |
| Alert 内多步向导 | 宿主自行导航 VC |
| macOS / Catalyst | 仅 iOS 15+ UIKit |

### 2.3 成功标准

- [ ] 删除确认破坏性按钮符合 FK 样式。
- [ ] 带输入框 Alert 在主按钮点击时返回 trim 后字符串。
- [ ] `presentOnce(id:)` 展示期间抑制重复。
- [ ] 队列中第二条在第一条关闭后出现。
- [ ] 勾选门控破坏性按钮在未勾选前禁用。
- [ ] README 含与 ActionSheet / Toast / BusinessAlertManager 选型树。

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

`centerAlert` 已定义：宽约 320、边距 32、背景 dim 0.45、可下滑关闭阈值 0.28。FKAlert **必须**以此为默认（可通过配置微调）。

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 App                                                        │
│  FKAlertPresenter.present(content:from:)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertCoordinator（@MainActor）                                │
│  按 id 去重 │ 队列 │ 当前 Alert 注册表                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKAlertViewController                                           │
│  标题 / 正文 / 图标 / FKTextField? / 勾选? / FKButton 列        │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKSheetPresentationController（.center / centerAlert）            │
│  背景 │ 键盘 │ 生命周期 │ 关闭手势                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 组件边界

| 关注点 | FKAlert | FKActionSheet | FKBusinessAlertManager |
|--------|---------|---------------|------------------------|
| 布局 | 纵向按钮栈 | 分区 + 行 | 系统 Alert |
| 位置 | 居中 | 底部 / Popover | 系统居中 |
| 输入 | 单行 `FKTextField` | 有限行类型 | UIAlert 字段 |
| 去重 | `presentOnce` | 独立 | 现有 `presentOnce` |
| 模块 | FKUIKit | FKUIKit | FKCoreKit |

依赖：`FKSheetPresentationController`、`FKButton`、`FKTextField`、`FKCoreKit`（`FKAlertAction`、`FKI18n`）。

### 5.1 FKCoreKit 复用要求（强制）

| 能力 | 必须使用（FKCoreKit） | 禁止 |
|------|----------------------|------|
| Alert 操作模型 | **`FKAlertAction`**（BusinessKit） | 在 FKUIKit 重复定义 Action |
| 本地化 | **`FKI18n`** | 硬编码按钮文案 |
| 队列/去重 | 参考 **`FKBusinessAlertManager`** 模式 | 无 id 的重复弹窗 |

Alert **不得**复制 **`FKActionSheet`** 行渲染器；仅复用 Sheet **center** 展示基础设施。

---

## 6. 内容模型

### 6.1 核心内容

```swift
public struct FKAlertContent: Sendable, Equatable {
  public var id: String?
  public var title: String?
  public var message: String?
  public var attributedMessage: Data?
  public var icon: FKAlertIcon?
  public var actions: [FKAlertAction]      // FKCoreKit BusinessKit
  public var textInput: FKAlertTextInput?
  public var dangerousAction: FKAlertDangerousActionOptions?
  public var accessibilityIdentifier: String?
}
```

### 6.2 图标（可选）

`FKAlertIcon`：无 / SF Symbol（warning、destructive 等色调）/ Asset。

### 6.3 正文渲染

- 标题：`headline` 或可配置
- 正文：`body`；过长时默认最多 5 行，超出可配置内部滚动

### 6.4 空内容规则

`title`、`message`、`icon`、`textInput` 至少一项非空；`actions` 为空时注入默认 OK（同 BusinessKit）。

---

## 7. 操作按钮与样式

### 7.1 `FKAlertAction.Style` → `FKButton`

| Style | FKButton 角色 |
|-------|---------------|
| `.default` | 主或次（按位置） |
| `.cancel` | 次/幽灵；可单独最底行 |
| `.destructive` | 破坏性 |

### 7.2 纵向顺序（规范）

1. 可选图标  
2. 标题  
3. 正文  
4. 可选输入框 / 勾选框  
5. **主操作**（非取消、非破坏性）  
6. **破坏性**（全宽）  
7. **取消**（默认最底）

两按钮（取消 + 删除）：破坏性在取消上方。

### 7.3 数量上限

可见最多 **3** 个按钮；超出 Debug 断言并裁剪为 取消 + 破坏性 + 第一个 default。

### 7.4 横向并排（可选）

`FKAlertButtonLayout.horizontalPair`：仅 2 个非破坏性并排；v1 **禁止**破坏性横向并排。

### 7.5 禁用条件

主/破坏性在以下情况禁用：

- 文本校验未通过（§8）  
- 危险勾选未勾选（§9）  
- `isLoading` 展示加载态  

---

## 8. 文本输入变体

### 8.1 模型

```swift
public struct FKAlertTextInput: Sendable, Equatable {
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
```

校验失败时复用 `FKTextField` 错误展示；不关闭 Alert。

### 8.2 集成

- v1 仅单行 `FKTextField`  
- 展示后短延迟自动聚焦（约 0.1s，等转场结束）

### 8.3 返回值

```swift
public enum FKAlertResult: Sendable, Equatable {
  case action(index: Int, action: FKAlertAction, text: String?)
  case cancelled
  case dismissed
}
```

---

## 9. 危险操作模式

### 9.1 破坏性样式

- `FKButton` 破坏性预设  
- 可选顶部警告图标  
- 正文由宿主写清后果；可配置关键词高亮

### 9.2 确认勾选框

```swift
public struct FKAlertDangerousActionOptions: Sendable, Equatable {
  public var requiresConfirmationCheckbox: Bool
  public var checkboxTitle: String
  public var destructiveActionIndex: Int?
}
```

未勾选时破坏性按钮 `isEnabled = false`。v1 控件：`UISwitch` 或已发布的 `FKCheckbox`（以 FKCheckbox 是否已发布为准）。

### 9.3 两步确认

v1 单 Alert + 勾选足够；两步连弹由宿主编排（文档示例）。

### 9.4 误触防护

可选破坏性点击前最小间隔（默认 0）。

---

## 10. 展示与 Sheet 集成

### 10.1 默认配置

```swift
public struct FKAlertPresentationConfiguration: Sendable, Equatable {
  public var sheet: FKSheetPresentationConfiguration  // 默认 .centerAlert
  public var allowsBackdropTapToDismiss: Bool         // 确认类默认 false
  public var allowsSwipeToDismiss: Bool
  public var cornerRadius: CGFloat?
}
```

含 `dangerousAction` 时默认：**禁止**点背景关闭与下滑关闭。

### 10.2 Presenter

```swift
@MainActor
public final class FKAlertPresenter {
  public static let shared: FKAlertPresenter

  func present(_ content: FKAlertContent, ...) async -> FKAlertResult
  func presentOnce(_ content: FKAlertContent, ...) async -> FKAlertResult?
  func dismiss(animated: Bool)
}
```

`presentOnce`：同 `id` 已在展示 → 立即返回 `nil`。

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
| `singleActive` | 排队 |
| `replaceCurrent` | 不调用旧 handler 直接替换 |
| `presentOnceByID` | 同 BusinessKit `presentOnce` |

默认：`present` 用 **`singleActive`**；`presentOnce` 用 **`presentOnceByID`**。

### 11.2 Handler 调用顺序

按钮点击 → 动画关闭 → 再执行 `FKAlertAction.handler`（避免重入 `present`）。

---

## 12. 公开 API

### 12.1 便捷构建

```swift
public enum FKAlert {
  static func confirm(title:message:confirmTitle:cancelTitle:isDestructive:from:) async -> Bool
  static func prompt(title:message:placeholder:confirmTitle:from:) async -> String?
}
```

### 12.2 根配置

`FKAlertConfiguration`：`presentation`、`appearance`、`interaction`、`textField`、`queue`、`buttonLayout`、`motion`、`accessibility`。

### 12.3 预设

| 预设 | 用途 |
|------|------|
| `destructiveConfirm()` | 删除类 |
| `informational()` | 单 OK |
| `textPrompt()` | 重命名 |

---

## 13. FKBusinessAlertManager 迁移

### 13.1 共存（v1）

- BusinessKit **保留**系统 Alert 路径。  
- 预留 `FKBusinessAlertBackend`：`systemAlert` / `fkAlert`（v1.1 实现可选）。

### 13.2 映射

| BusinessKit | FKAlert |
|-------------|---------|
| `FKAlertAction` | **同一类型** |
| `presentOnce(...)` | `FKAlertPresenter.presentOnce(FKAlertContent(...))` |

### 13.3 长期方向

UI 应用推荐 `FKAlertPresenter`；`FKAlertAction` 继续留在 FKCoreKit 作共享模型。

---

## 14. 配置模型

- **Appearance**：标题/正文字体、内边距、按钮间距、图标尺寸、正文最大高度。  
- **Interaction**：自动聚焦、`dismissOnPrimaryAction`、破坏性触觉。

---

## 15. 生命周期与关闭

`FKAlertDelegate`：`alertWillPresent` / `alertDidDismiss(result:)`。  
iPad 宽度受 `centerAlert` 限制；弱引用 presenter，避免 handler 循环引用。

---

## 16. 键盘与焦点

复用 Sheet **center 模式**键盘避让；输入类 Alert 随键盘上移；Return 触发主按钮校验路径。

---

## 17. 无障碍

- 出现时播报标题+正文  
- 优先聚焦：输入框 > 标题  
- 破坏性按钮可附加 hint  
- 勾选状态与破坏性启用关联播报  

---

## 18. 动效与触觉

继承 Sheet `.systemLike` 动画；Reduce Motion 仅交叉淡入淡出；破坏性确认可选 warning 触觉。

---

## 19. SwiftUI 桥接

```swift
func fkAlert(isPresented: Binding<Bool>, content: FKAlertContent, onResult: @escaping (FKAlertResult) -> Void) -> some View
```

对齐 `FKActionSheetModifier` 的 presenter 锚点模式。

---

## 20. 安全与内容

- 不记录安全输入框内容  
- 破坏性操作禁止自动定时关闭（v1）  

---

## 21. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

```text
Sources/FKUIKit/Components/Alert/
├── README.md
├── Public/
│   ├── FKAlert.swift
│   ├── FKAlertPresenter.swift
│   ├── FKAlertViewController.swift
│   ├── FKAlertContent.swift
│   ├── FKAlertResult.swift
│   ├── FKAlertConfiguration.swift
│   └── Bridge/FKAlertModifier.swift
├── Internal/
│   ├── FKAlertCoordinator.swift
│   ├── FKAlertContentView.swift
│   └── FKAlertButtonStackView.swift
└── Extension/
```

---

## 22. FKKitExamples 场景

路径：`Examples/.../FKUIKit/Alert/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `DestructiveDelete` | 破坏性删除 |
| 2 | `TextFieldRename` | 输入返回 |
| 3 | `PresentOnceDedup` | id 去重 |
| 4 | `QueuedAlerts` | FIFO 队列 |
| 5 | `CheckboxGatedDelete` | 勾选门控 |
| 6 | `ValidationFailure` | 校验错误 |
| 7 | `InformationalOK` | 单按钮 |
| 8 | `LongLegalMessage` | 长文滚动 |
| 9 | `SwiftUIModifier` | Binding |
| 10 | `iPadCenterSizing` | 居中尺寸 |
| 11 | `BackdropDismissPolicy` | 背景关闭策略 |
| 12 | `VoiceOverOrder` | 无障碍顺序 |

---

## 24. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 复用 FKCoreKit `FKAlertAction`？ | 是 |
| Q2 | v1 勾选控件？ | `UISwitch` 或 `FKCheckbox` |
| Q3 | BusinessKit 后端开关？ | 仅文档，后续实现 |
| Q4 | 最多 3 按钮？ | 是 |
| Q5 | v1 横向双按钮？ | 可选，默认关 |

---

## 25. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.5 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKSheetPresentationController README](../Sources/FKUIKit/Components/SheetPresentationController/README.md)
- [FKActionSheet README](../Sources/FKUIKit/Components/ActionSheet/README.md)
- [FKBusinessKit README](../Sources/FKCoreKit/Components/BusinessKit/README.md)
