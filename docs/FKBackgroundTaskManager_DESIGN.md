# FKBackgroundTaskManager — 模块设计需求文档

FKKit **`FKBackgroundTaskManager`** 的实现指导文档：统一封装 **`BGTaskScheduler`**（App Refresh / Processing 延迟任务）与 **`UIApplication.beginBackgroundTask`**（切后台后的短时续跑）；与 **`FKFileManager`** 后台 URLSession、**`FKBusinessKit`** 启动任务/生命周期、**`FKAsync`** GCD 调度分层清晰；实现 **`FKBackgroundTaskScheduling`** Pluggable 契约。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) Tier 3 — FKBackgroundTaskManager  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §9  
**Pluggable 契约：** [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) §16.3  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 两大执行模型](#6-两大执行模型)
- [7. BGTaskScheduler — 注册与 Info.plist](#7-bgtaskscheduler--注册与-infoplist)
- [8. BGTaskScheduler — 调度请求](#8-bgtaskscheduler--调度请求)
- [9. BGTask 处理器生命周期](#9-bgtask-处理器生命周期)
- [10. 短时续跑 beginBackgroundTask](#10-短时续跑-beginbackgroundtask)
- [11. 与 BusinessKit 组合](#11-与-businesskit-组合)
- [12. 与 FileManager / Network / Storage 组合](#12-与-filemanager--network--storage-组合)
- [13. 公开 API 索引](#13-公开-api-索引)
- [14. 错误模型](#14-错误模型)
- [15. 配置模型](#15-配置模型)
- [16. 并发与 Swift 6](#16-并发与-swift-6)
- [17. Pluggable 与依赖注入](#17-pluggable-与依赖注入)
- [18. Mock 与测试](#18-mock-与测试)
- [19. 本地化（FKI18n）](#19-本地化fki18n)
- [20. 宿主 App 集成清单](#20-宿主-app-集成清单)
- [21. 安全、隐私与配额](#21-安全隐私与配额)
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

iOS App 在**切后台**或**进程未运行**时仍可能需要完成：埋点 flush、缓存清理、配置预拉取、轻量同步。各团队重复集成 `BGTaskScheduler`、`beginBackgroundTask`：identifier 与 Info.plist 不一致、expiration 未调用 `setTaskCompleted`、与 URLSession 后台传输混淆、启动任务与 BG 任务职责不清。

**`FKBackgroundTaskManager`**（建议路径 `Sources/FKCoreKit/Components/BackgroundTask/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKBackgroundTaskScheduling`** | Pluggable 契约：注册 + 调度 BGTask |
| **`FKBackgroundTaskManager`** | 默认 `BGTaskScheduler` + `UIApplication` 编排 |
| **`FKBackgroundWorkExtending`** | `beginBackgroundTask` 短时续跑协议 |
| **`FKBackgroundTaskRegistration`** | App Refresh / Processing 注册描述符 |
| **`FKBackgroundAppRefreshRequest`** | 调度 App Refresh |
| **`FKBackgroundProcessingRequest`** | 调度 Processing（网络/充电约束在 submit 时设置） |
| **`FKBackgroundTaskHandle`** | BG 任务执行上下文（完成/过期） |
| **`FKBackgroundWorkToken`** | 短时续跑 token（`end()`） |
| **`FKBackgroundTaskError`** | 稳定错误分类 |
| **`FKMockBackgroundTaskScheduler`** | 测试用内存实现 |

**关键约束：** 本模块管理 **BGTaskScheduler** 与 **beginBackgroundTask**；**不**替代 **`URLSession` 后台传输**（见 `FKFileManager` §12、§14）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **双模型统一门面** — 同一 Manager 暴露「延迟 BG 任务」与「切后台续跑」API，文档化选型树。
2. **类型化注册** — `registerAppRefresh` / `registerProcessing` 包装 `BGTaskScheduler.register`，启动期一次安装。
3. **类型化调度** — `scheduleAppRefresh` / `scheduleProcessing` 包装 `submit`；校验 identifier **已在 Manager 内 register**；plist 白名单由 **宿主静态配置 + 系统 register/submit 错误映射**（见 §14）。
4. **Handler 契约** — `async` handler 返回 `Bool`（success）；框架保证 `setTaskCompleted` / expiration 成对调用。
5. **短时续跑** — `beginBackgroundWork` **同步**返回 `FKBackgroundWorkToken` 后立即在后台 `Task` 执行 work；超时自动 `end()`。
6. **取消调度** — `cancelScheduledTask(withIdentifier:)` 包装 `BGTaskScheduler.cancel`。
7. **查询（debug）** — `pendingTaskRequests()` 映射为可读摘要（仅 DEBUG 或 opt-in）。
8. **BusinessKit 配方** — 文档 + 可选 convenience：`flushAnalyticsOnBackground()` 等（不硬依赖 BusinessKit）。
9. **Swift 6** — 配置/handler `@Sendable`；Manager 无 UI；BG 回调线程文档化。
10. **Pluggable + Mock** — 符合 `FKBackgroundTaskScheduling`；公开 Mock。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| `URLSession` 后台下载/上传 | **`FKFileManager`** — `allowsBackground` + `handleEventsForBackgroundURLSession` |
| 静默推送 `content-available` 处理 | 宿主 AppDelegate；可选 Pluggable `FKPushNotificationRouting` |
| 音频/VoIP/定位长期后台 | 需专用 Background Modes entitlement；不在 v1 |
| `performFetchWithCompletionHandler` 封装 | **不封装** — 用 `BGAppRefreshTask` 替代；见 §7.4 迁移副作用 |
| 配置 `BGTaskSchedulerPermittedIdentifiers` 后继续用旧 Background Fetch API | 系统会**禁用** `application(_:performFetchWithCompletionHandler:)` 与 `setMinimumBackgroundFetchInterval` |
| 跨进程 Extension 调度 | Widget / NSE 各自注册；本模块仅主 App |
| 保证 BG 任务准时执行 | 系统启发式；仅文档化最佳实践 |
| watchOS / macOS | 仅 iOS 15+（`BGTaskScheduler` iOS 13+，FKKit floor iOS 15） |
| 自动写 Info.plist | 宿主 Xcode 配置；README 逐步清单 |

### 2.3 成功标准

- [ ] `installRegistrations()` 在 `application(_:didFinishLaunching:)` **返回前**（同步路径）完成；identifier 与 plist 一致时不 crash。
- [ ] `scheduleAppRefresh` 提交成功；通过 **Xcode → Debug → Simulate Background Tasks** 或 DEBUG 下 `pendingTaskRequests()` 验证 pending（**非**用户「设置」App）。
- [ ] Handler 正常返回后 `task.setTaskCompleted(success:)` 被调用。
- [ ] Expiration 时 `setTaskCompleted(success: false)` 被调用，handler 内 `isExpired` 为 true。
- [ ] `beginBackgroundWork` **同步**取得 token 后，在 `didEnterBackground` 场景下 async work 能完成并 `end()`。
- [ ] 未注册 identifier 调度 → `FKBackgroundTaskError.unregisteredIdentifier`。
- [ ] Examples：注册、调度、Mock 续跑、BusinessKit flush 配方。
- [ ] README 含与 FileManager / Startup / Lifecycle 选型树。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 领域 | 状态 |
|------|------|
| `BGTaskScheduler` / `beginBackgroundTask` 封装 | **无** |
| `FKFileManager` 后台 URLSession | **已交付** — 独立 background session |
| `FKBusinessKit.utils.startup` | **已交付** — **前台**启动任务，非 BG |
| `FKBusinessKit.lifecycle` | **已交付** — 状态流，不执行 BG 调度 |
| `FKAsync` | GCD 延迟/队列 — **非**系统 BG API |
| Pluggable `FKBackgroundTaskScheduling` | **草案** §16.3，无参考实现 |

### 3.2 重复集成痛点

| 痛点 | 影响 |
|------|------|
| identifier 未写入 `BGTaskSchedulerPermittedIdentifiers` | 启动 crash |
| 忘记 `setTaskCompleted` | 系统惩罚后续 BG 配额 |
| `beginBackgroundTask` 未 `end` | 被系统 kill；battery 警告 |
| 把大文件下载放进 BGProcessing | 应使用 URLSession background |
| 启动时 `runAll()` 与 BG refresh 重复 | 浪费电量、逻辑重复 |
| 模拟器上 BG 从不触发 | 开发误以为 bug |

---

## 4. 架构总览

```text
┌────────────────────────────────────────────────────────────────────┐
│                         Host Application                            │
│  AppDelegate / @main App                                            │
│    didFinishLaunching → FKBackgroundTaskManager.installRegistrations│
│    didEnterBackground → beginBackgroundWork { flush / save }        │
│  Feature modules                                                    │
│    scheduleAppRefresh / scheduleProcessing after user action        │
└───────────────────────────────┬────────────────────────────────────┘
                                │
┌───────────────────────────────▼────────────────────────────────────┐
│              FKBackgroundTaskManager (FKCoreKit)                      │
│  FKBackgroundTaskScheduling     — register + schedule BGTask         │
│  FKBackgroundWorkExtending      — beginBackgroundTask wrapper        │
│  FKBackgroundTaskCenter (internal) — expiration / completion glue    │
└───────────────┬──────────────────────────────┬─────────────────────┘
                │                              │
                ▼                              ▼
       BGTaskScheduler.shared          UIApplication.shared
       (BGAppRefresh / Processing)     (beginBackgroundTask / end)
                │
                ▼
         System executes handler
         (app woken in background)
```

**数据流（延迟 Refresh）：**

```text
用户完成关键操作 / lifecycle background
  → scheduleAppRefresh(earliestBeginDate: +15min)
  → 系统择机唤醒 App
  → registered handler(FKBackgroundTaskHandle)
  → async work → handle.complete(success:)
```

**数据流（切后台续跑）：**

```text
didEnterBackground
  → let token = beginBackgroundWork(name:) { await track.flush() }  // 同步返回 token
  → token.end() 或 expiration 自动 end
```

---

## 5. 模块边界

### 5.1 选型树（必读）

| 需求 | 推荐组件 | 说明 |
|------|----------|------|
| App **未运行**时定期轻量刷新（配置、小数据 sync） | **`FKBackgroundTaskManager`** — `BGAppRefreshTask` | 分钟~小时级，系统决定时机 |
| App **未运行**时较重任务（数据库清理、批量上传） | **`FKBackgroundTaskManager`** — `BGProcessingTask` | 可要求网络/充电 |
| App **切后台**后还需几十秒内跑完 | **`beginBackgroundWork`** | ~30s 量级，不保证 |
| **大文件**断点下载/上传 | **`FKFileManager`** | Background `URLSession` |
| **冷启动**时延迟非关键初始化 | **`FKBusinessKit.utils.startup`** | 前台 `runAll()` |
| 监听前后台切换 | **`FKBusinessKit.lifecycle`** | 仅状态，不调度 BG |
| 线程内延迟/防抖 | **`FKAsync`** | GCD，进程必须存活 |
| 提醒用户（锁屏通知） | **`FKLocalNotificationManager`** | UserNotifications |

### 5.2 与 FKFileManager

| 维度 | FKBackgroundTaskManager | FKFileManager（URLSession 后台传输） |
|------|-------------------------|--------------------------------------|
| API | `BGTaskScheduler` | `URLSessionConfiguration.background` |
| 典型工作 | JSON sync、flush、DB vacuum | 100MB+ 文件传输 |
| 恢复 | handler 内自管 | `reconnectBackgroundTasks` + completion handler |
| Background Modes（Capability） | **Background fetch**（App Refresh）；**Background processing**（Processing） | 通常 **Background fetch**（`fetch`）；**不要求** Background processing |

**规范：** Processing handler **可以**调用 `FKNetworkClient` 小请求，但 **不应**替代 FileManager 传大文件。

### 5.3 与 BusinessKit

| BusinessKit | 关系 |
|-------------|------|
| `utils.startup` | **互补** — startup = 启动时；BG = 进程外/后台 |
| `lifecycle` → `.background` | **组合** — 进入后台时 `scheduleAppRefresh` 或 `beginBackgroundWork` |
| `track.flush()` | **典型** `beginBackgroundWork` 内容；注意 BusinessKit **已有**定时 flush，background 续跑为**补充** |
| Pluggable Analytics | handler 内注入 uploader |

### 5.4 与 FKPermissions

- BG 任务 **无**独立权限弹窗；
- Processing 若访问相机/相册等，仍须在 handler 内检查权限（通常应在 foreground 预置数据）。

---

## 6. 两大执行模型

### 6.1 模型 A — BGTaskScheduler（延迟 / 唤醒）

| 类型 | Apple 类型 | 典型用途 | 约束 |
|------|------------|----------|------|
| **App Refresh** | `BGAppRefreshTask` | 拉 remote config、增量 sync | 短、轻；~30s |
| **Processing** | `BGProcessingTask` | 缓存清理、日志压缩上传 | 可 `requiresNetworkConnectivity` / `requiresExternalPower` |

### 6.2 模型 B — beginBackgroundTask（续跑）

| 属性 | 说明 |
|------|------|
| 触发 | App **已在运行**，即将/已经进入 background |
| 时长 | 系统给予有限时间（通常 ≤ ~30s，不保证） |
| 适用 | flush、保存状态、完成小网络请求 |
| 不适用 | 长时间下载、可靠定时 |

### 6.3 组合模式（推荐）

```text
lifecycle.background
  ├─ beginBackgroundWork { await quickFlush() }     // 尽力立即完成
  └─ scheduleAppRefresh(earliestBeginDate: +1h)   // 失败或未完成的兜底
```

---

## 7. BGTaskScheduler — 注册与 Info.plist

### 7.1 Info.plist（宿主职责）

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.example.app.refresh.config</string>
  <string>com.example.app.processing.cleanup</string>
</array>
```

Target → Signing & Capabilities → **Background Modes**：

- ☑ **Background fetch**（App Refresh）
- ☑ **Background processing**（Processing）

### 7.2 注册 API

```swift
public struct FKBackgroundTaskRegistration: Sendable, Hashable {
  public enum Kind: Sendable, Hashable {
    case appRefresh
    case processing
  }
  public let identifier: String
  public let kind: Kind
}
```

> **说明：** `requiresNetworkConnectivity` / `requiresExternalPower` 属于 **`BGProcessingTaskRequest` 提交时**属性（§8.2），**不在** `BGTaskScheduler.register` 阶段配置。

```swift
extension FKBackgroundTaskManager {
  /// Registers all handlers with BGTaskScheduler. Call once before application finishes launching.
  public func installRegistrations(_ registrations: [FKBackgroundTaskRegistration]) throws

  public func registerAppRefresh(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws

  public func registerProcessing(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws
}
```

**规则：**

- 同一 `identifier` 仅注册一次；重复 `register` → `FKBackgroundTaskError.duplicateRegistration`；
- `installRegistrations` 内部调用 `registerAppRefresh` / `registerProcessing`；
- **必须在** `application(_:didFinishLaunching:)` **返回前**、**同步路径**完成注册（Apple 要求）；SwiftUI `@main` App 使用 `UIApplicationDelegateAdaptor` 同理。

### 7.3 Identifier 约定

- 反向 DNS：`{bundleID}.refresh.{name}` / `{bundleID}.processing.{name}`；
- README 提供与 Examples 一致的 sample identifiers。
- **禁止**同一 identifier 同时用于 Refresh 与 Processing（Q8）。

### 7.4 从旧 Background Fetch 迁移

配置 `BGTaskSchedulerPermittedIdentifiers` 后，系统**禁用**：

- `application(_:performFetchWithCompletionHandler:)`
- `UIApplication.shared.setMinimumBackgroundFetchInterval(_:)`

README 须说明：迁移至 `BGAppRefreshTask` + `scheduleAppRefresh`；勿与旧 API 混用。

---

## 8. BGTaskScheduler — 调度请求

### 8.1 App Refresh

```swift
public struct FKBackgroundAppRefreshRequest: Sendable, Hashable {
  public var identifier: String
  public var earliestBeginDate: Date?
}
```

```swift
public protocol FKBackgroundTaskScheduling: Sendable {
  func registerAppRefresh(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws
  func registerProcessing(
    identifier: String,
    handler: @escaping @Sendable (FKBackgroundTaskHandle) async -> Bool
  ) throws
  func scheduleAppRefresh(_ request: FKBackgroundAppRefreshRequest) async throws
  func scheduleProcessing(_ request: FKBackgroundProcessingRequest) async throws
  func cancelScheduledTask(withIdentifier identifier: String) async throws
}
```

> **Bootstrap：** `installRegistrations(_:)` 为 **Manager 便捷 API**（启动期批量注册），不强制纳入 Pluggable 协议；Feature 模块通过 DI 注入 `any FKBackgroundTaskScheduling` 时主要使用 `schedule*` / `cancel*`。

- 映射 `BGAppRefreshTaskRequest`；
- `earliestBeginDate` nil → 尽快；
- 频繁 `schedule` 会 coalesce — 文档说明勿 spam。

### 8.2 Processing

```swift
public struct FKBackgroundProcessingRequest: Sendable, Hashable {
  public var identifier: String
  public var earliestBeginDate: Date?
  public var requiresNetworkConnectivity: Bool
  public var requiresExternalPower: Bool
}
```

- 映射 `BGProcessingTaskRequest`；
- `requiresNetworkConnectivity` / `requiresExternalPower` **仅**在 submit 请求上设置（与 Apple API 一致）。

### 8.3 调度时机建议（README）

| 时机 | 建议 |
|------|------|
| 用户完成订单 / 同步触发点 | `scheduleAppRefresh(+15min)` |
| `lifecycle.background` | refresh + 可选 processing |
| 登录成功 | 预 schedule config refresh |
| App 启动 | **仅** `installRegistrations`，不强制 schedule |

---

## 9. BGTask 处理器生命周期

### 9.1 `FKBackgroundTaskHandle`

```swift
/// Shared handle for one BG task execution. Reference type — do not treat as value type.
public final class FKBackgroundTaskHandle: @unchecked Sendable {
  public let identifier: String
  public var isExpired: Bool { get }
  /// Marks task complete. Safe to call once; idempotent.
  public func complete(success: Bool)
}
```

**内部职责：**

1. 包装 `BGTask`（**引用类型**，避免 handler 内拷贝导致双 complete）；
2. 设置 `expirationHandler` → `isExpired = true`，取消 cooperative work（`Task.cancel` 若可）；
3. handler 返回后 `complete(success:)` → `setTaskCompleted(success:)`；
4. 若 handler 抛错 → `complete(success: false)`；
5. **禁止** double-complete — 内部 flag 保护。

### 9.2 Handler 签名

```swift
public typealias FKBackgroundTaskHandler = @Sendable (FKBackgroundTaskHandle) async -> Bool
```

| 返回值 | 语义 |
|--------|------|
| `true` | 工作成功完成 |
| `false` | 未完成或部分失败 — 系统可能降低优先级 |

### 9.3 协作式取消

- handler 内应周期性检查 `handle.isExpired` 或 `Task.isCancelled`；
- 长循环应可中断；
- 文档示例：Analytics flush 分批，每批检查 expired。

---

## 10. 短时续跑 beginBackgroundTask

### 10.1 协议

```swift
public protocol FKBackgroundWorkExtending: Sendable {
  /// Starts a UIKit background task and returns a token **immediately** (does not wait for `work`).
  @discardableResult
  func beginBackgroundWork(
    name: String?,
    work: @escaping @Sendable () async -> Void
  ) -> FKBackgroundWorkToken
}
```

```swift
public struct FKBackgroundWorkToken: Sendable {
  /// Ends background task. Idempotent.
  public func end()
  public var isValid: Bool { get }
}
```

### 10.2 行为

1. 调用 `UIApplication.shared.beginBackgroundTask(withName:expirationHandler:)`；
2. **同步**构造并返回 `FKBackgroundWorkToken`（**不得** await `work` 后再返回）；
3. 在 detached/`Task` 中 `await work()`；
4. `work` 完成 → `token.end()`；
5. expirationHandler 触发 → 取消 Task（若可能）→ `token.end()`；
6. `name` 用于 Instruments / debug（可选，默认 `"FKBackgroundWork"`）。

### 10.3 与 `@MainActor` work

- `work` 为 `@Sendable async` — UI 更新须在 work 内 `await MainActor.run { }`；
- 文档示例：flush 在网络线程，UI 不更新。

### 10.4 嵌套调用

- v1：**不**支持嵌套 token 栈；第二次 `beginBackgroundWork` 独立计数；
- 文档建议同一 `didEnterBackground` 合并为单次 work block。

---

## 11. 与 BusinessKit 组合

### 11.1 Analytics flush 配方（文档 + 可选 Extension）

```swift
// Extension/FKBackgroundTaskManager+BusinessKit.swift (optional, weak coupling via closure)
extension FKBackgroundTaskManager {
  /// Schedules refresh that flushes analytics when uploader provided.
  public func registerAnalyticsRefresh(
    identifier: String,
    flush: @escaping @Sendable () async -> Bool
  )
}
```

- v1 默认：**不**新增 BusinessKit 依赖 target；
- Extension 文件 `#if canImport` 或宿主自行 glue；
- Examples 演示 closure 注入 `FKBusinessKit.shared.track` 缓冲 flush。

### 11.2 Lifecycle 挂钩（宿主侧）

```swift
FKBusinessKit.shared.lifecycle.observe { state in
  guard state == .background else { return }
  // beginBackgroundWork 同步返回 token；flush 为 BusinessKit 定时 flush 的补充
  _ = FKBackgroundTaskManager.shared.beginBackgroundWork(name: "flush") {
    await FKBusinessKit.shared.track.flush()
  }
  Task {
    try? await FKBackgroundTaskManager.shared.scheduleAppRefresh(
      FKBackgroundAppRefreshRequest(
        identifier: "com.example.app.refresh.analytics",
        earliestBeginDate: Date().addingTimeInterval(3600)
      )
    )
  }
}
```

### 11.3 与 Startup 分工

| | Startup | Background Task |
|---|---------|-----------------|
| 运行时机 | 冷启动 foreground | 后台 / 进程唤醒 |
| API | `FKStartupTask` + `runAll()` | BG register/schedule |
| 典型 | 预热 UI 缓存 | 上传昨日日志 |

**禁止**在 `FKStartupTask` 内 `scheduleProcessing` 重任务 — 拖慢启动；应 register 在 launch，schedule 在用户行为或 background 触发。

---

## 12. 与 FileManager / Network / Storage 组合

### 12.1 FileManager

- 大文件：**仅** `FKFileManager.download(..., allowsBackground: true)`；
- BG Processing handler 可调用 `FKFileManager` **沙盒清理**（小文件 deleteExpired）；
- 交叉引用 [FKFileManager_DESIGN.md](FKFileManager_DESIGN.md) §12、§14。

### 12.2 Network

- Refresh handler 可使用 `FKNetworkClient` 拉 lightweight JSON；
- 须处理 offline — 配合 `FKNetworkReachability` 或 fast-fail；
- 重试由 handler 自行决定；**不**在 Manager 内建 HTTP retry。

### 12.3 Storage

- `FKCodableStorage` / `FKFileStorage` 过期清理适合 **Processing**；
- 文档示例：weekly processing task 删除 TTL 过期键。

---

## 13. 公开 API 索引

| 类型 | 说明 |
|------|------|
| `FKBackgroundTaskScheduling` | BG 注册与调度协议 |
| `FKBackgroundWorkExtending` | 短时续跑协议 |
| `FKBackgroundTaskManager` | 默认实现 + `shared` |
| `FKBackgroundTaskRegistration` | 批量安装描述符 |
| `FKBackgroundAppRefreshRequest` | Refresh 调度 |
| `FKBackgroundProcessingRequest` | Processing 调度 |
| `FKBackgroundTaskHandle` | Handler 上下文（引用类型） |
| `FKBackgroundWorkToken` | 续跑 token |
| `FKBackgroundTaskHandler` | Handler 类型别名 |
| `FKBackgroundTaskError` | 错误 |
| `FKBackgroundTaskManagerConfiguration` | 配置 |
| `FKMockBackgroundTaskScheduler` | Mock |

---

## 14. 错误模型

```swift
public enum FKBackgroundTaskError: Error, Sendable, Equatable {
  case unregisteredIdentifier(String)
  case duplicateRegistration(String)
  case identifierNotPermitted(String)
  case schedulingFailed(code: Int)
  case backgroundWorkUnavailable
  case alreadyInstalled
  case notInstalled
}
```

| 错误 | 典型原因 |
|------|----------|
| `unregisteredIdentifier` | schedule 前未 register |
| `identifierNotPermitted` | 系统 `register`/`submit` 失败（常见：identifier 未写入 plist 白名单）；**v1 运行时无法读取 plist 预校验** |
| `schedulingFailed` | `BGTaskScheduler.Error` 映射（too many pending 等） |
| `backgroundWorkUnavailable` | 非 iOS / 无 UIApplication |
| `alreadyInstalled` | 重复 `installRegistrations` |

实现 `LocalizedError` + FKI18n（§19）。

---

## 15. 配置模型

```swift
public struct FKBackgroundTaskManagerConfiguration: Sendable {
  public var allowsMultipleInstall: Bool
  public var logScheduling: Bool
  public var debugLogPendingTasks: Bool

  public static let `default`: Self
}
```

---

## 16. 并发与 Swift 6

| 规则 | 说明 |
|------|------|
| Manager | 不加 `@MainActor`；内部 serial queue 保护 registry |
| BG launchHandler | 系统在 background queue 调用 — handler 内使用 `async` |
| `beginBackgroundTask` | expiration 可能在任意线程 — `end()` 线程安全 |
| Handler / work | `@Sendable` |
| Registry | 启动期单线程写入；之后只读 |

---

## 17. Pluggable 与依赖注入

### 17.1 协议位置

```text
Sources/FKCoreKit/Components/BackgroundTask/Public/FKBackgroundTaskScheduling.swift
Sources/FKCoreKit/Components/Pluggable/BackgroundTask/FKBackgroundTaskScheduling.swift  # 若拆分则 re-export
```

**决策（Q1 默认）：** 类型定义在 **`BackgroundTask/Public/`**，Pluggable **引用**同模块类型。

### 17.2 与 Pluggable §16.3 对齐

| 项 | 本设计 |
|----|--------|
| 协议面 | `register*` + `schedule*` + `cancel*`（见 §8.1） |
| `installRegistrations` | Manager bootstrap；**不在**协议内 |
| handler | `FKBackgroundTaskHandle` 引用类型 + `async -> Bool` |
| beginBackgroundTask | **`FKBackgroundWorkExtending`** 独立协议 |

### 17.3 与 Pluggable 历史草案差异

| 草案 | 本设计 |
|------|--------|
| 仅 `registerRefreshTask` + `scheduleAppRefresh` | 增加 Processing、register 入协议、cancel |
| handler 直接 `async -> Bool` | 经 `FKBackgroundTaskHandle` |
| 无 beginBackgroundTask | **`FKBackgroundWorkExtending`** |

### 17.4 组合根（future）

```swift
// FKPluggableServices
public var backgroundTaskScheduler: any FKBackgroundTaskScheduling
// default: FKBackgroundTaskManager.shared
```

---

## 18. Mock 与测试

```swift
public final class FKMockBackgroundTaskScheduler: FKBackgroundTaskScheduling, FKBackgroundWorkExtending, @unchecked Sendable {
  public private(set) var scheduledRefresh: [FKBackgroundAppRefreshRequest] = []
  public private(set) var scheduledProcessing: [FKBackgroundProcessingRequest] = []
  public var simulateHandler: (@Sendable (String) async -> Bool)?

  public func simulateLaunch(identifier: String) async
}
```

- 内存记录 schedule 调用；
- `simulateLaunch` 手动触发已注册 handler — Examples 与单元测试；
- **公开** Mock。

---

## 19. 本地化（FKI18n）

| 键 | 用途 |
|----|------|
| `fkcore.background_task.error.unregistered` | 未注册 identifier |
| `fkcore.background_task.error.not_permitted` | plist 缺失 |
| `fkcore.background_task.error.scheduling_failed` | 提交失败 |
| `fkcore.background_task.error.work_unavailable` | 续跑不可用 |

Debug 日志英文即可；用户可见错误走 FKI18n。

---

## 20. 宿主 App 集成清单

1. **Capabilities** — 按任务类型勾选：**Background fetch**（App Refresh）、**Background processing**（Processing）；URLSession 大文件传输见 FileManager（通常仅 fetch）。
2. **Info.plist** — `BGTaskSchedulerPermittedIdentifiers` 与代码 identifier **完全一致**（建议 CI/Review 静态核对；Manager **不**读取 plist）。
3. **Launch** — `installRegistrations(...)` 于 `application(_:didFinishLaunching:)` **返回前**；SwiftUI 使用 `UIApplicationDelegateAdaptor`。
4. **Debug** — Xcode → **Debug → Simulate Background Tasks**；或 lldb 私有 simulate（§27 Q7，**仅开发**）。
5. **勿依赖模拟器** — BG 执行不可靠；真机 + 上述 Debug 菜单。
6. **Metrics** — handler 内记录 success/duration 到 `FKBusinessKit.track` 或 Logger。

---

## 21. 安全、隐私与配额

- BG handler **禁止** log PII / token；
- Processing 清理磁盘须限定在 App sandbox；
- 失败过多会导致系统降低 BG 频率 — README 说明；
- 勿用 BG 规避 App Store 后台模式审核（需真实用户价值）；
- 与 GDPR：后台上传须符合用户同意与隐私政策。

---

## 22. v2 能力展望（非 v1 交付）

| 能力 | 说明 |
|------|------|
| `BGContinuedProcessingTask` | iOS/iPadOS 26+；**用户显式发起**的长任务；需 title/subtitle、进度上报、可选 Background GPU capability；与 v1 `BGProcessingTask` **不同**，勿混用 |
| Delegate 链 / 多模块注册表 | 按 feature module 拆分 identifier 命名空间 |
| 与 `FKPushNotificationRouting` silent push 协同 | push 唤醒 + BG 分工文档 |
| 持久化「上次 schedule 时间」 | Storage 防 spam schedule |
| Instruments signpost | `os_signpost` 集成 |
| 自动 `installRegistrations` from JSON config | 大型 App 配置驱动 |
| watchOS `WKApplicationRefreshBackgroundTask` | 独立模块 |

---

## 23. FKCoreKit 复用要求

| 需求 | 使用 |
|------|------|
| 日志 | `FKLogger` — debug 级别 schedule/complete |
| 错误文案 | `FKI18n.string` |
| 网络（handler 内） | `FKNetworkClient`（可选，非 Manager 依赖） |
| 存储清理 | `FKFileStorage` / `FKCodableStorage` |
| 生命周期挂钩 | 文档引用 `FKBusinessKit.lifecycle` |
| 并发 | handler 内可用 `FKAsync` 队列工具 |

**禁止**复制 FileManager 的 URLSession background 逻辑。

---

## 24. 建议源码目录结构

```text
Sources/FKCoreKit/Components/BackgroundTask/
├── README.md
├── Public/
│   ├── FKBackgroundTaskScheduling.swift
│   ├── FKBackgroundWorkExtending.swift
│   ├── FKBackgroundTaskManager.swift
│   ├── FKBackgroundTaskRegistration.swift
│   ├── FKBackgroundAppRefreshRequest.swift
│   ├── FKBackgroundProcessingRequest.swift
│   ├── FKBackgroundTaskHandle.swift
│   ├── FKBackgroundWorkToken.swift
│   ├── FKBackgroundTaskError.swift
│   ├── FKBackgroundTaskManagerConfiguration.swift
│   └── FKMockBackgroundTaskScheduler.swift
├── Internal/
│   ├── FKBackgroundTaskCenter.swift
│   ├── FKBGTaskSchedulerType.swift          # protocol + BGTaskScheduler wrapper
│   ├── FKBackgroundTaskMapper.swift
│   ├── FKBackgroundWorkSession.swift        # beginBackgroundTask lifecycle
│   └── FKBackgroundTaskErrorMapper.swift
└── Extension/
    └── FKBackgroundTaskManager+Debug.swift  # pendingTaskRequests debug API
```

`Package.swift` — 将 `Components/BackgroundTask` 加入 `fkCoreKitModuleDocDirectories`。

---

## 25. FKKitExamples 场景

路径建议：`Examples/FKKitExamples/FKKitExamples/Examples/FKCoreKit/BackgroundTask/`

### 25.1 Hub

| # | 场景 | 验证点 |
|---|------|--------|
| H0 | `FKBackgroundTaskHubViewController` | 子场景导航 + plist 说明 |

### 25.2 基线（v1）

| # | 场景 | 验证点 |
|---|------|--------|
| B1 | `InstallRegistrations` | 启动注册代码片段展示 |
| B2 | `ScheduleAppRefresh` | 提交 + Debug simulate |
| B3 | `ScheduleProcessing` | 网络/充电约束说明 |
| B4 | `HandlerSuccessFail` | Mock simulateLaunch true/false |
| B5 | `BeginBackgroundWork` | 切后台续跑模拟（Manual trigger） |
| B6 | `CancelScheduled` | cancel 后 pending 消失 |
| B7 | `LifecycleFlushRecipe` | BusinessKit flush 配方 |
| B8 | `MockScheduler` | 无 BGTaskScheduler 的单元演示 |

### 25.3 增强（v1.1+）

| # | 场景 | 验证点 |
|---|------|--------|
| E1 | `StorageCleanupProcessing` | Storage TTL 清理 |
| E2 | `PluggableInjection` | Mock 注入 |
| E3 | `NetworkRefresh` | 轻量 config pull |

---

## 26. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **BT0** | Registry + Mapper + Error | register / install |
| **BT1** | schedule refresh/processing + cancel | 调度 API |
| **BT2** | Handler lifecycle + expiration | complete 语义 |
| **BT3** | beginBackgroundWork + Token | 短时续跑 |
| **BT4** | Pluggable 对齐 + Mock + README | DI |
| **BT5** | Examples B1–B8 + Hub | 演示 |
| **BT6** | Gap/Roadmap/Pluggable 交叉引用 | 文档卫生 |

每阶段：`xcodebuild` `SWIFT_STRICT_CONCURRENCY=complete` → CHANGELOG。

---

## 27. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 类型定义在 BackgroundTask vs Pluggable？ | **BackgroundTask/Public** |
| Q2 | `FKBackgroundWorkExtending` 是否合并进同一协议？ | **独立协议**，Manager 双符合 |
| Q3 | BusinessKit Extension 是否入库？ | v1 **仅 Examples 配方**；v1.1 optional Extension |
| Q4 | `installRegistrations` 重复调用？ | 默认 throw `alreadyInstalled`；config 可允许多次 |
| Q5 | Handler 内自动 `Task.checkCancellation`？ | 文档约定；v1 不 wrapper |
| Q6 | DEBUG `pendingTaskRequests` public？ | `#if DEBUG` public，Release internal |
| Q7 | lldb `_simulateLaunchForTaskWithIdentifier` 文档？ | README 链 **Xcode Debug 菜单**；lldb 命令标注 **private API、仅开发** |
| Q8 | Processing 与 Refresh 共用 identifier？ | **禁止** — 一 id 一 kind |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初版：Tier 3 完整模块设计 |
| 2026-06-14 | 审查修订：Handle 改引用类型；beginBackgroundWork 同步返回 token；Processing 约束仅 submit；register 纳入协议；plist/launch/debug 表述修正 |

---

## 29. 相关文档

| 文档 | 内容 |
|------|------|
| [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) | §16.3 契约、E17 |
| [FKFileManager_DESIGN.md](FKFileManager_DESIGN.md) | URLSession 后台传输 §12、§14 |
| [FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md) | Startup §14.5、Lifecycle §11 |
| [FKLocalNotificationManager_DESIGN.md](FKLocalNotificationManager_DESIGN.md) | 通知 vs BG 选型 |
| [Async/README.md](../Sources/FKCoreKit/Components/Async/README.md) | GCD 调度 |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §9 Tier 3 |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | Tier 3 排期 |
