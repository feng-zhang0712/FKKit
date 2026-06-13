# FKBanner / FKNoticeBar — 设计需求文档

FKKit **`FKBanner`**（别名 **`FKNoticeBar`**）的实现指导文档：在**内容区顶部或底部**展示**持久性**通知条带，支持操作按钮与滑动关闭；与 **`FKToast`** 的全局短暂浮层队列**分离**。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.1  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.zh-CN.md](COMPONENT_GAP_ANALYSIS.zh-CN.md) §8.1  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 与 FKToast 的边界](#4-与-fktoast-的边界)
- [5. 架构总览](#5-架构总览)
- [6. 组件边界](#6-组件边界)
- [7. 内容模型](#7-内容模型)
- [8. 展示位置与 Safe Area](#8-展示位置与-safe-area)
- [9. 堆叠与优先级](#9-堆叠与优先级)
- [10. 交互与关闭](#10-交互与关闭)
- [11. 公开 API](#11-公开-api)
- [12. 配置模型](#12-配置模型)
- [13. 生命周期与宿主集成](#13-生命周期与宿主集成)
- [14. 无障碍](#14-无障碍)
- [15. SwiftUI 桥接](#15-swiftui-桥接)
- [16. 建议源码目录结构](#16-建议源码目录结构)
- [17. FKKitExamples 场景](#17-fkkitexamples-场景)
- [18. 待决问题](#18-待决问题)
- [19. 修订历史](#19-修订历史)

---

## 1. 概述

消费级 App 常见**非模态、持久**通知：

- 新版本可用、强制升级提示；
- 离线模式 / 网络不可用；
- 账号待验证、维护公告；
- 实验功能开关说明。

**`FKToast`** 适合 2–4 秒自动消失的轻反馈；**不适合**需要用户稍后处理、可带主操作按钮、长期占据布局空间的条带。

**`FKBanner`**（`Sources/FKUIKit/Components/Banner/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKBannerView`** | 单条 Banner 视图（标题、正文、图标、操作） |
| **`FKBannerHost`** | 附着于 VC/Window 的容器，管理 inset 与堆叠 |
| **`FKBannerCenter`** | 全局或 per-window 注册表（**独立于 FKToastCenter**） |
| **`FKBannerHandle`** | 可 `dismiss` / `update` 的句柄 |
| **`FKNoticeBar`** | **类型别名** 或 预设样式名（见 §12） |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **持久展示** — 默认无自动消失（可配置 timeout 作为 opt-in）。
2. **布局 inset** — Banner 占用空间，将下方内容顶下/顶上（非覆盖 Toast 式浮层，可配置 overlay 模式）。
3. **多条的堆叠** — 按优先级排序；同位置最多 N 条（默认 3）。
4. **滑动关闭** — 横向或纵向轻扫 dismiss（可禁用）。
5. **操作按钮** — 主/次操作，复用 **`FKButton`** 紧凑样式。
6. **语义样式** — info / warning / error / promo，与 **`FKWidgetStatusSemantic`** 或 Theme 对齐。
7. **键盘** — 可选避让（底部 Banner 时参考 Toast 键盘观察模式）。
8. **Swift 6** — `@MainActor` UI；配置 `Sendable`。
9. **SwiftUI** — `FKBannerModifier` / `FKBannerHostRepresentable`。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 系统 APNs 推送 UI | 本地通知走 Tier 3 `FKLocalNotificationManager` |
| 全屏 Interstitial 广告 | 不在范围 |
| 与 Toast 共用队列 | **禁止** — 见 §4 |
| 复杂富文本 HTML | 纯文本 + 可选 `NSAttributedString` |
| 内嵌 WebView | 不在范围 |
| macOS | 仅 iOS 15+ |

### 2.3 成功标准

- [ ] 顶部 Banner 将 `additionalSafeAreaInsets.top` 或 host 约束正确推开内容。
- [ ] 滑动关闭 + 操作按钮点击均触发 `didDismiss` 钩子。
- [ ] 两条不同 priority 的 Banner 按优先级排序堆叠。
- [ ] 与 Toast 同时展示时不互相抢同一容器（文档说明推荐布局）。
- [ ] README 含与 Toast 选型树。
- [ ] Examples 覆盖升级提示、离线条、堆叠、SwiftUI。

---

## 3. 背景与问题陈述

### 3.1 现有 FKToast 局限

| Toast 特性 | 为何不适合 Banner 场景 |
|------------|------------------------|
| 自动 dismiss | 升级提示需常驻至用户操作 |
| 全局 window overlay | 不推动 ScrollView contentInset |
| 队列偏短消息 | 不适合多行说明 + 双按钮 |
| maxConcurrentDisplayCount = 1 常见 | Banner 需多条堆叠 |

### 3.2 团队重复实现

- 在 `UITableView` 上方手搓 `UIView` + 手动改 `contentInset`；
- 与导航栏/大标题冲突；
- 离线监听 scattered 在各 VC。

**FKBanner** 提供统一 **Host + Center** 模式，类似 Toast 但语义不同。

---

## 4. 与 FKToast 的边界

**规范划分（路线图 R6 扩展）：**

| 模式 | 组件 | 持续时间 | 布局 |
|------|------|----------|------|
| 短提示、自动消失 | **`FKToast`** | 秒级 | 浮层 overlay |
| 持久通知、可带操作 | **`FKBanner` / `FKNoticeBar`** | 直至关闭 | inset / 可选 overlay |
| 阻塞确认 | **`FKAlert`**（待建） | 模态 | Sheet center |
| 底部操作列表 | **`FKActionSheet`** | 模态 | Sheet bottom |

**实现约束：**

- `FKBannerCenter` **不得** 调用 `FKToastCenter`；
- 共享仅 UI primitive：`FKButton`、`CornerShadow`、`FKUIKitI18n`、可选 `FKTheme`。

---

## 5. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 App / Scene                                                │
│  FKBanner.show(...)  或  hostViewController.attachBannerHost()   │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKBannerCenter（@MainActor，per UIWindow 或 全局）              │
│  注册表 │ priority 排序 │ dedup by id                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKBannerHostView                                                │
│  附加在 root VC / navigation 容器 │ 调整 safeArea / constraints   │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        FKBannerView   FKBannerView   FKBannerView
        (warning)      (offline)      (promo)
```

**两种集成模式：**

| 模式 | 说明 |
|------|------|
| **Global window** | 类似 Toast，挂 key window 顶部；适合 App 级离线条 |
| **Hosted** | 挂在特定 `UIViewController` 下，只影响该 VC  subtree |

v1 **必须** 支持 Global；Hosted 为 P1。

---

## 6. 组件边界

| 关注点 | FKBanner | FKToast | FKEmptyState |
|--------|----------|---------|--------------|
| 持久条带 | **是** | 否 | 否（全屏/区域态） |
| 自动消失 | 可选 | 默认是 | 否 |
| 推动布局 inset | **是** | 否 | 覆盖/内嵌 |
| 队列中心 | `FKBannerCenter` | `FKToastCenter` | 无全局 |

### 6.1 FKCoreKit / FKUIKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 按钮 | **`FKButton`** 紧凑配置 | 裸 UIButton 作为主 API |
| 圆角/阴影 | **`CornerShadow`** 或 **`FKLayerShadowStyle`** | 重复 shadow 路径 |
| 语义色 | **`FKWidgetStatusColorTokens`** 或未来 **`FKTheme`** | 硬编码 RGB 表 |
| 网络离线文案 | 可选读 **`FKNetworkReachability`** / Pluggable | 自建 Reachability |
| 本地化 | **`FKUIKitI18n`** | 硬编码 |
| 去重防抖 | 参考 Toast dedup 窗口；可选 **`FKDebouncer`** | 无 id 无限堆叠 |

---

## 7. 内容模型

```swift
public struct FKBannerContent: Sendable, Equatable {
  public var id: String?
  public var title: String?
  public var message: String
  public var icon: FKBannerIcon?
  public var primaryAction: FKBannerAction?
  public var secondaryAction: FKBannerAction?
  public var accessibilityIdentifier: String?
}

public struct FKBannerAction: Sendable, Equatable {
  public var title: String
  public var style: FKBannerActionStyle  // primary / secondary / destructive
  public var handler: (@MainActor () -> Void)?  // 存储策略见 Q2
}
```

**图标：**

```swift
public enum FKBannerIcon: Sendable, Equatable {
  case none
  case symbol(name: String, tint: FKBannerIconTint?)
  case image(UIImage)  // @unchecked Sendable 包装
}
```

---

## 8. 展示位置与 Safe Area

### 8.1 FKBannerPosition

```swift
public enum FKBannerPosition: Sendable, Equatable {
  case top
  case bottom
  case belowNavigationBar  // 大标题场景
}
```

### 8.2 Inset 策略

| `layoutMode` | 行为 |
|--------------|------|
| `.intrinsic`（默认） | Host 增高，子 VC `additionalSafeAreaInsets` 增加 |
| `.overlay` | 浮于内容之上，不推 layout（类似 Toast，用于临时 promo） |

### 8.3 与 NavigationBar / TabBar

- 顶部 Banner 默认在 **safe area top** 之下，或 `belowNavigationBar` 时在 nav bar 下缘；
- 底部 Banner 在 tab bar **之上**；
- 文档说明 `UINavigationController` + `UIScrollView` 的 `contentInsetAdjustmentBehavior` 建议。

---

## 9. 堆叠与优先级

```swift
public enum FKBannerPriority: Int, Sendable, Comparable {
  case low = 0
  case normal = 100
  case high = 200
  case critical = 300
}
```

**规则：**

- 同 `position` 多条时按 `priority` 降序，再按 FIFO；
- `maxStackCount` 超出时丢弃 `low` 或合并（可配置 `overflowPolicy`）；
- 相同 `id` 再次 `show` → **update** 现有条（类似 `FKToast.showOrUpdate`）。

---

## 10. 交互与关闭

### 10.1 关闭原因

```swift
public enum FKBannerDismissReason: Sendable, Equatable {
  case manual
  case swipe
  case actionCompleted
  case replaced
  case timeout
  case programmatic
}
```

### 10.2 手势

- 默认启用 vertical swipe away（top 向上 / bottom 向下）；
- 滑动超过阈值触发 dismiss 动画；
- `isSwipeToDismissEnabled = false` 用于强制升级条。

### 10.3 生命周期钩子

对齐 Toast 命名：

```swift
public struct FKBannerLifecycleHooks: Sendable {
  public var willShow: (@MainActor (String) -> Void)?
  public var didShow: (@MainActor (String) -> Void)?
  public var willDismiss: (@MainActor (String, FKBannerDismissReason) -> Void)?
  public var didDismiss: (@MainActor (String, FKBannerDismissReason) -> Void)?
}
```

---

## 11. 公开 API

```swift
public enum FKBanner {
  @MainActor
  public static var defaultConfiguration: FKBannerConfiguration { get set }

  @discardableResult
  public static func show(
    _ content: FKBannerContent,
    configuration: FKBannerConfiguration = .default,
    hooks: FKBannerLifecycleHooks = .init()
  ) -> FKBannerHandle

  public static func dismiss(_ id: String, reason: FKBannerDismissReason = .programmatic)
  public static func dismissAll(position: FKBannerPosition? = nil)
}
```

**便利 API：**

```swift
FKBanner.showOffline(message: "You're offline", actionTitle: "Retry") { ... }
FKBanner.showAppUpdate(version: "2.0", actionTitle: "Update") { ... }
```

---

## 12. 配置模型

```swift
public struct FKBannerConfiguration: Sendable, Equatable {
  public var style: FKBannerStyle          // info / warning / error / promo / custom
  public var position: FKBannerPosition
  public var layoutMode: FKBannerLayoutMode
  public var priority: FKBannerPriority
  public var timeout: TimeInterval?        // nil = 持久
  public var isSwipeToDismissEnabled: Bool
  public var stack: FKBannerStackConfiguration
  public var appearance: FKBannerAppearanceConfiguration
  public var animation: FKBannerAnimationConfiguration
}
```

### 12.1 FKNoticeBar 命名

**推荐：**

- **`FKNoticeBar`** = `typealias FKNoticeBar = FKBanner` **或** `FKBannerConfiguration.noticeBarPreset`（偏中性 info 样式、top、intrinsic）；
- README 说明两名称等价，**对外 API 以 `FKBanner` 为主**。

---

## 13. 生命周期与宿主集成

### 13.1 App 级离线条

```swift
// AppDelegate / SceneDelegate — reachability 变化
if !isReachable {
  offlineHandle = FKBanner.show(.offline, configuration: .offlinePreset)
} else {
  offlineHandle?.dismiss()
}
```

### 13.2 VC 级

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  bannerHost.attach(to: self, position: .top)
}
```

### 13.3 与 FKBusinessKit 版本更新

- `FKBusinessVersionManager` 检测到新版本 → 回调宿主；
- 宿主调用 `FKBanner.showAppUpdate` — **BusinessKit 不直接依赖 Banner**（避免环依赖），Examples 演示组合。

---

## 14. 无障碍

- Banner 出现：`UIAccessibility.post(.layoutChanged)`；
- 操作按钮：独立 accessibility trait `.button`；
- 持久 Banner：不应每 N 秒重复 announcement（与 Toast 不同）；
- Dynamic Type：message 多行换行；最小高度 ≥ 44pt 可点区域。

---

## 15. SwiftUI 桥接

```swift
public struct FKBannerModifier: ViewModifier {
  @Binding var content: FKBannerContent?
  public func body(content: Content) -> some View
}

public extension View {
  func fkBanner(_ content: Binding<FKBannerContent?>, configuration: FKBannerConfiguration = .default) -> some View
}
```

UIKit 混合栈仍推荐 `FKBanner.show` 全局 API。

---

## 16. 建议源码目录结构

```text
Sources/FKUIKit/Components/Banner/
├── Public/
│   ├── FKBanner.swift
│   ├── FKBannerView.swift
│   ├── FKBannerContent.swift
│   ├── FKBannerConfiguration.swift
│   ├── FKBannerHandle.swift
│   ├── FKBannerCenter.swift
│   ├── FKNoticeBar.swift              // typealias / preset
│   └── Bridge/
│       └── FKBannerModifier.swift
├── Internal/
│   ├── FKBannerHostView.swift
│   ├── FKBannerStackLayoutEngine.swift
│   ├── FKBannerAnimator.swift
│   └── FKBannerKeyboardObserver.swift
└── README.md
```

---

## 17. FKKitExamples 场景

路径：`Examples/.../FKUIKit/Banner/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `InfoTopIntrinsic` | 顶部 inset 推开列表 |
| 2 | `OfflinePersistent` | 持久 + 重试操作 |
| 3 | `AppUpdatePromo` | 双按钮 + 不可滑动关闭 |
| 4 | `StackedPriorities` | 多条 priority 排序 |
| 5 | `BottomAboveTabBar` | Tab 场景 |
| 6 | `SwipeToDismiss` | 滑动关闭 |
| 7 | `ShowOrUpdateByID` | 同 id 更新文案 |
| 8 | `OverlayMode` | 不推 layout 模式 |
| 9 | `WithToastCoexist` | 与 Toast 同时存在布局建议 |
| 10 | `SwiftUIModifier` | Binding 展示 |
| 11 | `VoiceOver` | 无障碍顺序 |

---

## 18. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Global vs Hosted v1 范围？ | Global 必做；Hosted P1 |
| Q2 | Action handler 存储？ | `@MainActor () -> Void` + `@unchecked Sendable` 文档警示 |
| Q3 | `FKNoticeBar` 独立类还是 alias？ | alias + preset |
| Q4 | 是否复用 Toast 动画曲线？ | 共享 Internal 曲线常量，不共用 Center |
| Q5 | 最大堆叠数？ | 3 |

---

## 19. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版，源自 COMPONENT_ROADMAP §2.1 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKToast README](../Sources/FKUIKit/Components/Toast/README.md)
- [COMPONENT_GAP_ANALYSIS.zh-CN.md](COMPONENT_GAP_ANALYSIS.zh-CN.md)
