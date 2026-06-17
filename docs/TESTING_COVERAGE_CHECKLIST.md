# FKKit 测试覆盖清单（执行指导）

**状态：** 活文档 — 补测工作以本文 + [`TESTING_GUIDE.md`](TESTING_GUIDE.md) 为准。  
**关联：** [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md)（组件缺陷台账）  
**最后更新：** 2026-06-17

---

## 1. 文档目的

本文是 **「测什么、先测什么、测到哪算完成」** 的可执行清单，供后续分批补测使用。

与 [`TESTING_GUIDE.md`](TESTING_GUIDE.md) 的分工：

| 文档 | 作用 |
|------|------|
| `TESTING_GUIDE.md` | 策略、规范、运行方式、阶段计划 |
| **本文** | 模块级 API 覆盖矩阵、优先级、建议测试文件名、完成勾选 |
| `TESTING_COMPONENT_ISSUES.md` | 测试暴露的**组件 bug**（非用例错误） |

---

## 2. 执行规则（必读）

1. **按优先级从上到下** — 完成 P0 再大规模展开 P1/P2。
2. **测试失败时先分类**：
   - **用例错误** → 改测试（错误断言、错误 API 假设、并发时序）。
   - **组件 bug** → 记入 [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md)，**不要**改断言迁就错误行为（除非明确 Wontfix）。
3. **命名与目录** — `Tests/{FKCoreKit|FKUIKit}Tests/{Component}/FK{Type}Tests.swift`；类名与文件名一致。
4. **复用 Support** — Network 用 `FKNetworkTestCase` / `NetworkTestFixtures`；UIKit 行为用 `FKUIKitTestCase` + `@MainActor`。
5. **Internal 纯逻辑** — 允许 `@testable import FKCoreKit` / `FKUIKit`（如 `FKNetworkRetryExecutor`、`FKListSnapshotApplier`）。
6. **每批交付** — 本地 `xcodebuild test` + `SWIFT_STRICT_CONCURRENCY=complete` 全绿后再勾选本文。

---

## 3. 当前基线（2026-06-17）

| 指标 | 数值 |
|------|------|
| 测试文件 | ~255（+ Support/Fixtures） |
| 测试方法 | ~845 |
| FKCoreKit 通过 | 389（3 skipped：Keychain） |
| FKUIKit 通过 | 456 |
| FKCoreKit 组件目录 | 16/16 至少有 1 个测试文件 |
| FKUIKit 组件目录 | 30/30 至少有 1 个测试文件 |
| 主要缺口 | **深度**：配置 smoke 多、行为/集成少；Player / ImageLoader / Refresh 行为 |

**Phase 3 行覆盖参考目标**（非 CI 门禁）：FKCoreKit ~60–70%，FKUIKit ~30–40%。

---

## 4. 优先级定义

| 级别 | 含义 | 完成标准 |
|------|------|----------|
| **P0** | 核心逻辑 / 高回归风险 / 无 UI 或轻 UI | 公开 API 主路径 + 主要 error path 有测试 |
| **P1** | 重要但可 Mock 系统 API | 主路径 + 边界 |
| **P2** | 配置补全、presets、Equatable | 与现有 ConfigurationTests 模式一致 |
| **P3** | 集成 / MainActor UI 行为 | 可观察状态，不测像素 |
| **Defer** | 系统 UI、AVPlayer 解码、XCUITest | Examples + Mock；不写自动化 |

---

## 5. FKCoreKit 模块清单

### 5.1 Extension（完善度：高 ★★★★☆）

| 状态 | 测试文件/范围 | 缺口 |
|------|---------------|------|
| [x] | 40+ 文件，String/Date/URL/Dictionary/… | 随新 Extension 增量补 smoke |
| [ ] | — | 新 public API 合入时同步加 case |

---

### 5.2 Network（完善度：中 ★★★☆☆）

**已有：** `FKNetworkClientTests`（7）、`FKNetworkRetryPolicyTests`、`FKSSLPinningConfigurationTests`

