# FKLocalNotificationManager — 模块设计需求文档

FKKit **`FKLocalNotificationManager`** 的实现指导文档：基于 **`UserNotifications`** 的**本地通知**调度、查询、取消与点击响应桥接；**权限申请**统一走 **`FKPermissions`**，与 **`FKBanner` / `FKToast`**、远程 APNs 路由分层清晰；实现 **`FKLocalNotificationScheduling`** Pluggable 契约。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) Tier 3 — FKLocalNotificationManager  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §9  
**Pluggable 契约：** [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) §16.1  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 权限与授权状态](#6-权限与授权状态)
- [7. 内容模型与触发器](#7-内容模型与触发器)
- [8. 调度、更新与取消](#8-调度更新与取消)
- [9. 查询与 Badge](#9-查询与-badge)
- [10. 分类与操作按钮](#10-分类与操作按钮)
- [11. 前台展示与 Delegate 桥接](#11-前台展示与-delegate-桥接)
- [12. 点击响应与 DeepLink 路由](#12-点击响应与-deeplink-路由)
- [13. 公开 API 索引](#13-公开-api-索引)
- [14. 错误模型](#14-错误模型)
- [15. 配置模型](#15-配置模型)
- [16. 并发与 Swift 6](#16-并发与-swift-6)
- [17. Pluggable 与依赖注入](#17-pluggable-与依赖注入)
- [18. Mock 与测试](#18-mock-与测试)
- [19. 本地化（FKI18n）](#19-本地化fki18n)
- [20. 宿主 App 集成清单](#20-宿主-app-集成清单)
- [21. 安全与隐私](#21-安全与隐私)
- [22. v2 能力展望（非 v1 交付）](#22-v2-能力展望非-v1-交付)
- [23. FKCoreKit 复用要求](#23-fkcorekit-复用要求)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [26. 分阶段交付计划](#26-分阶段交付计划)
- [27. 待决问题](#27-待决问题)
- [28. 修订历史](#28-修订历史)
- [29. 相关文档](#29-相关文档)

---

## 1. 概述

Reminder、订单状态、离线消息、定时任务等场景需要在 App **不在前台**时通过**系统通知中心**触达用户。各团队重复封装 `UNUserNotificationCenter`：触发器构建不一致、identifier 冲突、权限与调度耦合、点击 payload 与路由散落 AppDelegate。

**`FKLocalNotificationManager`**（建议路径 `Sources/FKCoreKit/Components/LocalNotification/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKLocalNotificationScheduling`** | `Sendable` 协议（与 Pluggable §16.1 对齐，本模块为参考实现宿主） |
| **`FKLocalNotificationManager`** | 默认 `UNUserNotificationCenter` 编排实现 |
| **`FKLocalNotificationRequest`** | 调度输入：内容 + 触发器 + 元数据 |
| **`FKLocalNotificationTrigger`** | 类型化触发器（时间间隔 / 日历 / 立即） |
| **`FKLocalNotificationContent`** | 标题、正文、副标题、sound、badge、userInfo、附件 |
| **`FKLocalNotificationCategory`** | 分类注册与操作按钮 |
| **`FKLocalNotificationResponseHandler`** | 可选点击/操作回调；可桥接 `FKBusinessKit` Deeplink |
| **`FKLocalNotificationError`** | 稳定错误分类 |
| **`FKMockLocalNotificationScheduler`** | 测试用内存实现 |

**关键约束：** 本模块负责**本地**通知生命周期；**不**注册 APNs Token、**不**解析远程 payload（见 Pluggable `FKPushNotificationRouting` v2）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **类型化调度 API** — `async throws schedule(_:)`，隐藏 `UNNotificationRequest` 拼装细节。
2. **权限分离** — 调度前**不**隐式弹系统授权框；文档强制先 `FKPermissions.shared.request(.notifications)`。
3. **Identifier 语义** — 支持按 id 更新（同 id 覆盖 pending）、批量取消、取消全部。
4. **触发器覆盖** — v1：`timeInterval`（含 `repeats`）、`calendar`（含 `repeats`）、`immediate`（映射 `trigger: nil` 立即投递）；查询 pending/delivered。
5. **Badge 辅助** — 设置 per-request badge；提供 `setBadgeCount` / `clearBadge` 便捷 API（iOS 16+ `setBadgeCount` 优先）。
6. **分类与操作** — 注册 `FKLocalNotificationCategory`；响应回调区分 default tap vs action id。
7. **前台展示策略** — 可配置 `FKLocalNotificationPresentationOptions`（banner / sound / badge / list）。
8. **DeepLink 桥接** — `userInfo` 内标准 key 解析 URL → 可选转交 `FKBusinessKit.shared.deeplink`（opt-in）。
9. **Swift 6** — 配置与请求 `Sendable`；Manager 无 UI，**不加** `@MainActor`；Delegate 回调文档说明主线程。
10. **Pluggable** — `FKLocalNotificationManager.shared` 符合 `FKLocalNotificationScheduling`；Mock 公开。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 远程 APNs 注册与接收 | 宿主 `UIApplicationDelegate`；路由见 Pluggable `FKPushNotificationRouting` |
| 富媒体推送扩展（Notification Service Extension） | 宿主 target；本模块可提供 payload 字段约定文档 |
| 地理围栏触发 `UNLocationNotificationTrigger` | v2；需 Location 权限与显著位置变更 |
| Critical Alert  entitlement | 需 Apple 特批；v1 仅文档说明，API 门控 |
| 跨 App 通知共享 | 不在范围 |
| 服务端排程 | 宿主后端 + 本地调度；本模块不联网 |
| 应用内 Banner/Toast 替代 | 见 §5 — `FKBanner` / `FKToast` |
| watchOS / macOS | 仅 iOS 15+ |
| 自动请求通知权限 | **禁止** — 必须经 `FKPermissions` |

### 2.3 成功标准

- [ ] 授权为 `.authorized` / `.provisional` 时，`schedule` 成功并在 Settings → 通知中可见 pending。
- [ ] 同 `identifier` 再次 `schedule` 覆盖原 pending（文档化语义）。
- [ ] `cancelPending(withIdentifier:)` / `cancelAllPending()` 生效。
- [ ] `pendingRequests()` / `deliveredNotifications()` 返回可映射的 `FKLocalNotificationRequest` 摘要。
- [ ] 用户点击通知：注册的 `FKLocalNotificationResponseHandler` 收到 `FKLocalNotificationResponse`；DeepLink 桥接 opt-in 可路由 URL。
- [ ] 未授权时 `schedule` 抛出 `FKLocalNotificationError.notAuthorized`（不弹窗）。
- [ ] Examples：权限流、延迟通知、日历重复、分类操作、取消、Mock。
- [ ] README 含与 FKBanner/Toast、Permissions、BusinessKit 选型树。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 领域 | 状态 |
|------|------|
| `Sources/` 内 `UserNotifications` 封装 | **无** |
| `FKPermissions` `.notifications` | **已交付** — `FKNotificationPermissionHandler` |
| Pluggable `FKLocalNotificationScheduling` | **草案**（§16.1），无参考实现 |
| `FKBanner` / `FKToast` | 应用内 UI；非系统通知 |
| `FKBusinessKit.deeplink` | 已交付；`FKDeeplinkSource` 尚无 `.localNotification` / `.push`（v1.1 可扩展） |

### 3.2 重复集成痛点

| 痛点 | 影响 |
|------|--------|
| 在 feature 模块直接 `requestAuthorization` | 与 `FKPermissions` 状态不一致；难以统一预提示 |
| `Date` vs `TimeInterval` 触发器混用 | 时区/DST 边界 bug |
| identifier 无命名规范 | 取消失败、重复通知 |
| `userInfo` 随意字典 | 点击路由无法与 Deeplink 对齐 |
| Delegate 写在 AppDelegate 数百行 | 难以测试与 Mock |
| 未区分 provisional 授权 | 静默失败 |
| 超过 **64** 条 pending 仍盲目 schedule | 系统**静默丢弃**超出部分，无错误回调 |

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Host Application                          │
│  AppDelegate / SceneDelegate                                     │
│    └─ UNUserNotificationCenter.delegate → FKLocalNotification…   │
│  Feature modules                                                 │
│    └─ FKPermissions.request(.notifications)  →  schedule/cancel   │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│              FKLocalNotificationManager (FKCoreKit)              │
│  FKLocalNotificationScheduling                                   │
│    schedule / cancel / query / registerCategories                │
│  FKLocalNotificationCenterDelegateAdapter (internal)             │
│    willPresent / didReceive → ResponseHandler / DeeplinkBridge   │
└────────────────────────────┬────────────────────────────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  FKPermissions        FKBusinessKit.deeplink   FKI18n (errors)
  (.notifications)     (opt-in URL routing)     (optional defaults)
         │
         ▼
  UNUserNotificationCenter (system)
```

**数据流（调度）：**

```text
Feature 确认权限已 granted
  → 构建 FKLocalNotificationRequest
  → manager.schedule(request)
  → UNNotificationRequest + UNNotificationTrigger
  → 系统 pending 队列
```

**数据流（点击）：**

```text
用户点击通知 / 操作按钮
  → UNUserNotificationCenterDelegate.didReceive
  → FKLocalNotificationResponse
  → [optional] 解析 userInfo[FKLocalNotificationUserInfoKey.deeplinkURL]
  → [optional] FKBusinessKit.shared.deeplink.route(url, source: .unknown)
  → Host FKLocalNotificationResponseHandler
```

---

## 5. 模块边界

### 5.1 与 FKPermissions

| 职责 | 归属 |
|------|------|
| `requestAuthorization` / `getNotificationSettings` | **`FKPermissions`** |
| 预提示 `FKPermissionPrePrompt` | **`FKPermissions`** |
| 调度、取消、Delegate | **`FKLocalNotificationManager`** |

**规范：** `FKLocalNotificationManager` **不得**调用 `UNUserNotificationCenter.requestAuthorization`。授权状态须经 **`FKPermissions`**（`@MainActor`）查询 — 见 §16。

### 5.2 与 FKBanner / FKToast

| 场景 | 推荐组件 |
|------|----------|
| App **在前台**，需持久条带（升级、离线） | **`FKBanner`** |
| App **在前台**，短暂反馈 | **`FKToast`** |
| App **在后台/锁屏**，定时/事件提醒 | **`FKLocalNotificationManager`** |
| 用户已打开 App，仅补一条 in-app 提示 | Banner/Toast — **非**本地通知 |

见 [FKBanner-FKNoticeBar_DESIGN.md](FKBanner-FKNoticeBar_DESIGN.md) §2.2。

### 5.3 与 BusinessKit / Pluggable

| 能力 | v1 | 说明 |
|------|-----|------|
| 点击 URL 路由 | opt-in 桥接 | 不强制依赖 `FKBusinessKit` target 循环；可用 closure 注入 |
| `FKDeeplinkSource.localNotification` | v1.1 | BusinessKit 扩展枚举 |
| `FKPushNotificationRouting` | Pluggable v2 | 远程推送；非本模块 |
| `FKLocalNotificationScheduling` | v1 | 本模块默认实现 |

### 5.4 与 FKBusinessKit Lifecycle

- 本地通知**不**替代 Lifecycle 启动任务；
- 可选：在 `didFinishLaunching` 注册 categories + 设置 delegate adapter（文档示例）。

---

## 6. 权限与授权状态

### 6.1 授权检查

```swift
/// Returns whether scheduling is allowed without prompting.
public func canScheduleNotifications() async -> Bool
```

实现：`await MainActor.run { await FKPermissions.shared.status(for: .notifications) }`（或等价隔离），当 status 为 `.authorized`、`.provisional` 时返回 `true`。

| `FKPermissionStatus` | `canSchedule` | `schedule` 行为 |
|----------------------|---------------|-----------------|
| `.authorized` | ✅ | 正常调度 |
| `.provisional` | ✅ | 静默投递（无权限弹窗） |
| `.ephemeral` | ✅ | App Clip 等场景（主 App 可忽略） |
| `.notDetermined` | ❌ | `throw .notAuthorized` |
| `.denied` / `.restricted` | ❌ | `throw .notAuthorized` |

### 6.2 集成方权限流（文档强制）

```swift
let result = await FKPermissions.shared.request(
  .notifications,
  prePrompt: FKPermissionPrePrompt(
    title: "Stay Updated",
    message: "We send reminders for orders and messages."
  )
)
guard result.isGranted else { return }
try await FKLocalNotificationManager.shared.schedule(request)
```

### 6.3 授权选项扩展（v1.1）

`FKPermissions` 当前固定 `[.alert, .badge, .sound]`。若需 `.provisional`、`.criticalAlert`、`.providesAppNotificationSettings`，在 **Permissions 增强 PR** 扩展 `FKNotificationPermissionOptions`，本模块文档交叉引用 — **v1 不修改 Permissions API**。

---

## 7. 内容模型与触发器

### 7.1 `FKLocalNotificationContent`

```swift
public struct FKLocalNotificationContent: Sendable, Hashable {
  public var title: String
  public var body: String
  public var subtitle: String?
  public var sound: FKLocalNotificationSound
  public var badge: Int?
  public var userInfo: [String: String]
  public var threadIdentifier: String?
  public var targetContentIdentifier: String?
  public var interruptionLevel: FKNotificationInterruptionLevel?
  public var relevanceScore: Double?
}
```

| 字段 | 说明 |
|------|------|
| `sound` | `.default` / `.none` / `.named(String)` |
| `userInfo` | **仅 `String` 值** — 简化 Sendable；复杂结构 JSON 字符串化 |
| `interruptionLevel` | iOS 15+；`.timeSensitive` 需 **Time Sensitive Notifications** entitlement |
| `relevanceScore` | iOS 15+ 调度优先级提示 |

> **v1.1：** `attachments: [FKLocalNotificationAttachment]` 另增于 `FKLocalNotificationContent` 或扩展 API，**v1 模型不含附件字段**。

### 7.2 标准 userInfo 键

```swift
public enum FKLocalNotificationUserInfoKey {
  public static let deeplinkURL = "fk.deeplink.url"
  public static let routeID = "fk.route.id"
  public static let analyticsEvent = "fk.analytics.event"
}
```

### 7.3 `FKLocalNotificationTrigger`

```swift
public enum FKLocalNotificationTrigger: Sendable, Hashable {
  /// Fire after interval; `repeats` for recurring interval.
  case timeInterval(TimeInterval, repeats: Bool)
  /// Calendar components in specified timezone.
  case calendar(FKLocalNotificationCalendarTrigger, repeats: Bool)
  /// Deliver immediately (`UNNotificationRequest` with `trigger: nil`).
  case immediate
}

public struct FKLocalNotificationCalendarTrigger: Sendable, Hashable {
  public var dateComponents: DateComponents
  public var timezone: TimeZone
}
```

**校验规则：**

- `timeInterval` 必须 `> 0`（`immediate` 除外）；
- `repeats == true` 时 interval 必须 ≥ 60s（系统要求，否则 throw `invalidTrigger`）；
- `calendar` 至少指定一个非空 component；
- `immediate` → Mapper 使用 **`trigger: nil`**（非 `timeInterval: 0.1` 技巧）。

### 7.4 `FKLocalNotificationRequest`

```swift
public struct FKLocalNotificationRequest: Sendable, Hashable {
  public var identifier: String
  public var content: FKLocalNotificationContent
  public var trigger: FKLocalNotificationTrigger
  public var categoryIdentifier: String?
}
```

**Identifier 约定（README）：**

- 建议 `{domain}.{feature}.{id}`，如 `order.reminder.12847`；
- 同 identifier **replace** pending request（调用 `add` 前不额外 remove，依赖系统 replace 语义）。

---

## 8. 调度、更新与取消

### 8.1 协议面（与 Pluggable 对齐并扩展）

```swift
public protocol FKLocalNotificationScheduling: Sendable {
  func schedule(_ request: FKLocalNotificationRequest) async throws
  func schedule(_ requests: [FKLocalNotificationRequest]) async throws
  func cancelPending(withIdentifier identifier: String) async
  func cancelPending(withIdentifiers identifiers: [String]) async
  func cancelAllPending() async
  func removeDelivered(withIdentifier identifier: String) async
  func removeAllDelivered() async
}
```

Pluggable 草案仅含单条 schedule — **以实现为准扩展批量**；Mock 与 Manager 均实现完整协议。

### 8.2 `FKLocalNotificationManager`

```swift
public final class FKLocalNotificationManager: FKLocalNotificationScheduling, @unchecked Sendable {
  public static let shared: FKLocalNotificationManager
  public init(notificationCenter: UserNotificationCenterType = SystemUserNotificationCenter())
}
```

- 内部持有 `UNUserNotificationCenter` 抽象（便于 Mock）；
- `schedule` 映射 → `UNMutableNotificationContent` + `UNNotificationTrigger` → `add(_:withCompletionHandler:)` 包装为 `async throws`；
- 系统 error 映射为 `FKLocalNotificationError`。

### 8.3 更新语义

| 操作 | 行为 |
|------|------|
| 同 id 再 `schedule` | 替换 pending |
| 修改已投递内容 | 不支持 — 仅 `removeDelivered` 后重新 schedule |
| 取消后重排 | `cancelPending` → `schedule` |

### 8.4 Pending 数量上限（系统约束）

- iOS 对 **pending 本地通知**硬限制约 **64 条**（含 repeating 计为 1 条）；超出时系统**静默保留最早触发的 64 条**，**无**错误回调。
- v1：文档 + README 警告；`pendingRequests().count` 供集成方自检；接近上限时 debug log。
- v1.1（可选）：`FKLocalNotificationPendingBudget` — 超出部分落 `FKStorage`，App 激活时重排（见 §22）。

---

## 9. 查询与 Badge

### 9.1 查询 API

```swift
extension FKLocalNotificationManager {
  public func pendingRequests() async -> [FKLocalNotificationPendingSummary]
  public func deliveredNotifications() async -> [FKLocalNotificationDeliveredSummary]
}

public struct FKLocalNotificationPendingSummary: Sendable, Hashable, Identifiable {
  public var id: String { identifier }
  public let identifier: String
  public let content: FKLocalNotificationContent
  public let triggerDescription: String
}

public struct FKLocalNotificationDeliveredSummary: Sendable, Hashable, Identifiable {
  public var id: String { identifier }
  public let identifier: String
  public let content: FKLocalNotificationContent
  public let deliveryDate: Date?
}
```

### 9.2 Badge

```swift
extension FKLocalNotificationManager {
  /// Sets app icon badge; uses iOS 16+ API when available.
  public func setBadgeCount(_ count: Int) async throws
  public func clearBadge() async throws
}
```

- iOS 16+：`UNUserNotificationCenter.setBadgeCount(_:withCompletionHandler:)`；
- iOS 15 回退：`UIApplication.shared.applicationIconBadgeNumber`（文档标注 MainActor 调用方责任，或 Manager 内部 `MainActor.run`）。

---

## 10. 分类与操作按钮

### 10.1 模型

```swift
public struct FKLocalNotificationCategory: Sendable, Hashable {
  public var identifier: String
  public var actions: [FKLocalNotificationAction]
  public var intentIdentifiers: [String]
  public var options: FKLocalNotificationCategoryOptions
}

public struct FKLocalNotificationAction: Sendable, Hashable {
  public var identifier: String
  public var title: String
  public var options: FKLocalNotificationActionOptions
}

public struct FKLocalNotificationCategoryOptions: OptionSet, Sendable {
  public static let customDismissAction
  public static let allowInCarPlay
  // ...
}
```

### 10.2 注册

```swift
extension FKLocalNotificationManager {
  public func registerCategories(_ categories: [FKLocalNotificationCategory]) async throws
  public func registeredCategoryIdentifiers() async -> Set<String>
}
```

- App 启动时注册一次；重复注册覆盖；
- `FKLocalNotificationRequest.categoryIdentifier` 必须已注册，否则系统仍展示但无自定义操作（debug log 警告，不 throw）。

---

## 11. 前台展示与 Delegate 桥接

### 11.1 问题

App 前台时，本地通知默认可能不展示 Banner。需实现 `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)`。

### 11.2 `FKLocalNotificationCenterDelegateAdapter`

内部类型，由 Manager 在 `installDelegateIfNeeded()` 时注册（opt-in，避免多 delegate 冲突）：

```swift
public struct FKLocalNotificationPresentationOptions: OptionSet, Sendable {
  public static let banner
  public static let list
  public static let sound
  public static let badge
}

extension FKLocalNotificationManager {
  /// Installs adapter as `UNUserNotificationCenter.current().delegate`.
  /// Call once from AppDelegate; forwards to any previous delegate if needed (v1.1).
  public func installDelegate(
    presentation: FKLocalNotificationPresentationOptions = [.banner, .list, .sound]
  )
}
```

**v1 行为：** 默认 **不**自动安装 delegate（`automaticallyInstallDelegate == false`）；调用 `installDelegate()` 会设置 adapter 为 `UNUserNotificationCenter.current().delegate` — 文档警告会覆盖已有 delegate。

**v1.1：** delegate 链/组合模式（forward 未处理方法）。

### 11.3 展示策略

| App 状态 | 默认 |
|----------|------|
| 前台 | 按 `presentation` 展示 banner + sound |
| 后台 | 系统默认 |
| 锁屏 | 系统默认 |

---

## 12. 点击响应与 DeepLink 路由

### 12.1 响应模型

```swift
public struct FKLocalNotificationResponse: Sendable {
  public let requestIdentifier: String
  public let actionIdentifier: String
  public let userInfo: [String: String]
  public let isDefaultAction: Bool
}

public typealias FKLocalNotificationResponseHandler = @Sendable (FKLocalNotificationResponse) -> Void
```

```swift
extension FKLocalNotificationManager {
  /// Thread-safe setter; delegate invokes on main queue.
  public func setResponseHandler(_ handler: FKLocalNotificationResponseHandler?)
  public func setDeeplinkRouter(_ router: (@Sendable (URL) -> Bool)?)
}
```

- 内部用 lock 保护 handler/router；**禁止**直接暴露可变成员（避免 `@unchecked Sendable` 数据竞争）。
- `deeplinkRouter` 默认 `nil`；
- 提供 convenience：`useBusinessKitDeeplink()` 内部调用 `FKBusinessKit.shared.deeplink.route(_:source:)`（`source: .unknown` 直至 BusinessKit 扩展）。

### 12.2 解析顺序

默认顺序（可通过 `FKLocalNotificationManagerConfiguration.routeDeeplinkBeforeResponseHandler` opt-in，默认 `false`）：

1. 构造 `FKLocalNotificationResponse`（含 `actionIdentifier`、`isDefaultAction`）；
2. 调用 `responseHandler`（若已设置）；
3. 若 `userInfo[fk.deeplink.url]` 存在且 `deeplinkRouter != nil` → 路由（**convenience**；复杂路由建议在 handler 内完成）；
4. **不**自动 `removeDelivered` — 宿主按需清理。

### 12.3 与远程推送分工

| 来源 | 模块 |
|------|------|
| 本地 schedule | **FKLocalNotificationManager** |
| APNs `userInfo` | 宿主 + **`FKPushNotificationRouting`**（Pluggable v2） |
| 二者相同 URL 键 | 共享 `FKLocalNotificationUserInfoKey.deeplinkURL` 约定 |

---

## 13. 公开 API 索引

| 类型 | 说明 |
|------|------|
| `FKLocalNotificationScheduling` | 协议 |
| `FKLocalNotificationManager` | 默认实现 + shared |
| `FKLocalNotificationRequest` | 调度输入 |
| `FKLocalNotificationContent` | 内容 |
| `FKLocalNotificationTrigger` | 触发器 |
| `FKLocalNotificationCategory` | 分类 |
| `FKLocalNotificationAction` | 操作按钮 |
| `FKLocalNotificationResponse` | 点击响应 |
| `FKLocalNotificationError` | 错误 |
| `FKLocalNotificationPresentationOptions` | 前台展示 |
| `FKLocalNotificationUserInfoKey` | 标准 payload 键 |
| `FKLocalNotificationManager.setResponseHandler` | 线程安全响应回调 |
| `FKLocalNotificationManager.setDeeplinkRouter` | 可选 Deeplink 路由 |
| `FKMockLocalNotificationScheduler` | Mock |
| `FKLocalNotificationManager.installDelegate` | Delegate 安装 |

---

## 14. 错误模型

```swift
public enum FKLocalNotificationError: Error, Sendable, Equatable {
  case notAuthorized
  case invalidTrigger(String)
  case invalidContent(String)
  case attachmentUnavailable(String)
  case systemError(String)
  case badgeUpdateFailed
}
```

| 错误 | 典型原因 |
|------|----------|
| `notAuthorized` | Permissions 未 granted |
| `invalidTrigger` | interval ≤ 0、repeats 间隔 < 60s |
| `invalidContent` | 空 title+body、attachment 路径无效 |
| `systemError` | `UNError` 映射，保留 code 描述 |

实现 `LocalizedError`，文案走 FKI18n（§19）。

---

## 15. 配置模型

```swift
public struct FKLocalNotificationManagerConfiguration: Sendable {
  public var defaultPresentation: FKLocalNotificationPresentationOptions
  /// Default `false` — call `installDelegate()` explicitly from AppDelegate / delegate adaptor.
  public var automaticallyInstallDelegate: Bool
  public var logSchedulingFailures: Bool
  /// When `true`, deeplink routing runs before `responseHandler` (default `false`).
  public var routeDeeplinkBeforeResponseHandler: Bool

  public static let `default`: Self  // automaticallyInstallDelegate == false
}
```

- `shared` 使用 `.default`（**不**自动覆盖 `UNUserNotificationCenter.delegate`）；
- 自定义实例可注入 `UserNotificationCenterType` 测试桩。

---

## 16. 并发与 Swift 6

| 规则 | 说明 |
|------|------|
| Manager | 不加 `@MainActor`；内部 serial queue 或与 UN 回调对齐 |
| **FKPermissions** | `@MainActor` — `canSchedule` / 授权检查须 `await MainActor.run { ... }` |
| `schedule` / `cancel` | `async`；completion handler 转 continuation |
| Delegate 方法 | 系统在 main queue 调用 — adapter 内 `@MainActor` 隔离 UI 相关 badge 回退 |
| Handler 注册 | `setResponseHandler` / `setDeeplinkRouter` 线程安全 |
| 类型 | Request/Content/Trigger/Error `Sendable` |
| Handler closure | `@Sendable`；避免捕获 non-Sendable UI |

---

## 17. Pluggable 与依赖注入

### 17.1 协议位置

```text
Sources/FKCoreKit/Components/Pluggable/Notifications/FKLocalNotificationScheduling.swift
Sources/FKCoreKit/Components/Pluggable/Notifications/FKLocalNotificationRequest.swift  // 若与 Manager 共享则放 Public 并由 Pluggable re-export
```

**决策（Q1 默认）：** 请求/内容类型定义在 **`LocalNotification/Public/`**，Pluggable 协议 **引用** 同模块类型，避免重复 struct。

### 17.2 注册

```swift
// FKPluggableServices (future)
public var localNotificationScheduler: any FKLocalNotificationScheduling
// default: FKLocalNotificationManager.shared
```

### 17.3 与 Pluggable 草案差异

| Pluggable 草案 | 本设计 |
|----------------|--------|
| 仅 `title/body/fireDate/timeInterval` | 完整 `Content` + `Trigger` enum |
| 无 query API | 增加 pending/delivered |
| 无 categories | v1 增加 |

实现 Pluggable 文档时 **以本文为准** 更新 §16.1 代码片段。

---

## 18. Mock 与测试

```swift
public final class FKMockLocalNotificationScheduler: FKLocalNotificationScheduling, @unchecked Sendable {
  public private(set) var scheduled: [FKLocalNotificationRequest] = []
  public var shouldThrow: FKLocalNotificationError?
  public var authorizationGranted: Bool = true
  // ...
}
```

- 内存存储 scheduled/cancelled；
- Examples「模拟点击」：直接调用 `responseHandler`；
- **公开** Mock（与 `FKMockBiometricAuthenticator` 一致）。

---

## 19. 本地化（FKI18n）

| 键 | 用途 |
|----|------|
| `fkcore.local_notification.error.not_authorized` | 未授权 |
| `fkcore.local_notification.error.invalid_trigger` | 触发器无效 |
| `fkcore.local_notification.error.system` | 系统失败 |
| `fkcore.local_notification.permission.pre_prompt.title` | 文档示例（可选，宿主可自定义） |

通知 **title/body** 由集成方本地化后传入 — Manager 不自动翻译。

---

## 20. 宿主 App 集成清单

1. **Info.plist** — 无需专用 key；建议说明性 copy 配合预提示。
2. **启动** — `registerCategories`；**显式** `installDelegate()`（SwiftUI：`UIApplicationDelegateAdaptor`）；可选 launch 时 `clearBadge`。
3. **权限** — 功能点前 `FKPermissions.request(.notifications)`（`@MainActor`）。
4. **AppDelegate** — 若远程推送共存，delegate 方法转发顺序见 README（v1.1 delegate 链）。
5. **Background** — 本地通知无需 `UIBackgroundModes`；location 触发除外（v2）。
6. **Pending 预算** — Reminder 类 App 须监控 64 条上限（§8.4）。

---

## 21. 安全与隐私

- **禁止**在 `userInfo` 存放 refresh token、密码、PII 明文；仅 opaque id 或 signed token id；
- **禁止**日志打印完整 `userInfo`（Release）；
- Deeplink URL 路由前由宿主 **校验** scheme/host（复用 BusinessKit route 校验）；
- `interruptionLevel: .timeSensitive` 须 App 具备 **Time Sensitive Notifications** capability，否则系统降级；
- 通知内容遵守 GDPR/本地法规 — 退订/关闭路径文档化（跳转 Settings）；
- **64 条 pending 上限** — 见 §8.4；超出时用户可能永远收不到通知且 App 无回调。

---

## 22. v2 能力展望（非 v1 交付）

| 能力 | 说明 |
|------|------|
| `FKLocalNotificationPendingBudget` | Storage 溢出队列 + 激活时重排（§8.4） |
| `UNLocationNotificationTrigger` | 地理围栏；依赖 Location + 显著位置 |
| 附件富媒体 | 图片/音频附件；大小限制 |
| `FKPushNotificationRouting` 一体 Examples | 本地 + 远程统一 Deeplink |
| `FKDeeplinkSource.localNotification` / `.push` | BusinessKit 枚举扩展 |
| Delegate 链 | 与第三方 SDK 共存 |
| Notification Content Extension 模板 | 文档 + 示例 target |
| 排程持久化层 | 崩溃恢复、与 Storage 同步的 id  registry |
| Time Sensitive / Critical Alert | entitlement 门控 API |

---

## 23. FKCoreKit 复用要求

| 需求 | 使用 |
|------|------|
| 权限 | `FKPermissions.shared` |
| Deeplink | `FKBusinessKit.shared.deeplink`（optional） |
| 错误文案 | `FKI18n.string` |
| 日志 | `FKLogger`（debug 调度失败，不 log PII） |
| 日期/时区 | `Components/Extension/Foundation` 已有 Date/Calendar 扩展 |

**禁止**复制 Permissions 内 UN 授权逻辑。

---

## 24. 建议源码目录结构

```text
Sources/FKCoreKit/Components/LocalNotification/
├── README.md
├── Public/
│   ├── FKLocalNotificationScheduling.swift      # 或仅 Pluggable 引用
│   ├── FKLocalNotificationManager.swift
│   ├── FKLocalNotificationRequest.swift
│   ├── FKLocalNotificationContent.swift
│   ├── FKLocalNotificationTrigger.swift
│   ├── FKLocalNotificationCategory.swift
│   ├── FKLocalNotificationResponse.swift
│   ├── FKLocalNotificationError.swift
│   ├── FKLocalNotificationPresentationOptions.swift
│   ├── FKLocalNotificationUserInfoKey.swift
│   ├── FKLocalNotificationManagerConfiguration.swift
│   └── FKMockLocalNotificationScheduler.swift
├── Internal/
│   ├── FKLocalNotificationCenterDelegateAdapter.swift
│   ├── FKLocalNotificationRequestMapper.swift     # FK ↔ UN
│   ├── FKLocalNotificationTriggerMapper.swift
│   ├── FKLocalNotificationErrorMapper.swift
│   └── UserNotificationCenterType.swift           # protocol + system wrapper
└── Extension/
    └── FKLocalNotificationManager+BusinessKit.swift  # useBusinessKitDeeplink()
```

`Package.swift` — 将 `Components/LocalNotification` 加入 `fkCoreKitModuleDocDirectories` exclude 列表。

Pluggable：

```text
Sources/FKCoreKit/Components/Pluggable/Notifications/
└── FKLocalNotificationScheduling.swift            # protocol only if split
```

---

## 25. FKKitExamples 场景

路径建议：`Examples/FKKitExamples/FKKitExamples/Examples/FKCoreKit/LocalNotification/`

### 25.1 Hub

| # | 场景 | 验证点 |
|---|------|--------|
| H0 | `FKLocalNotificationHubViewController` | 导航至各子场景 |

### 25.2 基线（v1）

| # | 场景 | 验证点 |
|---|------|--------|
| B1 | `PermissionGate` | 预提示 → 系统授权 → granted 后启用调度 |
| B2 | `ScheduleInterval` | 10s 后通知；foreground banner |
| B3 | `ScheduleCalendarDaily` | 每日重复；pending 列表 |
| B4 | `CategoryActions` | 「标记已读」「稍后」两操作 |
| B5 | `CancelAndReplace` | 同 id 覆盖；cancel 生效 |
| B6 | `BadgeCount` | 设置/清除角标 |
| B7 | `DeeplinkTap` | userInfo URL → BusinessKit 路由演示 |
| B8 | `MockScheduler` | 无系统弹窗的单元式演示 |

### 25.3 增强（v1.1+）

| # | 场景 | 验证点 |
|---|------|--------|
| E1 | `AttachmentImage` | 图片附件 |
| E2 | `ProvisionalAuthorization` | 静默 provisional |
| E3 | `PluggableInjection` | Mock scheduler 注入 |

---

## 26. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **L0** | 核心 API + Mapper + Error | schedule/cancel/query |
| **L1** | Delegate adapter + 前台展示 | willPresent |
| **L2** | Categories + Response + Deeplink 桥接 | 点击路由 |
| **L3** | Pluggable 协议对齐 + Mock + README | DI |
| **L4** | Examples B1–B8 + Hub | 演示 |
| **L5** | 根 README / Roadmap / Gap 勾选 | 发布卫生 |

每阶段：`xcodebuild` `SWIFT_STRICT_CONCURRENCY=complete` → CHANGELOG。

---

## 27. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 类型定义在 LocalNotification vs Pluggable？ | **LocalNotification/Public**，Pluggable 引用 |
| Q2 | `installDelegate` 覆盖已有 delegate？ | v1 覆盖 + 文档警告；v1.1 链式转发 |
| Q3 | `schedule` 在未授权时 throw vs no-op？ | **throw** `notAuthorized` |
| Q4 | Badge API 是否独立 protocol？ | 否，Manager extension |
| Q5 | 是否依赖 FKUIKit？ | **否** — 纯 FKCoreKit |
| Q6 | BusinessKit `FKDeeplinkSource` 扩展时机？ | v1.1；v1 用 `.unknown` |
| Q7 | 批量 schedule 部分失败语义？ | 全部 throw 首个错误；v1.1 返回 `[Result]` |
| Q8 | attachment v1 还是 v1.1？ | **v1.1** |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初版：Tier 3 完整模块设计 |
| 2026-06-14 | 审查修订：FKPermissions MainActor；64 pending 上限；immediate→nil trigger；handler 线程安全；附件移 v1.1 |

---

## 29. 相关文档

| 文档 | 内容 |
|------|------|
| [Permissions/README.md](../Sources/FKCoreKit/Components/Permissions/README.md) | `.notifications` 权限 |
| [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) | §16.1 契约、§16.2 远程推送 |
| [FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md) | Deeplink 路由 |
| [FKBanner-FKNoticeBar_DESIGN.md](FKBanner-FKNoticeBar_DESIGN.md) | 应用内条带 vs 系统通知 |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §9 Tier 3 |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | Tier 3 排期 |
| [FKBackgroundTaskManager_DESIGN.md](FKBackgroundTaskManager_DESIGN.md) | BG 任务 vs 通知选型 |
