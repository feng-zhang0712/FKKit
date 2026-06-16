# FKPluggable — 模块增强设计需求文档

FKKit **`FKPluggable`** 的**增量增强**实现指导文档：在现有协议契约层之上，交付 **参考实现（Reference Implementations）**、**模块桥接适配器**、**组合根（Composition Root）** 与 **测试 Mock 套件**，补齐「仅有协议、无落地」的高价值能力，并消除与 `Network` / `Storage` / `BusinessKit` / `Logger` 等模块的**平行协议栈**摩擦。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §Pluggable 契约对齐  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §11  
**模块 README：** [Pluggable/README.md](../Sources/FKCoreKit/Components/Pluggable/README.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 现状基线](#4-现状基线)
- [5. 结构性缺口：平行协议栈](#5-结构性缺口平行协议栈)
- [6. 增强项总览](#6-增强项总览)
- [7. 参考实现 — Configuration](#7-参考实现--configuration)
- [8. 参考实现 — Session](#8-参考实现--session)
- [9. 参考实现 — Storage 桥接](#9-参考实现--storage-桥接)
- [10. 参考实现 — Networking 桥接](#10-参考实现--networking-桥接)
- [11. 参考实现 — Logging 桥接](#11-参考实现--logging-桥接)
- [12. 参考实现 — Lifecycle 与 Routing 桥接](#12-参考实现--lifecycle-与-routing-桥接)
- [13. 参考实现 — Analytics 桥接](#13-参考实现--analytics-桥接)
- [14. 参考实现 — Text Input](#14-参考实现--text-input)
- [15. 参考实现 — Reachability 统一](#15-参考实现--reachability-统一)
- [16. 新增 Pluggable 契约（v2 协议组）](#16-新增-pluggable-契约v2-协议组)
- [17. 组合根与服务注册](#17-组合根与服务注册)
- [18. Mock 与测试套件](#18-mock-与测试套件)
- [19. 契约版本与破坏性变更](#19-契约版本与破坏性变更)
- [20. 模块边界与复用](#20-模块边界与复用)
- [21. 公开 API 草案汇总](#21-公开-api-草案汇总)
- [22. 错误模型](#22-错误模型)
- [23. 并发与 Sendable](#23-并发与-sendable)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [26. 分阶段交付计划](#26-分阶段交付计划)
- [27. 待决问题](#27-待决问题)
- [28. 修订历史](#28-修订历史)
- [29. 相关文档](#29-相关文档)

---

## 1. 概述

`FKPluggable`（`Sources/FKCoreKit/Components/Pluggable/`）定义 iOS App **可插拔基础设施边界**：网络、埋点、存储、会话、配置、本地化、路由、日志、生命周期、图片、列表 Cell、文本输入等 **21 个 Swift 文件、仅协议与共享值类型**。

设计原则（见 `FKPluggable.swift`）：

- **Protocol-oriented** — 模块边界依赖抽象；
- **Injectable** — 在 App 启动或测试中装配具体类型；
- **Testable** — Mock/Stub 无需继承 UIKit；
- **Sendable-first** — Swift 6 并发友好。

**当前成熟度判断：**

| 维度 | 状态 |
|------|------|
| 协议覆盖面 | 广 — 覆盖中大型 App 常见 DI 切面 |
| 库内参考实现 | 窄 — 仅 `FKImageLoader`、`FKBiometricAuth`（经 typealias）、`FKI18n` → `FKLocalizing` |
| 与邻模块对齐 | 弱 — `Storage`/`Network`/`BusinessKit`/`Logger` 各有平行协议，未桥接 |
| 组合根 | 无 — README 仅有 sketch，无 `FKPluggableServices` 类型 |
| Mock 套件 | 零散 — `FKMockBiometricAuthenticator` 等分散在各组件 |

本设计文档将缺口规范化为 **可验收交付项**，分为：

1. **桥接适配器** — 让现有生产模块 **自动符合** Pluggable 协议；
2. **参考实现** — Feature Flag、Remote Config、Session、Text Formatter 等；
3. **组合根** — 可选的 `Sendable` 服务容器与 Examples 装配模板；
4. **v2 协议组** — 本地通知、推送路由、后台任务（按需）；
5. **Mock 套件** — 统一测试注入路径。

**原则：** 全部为 **opt-in**；未使用参考实现时，现有公开 API **行为不变**（semver minor）。中大型 App **仍可** 仅依赖协议并在宿主侧实现。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **消除平行协议摩擦** — `FKCodableStoring` ↔ `FKCodableStorage`、`FKNetworkReachabilityProviding` ↔ `NetworkStatusProviding` 等提供官方桥接或统一类型别名策略（见 §5）。
2. **Tier 1 参考实现** — `FKFeatureFlagProviding`、`FKRemoteConfigProviding`、`FKAppEnvironmentProviding`、`FKUserSessionProviding` + `FKUserSessionObserving`。
3. **Tier 2 参考实现** — `FKTextFormatting` / `FKTextValidating` 共享规则（手机号、邮箱、银行卡等）；`FKPluggableLogging` ← `FKLogger` 桥接。
4. **Networking 桥接** — `FKAPIClientProviding` 适配 `FKNetworkClient`；`FKCredentialProviding` 适配 Keychain Storage。
5. **组合根模板** — `FKPluggableServices`（或等价）+ Examples `AppCompositionRoot` 场景。
6. **Mock 套件** — `Pluggable/Mock/` 下可复用 Stub（API Client、Session、Feature Flag、Reachability）。
7. **文档** — 更新 `Pluggable/README.md` 契约表（✅ 参考实现 / 🔌 桥接 / 📋 仅协议）；`contractVersion` 策略文档化。
8. **Swift 6** — 新类型 `Sendable`；`@MainActor` 仅 UI 相关协议（路由、图片加载）。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| 强制全局单例 | 参考实现可提供 `shared`，但组合根注入为推荐路径 |
| 第三方 SDK 适配器 | Firebase Remote Config、LaunchDarkly 等由宿主实现协议 |
| 替换 `BusinessKit` / `Network` 公开 API | 仅桥接与文档对齐，不删现有类型 |
| 合并 `FKBusinessKit` 与 `FKPluggable` 为单一 mega-module | 保持 Pluggable 薄契约层 |
| GraphQL / WebSocket 客户端 | 不在 Pluggable v1 增强范围 |
| 入库 CI 专用 Test Target | Mock 以库内 `Mock/` + Examples 为主 |
| UIKit 视图 | Pluggable 仍 **不含** 视图（Cell 协议除外） |

### 2.3 成功标准

- [ ] `FKFeatureFlagProviding` 内存实现 + Examples 开关演示场景。
- [ ] `FKRemoteConfigProviding` JSON 文件/HTTP 轻量适配器 + `fetch()` 演示。
- [ ] `FKUserDefaultsStorage` / `FKKeychainStorage` 通过适配器符合 `FKCodableStoring`。
- [ ] `FKNetworkClient` 通过适配器符合 `FKAPIClientProviding`（或文档化单一推荐路径）。
- [ ] `FKLogger` 桥接 `FKPluggableLogging`。
- [ ] `FKNetworkReachability` 同时满足 `FKNetworkReachabilityProviding` 与 `NetworkStatusProviding`。
- [ ] `FKPhoneNumberFormatter`（或等价）符合 `FKTextFormatting`，`FKTextField` Examples 可注入。
- [ ] `FKPluggable/README.md` 契约对齐表更新；`COMPONENT_GAP_ANALYSIS` §11 可勾选。
- [ ] `xcodebuild` **BUILD SUCCEEDED**；未配置参考实现时现有测试/编译通过。

---

## 3. 背景与问题陈述

### 3.1 为何需要 Pluggable 增强

中大型 iOS App 普遍在 **组合根（Composition Root）** 装配：

- API Client、Token 存储、埋点上传器、Feature Flag、Session、环境配置……

FKKit 在 `Pluggable/` 已定义稳定协议，但集成方反馈三类摩擦：

1. **「协议有了，从哪开始写？」** — 除图片加载外，几乎没有可拷贝的参考实现。
2. **「Storage 和 Pluggable 两套协议？」** — `FKCodableStorage` vs `FKCodableStoring` 命名与 API 面不一致，无法直接注入 `FKBusinessKit` sketch 中的 `any FKCodableStoring`。
3. **「BusinessKit 已经做了 DeepLink / 生命周期，和 Pluggable 重复？」** — 两套模型并行，文档未说明选型。

### 3.2 与 FKKit 模块哲学的关系

- **Pluggable** = 窄边界、可替换、可测试；
- **Network / Storage / BusinessKit** = 默认生产实现；
- **增强目标** = 让默认实现 **可被发现、可桥接、可注入**，而非把 Pluggable 变成第二个 BusinessKit。

---

## 4. 现状基线

### 4.1 源码布局（当前）

```text
Sources/FKCoreKit/Components/Pluggable/
├── FKPluggable.swift                 # contractVersion = 1
├── README.md
├── Analytics/
│   ├── FKPluggableAnalyticsEvent.swift
│   └── FKPluggableAnalyticsUploading.swift
├── Configuration/
│   └── FKAppEnvironment.swift      # FKAppEnvironment + 3 protocols
├── Core/
│   ├── FKAppLifecycleObserving.swift
│   └── FKPluggableObservation.swift
├── Localization/
│   └── FKLocalizing.swift
├── Logging/
│   └── FKLogging.swift
├── Media/
│   └── FKImageLoading.swift
├── Networking/
│   ├── FKAPIClientProviding.swift
│   ├── FKAPIRequest.swift
│   ├── FKHTTPMethod.swift
│   ├── FKCredentialProviding.swift
│   └── FKRequestIntercepting.swift
├── Routing/
│   ├── FKRoute.swift
│   └── FKRouteHandling.swift
├── Security/
│   └── FKBiometricAuthPluggable.swift
├── Session/
│   └── FKUserSessionProviding.swift
├── Storage/
│   └── FKKeyValueStoring.swift
└── UIKit/
    ├── FKCellReusable.swift
    └── FKTextInputPluggable.swift
```

### 4.2 协议组与实现状态矩阵

| 领域 | 协议 / 类型 | 库内参考实现 | 邻模块平行能力 | 状态 |
|------|-------------|--------------|----------------|------|
| **Networking** | `FKAPIClientProviding` | ❌ | `FKNetworkClient` / `Networkable` | 仅协议 |
| | `FKRequestIntercepting` | ❌ | `Network` Interceptors | 仅协议 |
| | `FKResponseIntercepting` | ❌ | `Network` Interceptors | 仅协议 |
| | `FKRequestSigning` | ❌ | `RequestSigner` | 仅协议 |
| | `FKCredentialProviding` | ❌ | Keychain 手动读写 | 仅协议 |
| | `FKTokenRefreshing` | ❌ | `TokenRefresher` | 仅协议 |
| | `FKNetworkReachabilityProviding` | ⚠️ | `FKNetworkReachability` → `NetworkStatusProviding` | 平行协议 |
| **Analytics** | `FKPluggableAnalyticsUploading` 等 | ❌ | `BusinessKit` EventTrack | 平行模型 |
| **Storage** | `FKKeyValueStoring` / `FKCodableStoring` | ❌ | `FKStorageBackend` / `FKCodableStorage` | 平行协议 |
| **Session** | `FKUserSessionProviding` / `Observing` | ❌ | — | 仅协议 |
| **Configuration** | `FKAppEnvironmentProviding` | ❌ | Build 配置散落 | 仅协议 |
| | `FKFeatureFlagProviding` | ❌ | — | 仅协议 |
| | `FKRemoteConfigProviding` | ❌ | — | 仅协议 |
| **Localization** | `FKLocalizing` | ✅ | `FKI18nManager` | 已桥接 |
| | `FKTranslating` | ❌ | `FKI18n` MessageFormat | 仅协议 |
| **Routing** | `FKDeeplinkParsing` / `FKRouteHandling` / `FKDeeplinkRouting` | ❌ | `BusinessKit` DeeplinkRouter | 平行模型 |
| **Logging** | `FKPluggableLogging` | ❌ | `FKLogger` | 平行能力 |
| **Lifecycle** | `FKAppLifecycleObserving` | ❌ | `FKBusinessLifecycleObserver` | 平行模型 |
| **Media** | `FKImageLoading` / `FKImageCaching` | ✅ | `FKImageLoader` | 已交付 |
| **Security** | `FKBiometricAuthenticating` | ✅ | `FKBiometricAuth` | 已交付 |
| **UIKit lists** | `FKCellReusable` 等 | ⚠️ | `FKListKit` 预设行 | 协议 + 辅助 |
| **Text input** | `FKTextFormatting` 等 | ❌ | `FKTextField` 本地校验 | 仅协议 |

图例：✅ 已有生产参考实现；⚠️ 有能力但未对齐协议；❌ 无库内实现。

### 4.3 已有共享 primitive

- `FKPluggableObservationToken` — 观察取消句柄；
- `FKPluggableJSONCodec` — `FKCodableStoring` 默认 JSON 编解码；
- `FKRouteContext` / `FKRouteHandlingResult` — 路由值类型；
- `FKAPIRequest` / `FKAPIResponse` — 传输中立 HTTP 描述符。

---

## 5. 结构性缺口：平行协议栈

### 5.1 Storage：`FKCodableStoring` vs `FKCodableStorage`

| 能力 | `FKCodableStoring` (Pluggable) | `FKCodableStorage` (Storage) |
|------|-------------------------------|------------------------------|
| 键类型 | `String` | `FKStorageKey` / `FKStorageStringKey` |
| TTL | ❌ | ✅ `set(_:key:ttl:)` |
| `removeAll` / `allKeys` | ❌ | ✅ |
| `purgeExpired` | ❌ | ✅ |
| JSON 辅助 | `FKPluggableJSONCodec` | Storage 模块 Encoder |

**设计决策（推荐）：**

- **不合并** 两套协议为单一巨型协议（避免 Pluggable 依赖 Storage 键类型）。
- 交付 **`FKCodableStoragePluggableAdapter`**：`FKCodableStorage` → `FKCodableStoring` 适配器（字符串键 + 忽略 TTL 或映射到默认 TTL）。
- 反向适配器 **v2 可选**（Pluggable → Storage），用于渐进迁移。
- README **决策树**：功能模块 DI 用 `FKCodableStoring`；直接持久化用 `FKCodableStorage`。

### 5.2 Reachability：`FKNetworkReachabilityProviding` vs `NetworkStatusProviding`

- `FKNetworkReachability` 已实现 `NetworkStatusProviding`。
- **增强：** 同一类型 **同时** 符合 `FKNetworkReachabilityProviding`（`isReachable` 映射 `isConnected` 或等价属性）。
- **新增：** `FKReachabilityBridge` 文档说明 `FKImageLoader`、`FKWebView` 离线 UI 注入路径。

### 5.3 Lifecycle / Deeplink：Pluggable vs BusinessKit

| 概念 | Pluggable | BusinessKit |
|------|-----------|---------------|
| 生命周期状态 | `FKPluggableAppLifecycleState` (4 态) | `FKAppLifecycleState` (含 `notRunning` 等) |
| DeepLink | `FKRouteHandling` 链式 handler | `FKDeeplinkRoute` 注册表 |
| 协调器 | `FKDeeplinkRouting` | `FKBusinessDeeplinkRouter` |

**设计决策：**

- **v1 增强不删除 BusinessKit API**。
- 交付 **`FKBusinessLifecyclePluggableAdapter`**：`FKBusinessLifecycleObserver` → `FKAppLifecycleObserving`（状态枚举映射表文档化）。
- 交付 **`FKBusinessDeeplinkPluggableAdapter`**：将 `FKDeeplinkRoute` 包装为 `FKRouteHandling`；或 `FKPluggableDeeplinkRouter` 内部委托 BusinessKit。
- README **决策树**：已用 `FKBusinessKit.shared` 的 App 继续用 BusinessKit；纯协议 DI 的新模块用 Pluggable 类型。

### 5.4 Analytics：Pluggable vs BusinessKit

- `FKPluggableAnalyticsEvent` 与 `FKAnalyticsEvent` **刻意区分**（注释已说明）。
- **增强：** `FKBusinessEventTrackPluggableUploader` — 实现 `FKPluggableAnalyticsUploading`，内部转调 BusinessKit 缓冲上传管道。
- **不强制** BusinessKit 实现 `FKPluggableAnalyticsTracking`（避免 API 面膨胀）。

---

## 6. 增强项总览

```text
┌──────────────────────────────────────────────────────────────────────┐
│ App Composition Root（宿主或 FKPluggableServices）                    │
└───────┬──────────────────────────────────────────────────────────────┘
        │ inject
        ▼
┌───────────────────┐     ┌────────────────────┐     ┌─────────────────┐
│ Pluggable 协议层  │◄────│ Reference Impl     │     │ Bridge Adapters │
│ (现有 + v2 新增)  │     │ FeatureFlag,       │     │ Storage→Storing │
│                   │     │ RemoteConfig,      │     │ Network→API     │
│                   │     │ Session, Text...   │     │ Logger→Pluggable│
└─────────┬─────────┘     └────────────────────┘     └─────────────────┘
          │
          ▼
┌──────────────────────────────────────────────────────────────────────┐
│ 现有 FKCoreKit 模块：Network, Storage, Logger, BusinessKit, I18n...  │
└──────────────────────────────────────────────────────────────────────┘
```

| ID | 增强项 | 优先级 | 类型 |
|----|--------|--------|------|
| E1 | Storage → `FKCodableStoring` 桥接 | P0 | 适配器 |
| E2 | `FKInMemoryFeatureFlags` | P0 | 参考实现 |
| E3 | `FKJSONRemoteConfigProvider` | P0 | 参考实现 |
| E4 | `FKBuildTimeAppEnvironment` | P0 | 参考实现 |
| E5 | `FKUserSessionStore` | P1 | 参考实现 |
| E6 | `FKNetworkClient` → `FKAPIClientProviding` | P1 | 适配器 |
| E7 | `FKKeychainCredentialStore` | P1 | 参考实现 |
| E8 | `FKLoggerPluggableAdapter` | P1 | 适配器 |
| E9 | Reachability 协议统一 | P1 | 扩展符合 |
| E10 | `FKSharedTextFormatters` | P1 | 参考实现 |
| E11 | BusinessKit Lifecycle/Deeplink 桥接 | P2 | 适配器 |
| E12 | BusinessKit Analytics 上传桥接 | P2 | 适配器 |
| E13 | `FKPluggableServices` 组合根 | P2 | 模板类型 |
| E14 | Mock 套件 (`Pluggable/Mock/`) | P2 | 测试支持 |
| E15 | v2：`FKLocalNotificationScheduling` | P3 | 新协议 |
| E16 | v2：`FKPushNotificationRouting` | P3 | 新协议 |
| E17 | v2：`FKBackgroundTaskScheduling` | P3 | 新协议 |

---

## 7. 参考实现 — Configuration

### 7.1 `FKInMemoryFeatureFlags`

**符合：** `FKFeatureFlagProviding`

| 行为 | 说明 |
|------|------|
| 默认值表 | 初始化时注入 `[String: Bool]` 与 `[String: String]` 多变量表 |
| `isEnabled` | 未知 key → `false`（与协议文档一致） |
| `stringValue` | 未知 key → `nil` |
| 运行时覆盖 | `setEnabled(_:forKey:)` / `setStringValue(_:forKey:)`（参考实现扩展，非协议要求） |
| 线程安全 | 内部 `NSLock` 或串行队列；类型 `@unchecked Sendable` 若用 class |

```swift
public final class FKInMemoryFeatureFlags: FKFeatureFlagProviding, @unchecked Sendable {
  public init(
    defaults: [String: Bool] = [:],
    stringDefaults: [String: String] = [:]
  )
  public func isEnabled(_ key: String) -> Bool
  public func stringValue(for key: String) -> String?
}
```

### 7.2 `FKJSONRemoteConfigProvider`

**符合：** `FKRemoteConfigProviding`

| 行为 | 说明 |
|------|------|
| 数据源 | ① 本地 Bundle JSON；② 可选 HTTP URL（使用 `URLSession`，不强制 `FKNetworkClient`） |
| `fetch()` | 拉取并合并到内存快照；失败抛出 `FKRemoteConfigError` |
| 值读取 | `string(forKey:)` / `bool(forKey:)` 从未激活快照读取 |
| 激活策略 | `fetch()` 成功后立即激活；无「待激活」双缓冲（v1 简化） |
| 缓存 | 可选写入 `FKFileStorage` 子目录 |

```swift
public struct FKJSONRemoteConfigConfiguration: Sendable {
  public var bundleResourceName: String?      // e.g. "remote_config_default.json"
  public var remoteURL: URL?
  public var fetchTimeout: TimeInterval
}

public final class FKJSONRemoteConfigProvider: FKRemoteConfigProviding, @unchecked Sendable {
  public init(configuration: FKJSONRemoteConfigConfiguration)
  public func fetch() async throws
  public func string(forKey key: String) -> String?
  public func bool(forKey key: String) -> Bool?
}
```

**非目标 v1：** Firebase SDK、实时流式更新、A/B 实验分流算法。

### 7.3 `FKBuildTimeAppEnvironment`

**符合：** `FKAppEnvironmentProviding`

| 行为 | 说明 |
|------|------|
| 环境解析 | 从 `Info.plist` 自定义键 `FKAppEnvironment` 或编译条件 `#if DEBUG` 回退 |
| URL 表 | `development` / `staging` / `production` 各一套 `apiBaseURL` / `webBaseURL` |
| 不可变 | 初始化后 `Sendable` 快照 |

```swift
public struct FKBuildTimeAppEnvironment: FKAppEnvironmentProviding, Sendable {
  public init(plist: [String: Any] = Bundle.main.infoDictionary ?? [:])
  public var environment: FKAppEnvironment
  public var apiBaseURL: URL
  public var webBaseURL: URL?
}
```

---

## 8. 参考实现 — Session

### 8.1 `FKUserSessionStore`

**符合：** `FKUserSessionProviding` + `FKUserSessionObserving`

| 行为 | 说明 |
|------|------|
| 持久化 | 可选注入 `any FKCodableStoring`（经 E1 桥接的 Keychain/UserDefaults） |
| 字段 | `userID`、`accessToken`（可选，与 `FKCredentialProviding` 分工：Session 管身份，Credential 管令牌） |
| `signOut()` | 清除存储 + 通知观察者 `false` |
| 观察 | `observeAuthenticationChange` → `FKPluggableObservationToken` |
| 登录 | `signIn(userID:)` 非协议方法，供 Examples 与宿主调用 |

```swift
public final class FKUserSessionStore: FKUserSessionProviding, FKUserSessionObserving, @unchecked Sendable {
  public init(storage: any FKCodableStoring)
  public var isAuthenticated: Bool
  public var userID: String?
  public func signOut() throws
  public func observeAuthenticationChange(
    _ handler: @escaping @Sendable (Bool) -> Void
  ) -> FKPluggableObservationToken
  // Reference-only:
  public func signIn(userID: String) throws
}
```

**与 `FKCredentialProviding` 关系：** 文档说明 Session 存 `userID`；Token 存 `FKKeychainCredentialStore`；Network 拦截器读 Credential，UI 读 Session。

---

## 9. 参考实现 — Storage 桥接

### 9.1 `FKCodableStoragePluggableAdapter`

将任意 `FKCodableStorage` 桥接为 `FKCodableStoring`：

```swift
public final class FKCodableStoragePluggableAdapter: FKCodableStoring, @unchecked Sendable {
  public init(
    storage: any FKCodableStorage,
    keyPrefix: String = "pluggable."
  )
  // maps String keys → FKStorageStringKey with prefix
  public func data(forKey key: String) throws -> Data?
  public func set(_ data: Data?, forKey key: String) throws
  public func remove(forKey key: String) throws
  public func contains(key: String) -> Bool
}
```

| 规则 | 说明 |
|------|------|
| TTL | 桥接层 `set` 使用 Storage 默认 TTL 或配置 `defaultTTL` |
| `contains` | 委托 `exists(key:)` |
| 错误 | Storage 错误向上抛出，不包装（v1） |

### 9.2 `FKInMemoryKeyValueStore`

**符合：** `FKCodableStoring` — 测试与 Examples 用：

```swift
public final class FKInMemoryKeyValueStore: FKCodableStoring, @unchecked Sendable { ... }
```

---

## 10. 参考实现 — Networking 桥接

### 10.1 `FKNetworkClientPluggableAdapter`

**符合：** `FKAPIClientProviding`

| 行为 | 说明 |
|------|------|
| 委托 | 内部持有 `FKNetworkClient`（或 `Networkable`） |
| 映射 | `FKAPIRequest` → 内部 `Requestable` 匿名类型或 `FKNetworkEndpoint` |
| 响应 | `FKAPIResponse` ← `Data` + `HTTPURLResponse` |
| 错误 | `NetworkError` 向上抛出；文档说明与 Pluggable 错误边界 |

```swift
public struct FKNetworkClientPluggableAdapter: FKAPIClientProviding, Sendable {
  public init(client: FKNetworkClient = .shared)
  public func perform(_ request: FKAPIRequest) async throws -> FKAPIResponse
}
```

### 10.2 `FKKeychainCredentialStore`

**符合：** `FKCredentialProviding`

| 行为 | 说明 |
|------|------|
| 后端 | `FKKeychainStorage` 或 `FKKeychainKeyStore` |
| 键名 | 可配置 `service` + `accessTokenKey` / `refreshTokenKey` |
| 线程 | 串行化读写 |

### 10.3 拦截器桥接（可选 P2）

| Pluggable | Network 现有 | 适配器 |
|-----------|--------------|--------|
| `FKRequestIntercepting` | Request interceptor 闭包 | `FKRequestInterceptingAdapter` 包装 |
| `FKResponseIntercepting` | Response interceptor | 同上 |
| `FKRequestSigning` | `RequestSigner` | `FKRequestSigningAdapter` |

---

## 11. 参考实现 — Logging 桥接

### 11.1 `FKLoggerPluggableAdapter`

**符合：** `FKPluggableLogging`

| 行为 | 说明 |
|------|------|
| 级别映射 | `FKPluggableLogLevel` ↔ `FKLogLevel` 枚举映射表 |
| 委托 | `FKLogger.shared` 或注入的 `FKLogger` |
| `minimumLevel` | 读写代理到 `FKLogger` 配置 |
| 元数据 | `file` / `function` / `line` 传入 `FKLogger` 格式化器 |

```swift
public struct FKLoggerPluggableAdapter: FKPluggableLogging, Sendable {
  public var minimumLevel: FKPluggableLogLevel
  public init(logger: FKLogger = .shared)
  public func log(level: ..., message: ..., file: ..., function: ..., line: ...)
}
```

**文档：** `FKLogger` 为生产默认；`FKPluggableLogging` 为跨模块 DI 边界（Network 调试钩子、Analytics 等）。

---

## 12. 参考实现 — Lifecycle 与 Routing 桥接

### 12.1 `FKBusinessLifecyclePluggableAdapter`

| 映射 | `FKAppLifecycleState` → `FKPluggableAppLifecycleState` |
|------|--------------------------------------------------------|
| `notRunning` | `terminated` 或忽略（文档说明） |
| `active` | `active` |
| `inactive` | `inactive` |
| `background` | `background` |

### 12.2 `FKPluggableDeeplinkRouter`

**符合：** `FKDeeplinkRouting`

- 内部组合 `FKDeeplinkParsing`（默认 URL parser）+ `[FKRouteHandling]` 链；
- 可选构造参数：委托现有 `FKBusinessDeeplinkRouter` 做 host/path 匹配后转 `FKRouteContext`。

---

## 13. 参考实现 — Analytics 桥接

### 13.1 `FKBusinessAnalyticsPluggableUploader`

**符合：** `FKPluggableAnalyticsUploading`

```swift
public struct FKBusinessAnalyticsPluggableUploader: FKPluggableAnalyticsUploading, Sendable {
  public init(eventTrack: FKBusinessEventTrack = .shared)
  public func upload(batch: [FKPluggableAnalyticsEvent]) async throws
}
```

| 映射 | `FKPluggableAnalyticsEvent` → BusinessKit 事件模型 |
|------|-----------------------------------------------------|
| 参数 | `parameters` 字典直接合并 |
| 批处理 | 逐条 `trackEvent` 或批量 API（若 BusinessKit 暴露） |

---

## 14. 参考实现 — Text Input

### 14.1 共享 Formatter / Validator

交付 **无 associated type 困扰** 的具体类型 + 泛型包装器：

| 类型 | 协议 | 规则 |
|------|------|------|
| `FKPhoneNumberTextFormatter` | `FKTextFormatting` | 分组显示、raw 仅数字 |
| `FKEmailTextValidator` | `FKTextValidating` | 本地 RFC 5322 简化规则 |
| `FKBankCardTextFormatter` | `FKTextFormatting` | 4 位空格分组 |
| `FKLengthTextValidator` | `FKTextValidating` | min/max 长度 |

```swift
public struct FKPhoneNumberFormattingRule: Sendable, Hashable {
  public var maxDigits: Int
  public static let `default` = FKPhoneNumberFormattingRule(maxDigits: 11)
}

public struct FKPhoneNumberTextFormatter: FKTextFormatting {
  public typealias Rule = FKPhoneNumberFormattingRule
  public func format(text: String, rule: Rule) -> FKTextFormattingResult
}
```

### 14.2 `FKTextField` 集成

- `FKTextField` 增加可选 `formatter: (any FKTextFormatting)?` 注入路径 **或** 文档化通过 configuration 闭包使用共享 Formatter；
- Examples：`PhoneInput` 场景使用 `FKPhoneNumberTextFormatter`。

### 14.3 `FKTextAsyncValidating`（P2）

- `FKNetworkBackedTextValidator` — 委托 `FKAPIClientProviding` 调用校验 API；
- 超时与取消文档化。

---

## 15. 参考实现 — Reachability 统一

### 15.1 `FKNetworkReachability` 扩展

```swift
extension FKNetworkReachability: FKNetworkReachabilityProviding {
  public var isReachable: Bool { /* maps from existing connected state */ }
}
```

### 15.2 `FKReachabilityService`（可选）

- 单例包装，供 `FKImageLoaderConfiguration.useNetworkReachability` 与 Pluggable DI 共用同一实例；
- 文档：**一个 App 一个 Reachability 实例**。

---

## 16. 新增 Pluggable 契约（v2 协议组）

以下协议在 **v1 增强** 中仅定义契约 + README 占位；实现可推迟到 Tier 3（见 [COMPONENT_GAP_ANALYSIS](COMPONENT_GAP_ANALYSIS.md) §9）。

### 16.1 `FKLocalNotificationScheduling`

> **完整 API、内容/触发器模型、Delegate 与 Examples 见：** [FKLocalNotificationManager_DESIGN.md](FKLocalNotificationManager_DESIGN.md)

Pluggable 契约（**以实现文档为准**，以下为最小面摘要）：

```swift
public protocol FKLocalNotificationScheduling: Sendable {
  func schedule(_ request: FKLocalNotificationRequest) async throws
  func schedule(_ requests: [FKLocalNotificationRequest]) async throws
  func cancelPending(withIdentifier identifier: String) async
  func cancelAllPending() async
}

// Types live in LocalNotification/Public/ — see FKLocalNotificationManager_DESIGN §7
public struct FKLocalNotificationRequest: Sendable, Hashable {
  public var identifier: String
  public var content: FKLocalNotificationContent
  public var trigger: FKLocalNotificationTrigger
  public var categoryIdentifier: String?
}
```

- 权限：**不**在协议内申请；调用方先走 `FKPermissions`；
- 参考实现：`FKLocalNotificationManager`（`UserNotifications`）。

### 16.2 `FKPushNotificationRouting`

```swift
public protocol FKPushNotificationRouting: Sendable {
  func handleRemoteNotification(
    userInfo: [AnyHashable: Any],
    source: FKPushNotificationSource
  ) -> FKRouteHandlingResult
}

public enum FKPushNotificationSource: Sendable {
  case foreground, background, userAction
}
```

- 与 `FKDeeplinkRouting` 协作：payload 内 URL → 转 DeepLink 链。

### 16.3 `FKBackgroundTaskScheduling`

> **完整 API、Processing/Refresh 模型、beginBackgroundTask 与 Examples 见：** [FKBackgroundTaskManager_DESIGN.md](FKBackgroundTaskManager_DESIGN.md)

Pluggable 契约（**以实现文档为准**，以下为最小面摘要）：

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

// FKBackgroundTaskHandle: final class — see FKBackgroundTaskManager_DESIGN §9
// Processing constraints: only on FKBackgroundProcessingRequest at submit time
```

- 与 `BusinessKit` 启动任务（foreground）、`FileManager` 后台 URLSession 文档交叉引用；
- 参考实现：`FKBackgroundTaskManager`（`BackgroundTasks` + `UIKit`）。

### 16.4 v2 与 `contractVersion`

- 仅 **新增协议** → `contractVersion` **可不递增**（semver minor）；
- 修改现有协议要求 → 递增 `contractVersion` 并记入 `CHANGELOG`。

---

## 17. 组合根与服务注册

### 17.1 `FKPluggableServices`

可选 **Sendable 结构体**（非强制单例），作为 Examples 与文档模板：

```swift
public struct FKPluggableServices: Sendable {
  public var apiClient: any FKAPIClientProviding
  public var storage: any FKCodableStoring
  public var session: any FKUserSessionProviding
  public var sessionObserver: any FKUserSessionObserving
  public var environment: any FKAppEnvironmentProviding
  public var featureFlags: any FKFeatureFlagProviding
  public var remoteConfig: any FKRemoteConfigProviding
  public var imageLoader: any FKImageLoading
  public var logger: any FKPluggableLogging
  public var reachability: any FKNetworkReachabilityProviding
  public var biometricAuth: any FKBiometricAuthenticating
  public var localizer: any FKLocalizing

  /// Production defaults for small apps and Examples.
  public static func productionDefaults() -> FKPluggableServices
}
```

### 17.2 装配规则

| 规则 | 说明 |
|------|------|
| 构造时机 | `AppDelegate` / `@main` SwiftUI `App` init |
| 测试 | `FKPluggableServices` + 全 Mock 注入 |
| 特征模块 | 仅接收需要的 `any Protocol`，不传递整个容器 |
| 避免 | 全局可变单例泛滥；`productionDefaults()` 仅便利入口 |

---

## 18. Mock 与测试套件

路径：`Pluggable/Mock/`（或 `Pluggable/Implementations/Mock/`）

| Mock 类型 | 符合协议 | 用途 |
|-----------|----------|------|
| `FKMockAPIClient` | `FKAPIClientProviding` |  canned `FKAPIResponse` |
| `FKMockFeatureFlags` | `FKFeatureFlagProviding` | 可编程开关 |
| `FKMockUserSession` | Session 双协议 | 登录态切换 |
| `FKMockReachability` | `FKNetworkReachabilityProviding` | 离线 UI |
| `FKMockPluggableLogger` | `FKPluggableLogging` | 断言日志 |
| `FKMockImageLoader` | `FKImageLoading` | 已有模式可迁入统一目录 |

**要求：**

- 全部 `Sendable`；
- 无 UI；
- Examples 场景 `DI_MockComposition` 演示替换生产实现。

---

## 19. 契约版本与破坏性变更

| 变更类型 | `FKPluggable.contractVersion` | Semver |
|----------|-------------------------------|--------|
| 新增协议 / 参考实现 | 不变 | minor |
| 新增协议要求（现有 conformers 破坏） | +1 | major |
| 重命名协议 | +1 | major |
| 桥接适配器 | 不变 | minor |

**文档要求：** `Pluggable/README.md` 增加 **Contract changelog** 表。

---

## 20. 模块边界与复用

### 20.1 强制复用（实现前检索）

| 需求 | 使用 | 禁止 |
|------|------|------|
| JSON 编解码 | `FKPluggableJSONCodec` / Storage Encoder | 自建 JSON |
| 观察取消 | `FKPluggableObservationToken` | 自建 token |
| Keychain | `FKKeychainStorage` | 直接 Security API 散落 |
| 网络执行 | `FKNetworkClient` | 重复 URLSession |
| 日志 | `FKLogger` | `print` 调试 |
| 防抖 | `FKAsync` | 自建 Timer |
| 权限 | `FKPermissions` | 通知等直接申请 |

### 20.2 依赖方向

```text
Pluggable/Implementations  →  Storage, Network, Logger, BusinessKit, I18n, BiometricAuth
Pluggable/*.swift (协议)     →  Foundation (+ UIKit 仅 Cell/Image 协议)
Network / Storage / ...      →  不依赖 Pluggable/Implementations
```

---

## 21. 公开 API 草案汇总

见各 §7–§16；实现时所有公开类型英文 `///` 文档注释。

---

## 22. 错误模型

新增错误枚举（放在 `Pluggable/Implementations/` 或各实现文件旁）：

```swift
public enum FKRemoteConfigError: Error, Sendable {
  case missingSource
  case fetchFailed(underlying: Error)
  case invalidPayload
}

public enum FKPluggableSessionError: Error, Sendable {
  case storageFailure(underlying: Error)
  case notAuthenticated
}
```

**原则：** 不引入巨型 `FKPluggableError`；按子域分枚举。

---

## 23. 并发与 Sendable

| 类型 | 策略 |
|------|------|
| `struct` 适配器 | `Sendable` |
| `final class` 可变状态 | `@unchecked Sendable` + 锁/串行队列 |
| `FKRouteHandling` / `FKImageLoading` | `@MainActor` 保持现有 |
| `FKUserSessionProviding` | `AnyObject` — 观察者与 Session 同一实例 |

Verify：`SWIFT_STRICT_CONCURRENCY=complete`。

---

## 24. 建议源码目录结构

```text
Sources/FKCoreKit/Components/Pluggable/
├── README.md                          # 更新契约表 + 决策树
├── FKPluggable.swift
├── Analytics/                       # 现有协议
├── Configuration/                     # 现有协议
├── ...
├── Implementations/                   # 新增 — 参考实现与桥接
│   ├── Configuration/
│   │   ├── FKInMemoryFeatureFlags.swift
│   │   ├── FKJSONRemoteConfigProvider.swift
│   │   └── FKBuildTimeAppEnvironment.swift
│   ├── Session/
│   │   └── FKUserSessionStore.swift
│   ├── Storage/
│   │   ├── FKCodableStoragePluggableAdapter.swift
│   │   └── FKInMemoryKeyValueStore.swift
│   ├── Networking/
│   │   ├── FKNetworkClientPluggableAdapter.swift
│   │   └── FKKeychainCredentialStore.swift
│   ├── Logging/
│   │   └── FKLoggerPluggableAdapter.swift
│   ├── Lifecycle/
│   │   └── FKBusinessLifecyclePluggableAdapter.swift
│   ├── Routing/
│   │   └── FKPluggableDeeplinkRouter.swift
│   ├── Analytics/
│   │   └── FKBusinessAnalyticsPluggableUploader.swift
│   ├── TextInput/
│   │   ├── FKPhoneNumberTextFormatter.swift
│   │   └── ...
│   ├── Reachability/
│   │   └── FKNetworkReachability+Pluggable.swift
│   └── Composition/
│       └── FKPluggableServices.swift
├── Mock/                              # 新增 — 测试 Mock
│   ├── FKMockAPIClient.swift
│   ├── FKMockFeatureFlags.swift
│   └── ...
└── v2/                                # 可选 — 新协议草案
    ├── FKLocalNotificationScheduling.swift
    └── FKPushNotificationRouting.swift
```

**Package.swift：** `Implementations/` 无 README 则不必 `exclude`；若加 README 则 `exclude`。

---

## 25. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/Pluggable/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `CompositionRootDefaults` | `FKPluggableServices.productionDefaults()` 装配 |
| 2 | `FeatureFlagToggle` | 内存 Flag 开/关影响 UI 或日志 |
| 3 | `RemoteConfigFetch` | Bundle JSON `fetch` + 读取 |
| 4 | `SessionSignInOut` | Session 持久化 + 观察回调 |
| 5 | `StorageBridge` | `FKUserDefaultsStorage` 经适配器注入 |
| 6 | `MockAPIClient` | 替换网络层返回 canned 响应 |
| 7 | `PhoneFormatter` | `FKPhoneNumberTextFormatter` + TextField |
| 8 | `ReachabilityOffline` | Mock 不可达 → ImageView 失败态 |
| 9 | `LoggerBridge` | Pluggable logger → FKLogger 输出 |
| 10 | `DeeplinkPluggable` | `FKPluggableDeeplinkRouter` 链式 handler |
| 11 | `AnalyticsBridge` | Pluggable 事件 → BusinessKit 缓冲（可选） |

Hub 英文标题 + 副标题；每个场景覆盖一个公共能力路径。

---

## 26. 分阶段交付计划

| 阶段 | 交付物 | 依赖 |
|------|--------|------|
| **P0** | E1 Storage 桥接、E2–E4 Configuration 参考实现、README 更新 | Storage |
| **P1** | E5 Session、E6–E7 Network 桥接、E8 Logger、E9 Reachability、E10 Text、Mock 基础 | Network, Logger |
| **P2** | E11–E14 BusinessKit 桥接、组合根、Examples Hub | BusinessKit |
| **P3** | E15–E17 v2 协议 + 本地通知参考实现 | Permissions, UserNotifications |

每阶段：`xcodebuild` 通过 → `CHANGELOG` → Examples → 根 README 索引（若新增公开模块名）。

---

## 27. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | `Implementations/` 与邻模块同文件夹 vs 子目录？ | **`Pluggable/Implementations/`** — 契约与实现分离 |
| Q2 | `FKPluggableServices` 是否入公开 API？ | 是 — 作为可选模板，非强制 |
| Q3 | Storage 桥接是否支持 TTL 暴露？ | v1 用默认 TTL；v1.1 配置 `defaultTTL` |
| Q4 | `FKAPIClientProviding` vs 直接用 `Networkable`？ | 双轨：DI 用 Pluggable；模块内用 Networkable |
| Q5 | v2 通知协议是否纳入 v1 增强 PR？ | 否 — 仅文档定义，实现 P3 |
| Q6 | Mock 类型是否 `public`？ | 是 — 开源可测试性 |
| Q7 | `contractVersion` 何时升为 2？ | 仅现有协议破坏性变更时 |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初版：Pluggable 缺口分析、参考实现、桥接、v2 协议、组合根与 Examples 规划 |

---

## 29. 相关文档

| 文档 | 内容 |
|------|------|
| [Pluggable/README.md](../Sources/FKCoreKit/Components/Pluggable/README.md) | 契约组索引 |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §11 Pluggable 缺口 |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | Pluggable 契约对齐 |
| [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md) | 网络模块完整设计（与 E6/E9 协同） |
| [FKNetwork_ENHANCEMENT_DESIGN.md](FKNetwork_ENHANCEMENT_DESIGN.md) | 网络 Roadmap 四项增强索引 |
| [FKFileManager_ENHANCEMENT_DESIGN.md](FKFileManager_ENHANCEMENT_DESIGN.md) | 文件/ZIP |
| [FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md) | BusinessKit 完整设计（Pluggable 桥接 §16） |
| [FKBusinessKit_ENHANCEMENT_DESIGN.md](FKBusinessKit_ENHANCEMENT_DESIGN.md) | BusinessKit 增量增强索引 |
| [FKLocalNotificationManager_DESIGN.md](FKLocalNotificationManager_DESIGN.md) | 本地通知参考实现（§16.1） |
| [FKBackgroundTaskManager_DESIGN.md](FKBackgroundTaskManager_DESIGN.md) | 后台任务参考实现（§16.3） |
| [FKBiometricAuth_DESIGN.md](FKBiometricAuth_DESIGN.md) | 生物识别 Pluggable 注入 |
| [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md) | 图片 Pluggable 参考实现范例 |
| [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md) | Text Formatter 消费方 |
