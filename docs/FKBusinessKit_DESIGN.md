# FKBusinessKit — 模块设计需求文档

FKKit **`FKBusinessKit`** 的完整实现指导文档：规范 **已交付能力** 的行为边界、**增量增强**（Alert 后端统一、Pluggable 桥接、Top VC 公开化、Examples Hub）、与 **`FKI18n` / `FKAlert` / `Pluggable` / FKUIKit Widgets** 的分工，补齐缺口分析中尚未文档化的能力描述。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §现有模块增强 — FKBusinessKit  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §10.3  
**模块 README：** [BusinessKit/README.md](../Sources/FKCoreKit/Components/BusinessKit/README.md)  
**Widgets 组合片段：** [FKBusinessKit-Widgets-Integration_DESIGN.md](FKBusinessKit-Widgets-Integration_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 已交付能力详表](#6-已交付能力详表)
- [7. 统一入口与配置](#7-统一入口与配置)
- [8. 版本更新（Version）](#8-版本更新version)
- [9. 全局埋点（Track）](#9-全局埋点track)
- [10. 应用内国际化（I18n）](#10-应用内国际化i18n)
- [11. 生命周期（Lifecycle）](#11-生命周期lifecycle)
- [12. DeepLink 与 Universal Link](#12-deeplink-与-universal-link)
- [13. 设备与应用信息（Info）](#13-设备与应用信息info)
- [14. 业务工具（Utils）](#14-业务工具utils)
- [15. Alert 后端统一（增强）](#15-alert-后端统一增强)
- [16. Pluggable 桥接（增强）](#16-pluggable-桥接增强)
- [17. Top VC 解析器公开化（增强）](#17-top-vc-解析器公开化增强)
- [18. 与 FKAlert / FKBanner / Widgets 组合](#18-与-fkalert--fkbanner--widgets-组合)
- [19. 与 FKI18n / Pluggable 环境对齐](#19-与-fki18n--pluggable-环境对齐)
- [20. 错误模型](#20-错误模型)
- [21. 并发与 Swift 6](#21-并发与-swift-6)
- [22. v2 能力展望（非 v1 交付）](#22-v2-能力展望非-v1-交付)
- [23. FKCoreKit 复用要求](#23-fkcorekit-复用要求)
- [24. 公开 API 索引](#24-公开-api-索引)
- [25. 建议源码目录结构](#25-建议源码目录结构)
- [26. FKKitExamples 场景](#26-fkkitexamples-场景)
- [27. 分阶段交付计划](#27-分阶段交付计划)
- [28. 待决问题](#28-待决问题)
- [29. 修订历史](#29-修订历史)
- [30. 相关文档](#30-相关文档)

---

## 1. 概述

中大型 iOS App 在 **App 壳层** 重复实现：版本更新提示、埋点缓冲上传、语言切换、生命周期监听、DeepLink 分发、脱敏格式化、启动任务编排。逻辑分散在 AppDelegate、各 Feature 模块与临时 Singleton 中。

**`FKBusinessKit`**（`Sources/FKCoreKit/Components/BusinessKit/`）通过 **`FKBusinessKit.shared`** 提供单一门面，子能力按协议拆分、可整体或逐项替换：

| 门面属性 | 协议 | 默认实现 |
|----------|------|----------|
| `version` | `FKBusinessVersioning` | `FKBusinessVersionManager` |
| `track` | `FKBusinessTracking` | `FKBusinessAnalyticsTracker` |
| `i18n` | `FKBusinessLocalizing` | `FKBusinessI18nManager` → `FKI18nManager` |
| `lifecycle` | `FKBusinessLifecycleObserving` | `FKBusinessLifecycleObserver` |
| `deeplink` | `FKBusinessDeeplinkRouting` | `FKBusinessDeeplinkRouter` |
| `info` | `FKBusinessInfoProviding` | `FKBusinessInfoProvider` |
| `utils` | `FKBusinessUtilitiesProviding` | `FKBusinessUtilities` |

**关键约束：** Foundation + UIKit；**零第三方**；线程安全；阻塞主线程的同步网络/磁盘工作在子系统内部 offload；Swift 6 `Sendable` 配置与错误。

**成熟度：** 七大子系统 **生产可用**；`FKBusinessAlertManager` 仍为 **系统 Alert**；Pluggable 桥接、Alert 后端、Examples Hub 分场景 **待增强**（§15–§17、§26）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标（模块整体）

1. **单一组合根友好门面** — `FKBusinessKit.shared` + 可注入 `init` 替换子协议实现。
2. **版本决策** — 本地/远程比较、可选/强制更新、`FKAppStoreRemoteVersionProvider`。
3. **埋点管道** — page/click/custom、公共参数、文件缓冲、批量上传、重试与丢弃策略。
4. **应用内语言** — 独立于系统语言；观察者与 Notification；委托 `FKI18nManager`。
5. **生命周期流** — `UIApplication` 通知 → `FKAppLifecycleState`。
6. **DeepLink** — host/path 通配、query 解析、handler 注册表。
7. **业务 Utils** — 时间/数字/脱敏/Alert 去重/启动任务。
8. **增量增强** — `FKBusinessAlertBackend`、Pluggable 适配器、公开 Top VC、Examples Hub（§15–§17）。
9. **文档化边界** — 与 FKAlert、FKBanner、Widgets、Pluggable 选型决策树（§18–§19）。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| UI 控件渲染（Chip、TabBar 面板） | FKUIKit / 未来薄封装；**不在 BusinessKit 复制 Widgets** |
| 完整用户会话/登录 | Pluggable `FKUserSessionProviding`；BusinessKit 不内置 |
| 替代 `FKI18n` 全部 API | BusinessKit 为 **facade**；高级 MessageFormat 用 `coreManager` |
| 替代 `FKNetwork` / `FKStorage` | 埋点上传由宿主注入 `FKAnalyticsUploading` |
| 强制依赖 `FKAlert` | Alert 后端 **可选** `fkAlert`（§15） |
| 第三方 SDK（Firebase Analytics 等） | 宿主适配器实现 Upload 协议 |

### 2.3 成功标准

**已交付（维持）：**

- [ ] 现有 `FKBusinessKitExampleViewController` 与编译无回归。

**增量增强：**

- [ ] `FKBusinessAlertBackend` 配置 + 文档与 FKAlert 决策树。
- [ ] Pluggable 桥接类型入库或文档化装配（Lifecycle / Deeplink / Analytics）。
- [ ] `FKTopViewControllerResolver` 公开 API 或 Extension 迁移。
- [ ] Examples Hub：每子系统至少一个独立场景（§26）。
- [ ] README 链到本文；`xcodebuild` **BUILD SUCCEEDED**。

---

## 3. 背景与问题陈述

### 3.1 为何需要 BusinessKit

| 痛点 | BusinessKit 回应 |
|------|------------------|
| 版本检查与弹窗散落 | `version.checkForUpdate` + `presentUpdatePromptIfNeeded` |
| 各模块自建埋点队列 | `track` 文件缓冲 + 批量 flush |
| 语言切换与 UI 刷新不同步 | `i18n.observeLanguageChange` + Notification |
| AppDelegate 生命周期钩子重复 | `lifecycle.observe` |
| URL 路由表不统一 | `deeplink.register` + 通配 path |
| 日志/展示需脱敏 | `utils.mask` |
| 启动时串行阻塞 | `utils.startup.register` + 优先级/延迟 |

### 3.2 当前文档与实现缺口

| 缺口 | 本文章节 |
|------|----------|
| Alert 仅 `UIAlertController` | §15 |
| Pluggable 平行模型（Lifecycle/Deeplink/Analytics） | §16 |
| `FKTopViewControllerResolver` 内部 enum | §17 |
| `TabBarFilter` 文档引用但 **FKKit 源码未交付** | §22 |
| Examples 单页 Demo，非 Hub | §26 |
| 版本更新 vs FKBanner 组合 | §18 |
| `FKBusinessEnvironment` vs `FKAppEnvironment` | §19 |

---

## 4. 架构总览

```text
                    FKBusinessKit.shared
                            │
    ┌───────────┬───────────┼───────────┬───────────┬───────────┐
    ▼           ▼           ▼           ▼           ▼           ▼
 version      track        i18n     lifecycle    deeplink      info
    │           │           │           │           │           │
    │           │      FKI18nManager     UIApp      route      Bundle
    │           │           │        notifications  table    hw.machine
    ▼           ▼           │           │           │           │
 App Store   file FIFO                  │           │           │
 provider    + uploader                 │           │           │
                                         └───────────┴───────────┘
                                                     │
                                              utils (time/number/
                                              mask/alerts/startup)
```

### 4.1 配置流

- `FKBusinessKitConfiguration` 存于 `FKBusinessConfigurationStore`（`NSLock`）；
- `track` 通过 `configurationProvider` 闭包读取 flush 间隔、batch 大小、重试次数；
- `info.channel` / `environment` 来自 configuration + build flags。

---

## 5. 模块边界

### 5.1 源码布局（当前）

```text
Sources/FKCoreKit/Components/BusinessKit/
├── Core/
│   ├── FKBusinessKit.swift
│   ├── FKBusinessKitConfiguration.swift
│   ├── FKBusinessProtocols.swift
│   └── FKBusinessInfoProvider.swift
├── Model/
│   ├── FKBusinessModels.swift      # Version, Analytics, Deeplink, Alert, Startup
│   ├── FKBusinessError.swift
│   └── FKBusinessObservationToken.swift
├── Version/
│   ├── FKBusinessVersionManager.swift
│   └── FKAppStoreRemoteVersionProvider.swift
├── Track/
│   └── FKBusinessAnalyticsTracker.swift
├── I18n/
│   └── FKBusinessI18nManager.swift
├── Lifecycle/
│   └── FKBusinessLifecycleObserver.swift
├── Deeplink/
│   └── FKBusinessDeeplinkRouter.swift
├── Utils/
│   ├── FKBusinessUtilities.swift   # + FKTopViewControllerResolver (internal)
│   ├── FKBusinessAlertManager.swift
│   ├── FKBusinessTimeFormatter.swift
│   ├── FKBusinessNumberFormatter.swift
│   ├── FKBusinessMasker.swift
│   └── FKBusinessStartupTaskManager.swift
└── README.md
```

### 5.2 增强后布局（§25）

`Bridge/`（Pluggable 适配器）、`Alert/`（Backend 枚举）、可选 `Extension/FKTopViewController+Business.swift` 上移 CoreKit Extension。

### 5.3 不在本模块

- UIKit 复合筛选 UI（`TabBarFilter` 若交付，归属 FKUIKit 或独立 Business 薄封装，见 §22）；
- `FKAlert` 视图与 Presenter（FKUIKit）；
- 网络栈实现（注入 Upload 协议）。

---

## 6. 已交付能力详表

| 子系统 | 能力 | 成熟度 | 说明 |
|--------|------|--------|------|
| **Version** | 本地 metadata、远程 check、决策 enum | ✅ | 语义化版本比较 |
| | App Store Lookup provider | ✅ | iTunes API |
| | 更新弹窗（系统 Alert） | ✅ | 可选/强制 |
| **Track** | pageView / click / custom | ✅ | |
| | 公共参数（device/version/channel） | ✅ | + 可选 provider |
| | 文件 FIFO 缓冲 | ✅ | Caches/FKBusinessKit |
| | 定时 flush + 手动 flush | ✅ | 可配置 interval |
| | 批量 upload + 重试 + drop | ✅ | maxRetryCount |
| **I18n** | 语言切换与持久化 | ✅ | 包装 FKI18nManager |
| | `localized(_:table:)` | ✅ | |
| | 观察者与 Notification | ✅ | |
| **Lifecycle** | 6+1 状态 enum | ✅ | 含 notRunning/launching |
| | UIApplication 通知桥 | ✅ | |
| **Deeplink** | register/unregister | ✅ | |
| | host + path `*` 匹配 | ✅ | |
| | query 参数字典 | ✅ | |
| **Info** | bundle/version/build/device/OS/screen | ✅ | |
| | channel + environment | ✅ | |
| **Utils.time** | 固定格式 + 相对时间 | ✅ | 中英文友好 |
| **Utils.number** | 金额 + 紧凑单位 | ✅ | K/M/万 |
| **Utils.mask** | 手机/身份证/邮箱/通用 | ✅ | |
| **Utils.alerts** | presentOnce 去重 | ✅ | 系统 Alert |
| **Utils.startup** | 优先级 + delay + runAll | ✅ | |
| **Alert 后端** | FKAlert 集成 | ❌ | §15 |
| **Pluggable 桥接** | 三适配器 | ❌ | §16 |
| **Top VC 公开** | — | ❌ | §17 |
| **TabBarFilter** | 文档提及 | ❌ 未入库 | §22 |
| **Examples Hub** | 单页 Demo | ⚠️ | §26 |

---

## 7. 统一入口与配置

### 7.1 `FKBusinessKit`

```swift
public final class FKBusinessKit: @unchecked Sendable {
  public static let shared
  public var configuration: FKBusinessKitConfiguration
  public let version: FKBusinessVersioning
  public let track: FKBusinessTracking
  public let i18n: FKBusinessLocalizing
  public let lifecycle: FKBusinessLifecycleObserving
  public let deeplink: FKBusinessDeeplinkRouting
  public let info: FKBusinessInfoProviding
  public let utils: FKBusinessUtilitiesProviding

  public init(configuration: ..., version: ..., track: ..., ...)  // 全可注入
  public func updateConfiguration(_ transform: (inout FKBusinessKitConfiguration) -> Void)
}
```

### 7.2 `FKBusinessKitConfiguration`

| 字段 | 默认 | 用途 |
|------|------|------|
| `channel` | `"AppStore"` | 埋点公共参数 |
| `environment` | `.current` | debug/release |
| `defaultLanguageCode` | `"en"` | I18n 初始语言 |
| `analyticsFlushInterval` | 10s | 定时 flush |
| `analyticsMaxBatchSize` | 20 | 单批上限 |
| `analyticsMaxRetryCount` | 3 | 上传失败重试 |

### 7.3 增强配置（§15）

```swift
public enum FKBusinessAlertBackend: Sendable, Equatable {
  case systemAlert          // 默认，现有行为
  case fkAlert              // 委托 FKUIKit FKAlertPresenter
}

public extension FKBusinessKitConfiguration {
  public var alertBackend: FKBusinessAlertBackend  // default .systemAlert
}
```

---

## 8. 版本更新（Version）

### 8.1 决策流

```text
fetchRemoteVersion → compare(local, remote) → upToDate | optionalUpdate | forceUpdate
                                                      ↓
                              presentUpdatePromptIfNeeded (系统 Alert，§15 可 FKAlert)
```

### 8.2 `FKUpdateDecision`

| Case | 行为 |
|------|------|
| `upToDate` | 不弹窗 |
| `optionalUpdate` | 可取消 + 跳转 updateURL |
| `forceUpdate` | 不可取消（仅强制更新路径） |

### 8.3 `FKRemoteVersionProviding`

- 内置：`FKAppStoreRemoteVersionProvider`（bundle ID → iTunes Lookup）；
- 宿主可注入 **自建后端** provider（灰度、企业包）— 实现协议即可。

### 8.4 与 FKBanner 组合（§18）

- BusinessKit **检测** → 回调/返回值；
- 宿主选择 **FKBanner** 持久条或 **version.presentUpdatePromptIfNeeded**；
- **禁止** BusinessKit 直接依赖 FKBanner（避免 FKUIKit ← FKCoreKit 环）。

---

## 9. 全局埋点（Track）

### 9.1 事件模型

| API | `FKAnalyticsEventType` | name 字段 |
|-----|------------------------|-----------|
| `trackPageView` | `.pageView` | page id |
| `trackClick` | `.click` | element id（page 写入 parameters） |
| `trackEvent` | `.custom` | 自定义名 |

### 9.2 公共参数（自动合并）

- `bundleID`, `appVersion`, `buildNumber`, `deviceModel`, `systemVersion`, `screenSize`, `channel`, `environment`；
- `setCommonParametersProvider` 追加业务字段。

### 9.3 缓冲与上传

| 阶段 | 行为 |
|------|------|
| enqueue | 串行 queue 写入 `FKAnalyticsFileStore` |
| timer | 按 `analyticsFlushInterval` 触发 flush |
| flush | 取 batch（≤ maxBatchSize）→ `FKAnalyticsUploading.upload` |
| 失败 | 重试至 maxRetryCount，仍失败则 **丢弃 batch**（文档化） |
| 后台 | 推荐 `lifecycle` → background 时 `track.flush()` |

### 9.4 与 Pluggable 关系

- `FKAnalyticsUploading`（BusinessKit）vs `FKPluggableAnalyticsUploading`（Pluggable）— **平行协议**；
- 桥接：`FKBusinessAnalyticsPluggableUploader`（Pluggable → BusinessKit 缓冲）或反向适配器（§16）。

---

## 10. 应用内国际化（I18n）

### 10.1 架构

- `FKBusinessI18nManager` **包装** `FKI18nManager`；
- `coreManager` 暴露高级 API（MessageFormat、plural、bundle override）；
- 存储键：`com.fkkit.business.i18n.language`（可配置）。

### 10.2 与独立 `FKI18n` 模块选型

| 场景 | 选用 |
|------|------|
| 已通过 BusinessKit 装配 | `FKBusinessKit.shared.i18n` |
| 纯 Core 模块、无 Business 门面 | 直接 `FKI18nManager` / `FKLocalizing` |
| SwiftUI/UIKit 扩展 | `String.fk_localized` 等 FKI18n 扩展 |

### 10.3 增强（文档）

- README 说明：`setLanguageCode` 后应刷新 UI（观察 Notification）；
- Examples：中/英切换 + 相对时间 formatter 联动。

---

## 11. 生命周期（Lifecycle）

### 11.1 `FKAppLifecycleState`

| 状态 | 典型触发 |
|------|----------|
| `notRunning` | 初始 |
| `launching` | init → didFinishLaunching 前 |
| `active` | didBecomeActive |
| `inactive` | willResignActive |
| `background` | didEnterBackground |
| `terminated` | willTerminate |

### 11.2 观察契约

- `observe` **立即** 回调当前 state；
- 返回 `FKBusinessObservationToken`，`invalidate()` 或 deinit 清理。

### 11.3 与 Pluggable 映射（§16）

| BusinessKit | Pluggable |
|-------------|-----------|
| `FKAppLifecycleState` | `FKPluggableAppLifecycleState` |
| 6 态 vs 4 态 | 适配器映射表（notRunning/launching → terminated 等） |

---

## 12. DeepLink 与 Universal Link

### 12.1 路由注册

```swift
kit.deeplink.register(FKDeeplinkRoute(
  id: "product",
  host: "example.com",
  pathPattern: "/product/*"
) { context in
  // context.url, context.source, context.parameters
  return true  // handled
})
```

### 12.2 匹配规则

- `host` nil → 任意 host；
- `pathPattern` 段数须一致；`*` 匹配单段；
- 多 route 注册顺序：**字典迭代顺序不保证** — 文档建议唯一匹配或 handler 内互斥。

### 12.3 `FKDeeplinkSource`

`deeplink` | `universalLink` | `handoff` | `unknown` — 由 AppDelegate / SceneDelegate 传入。

### 12.4 增强

| 能力 | 说明 |
|------|------|
| Push payload → URL | 宿主解析后 `deeplink.route`；可选 v2 `FKPushNotificationRouting`（Pluggable） |
| Pluggable 链式 handler | `FKBusinessDeeplinkPluggableAdapter`（§16） |
| 优先级/排序 | v2：route priority 字段 |

---

## 13. 设备与应用信息（Info）

### 13.1 `FKBusinessInfoProviding`

| 属性 | 来源 |
|------|------|
| `bundleID`, `appVersion`, `buildNumber` | `Bundle.main` |
| `systemVersion` | `UIDevice` |
| `deviceModelIdentifier` | `hw.machine` sysctl |
| `screenSize` | `UIScreen.main.bounds.size` |
| `channel` | configuration |
| `environment` | configuration / `#if DEBUG` |

### 13.2 用途

- 埋点公共参数；
- 版本比较 local metadata；
- 诊断与支持工单附件。

---

## 14. 业务工具（Utils）

### 14.1 Time（`FKBusinessTimeFormatter`）

- `format(date:format:locale:)` — 固定模板；
- `relativeDescription(from:now:)` — 「刚刚 / N 分钟前 / 昨天 HH:mm」类文案（随 `currentLanguageCode`）。

### 14.2 Number（`FKBusinessNumberFormatter`）

- `formatAmount` — 千分位 + 小数位；
- `formatCompact` — `1.2K` / `3.5万`（中英文）。

### 14.3 Mask（`FKBusinessMasker`）

- 手机、身份证、邮箱预设规则；
- 通用 `mask(_:keepPrefix:keepSuffix:maskCharacter:)`。

### 14.4 Alerts（`FKBusinessAlertManager`）

- `presentOnce(id:title:message:actions:presenter:)` — **同 id 去重**；
- 空 actions → 单 OK（FKI18n）；
- presenter nil → `FKTopViewControllerResolver`（§17）。

### 14.5 Startup（`FKBusinessStartupTaskManager`）

- `register(FKStartupTask)` — id 可覆盖；
- `runAll()` — 按 priority（high→low）+ delay 顺序 async 执行；
- **不** 保证失败隔离 — 单 task 异常应内部捕获（文档约定）。

---

## 15. Alert 后端统一（增强）

> 详见 [FKAlert_DESIGN.md](FKAlert_DESIGN.md) §13、§27 Q3。

### 15.1 现状

- `utils.alerts` → `FKBusinessAlertManager` → **`UIAlertController`**；
- `FKAlertAction` 模型在 BusinessKit，**FKAlert**（FKUIKit）复用该模型。

### 15.2 目标

```swift
public enum FKBusinessAlertBackend: Sendable, Equatable {
  case systemAlert
  case fkAlert
}

protocol FKBusinessAlertManaging {
  // 现有 API 不变；内部 switch backend
}
```

| Backend | 行为 |
|---------|------|
| `systemAlert` | 现有 `UIAlertController`（**默认**） |
| `fkAlert` | `FKAlertPresenter` / `FKAlert.confirm`（FKUIKit 可选依赖路径：weak linking 或宿主注入 presenter 闭包） |

### 15.3 非目标 v1.1

- 删除 `FKBusinessAlertManager`；
- BusinessKit **硬依赖** FKUIKit target — 推荐 **闭包注入** `FKAlertPresenting` 协议由 App 层绑定 FKAlert。

### 15.4 建议协议（可选）

```swift
public protocol FKBusinessAlertPresenting: AnyObject {
  @MainActor
  func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    from presenter: UIViewController?
  )
}
```

- `FKBusinessKitConfiguration.alertPresenter: (any FKBusinessAlertPresenting)?`；
- nil + backend `.fkAlert` → fallback `.systemAlert` 并 log warning。

---

## 16. Pluggable 桥接（增强）

> 与 [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) §12、§13 对齐。

| 适配器 | 符合 Pluggable | 委托 BusinessKit |
|--------|------------------|------------------|
| `FKBusinessLifecyclePluggableAdapter` | `FKAppLifecycleObserving` | `FKBusinessLifecycleObserver` |
| `FKBusinessDeeplinkPluggableAdapter` | `FKRouteHandling` / `FKDeeplinkRouting` | `FKBusinessDeeplinkRouter` |
| `FKBusinessAnalyticsPluggableUploader` | `FKPluggableAnalyticsUploading` | `FKBusinessAnalyticsTracker` 缓冲 |

**交付位置：** `BusinessKit/Bridge/` 或 `Pluggable/Implementations/BusinessKit/`（Q1 待决）。

**README 决策树：**

- 已用 `FKBusinessKit.shared` → 继续 BusinessKit API；
- 纯 DI / 多 Target 测试 → Pluggable 类型 + 适配器。

---

## 17. Top VC 解析器公开化（增强）

### 17.1 现状

```swift
@MainActor
enum FKTopViewControllerResolver {  // internal to BusinessKit module
  static func topMostViewController() -> UIViewController?
}
```

用于：版本更新弹窗、BusinessAlert、`presentOnce`。

### 17.2 目标

**方案 A（推荐）：** 迁至 `FKCoreKit/Components/Extension/UIKit/UIViewController+TopMost.swift`

```swift
public extension UIViewController {
  @MainActor
  static func fk_topMostViewController() -> UIViewController?
}
```

- BusinessKit 内部改调 `UIViewController.fk_topMostViewController()`；
- Toast、FKAlert、Banner 等 FKUIKit 组件复用。

**方案 B：** 保持 internal，文档导出 **复制实现** snippet — 不推荐。

---

## 18. 与 FKAlert / FKBanner / Widgets 组合

### 18.1 选型决策树

| 需求 | 选用 |
|------|------|
| 系统风格一次性提示 | `utils.alerts.presentOnce` 或 backend `.systemAlert` |
| FK 品牌化居中确认 | **FKAlert**（FKUIKit）；backend `.fkAlert` 或直接用 Presenter |
| 持久顶部升级条 | **FKBanner**（待建）；BusinessKit 仅提供 version check |
| 行内 Chip/Tag | **FKChipGroup**（FKUIKit Widgets） |
| Tab + Sheet 复杂筛选 | **TabBarFilter**（未入库，§22）或 Sheet + Chip 组合 |

### 18.2 Widgets 集成

- 遵循 [FKBusinessKit-Widgets-Integration_DESIGN.md](FKBusinessKit-Widgets-Integration_DESIGN.md)：
  - **禁止** 在 BusinessKit 复制 Chip/Avatar 渲染；
  - BusinessKit 提供 **编排示例**（Examples），非 v1 强制 API。

---

## 19. 与 FKI18n / Pluggable 环境对齐

| BusinessKit | Pluggable / 其他 |
|-------------|------------------|
| `FKBusinessEnvironment` (.debug/.release) | `FKAppEnvironment` (.development/.staging/.production) |
| `configuration.channel` | 埋点 / Remote Config 公共参数 |
| `info` 字段 | `FKPluggableAnalyticsCommonParametersProviding` 可重复注入 |

**装配建议（文档）：**

```swift
kit.updateConfiguration { $0.channel = appEnvironment.channelLabel }
// Pluggable FKBuildTimeAppEnvironment.apiBaseURL → Network 配置（非 BusinessKit 职责）
```

---

## 20. 错误模型

### 20.1 `FKBusinessError`

| Case | 场景 |
|------|------|
| `invalidArgument` | 参数非法 |
| `missingConfiguration` | 缺少 uploader 等 |
| `unsupported` | iOS 版本不足等 |
| `networkFailed` | 版本远程 fetch 失败 |
| `persistenceFailed` | 埋点文件 IO |
| `cancelled` | 任务取消 |
| `unknown` | 包装 Error |

- `LocalizedError` + FKI18n `fkcore.business.error.*`。

---

## 21. 并发与 Swift 6

| 组件 | 策略 |
|------|------|
| `FKBusinessKit` | `@unchecked Sendable`；configuration store 加锁 |
| Track / Startup | 私有 `DispatchQueue` |
| Deeplink / Lifecycle | `NSLock` 保护 registry/observers |
| UI  presentation | `@MainActor` Task（Version、Alert） |
| `FKDeeplinkHandler` | `@Sendable` closure |
| `FKStartupTask.work` | `@Sendable () async -> Void` |

---

## 22. v2 能力展望（非 v1 交付）

| 能力 | 说明 | 优先级 |
|------|------|--------|
| **TabBarFilter** | Tab + 锚点 Sheet 筛选面板；文档已引用，**源码未在 FKKit** | 中 |
| **FKUserListLeadingView** 等薄封装 | Widgets 组合胶水 | 低 |
| **Route priority** | DeepLink 确定性匹配 | 低 |
| **Analytics 隐私/consent gate** | flush 前 consent 检查 | 中 |
| **Backend version API 预设** | 除 App Store 外的 REST provider 模板 | 中 |
| **Scene 多窗口 Top VC** | 改进 resolver（已部分支持 foregroundActive scene） | 低 |
| **SwiftUI App 生命周期** | `@Environment(\.scenePhase)` 桥接文档 | 低 |

---

## 23. FKCoreKit 复用要求

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 本地化 | `FKI18n` / `FKBusinessI18nManager.coreManager` | 硬编码 UI 文案 |
| 错误文案 | `FKBusinessError` + FKI18n | 字符串散落 |
| I18n 核心 | `FKI18nManager` | BusinessKit 内重复 lproj 解析 |
| Alert 模型 | 共享 `FKAlertAction` | FKUIKit 再定义一套 Action |
| 网络上传 | 宿主实现 Upload 协议 | BusinessKit 内 URLSession 直调 REST |
| Top VC | 迁移后 `UIViewController.fk_*` | 第三份 resolver 复制 |

---

## 24. 公开 API 索引

**入口：** `FKBusinessKit.shared`、`init(...)`

| 子系统 | 主要 API |
|--------|----------|
| Config | `configuration`, `updateConfiguration` |
| Version | `appMetadata`, `checkForUpdate`, `presentUpdatePromptIfNeeded` |
| Track | `trackPageView`, `trackClick`, `trackEvent`, `setUploader`, `flush` |
| I18n | `currentLanguageCode`, `setLanguageCode`, `localized`, `observeLanguageChange`, `coreManager` |
| Lifecycle | `state`, `observe` |
| Deeplink | `register`, `unregister`, `route` |
| Info | bundle/version/device/... properties |
| Utils | `time`, `number`, `mask`, `alerts`, `startup` |

**共享模型：** `FKAlertAction`, `FKAnalyticsEvent`, `FKDeeplinkRoute`, `FKStartupTask`, `FKVersionCheckResult`, ...

---

## 25. 建议源码目录结构

```text
Sources/FKCoreKit/Components/BusinessKit/
├── Bridge/                              # 新增 — Pluggable
│   ├── FKBusinessLifecyclePluggableAdapter.swift
│   ├── FKBusinessDeeplinkPluggableAdapter.swift
│   └── FKBusinessAnalyticsPluggableUploader.swift
├── Alert/                               # 新增 — Backend
│   └── FKBusinessAlertBackend.swift
├── Core/
├── ...
└── README.md                            # 链到本文 + 决策树
```

---

## 26. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/BusinessKit/`

### 26.1 现状

- 单文件 `FKBusinessKitExampleViewController` — 综合 Demo（可保留为 **All-in-One**）。

### 26.2 目标 Hub 结构

| # | 场景 | 验证点 |
|---|------|--------|
| H0 | `AllInOne` | 现有综合 Demo |
| **B1** | `VersionCheck` | App Store / mock provider + 决策 |
| **B2** | `VersionForceUpdate` | force 路径 |
| **B3** | `AnalyticsBufferFlush` | uploader + background flush |
| **B4** | `LanguageSwitch` | i18n + 相对时间刷新 |
| **B5** | `LifecycleLog` | 状态流 |
| **B6** | `DeeplinkRoute` | 注册 + 模拟 URL |
| **B7** | `MaskAndFormat` | mask + number + time |
| **B8** | `StartupTasks` | 优先级与 delay |
| **B9** | `AlertPresentOnce` | 去重 |
| **E1** | `AlertBackendFKAlert` | backend 切换（增强后） |
| **E2** | `PluggableBridge` | Analytics 适配器（增强后） |
| **E3** | `BannerVersionCompose` | 文档式：check → 宿主 Banner（FKBanner 落地后） |

---

## 27. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **B0** | Examples Hub 骨架 + B1–B9 拆分 | 已交付能力可见性 |
| **B1** | Top VC → Extension；README 决策树 | 横切复用 |
| **B2** | Pluggable Bridge 三适配器 | DI 对齐 |
| **B3** | Alert Backend 协议 + 文档 | FKAlert 共存 |
| **B4** | Optional FKAlert Examples E1 | 端到端 |
| **B5** | TabBarFilter 评估（FKUIKit 或放弃文档引用） | 降低文档漂移 |

---

## 28. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Bridge 放 BusinessKit vs Pluggable？ | **Pluggable/Implementations/BusinessKit/** |
| Q2 | `fkAlert` backend 如何不硬依赖 FKUIKit？ | **协议注入** `FKBusinessAlertPresenting` |
| Q3 | TabBarFilter 是否进入 FKKit？ | **FKUIKit 薄封装** 或修正文档去掉外部引用 |
| Q4 | Deeplink 多 route 匹配顺序？ | v2 增加 priority；v1 文档警告 |
| Q5 | Analytics 丢弃策略可配置？ | v2；v1 文档固定行为 |
| Q6 | Hub 与 All-in-One 并存？ | 是 |

---

## 29. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初版：已交付七子系统详表、Alert/Pluggable/TopVC 增强、Examples Hub、边界决策树 |

---

## 30. 相关文档

| 文档 | 内容 |
|------|------|
| [BusinessKit/README.md](../Sources/FKCoreKit/Components/BusinessKit/README.md) | 使用指南 |
| [FKBusinessKit_ENHANCEMENT_DESIGN.md](FKBusinessKit_ENHANCEMENT_DESIGN.md) | 增量增强索引 |
| [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) | BusinessKit 桥接 |
| [FKAlert_DESIGN.md](FKAlert_DESIGN.md) | Alert 迁移与 Backend |
| [FKBanner-FKNoticeBar_DESIGN.md](FKBanner-FKNoticeBar_DESIGN.md) | 版本条组合 |
| [FKBusinessKit-Widgets-Integration_DESIGN.md](FKBusinessKit-Widgets-Integration_DESIGN.md) | Widgets 组合 |
| [FKBackgroundTaskManager_DESIGN.md](FKBackgroundTaskManager_DESIGN.md) | 后台 flush / Processing 配方 |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §10.3 |