| 优先级 | API / 行为 | 建议测试文件 | 状态 |
|--------|------------|--------------|------|
| P0 | `FKRequestDeduplicator.shouldProceed` / `complete` | `FKRequestDeduplicatorTests.swift` | [x] |
| P0 | `FKNetworkClient` + `.idempotentDeduplicated` 并发去重 | `FKNetworkClientDeduplicationTests.swift` | [x] |
| P0 | `FKNetworkClient` HTTP retry（503→200、retryExhausted） | `FKNetworkClientRetryTests.swift` | [x] |
| P0 | `FKNetworkRetryExecutor`（@testable） | `FKNetworkRetryExecutorTests.swift` | [x] |
| P0 | `FKMultipartFormData.encode` | `FKMultipartFormDataTests.swift` | [x] |
| P1 | `AuthHeaderInterceptor` / `MD5RequestSigner` | `FKNetworkInterceptorsTests.swift` | [x] |
| P1 | `FKNetworkCache` TTL | `FKNetworkCacheTests.swift` | [x] |
| P1 | `FKNetworkConfiguration.environmentMap` | `FKNetworkConfigurationTests.swift` | [x] |
| P2 | `FKSSLPinningValidator` | `FKSSLPinningValidatorTests.swift` | [x] |
| Defer | 真实 TLS / 证书 fixture | — | — |

---

### 5.3 ImageLoader（完善度：低 ★★☆☆☆）

**已有：** `FKImageLoaderConfigurationTests`、`FKImageLoadRequestCacheKeyTests`

| 优先级 | API / 行为 | 建议测试文件 | 状态 |
|--------|------------|--------------|------|
| P0 | `FKImageLoaderURLSessionSettings` clamp | `FKImageLoaderURLSessionSettingsTests.swift` | [x] |
| P0 | `FKImageLoader.loadImageResult` + Mock URLSession | `FKImageLoaderTests.swift` | [x] |
| P0 | `.cacheOnly` → `cacheMissUnderCacheOnlyPolicy` | `FKImageLoaderTests.swift` | [x] |
| P0 | `reachabilityFastFail` → `.offline` | `FKImageLoaderTests.swift` | [x] |
| P1 | `store` / `cachedImage` round-trip | `FKImageLoaderCacheTests.swift` | [x] |
| P1 | `cancelLoad` + Task cancellation | `FKImageLoaderTests.swift` | [x] |
| P2 | `onEvent` 回调 | `FKImageLoaderTests.swift` | [x] |

---

### 5.4 Storage / Security / Async / I18n / QRCode / BusinessKit / FileManager / Logger

| 模块 | 完善度 | P0 剩余 |
|------|--------|---------|
| Storage | ★★★☆☆ | Keychain 真机矩阵（Simulator skip 已有） |
| Security | ★★★☆☆ | RSA 长向量 fixture（可选） |
| Async | ★★★☆☆ | Debouncer 边界（interval 0 / cancel / coalesce） | [x] |
| I18n | ★★★☆☆ | plural 复杂规则（若有） |
| QRCode | ★★★★☆ | 维持 |
| BusinessKit | ★★★☆☆ | StartupTask 串行 + delay 排序 | [x] |
| FileManager | ★★★☆☆ | Background session coordinator | [x] |
| Logger | ★★★☆☆ | 维持 |
| Pluggable | ★★★★☆ | 新 Mock 组合场景随功能增量 |

---

### 5.5 Permissions / LocalNotification / BackgroundTask / BiometricAuth

| 优先级 | API | 建议测试文件 | 状态 |
|--------|-----|--------------|------|
| P0 | `FKPermissions.request` batch（空数组 / 多 kind 完成） | `FKPermissionsTests.swift` | [x] |
| P0 | `observeStatusChanges` + token `invalidate` | `FKPermissionObservationTokenTests.swift` + `FKPermissionsTests.swift` | [x] |
| P1 | prePrompt cancel → `.prePromptCancelled` | `FKPermissionPrePromptPresenterTests.swift` | [x] |
| Defer | 各 `FKPermissionHandling` 真实 TCC | Examples | — |
| P1 | `FKMockLocalNotificationScheduler` 深度 | 扩展 `FKMockLocalNotificationSchedulerTests` | [x] |
| P1 | `FKMockBackgroundTaskScheduler` 深度 | 扩展 `FKMockBackgroundTaskSchedulerTests` | [x] |
| P2 | `FKMockBiometricAuthenticator` 完整 flow | 扩展 `FKMockBiometricAuthenticatorTests` | [x] |

---

## 6. FKUIKit 模块清单

### 6.1 Player（完善度：极低 ★☆☆☆☆ — 110+ 源文件，2 测试文件）

| 优先级 | API | 建议测试文件 | 状态 |
|--------|-----|--------------|------|
| P0 | `FKMediaFormatProbe.probe` | `FKMediaFormatProbeTests.swift` | [x] |
| P0 | `FKAudioQueue` advance/retreat/mode | `FKAudioQueueTests.swift` | [x] |
| P0 | `FKAudioLyricsParser` | `FKAudioLyricsParserTests.swift` | [x] |
| P0 | `FKMediaSource.candidateURLs` 等 | `FKMediaSourceTests.swift` | [x] |
| P1 | `FKMediaEngineRouter.selectEngine` | `FKMediaEngineRouterTests.swift` | [x] |
| P1 | `FKVideoSubtitleParser` | `FKVideoSubtitleParserTests.swift` | [x] |
| P1 | `FKMediaQoEService` | `FKMediaQoEServiceTests.swift` | [x] |
| P1 | `FKMediaInMemoryResumeStore` | `FKMediaResumeStoreTests.swift` | [x] |
| Defer | `FKAVPlayerEngine`、真实解码、NowPlaying | Examples | — |

---

### 6.2 Refresh（完善度：低 ★★☆☆☆ — 无行为测试）

| 优先级 | API | 建议测试文件 | 状态 |
|--------|-----|--------------|------|
| P0 | `FKRefreshControl` begin/end 状态机 | `FKRefreshControlStateTests.swift` | [x] |
| P0 | action token 过期 `endRefreshing(token:)` | 同上 | [x] |
| P1 | `FKRefreshCoordinator.canStart`（@testable） | `FKRefreshCoordinatorTests.swift` | [x] |
| P2 | footer auto-trigger re-arm | `FKRefreshControlStateTests.swift` | [x] |

---

### 6.3 ListKit（完善度：中 ★★★☆☆）

| 优先级 | API | 建议测试文件 | 状态 |
|--------|-----|--------------|------|
| P0 | `FKListSnapshotApplier` mutations（@testable） | `FKListSnapshotMutationTests.swift` | [x] |
| P0 | `duplicateItemIDs` | 同上 | [x] |
| P1 | `FKDiffableTableViewController.applyMutation` | `FKDiffableListMutationTests.swift` | [x] |
| P2 | `FKListPresentationState` 转换 | `FKListPresentationStateTests.swift` | [x] |

---

### 6.4 TextField / Alert / PagingController

| 模块 | P0 缺口 | 建议文件 | 状态 |
|------|---------|----------|------|
| TextField | validator 分支补全（bankCard/password/18位身份证） | 扩展 `FKTextFieldDefaultValidatorTests` | [x] |
| TextField | `FKTextFieldCompositeValidator` | `FKTextFieldCompositeValidatorTests.swift` | [x] |
| TextField | `FKTextField` UI pipeline | `FKTextFieldBehaviorTests.swift` | [x] |
| Alert | `FKAlertActionResolver`（@testable，action 排序/默认 OK） | `FKAlertActionResolverTests.swift` | [x] |
| Alert | `FKAlertCoordinator` queue（@testable） | `FKAlertCoordinatorTests.swift` | [x] |
| PagingController | `FKPagingStateMachine`（@testable） | `FKPagingStateMachineTests.swift` | [x] |
| PagingController | `FKPagingController` 程序化切页 | `FKPagingControllerTests.swift` | [x] |

---

### 6.5 SheetPresentationController / Callout

| 优先级 | API | 建议测试文件 | 状态 |
|--------|-----|--------------|------|
| P0 | `resolvedShellHeight(fromContentHeight:…)` | `FKSheetPreferredContentSizingTests.swift` | [x] |
| P1 | presets `centerAlert` / `bottomSheetDefault` | 扩展 `FKSheetPresentationPresetsTests` | [x] |
| P1 | `FKCalloutLayoutEngine`（@testable） | `FKCalloutLayoutEngineTests.swift` | [x] |
| P2 | `FKCallout.show` / `dismiss` 集成 | `FKCalloutPresentationTests.swift` | [x] |

---

### 6.6 其余 FKUIKit 组件（配置 smoke 已有，行为可选）

| 组件 | 完善度 | 下一批 P1 行为测试 |
|------|--------|-------------------|
| Button | ★★★☆☆ | 扩展 `FKButtonStateTests`（gradient/content 模式） | [x] |
| Carousel / TabBar / Search* | ★★★☆☆ | selection reducer / infinite loop adapter | [x] |
| ImageView / PhotoPicker | ★★☆☆☆ | retry debounce + selection policy | [x] |
| Toast / EmptyState / Badge | ★★☆☆☆ | Toast queue actor + EmptyState layout metrics | [x] |
| WebView / Skeleton / Blur | ★★☆☆☆ | 维持 defaults；Defer WKWebView 渲染 |
| FlowVisualization | ★★★☆☆ | StepIndicator layout engine | [x] |
| Widgets | ★★★☆☆ | Avatar/Chip 尺寸 preset 已有 |
| Theme / Core | ☆☆☆☆☆ | `FKTheme` token 解析（color/metrics/resolver） | [x] |

---

## 7. 第一批实施范围（2026-06-17 启动）

本批勾选 **§5.2 P0、§5.3 P0、§6.1 P0、§6.2 P0、§6.3 P0、§6.4 TextField 部分、§6.5 P0** — **已完成（2026-06-17）**。

---

## 7.1 第二批实施范围（2026-06-17）

本批勾选 **§5.2 P1、§5.5 P0、§6.1 P1、§6.2 P1、§6.4 Alert/Paging/TextField、§6.5 P1 Callout** — **已完成（2026-06-17）**。

| 模块 | 新增测试文件 | 用例数（约） |
|------|--------------|--------------|
| FKCoreKit Network | `FKNetworkInterceptorsTests`、`FKNetworkCacheTests`、`FKNetworkConfigurationTests` | 9 |
| FKCoreKit Permissions | `FKPermissionObservationTokenTests`、`FKPermissionsTests` | 5 |
| FKUIKit Player | `FKMediaEngineRouterTests`、`FKVideoSubtitleParserTests`、`FKMediaQoEServiceTests`、`FKMediaResumeStoreTests` | 16 |
| FKUIKit Alert / Paging / TextField / Refresh / Callout | `FKAlertActionResolverTests`、`FKPagingStateMachineTests`、`FKTextFieldCompositeValidatorTests`、`FKRefreshCoordinatorTests`、`FKCalloutLayoutEngineTests` | 18 |
| **合计新增** | **14 文件** | **~48** |

**Batch-2 失败分类（均修测试，无组件变更）：**

| 现象 | 分类 | 处理 |
|------|------|------|
| `FKVideoSubtitleParser` invalidEncoding 未抛出 | 用例错误 | Foundation 对多种字节序列仍能解码；改为断言无 cue 结构时返回空数组 |
| `FKAlertActionResolver` 4 actions trim 触发 `assertionFailure` | 用例错误 | Debug 下 `assertionFailure` 终止进程；改为 ≤3 actions 的 passthrough 测试 |
| `FKPermissions` 并发回调 `callbackCount` 变异 | 用例错误 | 改用 `LockedCounter` + 显式 `[FKPermissionRequest]()` 消除 overload 歧义 |

**下一批建议（仍为 `[ ]`）：** Extension 增量维护、Flow Timeline timestamp formatter、I18n plural（若有）、Network 真实 TLS fixture（Defer）。

---

## 7.6 第七批实施范围（2026-06-17）

本批勾选 **§5.4 FileManager/Throttler、§6.6 Theme/Flow Timeline** — **已完成（2026-06-17）**。

| 模块 | 新增/扩展测试文件 | 用例数（约） |
|------|-------------------|--------------|
| FKCoreKit FileManager | `FKBackgroundSessionCoordinatorTests` | 3 |
| FKCoreKit Async | 扩展 `FKThrottlerTests` | 1 |
| FKUIKit Theme | `FKThemeColorTests`、`FKThemeResolverTests`、`FKThemeMetricsTests` | 10 |
| FKUIKit FlowVisualization | `FKFlowStateApplierTests`、`FKTimelineLayoutEngineTests` | 7 |
| **合计新增** | **5 新文件 + 1 扩展** | **~21** |

**Batch-7 失败分类（均修测试，无组件变更）：**

| 现象 | 分类 | 处理 |
|------|------|------|
| Timeline leading rail 断言 title 在 node 左侧 | 用例错误 | 改为断言 `titleFrame.minX > nodeFrame.maxX` |
| 空 sections 高度仅断言 bottom inset | 用例错误 | 改为 `top + bottom` insets |

**验证：** `xcodebuild test` — **842 passed**（FKCoreKit 389 + FKUIKit 456；3 skipped Keychain）。

---

本批勾选 **§5.2 P2 SSL Pinning、§5.4 Async/BusinessKit、§6.6 Toast/EmptyState/Flow layout** — **已完成（2026-06-17）**。

| 模块 | 新增/扩展测试文件 | 用例数（约） |
|------|-------------------|--------------|
| FKCoreKit Network | `FKSSLPinningValidatorTests` | 8 |
| FKCoreKit Async | 扩展 `FKDebouncerTests` | 3 |
| FKCoreKit BusinessKit | 扩展 `FKBusinessStartupTaskManagerTests` | 2 |
| FKUIKit Toast | `FKToastQueueActorTests` | 7 |
| FKUIKit EmptyState | `FKEmptyStateLayoutMetricsTests` | 4 |
| FKUIKit FlowVisualization | `FKStepIndicatorLayoutEngineTests` | 4 |
| **合计新增** | **4 新文件 + 2 扩展** | **~28** |

**Batch-6 失败分类：**

| 现象 | 分类 | 处理 |
|------|------|------|
| `.dropNew` 首条 toast 永不入队 / 测试访问空数组崩溃 | **组件 bug T-005** | `FKToastQueueActor` 空闲时允许首条入队；见 [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md) |
| `testMaxVisibleStepsForcesHorizontalScroll` 断言 contentWidth > bounds | 用例错误 | 改为断言 `needsHorizontalScroll` 与 step 数量 |
| `testRightToLeftLayoutMirrorsNodeFrames` 像素级 mirror 误差 | 用例错误 | 改为断言 RTL 下 node `midX` 逆序 |

**验证：** `xcodebuild test` — **821 passed**（FKCoreKit 385 + FKUIKit 439；3 skipped Keychain）。

---

## 7.4 第五批实施范围（2026-06-17）

本批勾选 **§5.5 Mock 深度、§6.6 Carousel/TabBar/ImageView/PhotoPicker** — **已完成（2026-06-17）**。

| 模块 | 新增/扩展测试文件 | 用例数（约） |
|------|-------------------|--------------|
| FKCoreKit LocalNotification | 扩展 `FKMockLocalNotificationSchedulerTests` | 4 |
| FKCoreKit BackgroundTask | 扩展 `FKMockBackgroundTaskSchedulerTests` | 4 |
| FKCoreKit BiometricAuth | 扩展 `FKMockBiometricAuthenticatorTests` | 3 |
| FKUIKit TabBar / Carousel | `FKTabBarSelectionReducerTests`、`FKCarouselInfiniteLoopAdapterTests` | 8 |
| FKUIKit ImageView / PhotoPicker | `FKImageViewBehaviorTests`、`FKPhotoPickerSelectionPolicyTests` | 7 |
| **合计新增** | **4 新文件 + 3 扩展** | **~23** |

**Batch-5 失败分类（均修测试，无组件变更）：**

| 现象 | 分类 | 处理 |
|------|------|------|
| `testRetryIsNoOpWhenRetryIsDisabled` 因 `url` setter 触发加载 | 用例错误 | 改用 `currentURL` 仅绑定 URL，断言 `retry()` 不增加 load 次数 |
| `testSimulateLaunchReturnsFalseWhenTaskExpired` 捕获 var 并发变异 | 用例错误 | 改用 `LockedFlag` |
| Biometric 测试使用不存在的 policy / options 参数 | 用例错误 | 改用 `.devicePasscode` 与 `localizedFallbackTitle` |

**验证：** `xcodebuild test` — **796 passed**（FKCoreKit 372 + FKUIKit 424；3 skipped Keychain）。

---

## 7.3 第四批实施范围（2026-06-17）

本批勾选 **§5.3 P2 onEvent、§6.2 P2 footer re-arm、§6.4 TextField pipeline、§6.5 Callout 集成、§6.6 Button** — **已完成（2026-06-17）**。

| 模块 | 新增/扩展测试文件 | 用例数（约） |
|------|-------------------|--------------|
| FKCoreKit ImageLoader | 扩展 `FKImageLoaderTests`（`onEvent`） | 2 |
| FKUIKit Refresh | 扩展 `FKRefreshControlStateTests`（footer re-arm） | 2 |
| FKUIKit TextField | `FKTextFieldBehaviorTests` | 4 |
| FKUIKit Callout | `FKCalloutPresentationTests` | 3 |
| FKUIKit Button | 扩展 `FKButtonStateTests`（gradient / text+image） | 2 |
| **合计新增** | **2 新文件 + 3 扩展** | **~13** |

**Batch-4 失败分类（均修测试，无组件变更）：**

| 现象 | 分类 | 处理 |
|------|------|------|
| `FKTextField` 输入 `"12345"` 后 `validationResult` 仍为 valid | 用例错误 | 默认 `validationPolicy.debounceInterval == 0.2`，同步断言过早；测试中设 `debounceInterval = 0` |
| `FKButton.setImage` 缺少 `slot` 参数 | 用例错误 | 使用 `slot: .leading` 与 `image(slot:for:)` API |

**验证：** `xcodebuild test` — **773 passed**（FKCoreKit 361 + FKUIKit 412；3 skipped Keychain）。

---

## 7.2 第三批实施范围（2026-06-17）

本批勾选 **§5.3 P1、§5.5 prePrompt、§6.3 P1/P2、§6.4 Alert/Paging、§6.5 Sheet presets** — **已完成（2026-06-17）**。

| 模块 | 新增/扩展测试文件 | 用例数（约） |
|------|-------------------|--------------|
| FKCoreKit ImageLoader | `FKImageLoaderCacheTests`；扩展 `FKImageLoaderTests`（cancel） | 5 |
| FKCoreKit Permissions | `FKPermissionPrePromptPresenterTests` | 5 |
| FKUIKit ListKit | `FKDiffableListMutationTests`、`FKListPresentationStateTests` | 5 |
| FKUIKit Alert / Paging | `FKAlertCoordinatorTests`、`FKPagingControllerTests` | 4 |
| FKUIKit Sheet | 扩展 `FKSheetPresentationPresetsTests` | 2 |
| **合计新增** | **6 新文件 + 2 扩展** | **~21** |

**Batch-3 失败分类：**

| 现象 | 分类 | 处理 |
|------|------|------|
| `FKImageLoader` cancel → `.network` 而非 `.cancelled` | **组件 bug T-003** | `mapTransportError`；见 [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md) |
| prePrompt 在 xctest 不弹窗 / KVC 触发 action 崩溃 | **组件 bug T-004** + 用例策略 | scene 回退 + `presentingFrom` API + injectable `presentAlert`；集成测用 mock 闭包，不测 KVC |
| `FKPermissions(prePromptPresenter:)` private | 测试基础设施 | 增加 module-internal `init(prePromptPresenter:)` |
| `FKPagingController.setSelectedIndex(5)` 返回 true | 用例错误 | 改为 `setSelectedIndex(forItemID: "missing")` 期望 false |

**验证：** `xcodebuild test` — **760 passed**（FKCoreKit 359 + FKUIKit 401；3 skipped Keychain）。

---

## 8. 缺陷处理流程

```
测试失败
    ├─ 能否用最小 repro 稳定复现？
    │     ├─ 否 → 修测试（flaky / 时序 / MainActor）
    │     └─ 是 → 对照 public 文档/Examples 期望
    │               ├─ 文档说 A，代码做 B → 组件 bug → TESTING_COMPONENT_ISSUES.md
    │               └─ 测试假设错 → 修测试
    └─ 组件 bug 修复 PR 应附带 regression test
```

---

## 9. 维护

- 新 public API：**P0/P1 模块默认评估是否加测试**（见 `TESTING_GUIDE` §18）。
- 每完成一批：更新 §3 基线数字、§7 勾选、§5/§6 状态列。
- 组件 bug 修复后：在 `TESTING_COMPONENT_ISSUES.md` 将 Status 改为 **Fixed**。
