# FKKit 测试指导文档

**状态：** 活文档 — 后续所有自动化测试工作以本文为准。  
**分支：** 测试相关工作在 `feature/testing`（或自 `develop` 切出的 `feature/<scope>-tests`）上进行。  
**最后更新：** 2026-06-17

---

## 1. 文档目的

FKKit 是面向全球 iOS 开发者的开源 Swift 组件库（SPM + CocoaPods）。本文定义：

- **要不要测、测什么、不测什么**
- **测试目录与命名规范**
- **如何编写与运行测试**（面向从未写过测试的维护者）
- **覆盖率与 CI 的期望**
- **分阶段落地计划与组件优先级清单**

库源码、公开 API、注释、README、Examples 文案保持 **英文**；**本文档为中文维护指南**，不进入 Swift Package 编译目标。

---

## 2. 当前测试现状

| 项目 | 状态 |
|------|------|
| SPM 测试 Target | `FKCoreKitTests` + `FKUIKitTests`（`Package.swift`） |
| Extension 用例 | `Tests/FKCoreKitTests/Extension/` — 6 个测试类 |
| Network 用例 | `Tests/FKCoreKitTests/Network/FKNetworkClientTests.swift` — 7 个集成测试 |
| Storage 用例 | `Tests/FKCoreKitTests/Storage/FKMemoryStorageTests.swift` — 8 个用例 |
| Security 用例 | `Tests/FKCoreKitTests/Security/` — Hash + AES 首批用例 |
| Async 用例 | `Tests/FKCoreKitTests/Async/` — Debouncer + Throttler |
| I18n 用例 | `Tests/FKCoreKitTests/I18n/` — Localizer、LocaleMatcher、MessageFormat |
| FKUIKit 用例 | `Tests/FKUIKitTests/` — ListKit、Refresh、Button、EmptyState、PagingController、SearchBar、Player、Toast、Alert、TextField、ProgressBar、Skeleton、Divider、RatingControl、ActionSheet、Carousel、Callout、FlowVisualization、ImageView、PhotoPicker、BlurView、CornerShadow、ExpandableText、QRCode、Chip、Badge、Widgets、SheetPresentationController、TabBar、WebView |
| FKCoreKit P2 用例 | `QRCode/`、`BusinessKit/`、`FileManager/`、`ImageLoader/` |
| FKCoreKit P3 用例 | `Pluggable/`、`Permissions/`、`LocalNotification/`、`BackgroundTask/`、`BiometricAuth/`、`Logger/` |
| FKCoreKit P4 用例 | `Extension/DateExtensionTests`、`Pluggable/FKInMemoryFeatureFlags`、`Pluggable/FKMockImageLoader` |
| FKCoreKit P5 用例 | `Extension/Calendar`、`Storage/FKFileStorage`、`Security/FKSecurityCoder`+`FKSignatureService`、`BusinessKit/FKBusinessMasker` |
| FKCoreKit P6 用例 | `Extension/FKValueParsing`、`Storage/FKKeychainStorage`（无 entitlement 时 `XCTSkip`）、`BusinessKit/FKBusinessDeeplinkRouter` |
| FKCoreKit P7 用例 | `Pluggable/`（TextInput 格式化/校验、`FKRouteContext+URL`）、`BusinessKit/FKBusinessTimeFormatter`、`FKBusinessStartupTaskManager` |
| FKCoreKit P8 用例 | `Extension/URLExtensionTests`、`LocalNotification/FKLocalNotificationManagerConfiguration`、`BackgroundTask/FKBackgroundTaskManagerConfiguration`、`BiometricAuth/FKBiometricAuthConfiguration` |
| FKCoreKit P9 用例 | `Extension/`（Dictionary、Data、NumberFormatting、TimeInterval）、`ImageLoader/FKImageLoaderConfiguration`、`BusinessKit/FKBusinessKitConfiguration`、`Pluggable/FKURLDeeplinkParser` |
| FKCoreKit P10 用例 | `Extension/`（Encodable、Sequence、FloatingPoint、Error）、`I18n/FKI18nConfiguration`、`FileManager/FKFileManagerConfiguration`、`Logger/FKLoggerConfig`、`Network/FKSSLPinningConfiguration` |
| FKCoreKit P11 用例 | `Extension/`（CGFloat/CGRect/CGSize、Set、IndexPath、String+Processing/Hashing）、`Pluggable/FKHTTPMethod`+`FKRemoteConfigError`、`BackgroundTask/FKBackgroundTaskRegistration`、`LocalNotification/FKLocalNotificationUserInfoKey` |
| FKCoreKit P12 用例 | `Extension/`（BinaryInteger/CGPoint/Character/NSRange/Comparable/Decimal/ProcessInfo、FKDeviceInfo）、`Pluggable/FKJSONRemoteConfigConfiguration`+`FKPluggableAnalyticsEvent` |
| FKCoreKit P13 用例 | `Extension/`（Locale、TimeZone、Bundle、StringValidation、UIEdgeInsets、UserDefaults）、`Pluggable/FKBuildTimeAppEnvironment`、`LocalNotification/FKLocalNotificationPresentationOptions` |
| FKCoreKit P14 用例 | `Extension/`（DispatchQueue、FileManager、NSAttributedString、NotificationCenter）、`Network/FKNetworkRetryPolicy`、`BackgroundTask/FKBackgroundProcessingRequest`、`Permissions/FKPermissionModels`、`Pluggable/FKPluggableSessionError`、`QRCode/FKQRCodeGenerationOptions`、`FileManager/FKZipOptions` |
| FKUIKit P6 用例 | `SheetPresentationController/`、`TabBar/`、`WebView/`、`Widgets/FKMarqueeLabelConfiguration`、`ExpandableText/FKExpandableTextConfiguration`、`ActionSheet/FKActionSheetPresentationConfiguration` |
| FKUIKit P7 用例 | `Refresh/FKRefreshConfiguration`、`FlowVisualization/`（StepIndicator layout + Flow interaction）、`ProgressBar/FKProgressBarAppearanceConfiguration`、`RatingControl/FKRatingAppearanceConfiguration`、`Alert/FKAlertConfiguration`、`Badge/FKBadgeConfiguration`、`Carousel/FKCarouselAutoScrollConfiguration`、`TabBar/FKTabBarSelectionSnapshot` |
| FKUIKit P8 用例 | `PagingController/`（Configuration + NavigationBarTabOptions）、`SearchViewController/`（Loading/Presentation/Defaults）、`FlowVisualization/FKTimelineLayoutConfiguration`、`ProgressBar/`（Layout + Motion）、`TextField/`（Layout + ValidationPolicy） |
| FKUIKit P9 用例 | `RatingControl/`（Motion + Layout）、`FlowVisualization/FKFlowMotionConfiguration`、`Button/FKButtonLoadingIndicatorConfiguration`、`ListKit/FKListLayoutConfiguration`、`TextField/FKTextFieldMotionConfiguration`、`Carousel/FKCarouselPagingConfiguration`、`SearchViewController/FKSearchBehaviorConfiguration`、`ActionSheet/FKActionSheetHapticsConfiguration`、`PagingController/FKPagingEmptyStateConfiguration` |
| FKUIKit P10 用例 | `ListKit/`（Animation、Refresh、Loading）、`SearchViewController/FKSearchEmptyConfiguration`、`RatingControl/FKRatingAccessibilityConfiguration`、`Carousel/FKCarouselInteractionConfiguration`、`ProgressBar/FKProgressBarAccessibilityConfiguration`、`Alert/`（Motion + Accessibility）、`Player/FKMediaNetworkConfiguration`、`PhotoPicker/FKPhotoPickerPresentationConfiguration`、`Chip/FKChipGroupConfiguration` |
| FKUIKit P11 用例 | `ImageView/FKImageViewAccessibilityConfiguration`、`ListKit/`（Search、Empty、Error、Windowing）、`TextField/FKTextFieldValidationFeedbackConfiguration`、`Widgets/FKAvatarLayout`+`FKAvatarStoryRing`、`EmptyState/FKEmptyStateBackgroundAppearance`、`SearchBar/FKSearchIconConfiguration`、`Alert/FKAlertPresentationConfiguration`、`FlowVisualization/FKTimelineConfiguration`+`FKStepIndicatorConfiguration` |
| FKUIKit P12 用例 | `TextField/`（Accessibility、Counter、InlineMessage）、`ImageView/`（Interaction、Appearance）、`Alert/FKAlertAppearanceConfiguration`、`ListKit/FKListAppearanceConfiguration`、`Carousel/`（Layout、Indicator）、`Widgets/`（Avatar interaction/group、PresenceIndicator）、`FlowVisualization/FKFlowAccessibilityConfiguration`、`SheetPresentationController/FKSheetAnimationConfiguration` |
| FKUIKit P13 用例 | `TextField/`（Decoration、ClearButton、PasswordToggle）、`ImageView/FKImageViewLoadingConfiguration`、`Carousel/`（Motion、Accessibility、Configuration）、`FlowVisualization/FKFlowAppearanceConfiguration`、`Widgets/`（Avatar accessibility、MarqueeLabel interaction/accessibility）、`SearchBar/`（TextStyle、PlaceholderStyle）、`EmptyState/FKEmptyStateTypography` |
| FKUIKit P14 用例 | `Button/FKButtonFeedbackConfiguration`、`Callout/FKCalloutConfiguration`、`FlowVisualization/FKFlowProgressResolver`、`QRCode/FKQRCodeScannerConfiguration`、`PhotoPicker/FKPhotoCompressionOptions`、`SearchViewController/FKSearchViewControllerConfiguration`、`TabBar/FKTabBarLayoutConfiguration` |
| 组件缺陷台账 | [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md) — 测试发现的**组件 bug**（非用例错误） |
| FKCoreKit Support | `Fixtures.swift`、`NetworkTestFixtures.swift`、`BusinessKitTestFixtures.swift`、`LoggerTestFixtures.swift`、`FKNetworkTestCase.swift` |
| FKUIKit Support | `FKUIKitTestCase.swift`、`ListKitTestFixtures.swift` |
| PR 模板 | `.github/pull_request_template.md` — regression + `@MainActor` + new API checklist |
| **合计** | **842** passed（FKCoreKit 389 + FKUIKit 456；3 skipped：Keychain entitlement） |
| 覆盖清单 | [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) — 模块级 API 缺口与执行优先级 |
| CI | `.github/workflows/ci.yml` 在 iOS Simulator 上执行 `xcodebuild test`，并启用 `SWIFT_STRICT_CONCURRENCY=complete` |
| 人工验收 | `FKKitExamples` 覆盖各组件 public API 演示（**不能替代**自动化测试） |

**差距：** 各组件已有 smoke 测试；**深度缺口**见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md)（行为/集成、Player、Refresh 状态机等）。

---

## 3. 测试策略总览

### 3.1 核心原则

1. **分层投入** — FKCoreKit 以单元测试为主；FKUIKit 测可抽离的逻辑，UI 像素靠 Examples。
2. **测行为，不测实现** — 断言公开契约与可观察结果，避免绑定私有方法名或内部字段。
3. **Bug 必带回归** — 修 bug 的 PR 应优先附带 failing test → fix → pass。
4. **快且稳定** — 禁止真实网络、硬编码 `sleep`、依赖动画时长；用 Mock / stub。
5. **与 Examples 互补** — Examples = 演示 + 人工看 UI；Tests = 回归 + 边界 + CI 门禁。

### 3.2 测试类型

| 类型 | 工具 | 适用场景 | FKKit 优先级 |
|------|------|----------|--------------|
| **单元测试** | XCTest | 纯函数、配置、状态机、编解码、diff 算法 | **P0** |
| **Smoke 测试** | XCTest | 轻量断言 public API 未崩溃、基本契约成立 | **P0**（已有模式） |
| **集成测试** | XCTest + Mock | Network 全链路、Storage 读写、Pluggable 装配 | **P1** |
| **Snapshot 测试** | 可选（后期） | 稳定 UI 组件快照对比 | **P3** |
| **UI 测试** | XCUITest | 端到端点击流 | **不做**（成本高、易 flaky，留给宿主 App） |

### 3.3 什么必须测 / 什么可以少测

**必须测（高 ROI）：**

- 被多个模块复用的 `Extension/`、`Utils/`
- 有明确输入输出的 Core 逻辑（Network、Storage、Security、QRCode、I18n、Async）
- 历史上出过 bug 或频繁改动的区域
- 公开配置 struct 的 `Equatable` 行为、边界值（overflow、empty、nil）

**选择性测：**

- FKUIKit 中与 UI 无关的部分：ListKit diff/snapshot 变更、layout 计算、pagination index
- 协议 + Mock 已就绪的模块（见 §8）

**可以少测或不测：**

- 纯样式薄封装（如 `Divider`、简单 `BlurView`）
- 强依赖系统 UI 且难以稳定自动化（`PhotoPicker`、`WebView`、真实 Biometric）— 用 Mock + Examples
- 仅转发 Apple API、几乎无 FKKit 逻辑的 glue code

**结论：不是每个组件都要写测试文件；按 §9 优先级矩阵执行。**

---

## 4. 目录与文件组织

### 4.1 顶层结构（目标态）

```
Tests/
├── FKCoreKitTests/
│   ├── Extension/
│   │   ├── StringExtensionTests.swift
│   │   ├── ArrayExtensionTests.swift
│   │   └── ...
│   ├── Network/
│   │   └── FKNetworkClientTests.swift
│   ├── Storage/
│   ├── Security/
│   ├── Async/
│   ├── I18n/
│   ├── QRCode/
│   ├── BusinessKit/
│   └── Support/                    # 测试专用 helper（不进入 Sources/）
│       ├── Fixtures.swift
│       └── TestResources/          # 如需 JSON 等 fixture
└── FKUIKitTests/                   # 需在 Package.swift 新增 testTarget
    ├── ListKit/
    ├── Button/
    ├── Refresh/
    └── Support/
        └── MainActorTestCase.swift   # UI 相关基类（可选）
```

**规则：**

- 目录 **mirror** `Sources/<Module>/Components/<领域>/`，而非 mirror 每一个 README。
- 一个测试文件对应 **一个被测类型或一个紧密相关的小分组**；文件过大时再拆。
- `Support/` 仅放测试 helper、fixture、fake；**不要**把可复用生产逻辑塞进来（应上移到 FKCoreKit/FKUIKit）。

### 4.2 `Package.swift` 变更约定

当前：

```swift
.testTarget(
  name: "FKCoreKitTests",
  dependencies: ["FKCoreKit"],
  path: "Tests/FKCoreKitTests"
),
```

新增 FKUIKit 测试时追加：

```swift
.testTarget(
  name: "FKUIKitTests",
  dependencies: ["FKUIKit"],
  path: "Tests/FKUIKitTests"
),
```

新增 `Tests/` 下仅文档说明的文件 **不需要** `exclude`；若添加 test 专用资源，使用 test target 的 `resources:` 或在 `Support/` 内用 `Bundle.module`（SPM test target）。

### 4.3 命名规范

| 对象 | 规范 | 示例 |
|------|------|------|
| 测试类 | `final class <TypeUnderTest>Tests: XCTestCase` | `FKNetworkClientTests` |
| 测试文件 | 与类名一致 | `FKNetworkClientTests.swift` |
| 测试方法 | `test<Scenario><ExpectedOutcome>()` | `testTrimmedRemovesLeadingAndTrailingWhitespace` |
| Smoke 套件 | `*SmokeTests` | `FKCoreKitExtensionSmokeTests` |

测试方法名应 **自解释**；失败时从 Xcode 报告即可读懂场景。

---

## 5. 如何编写测试（入门）

### 5.1 三段式结构：Arrange → Act → Assert

```swift
import FKCoreKit
import XCTest

final class StringExtensionTests: XCTestCase {
  func testTrimmedRemovesLeadingAndTrailingWhitespace() {
    // Arrange — 准备输入
    let input = "  hello  "

    // Act — 调用被测 API
    let output = input.fk_trimmed

    // Assert — 断言可观察结果
    XCTAssertEqual(output, "hello")
  }
}
```

### 5.2 常用断言

| 断言 | 用途 |
|------|------|
| `XCTAssertEqual` | 值相等（`Equatable`） |
| `XCTAssertNil` / `XCTAssertNotNil` | Optional |
| `XCTAssertTrue` / `XCTAssertFalse` | 布尔条件 |
| `XCTAssertThrowsError` | 应抛出错误的 API |
| `XCTAssertNoThrow` | 不应崩溃/抛错 |

异步 API 使用 `async` test 方法：

```swift
func testFetchUserReturnsDTO() async throws {
  let client = makeMockClient(stub: userJSON)
  let user = try await client.send(UserRequest())
  XCTAssertEqual(user.name, "Ada")
}
```

### 5.3 每个测试只验证一件事

❌ 一个 test 里断言 20 个不相关 Extension  
✅ 按场景拆分；Smoke 套件可略聚合，但仍保持可读

### 5.4 测试代码语言与注释

- 测试源码：**英文**（与库一致）
- 测试内注释：仅在非 obvious 的 arrange 逻辑处简短英文说明

### 5.5 UI / MainActor 测试

FKUIKit 测试常在主线程：

```swift
import FKUIKit
import XCTest

@MainActor
final class FKButtonConfigurationTests: XCTestCase {
  func testApplyConfigurationUpdatesTitle() {
    let button = FKButton()
    button.apply(configuration: .init(title: "Save"))
    XCTAssertEqual(button.title(for: .normal), "Save")
  }
}
```

在 Swift 6 严格并发下，UI 测试类或方法标注 `@MainActor`，避免 CI 报 data-race 警告。

---

## 6. 运行测试

### 6.1 本地（与 CI 对齐）

```bash
# 列出可用模拟器（名称因 Xcode 版本而异）
xcrun simctl list devices available

# 运行全部 Package 测试
xcodebuild -scheme FKKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/DerivedData-FKKit \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_STRICT_CONCURRENCY=complete \
  test

# 仅运行 FKCoreKitTests
xcodebuild -scheme FKKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/DerivedData-FKKit \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_STRICT_CONCURRENCY=complete \
  -only-testing:FKCoreKitTests \
  test

# 单个测试类
xcodebuild ... -only-testing:FKCoreKitTests/StringExtensionTests test
```

模拟器名称失败时，用 `id=<UDID>` 或 `.github/scripts/pick_iphone_simulator_udid.py` 输出的 UDID。

### 6.2 Xcode

1. 打开 `Package.swift` 或 FKKit 工程  
2. `Product → Test`（⌘U）  
3. Test Navigator 中可单独运行 class / method

### 6.3 覆盖率（可选，本地观察）

```bash
xcodebuild -scheme FKKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/DerivedData-FKKit \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=NO \
  SWIFT_STRICT_CONCURRENCY=complete \
  test
```

在 Xcode Report Navigator → Coverage 查看。**不在 CI 中硬性卡百分比**（见 §7）。

---

## 7. 覆盖率期望

不设「全库 80%」一类 KPI。采用 **分模块、分阶段** 目标：

| 阶段 | FKCoreKit | FKUIKit | 门禁 |
|------|-----------|---------|------|
| **Phase 1** | Extension + Network smoke/核心路径 | 暂不强制 | CI 全绿 |
| **Phase 2** | Storage、Security、Async、I18n 核心 | ListKit / Button 逻辑层试点 | 新 bug fix 带 regression |
| **Phase 3** | 核心域 **行覆盖率 ~60–70%**（参考） | **~30–40%**（参考） | PR review 检查清单 |

关注 **关键路径覆盖率**（happy path + 主要 error path + 历史 bug 区域），而非盲目刷行数。

---

## 8. 已有 Mock 与测试友好 API

编写测试前 **先 grep 库内 Mock**，避免重复造轮子：

| Mock / 机制 | 路径 | 典型用途 |
|-------------|------|----------|
| `FKMockNetworkSession` | `FKCoreKit/.../Network/Tool/Mock/` | Network 全链路、状态码、重试 |
| `Requestable.mockData` + `enableMock` | Network README | 仅测解码/业务 |
| `FKMockAPIClient` | `Pluggable/Mock/` | Pluggable 边界 |
| `FKMockReachability` | `Pluggable/Mock/` | 网络可达性 |
| `FKMockLocalNotificationScheduler` | LocalNotification | 本地通知调度 |
| `FKMockBackgroundTaskScheduler` | BackgroundTask | 后台任务 |
| `FKMockBiometricAuthenticator` | BiometricAuth | 生物识别 |
| `FKMockImageLoader` / `FKMockUserSession` 等 | `Pluggable/Mock/` | 组合场景 |
| `FKI18nDictionaryLocalizer` | I18n | 内存文案 |
| `FKInMemoryFeatureFlags` | Pluggable | Feature flag |
| 可注入 Provider | Extension 日期/正则等 | 替换系统依赖 |

Network 详细说明见 `Sources/FKCoreKit/Components/Network/README.md` § Testing and Mocking。

---

## 9. 组件优先级矩阵

### 9.1 FKCoreKit（建议实施顺序）

| 优先级 | 组件 | 理由 | 建议首批测试点 |
|--------|------|------|----------------|
| **P0** | Extension | 全局复用、纯函数、已有 smoke | String/Array/Optional/Result/UUID/Date |
| **P0** | Network | 核心基础设施、已有 Mock | 请求构建、mock session、错误映射、重试 |
| **P1** | Storage | 数据持久化 | 编解码、过期、UserDefaults/File |
| **P1** | Security | 加解密/签名 | Hash、RSA 已知向量（fixture） |
| **P1** | Async | Debounce/Throttle | 时间用 injectable clock 或 expectation |
| **P1** | I18n | 格式化与 lookup | Dictionary localizer、 plural rules |
| **P2** | QRCode | 生成/解析 | 已知 payload  round-trip |
| **P2** | BusinessKit | 业务工具集 | Version compare、formatter |
| **P2** | FileManager | 路径与 iOS 封装 | 用 temp 目录，测后清理 |
| **P2** | ImageLoader | 缓存与 decode | Mock URLSession / 内存 cache |
| **P3** | Pluggable | 装配与 adapter | Mock 组合 smoke |
| **P3** | Permissions | 系统对话框 | Mock handler，不测真实 TCC |
| **P3** | LocalNotification / BackgroundTask | 系统 API | 已有 Mock scheduler |
| **P3** | BiometricAuth | 系统 API | `FKMockBiometricAuthenticator` |
| **P3** | Logger | 输出副作用 | Mock sink |
| **P4** | Extension（Date） | P0 补全 | 日期边界、ISO8601、字符串解析 |
| **P4** | Pluggable（FeatureFlags / ImageLoader） | 剩余 Mock | 内存 flag、`FKMockImageLoader` |
| **P5** | Storage（File） | 磁盘读写、TTL、`purgeExpired` | Keychain 真机 TCC |
| **P5** | Security（Coder/HMAC） | 编解码、参数签名 | RSA 长向量 |
| **P5** | BusinessKit（Masker） | 手机/邮箱/证件脱敏 | 纯 UI |
| **P5** | Extension（Calendar） | 周界、天数差 | 本地化日历边缘 |
| **P6** | Extension（ValueParsing） | `isNilOrEmpty`、类型转换、`catching` | 无 |
| **P6** | Storage（Keychain） | 读写/TTL/remove（probe 失败则 skip） | 真机 TCC、entitlement 矩阵 |
| **P6** | BusinessKit（Deeplink） | 注册/注销、路径 `*`、query 参数 | 真实 URL 打开 |
| **P7** | Pluggable（TextInput） | 手机/银行卡格式化、长度/邮箱校验 | 真实键盘 UI |
| **P7** | Pluggable（Routing） | `FKRouteContext.from(url:)` 路径与 query | 导航栈 |
| **P7** | BusinessKit（Time/Startup） | 相对时间、启动任务优先级 | 真机日历/DST 边缘 |
| **P8** | Extension（URL） | query 解析/追加/移除、`isHTTPOrHTTPS` | 无 |
| **P8** | LocalNotification / BackgroundTask / BiometricAuth | Manager 配置默认值与字段存储 | 系统权限对话框 |
| **P9** | Extension（Dictionary/Data/Number/TimeInterval） | JSON 编解码、hex、格式化、时间换算 | 无 |
| **P9** | ImageLoader / BusinessKit | 并发/TTL 钳制、BusinessKit 默认配置 | 真实网络加载 |
| **P9** | Pluggable（DeeplinkParser） | URL → `FKRouteContext` 委托一致性 | 导航栈 |
| **P10** | Extension（Encodable/Sequence/FloatingPoint/Error） | JSON round-trip、group/sum、clamp/lerp、NSError 桥接 | 无 |
| **P10** | I18n / FileManager / Logger / Network | 配置默认值与字段存储 | 真机 TCC、真实 TLS |
| **P11** | Extension（CoreGraphics/Set/IndexPath/String） | 像素取整、集合不可变、掩码/hash | 无 |
| **P11** | Pluggable / BackgroundTask / LocalNotification | HTTP method、RemoteConfig 错误、任务注册、userInfo key | 系统 API |
| **P12** | Extension（BinaryInteger/CGPoint/Character/NSRange/Comparable/Decimal/ProcessInfo/DeviceInfo） | 距离/掩码/范围钳制、设备元数据 | 无 |
| **P12** | Pluggable（RemoteConfig/Analytics） | JSON 配置、analytics event 字段 | 真实 HTTP fetch |
| **P13** | Extension（Locale/TimeZone/Bundle/StringValidation/UIEdgeInsets/UserDefaults） | 区域/时区/Bundle 查询、校验 regex、insets 运算、UserDefaults 便捷 API | 无 |
| **P13** | Pluggable（BuildTimeAppEnvironment） | Info.plist 环境解析 | 真实 bundle 资源 |
| **P13** | LocalNotification（PresentationOptions） | 展示选项组合 | 系统通知权限 |
| **P14** | Extension（DispatchQueue/FileManager/NSAttributedString/NotificationCenter） | 主线程投递、目录 URL、属性串、通知 post | 无 |
| **P14** | Network / BackgroundTask / Permissions / Pluggable / QRCode / FileManager | Retry 钳制、processing 请求、权限模型、session 错误、生成选项、ZIP 选项 | 真实 BGTask |

### 9.2 FKUIKit（建议实施顺序）

| 优先级 | 组件 | 测什么 | 少测什么 |
|--------|------|--------|----------|
| **P1** | ListKit | Snapshot/diff、mutation、height cache | 完整 UITableView 滚动动画 |
| **P1** | Refresh | Token/state 逻辑 | 下拉手势视觉 |
| **P2** | Button | Configuration apply、state、hit target 数值 | 渐变绘制像素 |
| **P2** | PagingController | Index 计算、nested scroll 策略 | 页面转场动画 |
| **P2** | SearchViewController / SearchBar | Query debounce、结果状态机 | 键盘外观 |
| **P2** | EmptyState / Toast / Alert | Present/dismiss 状态、配置 | 阴影/圆角 snapshot |
| **P3** | Player Core | 播放状态机（若有纯逻辑层） | AVPlayer 真实解码 |
| **P3** | 其余 Widgets | Configuration、`Equatable` | 大部分视觉 |
| **P4** | Alert / SearchViewController | 配置与状态枚举 | Present 动画 |
| **P4** | TextField | Validator / Formatter 管道 | 键盘/光标 |
| **P4** | ProgressBar / Skeleton / Divider | 配置钳制、样式映射 | 绘制像素 |
| **P4** | Widgets（Tag / CopyChip / StatusPill / IconView） | 尺寸 preset、semantic | 布局动画 |
| **P4** | RatingControl | Interaction 配置钳制 | 手势评分 UX |
| **P5** | ActionSheet / Carousel / Callout | 选择配置、presets | Present 动画 |
| **P5** | FlowVisualization | `FKFlowProgressResolver` | 步骤指示器绘制 |
| **P5** | ImageView / PhotoPicker | 失败文案、选择策略 | 真实相册 |
| **P5** | BlurView / CornerShadow / ExpandableText / QRCode | 配置与枚举 | 像素/扫描 UI |
| **P5** | Avatar（Widgets） | 尺寸 preset | 头像绘制 |
| **P6** | SheetPresentationController | Sheet/Center 配置钳制、presets | Present 动画、手势 |
| **P6** | TabBar | Presets、badge/accessory `resolved` | 滚动/指示器绘制 |
| **P6** | WebView | `FKWebViewDefaults` presets | WKWebView 渲染 |
| **P6** | Marquee / ExpandableText | 动画/布局配置、默认 collapse 规则 | 滚动动画像素 |
| **P6** | ActionSheet（Presentation） | 展示配置钳制、centered/popover preset | Modal 转场 |
| **P7** | Refresh（Configuration） | 阈值/时序钳制、默认 layout | 下拉手势 |
| **P7** | FlowVisualization（StepIndicator） | Layout/Interaction 钳制 | 节点绘制 |
| **P7** | ProgressBar / Rating / Alert / Badge | Appearance/Interaction 配置 | 像素 |
| **P7** | Carousel（AutoScroll） | 默认 interval、pause 标志 | 定时滚动 |
| **P7** | TabBar（SelectionSnapshot） | 选择快照字段 | 动画/reducer |
| **P8** | PagingController | Configuration 钳制、NavigationBarTabOptions | 页面转场 |
| **P8** | SearchViewController | Loading/Presentation 配置、Defaults preset | 键盘/列表 UI |
| **P8** | FlowVisualization（Timeline） | Layout 钳制、默认 rail/timestamp | 节点绘制 |
| **P8** | ProgressBar | Layout/Motion 钳制 | 绘制像素 |
| **P8** | TextField | Layout/ValidationPolicy 钳制 | 键盘/光标 |
| **P9** | RatingControl | Motion/Layout 钳制 | 手势评分 UX |
| **P9** | FlowVisualization（Motion） | 动画时长钳制、默认 timing | 节点绘制 |
| **P9** | Button（Loading） | Spinner scale 钳制 | 像素 |
| **P9** | ListKit（Layout） | 估算行高钳制 | 滚动动画 |
| **P9** | TextField（Motion） | 过渡时长钳制 | 键盘/光标 |
| **P9** | Carousel（Paging） | 分页阈值与 scroll 标志 | 定时滚动 |
| **P9** | SearchViewController（Behavior） | Cancel/remote 行为默认值 | 键盘/列表 UI |
| **P9** | ActionSheet（Haptics） | 默认关闭、impact style | Modal 转场 |
| **P9** | PagingController（EmptyState） | 空页占位文案 | 页面转场 |
| **P10** | ListKit（Animation/Refresh/Loading） | 行动画映射、preload 钳制、skeleton 策略 | 滚动动画 |
| **P10** | SearchViewController（Empty） | 空态 scenario 与 override | 键盘/列表 UI |
| **P10** | RatingControl / ProgressBar（Accessibility） | VoiceOver 配置默认值 | 像素 |
| **P10** | Carousel（Interaction） | nested scroll 策略 | 定时滚动 |
| **P10** | Alert（Motion/Accessibility） | Reduce Motion、announce 默认值 | Present 动画 |
| **P10** | Player / PhotoPicker / Chip | 网络重试配置、presentation style、chip group 布局 | AVPlayer 解码 |
| **P11** | ListKit（Search/Empty/Error/Windowing） | 搜索/空态/错误/窗口化配置 | 滚动动画 |
| **P11** | ImageView / TextField / Widgets / EmptyState | Accessibility、validation shake、Avatar 布局 | 像素 |
| **P11** | SearchBar / Alert / FlowVisualization | Icon 配置、presentation、Timeline/StepIndicator 组合配置 | Present 动画 |
| **P12** | TextField / ImageView / Alert / ListKit | Accessibility、appearance、counter/inline message | 像素/键盘 |
| **P12** | Carousel / Widgets / Flow / Sheet | Layout/indicator、Avatar/Presence、flow a11y、sheet animation 钳制 | 转场动画 |
| **P13** | TextField / ImageView / Carousel | Decoration/clear/password、loading 配置、motion/a11y/configuration | 像素/键盘 |
| **P13** | FlowVisualization / Widgets / SearchBar / EmptyState | Appearance 映射、Avatar/Marquee a11y+interaction、text/placeholder 样式、typography | 绘制像素 |
| **P14** | Button / Callout / Flow / QRCode / PhotoPicker / Search / TabBar | Feedback 配置、callout preset、progress resolver、scanner/compression、search VC 根配置、layout | Present 动画 |

---

## 10. 分阶段落地计划

### Phase 1 — 基础与规范（当前分支）

- [x] 创建 `feature/testing` 分支
- [x] 本文档 `docs/TESTING_GUIDE.md`
- [x] 扩充 `FKCoreKitTests/Extension/`（从 smoke 拆分为按类型分组）
- [x] `FKCoreKitTests/Network/` 首批用例（`FKMockNetworkSession`）
- [x] CI 保持全绿；单次 CI < ~10 分钟为宜

### Phase 2 — FKCoreKit 核心覆盖

- [x] Storage、Security、Async、I18n 测试目录与首批用例
- [x] 建立 `Tests/FKCoreKitTests/Support/Fixtures.swift`
- [x] 修 bug PR 模板：必须说明是否添加 regression test（`.github/pull_request_template.md`）

### Phase 3 — FKUIKit 试点

- [x] `Package.swift` 增加 `FKUIKitTests`
- [x] ListKit + Button 逻辑层测试
- [x] `@MainActor` 测试规范写入 team review checklist（§12.1、PR 模板）

### Phase 4 — 持续维护

- [x] 新 public API：评估是否需单元测试（P0/P1 默认需要）→ §18 决策门
- [x] Snapshot 工具评估（结论：暂不引入）→ [`TESTING_SNAPSHOT_EVALUATION.md`](TESTING_SNAPSHOT_EVALUATION.md)
- [x] 覆盖率趋势本地观察，不设 CI fail 阈值 → `scripts/run-tests-with-coverage.sh`
- [x] 测试运行脚本与 `Tests/README.md` 入口
- [x] Bug report Issue 模板（regression test 提示）
- [x] 根 `README.md` Contributing 指向测试文档

### P2 组件覆盖（2026-06-16）

- [x] FKCoreKit：`QRCode`、`BusinessKit`、`FileManager`、`ImageLoader`
- [x] FKUIKit：`Refresh`、`EmptyState`、`PagingController`、`SearchBar`（配置层）；Button 已在 Phase 3

### P3 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Pluggable`（Mock API / Logger / Session / Reachability）、`Permissions`（模型与 `isGranted`）、`LocalNotification`、`BackgroundTask`、`BiometricAuth`、`Logger`
- [x] FKUIKit：`Player Core`（`FKMediaPlaybackState` 纯逻辑）、`Toast`、`Chip`、`Badge`（`FKBadgeFormatter`）

### P4 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/Date`、`FKInMemoryFeatureFlags`、`FKMockImageLoader`
- [x] FKUIKit：`Alert`、`SearchViewController`、`TextField`（validator/formatter）、`ProgressBar`、`Skeleton`、`Divider`、`RatingControl`、`Widgets`（Tag / CopyChip / StatusPill / IconView）

### P5 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/Calendar`、`Storage/FKFileStorage`、`Security/FKSecurityCoder`+`FKSignatureService`、`BusinessKit/FKBusinessMasker`
- [x] FKUIKit：`ActionSheet`、`Carousel`、`Callout`、`FlowVisualization`、`ImageView`、`PhotoPicker`、`BlurView`、`CornerShadow`、`ExpandableText`、`QRCode`（overlay）、`Avatar`（size preset）

### P6 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/FKValueParsing`、`Storage/FKKeychainStorage`（Simulator 无 Keychain entitlement 时整类 skip）、`BusinessKit/FKBusinessDeeplinkRouter`
- [x] FKUIKit：`SheetPresentationController`（配置 + presets）、`TabBar`（presets + badge/accessory）、`WebView`（defaults）、`Marquee`、`ExpandableText`（configuration）、`ActionSheet`（presentation 配置）

### P7 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Pluggable/TextInput`（Length/Phone/Email/BankCard、`FKRouteContext+URL`）、`BusinessKit/FKBusinessTimeFormatter`、`FKBusinessStartupTaskManager`
- [x] FKUIKit：`Refresh/FKRefreshConfiguration`、`FlowVisualization`（StepIndicator layout + Flow interaction）、`ProgressBar` appearance、`RatingControl` appearance、`Alert` configuration、`Badge` configuration、`Carousel` auto-scroll、`TabBar` selection snapshot
- [x] 新增 [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md) — 测试失败时区分用例 vs 组件缺陷

### P8 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/URL`、`LocalNotification/FKLocalNotificationManagerConfiguration`、`BackgroundTask/FKBackgroundTaskManagerConfiguration`、`BiometricAuth/FKBiometricAuthConfiguration`
- [x] FKUIKit：`PagingController`（Configuration + NavigationBarTabOptions）、`SearchViewController`（Loading/Presentation/Defaults）、`FlowVisualization/FKTimelineLayoutConfiguration`、`ProgressBar` layout/motion、`TextField` layout/validation policy
- [x] P8 无组件缺陷 — 唯一失败为 `FKProgressBarLayoutConfigurationTests` 对 `CGFloat?` 的断言写法（已修正用例）

### P9 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/`（Dictionary、Data、NumberFormatting、TimeInterval）、`ImageLoader/FKImageLoaderConfiguration`、`BusinessKit/FKBusinessKitConfiguration`、`Pluggable/FKURLDeeplinkParser`
- [x] FKUIKit：`RatingControl` motion/layout、`FlowVisualization/FKFlowMotionConfiguration`、`Button` loading indicator、`ListKit/FKListLayoutConfiguration`、`TextField` motion、`Carousel` paging、`SearchViewController` behavior、`ActionSheet` haptics、`PagingController` empty state
- [x] P9 无组件缺陷

### P10 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/`（Encodable、Sequence、FloatingPoint、Error）、`I18n/FKI18nConfiguration`、`FileManager/FKFileManagerConfiguration`、`Logger/FKLoggerConfig`、`Network/FKSSLPinningConfiguration`
- [x] FKUIKit：`ListKit` animation/refresh/loading、`SearchViewController` empty、`RatingControl` accessibility、`Carousel` interaction、`ProgressBar` accessibility、`Alert` motion/accessibility、`Player/FKMediaNetworkConfiguration`、`PhotoPicker` presentation、`Chip/FKChipGroupConfiguration`
- [x] P10 无组件缺陷 — 编译/断言问题均为测试写法（enum case 名、`XCTAssertEqual` accuracy 重载）

### P11 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/`（CGFloat/CGRect/CGSize、Set、IndexPath、String processing/hashing）、`Pluggable/FKHTTPMethod`+`FKRemoteConfigError`、`BackgroundTask/FKBackgroundTaskRegistration`、`LocalNotification/FKLocalNotificationUserInfoKey`
- [x] FKUIKit：`ImageView` accessibility、`ListKit` search/empty/error/windowing、`TextField` validation feedback、`Widgets/Avatar` layout+story ring、`EmptyState` background appearance、`SearchBar` icon、`Alert` presentation、`FlowVisualization` timeline+step indicator 组合配置
- [x] P11 无组件缺陷 — 失败均为测试假设（enum case 名、`layout.axis` 等不存在 API、`CGFloat?` 断言重载）

### P12 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/`（BinaryInteger/CGPoint/Character/NSRange/Comparable/Decimal/ProcessInfo、FKDeviceInfo）、`Pluggable/FKJSONRemoteConfigConfiguration`+`FKPluggableAnalyticsEvent`
- [x] FKUIKit：`TextField` accessibility/counter/inline message、`ImageView` interaction/appearance、`Alert` appearance、`ListKit` appearance、`Carousel` layout/indicator、`Widgets` avatar interaction/group/presence、`FlowVisualization/FKFlowAccessibilityConfiguration`、`SheetPresentationController/FKSheetAnimationConfiguration`
- [x] P12 无组件缺陷

### P13 组件覆盖（2026-06-16）

- [x] FKCoreKit：`Extension/`（Locale、TimeZone、Bundle、StringValidation、UIEdgeInsets、UserDefaults）、`Pluggable/FKBuildTimeAppEnvironment`、`LocalNotification/FKLocalNotificationPresentationOptions`
- [x] FKUIKit：`TextField` decoration/clear/password、`ImageView` loading、`Carousel` motion/accessibility/configuration、`FlowVisualization/FKFlowAppearanceConfiguration`、`Widgets` avatar accessibility + MarqueeLabel interaction/accessibility、`SearchBar` text/placeholder style、`EmptyState/FKEmptyStateTypography`
- [x] **T-001 已修复** — `FKRegexMatching.Pattern.url` 路径字符类中 `[` 已转义；`String.fk_isValidURLPattern` 正向用例已恢复

### P14 组件覆盖（2026-06-17）

- [x] FKCoreKit：`Extension/`（DispatchQueue、FileManager、NSAttributedString、NotificationCenter）、`Network/FKNetworkRetryPolicy`、`BackgroundTask/FKBackgroundProcessingRequest`、`Permissions/FKPermissionModels`、`Pluggable/FKPluggableSessionError`、`QRCode/FKQRCodeGenerationOptions`、`FileManager/FKZipOptions`
- [x] FKUIKit：`Button` feedback、`Callout` presets、`FlowVisualization/FKFlowProgressResolver`、`QRCode` scanner、`PhotoPicker` compression、`SearchViewController` root config、`TabBar` layout
- [x] P14 无组件缺陷 — 失败均为测试写法（enum case 名、Swift 6 并发捕获）

---

## 11. PR 与协作规范

与根目录 `README.md` § Contributing 一致：

1. **目标分支：** `develop`（自 `feature/testing` 或 `feature/<module>-tests` 提 PR）
2. **Commit type：** `test(Extension): add String trimming cases` — scope 用模块名
3. **PR 描述须包含：**
   - 新增/变更的测试范围
   - 本地 `xcodebuild test` 命令与结果（**BUILD SUCCEEDED** / 全部 test passed）
   - 若仅文档：说明无 Swift 变更
4. **不改 unrelated 代码** — 测试 PR 避免夹带功能 refactor
5. **不提交** DerivedData、`.swiftpm` 个人缓存

---

## 12. Swift 6 与并发注意事项

| 话题 | 要求 |
|------|------|
| 语言模式 | Package 已启用 Swift 6；CI 使用 `SWIFT_STRICT_CONCURRENCY=complete` |
| MainActor | UIKit 测试类/方法使用 `@MainActor` |
| Sendable | 测试 fixture 优先 `Sendable` struct；避免跨线程共享 mutable state |
| 异步 | 优先 `async` test；必要时 `XCTestExpectation` + `fulfillment` |
| 全局单例 | 测 `FKNetworkConfiguration.shared` 等时，在 `tearDown` 恢复状态，避免用例间污染 |

### 12.1 FKUIKit `@MainActor` Review Checklist

新增或修改 `Tests/FKUIKitTests/` 时，PR review 与自测须确认：

- [ ] 涉及 `UIView` / `UIViewController` / `@MainActor` 类型（如 `FKListHeightCache`、`FKButton`）的测试类标注 `@MainActor`，或继承 `FKUIKitTestCase`
- [ ] 纯逻辑测试（`FKListSnapshot`、`FKListDefaults`、`FKButtonContentConfiguration`）可保持普通 `XCTestCase`，不强制 MainActor
- [ ] 闭包内不 mutate 非 Sendable 捕获变量；计数/收集使用 `LockedCounter` / `LockedStringCollector`（见 FKCoreKit Support）或 MainActor 隔离状态
- [ ] 避免 `XCTestExpectation` + `DispatchQueue.main.async` 组合触发 “sending non-Sendable self” 编译错误；优先 `async` test + `Task.sleep`，或同步断言
- [ ] UI 测试不测像素/快照（Phase 3 非目标）；只断言可观察行为（title、isEnabled、hit test、configuration 值）
- [ ] 本地在 `SWIFT_STRICT_CONCURRENCY=complete` 下 `xcodebuild test` 通过

---

## 13. 反模式（禁止）

- 依赖 **真实网络** 或 **生产 API**
- 测试中使用 **`sleep(1)`** 等待动画/防抖（应 inject timer 或用 expectation）
- 断言 **私有** API 或快照 **完整 class 布局**（重构即全碎）
- 把 **FKKitExamples** 当作唯一验证手段
- 为刷覆盖率写 **无断言** 或 **只测 getter** 的用例
- 在 `Sources/` 下为测试加 `#if DEBUG` 污染（除非已有先例且必要）
- 测试代码使用中文标识符或中文断言消息（与库规范不一致）
- 测试失败时**未分析**就改断言迁就错误行为 — 组件 bug 记入 [`TESTING_COMPONENT_ISSUES.md`](TESTING_COMPONENT_ISSUES.md)

---

## 14. 与 FKKitExamples 的分工

| 维度 | 自动化测试 (`Tests/`) | 示例 App (`Examples/`) |
|------|------------------------|-------------------------|
| 目的 | 回归、CI、边界条件 | 演示 API、人工 UX 验收 |
| 触发 | PR / CI 自动 | 手动运行 App |
| 覆盖 | 逻辑、契约、bug 复现 | 每个 public 能力至少一个 scenario |
| 维护 | 改行为必须更新 test | 改 public API 必须更新 Example |

新增组件时：**Examples 全覆盖**（项目强制）+ **按 §9 优先级决定是否加 test**。

---

## 15. 新增测试 Checklist（每次提交前）

- [ ] 测试命名与目录符合 §4
- [ ] 无 flaky 依赖（网络、时间、动画）
- [ ] 使用已有 Mock（§8）而非 duplicate helper
- [ ] `tearDown` 清理临时文件 / 单例状态
- [ ] 本地 `xcodebuild test` 通过（`SWIFT_STRICT_CONCURRENCY=complete`）
- [ ] 未新增 `Tests/` 以外的无关文件
- [ ] 若改 public 行为：更新组件英文 README + CHANGELOG（按发布流程）

---

## 18. 持续维护：新 API 与 Bug 测试决策门

Phase 4 起，每次改 `Sources/` 时在 PR 中过一遍本表（与 PR 模板 **New public API** / **Bug fix** 联动）。

### 18.1 新 public API

| 条件 | 是否加/更新 `Tests/` | 说明 |
|------|----------------------|------|
| FKCoreKit **P0/P1** 新类型或行为（Network、Storage、Security、Extension、Async、I18n） | **必须** | 至少 happy path + 主要 error path |
| FKUIKit **P1** 可测逻辑（ListKit 模型/diff、Refresh token、Button 状态机） | **必须** | `@MainActor` 见 §12.1 |
| FKUIKit 纯视觉 / 布局微调 | **可选** | Examples 必须更新；PR 说明为何无 test |
| P2/P3 新组件首版 | **推荐** | 至少 1 个 smoke 或核心路径 |
| P4 及后续配置型组件 | **推荐** | 配置/default/validator 等可测逻辑 |
| 仅 `internal` / 文档 / 注释 | **否** | 无 Swift 行为变更 |

**无法写自动化测试时**，PR 描述须写明原因（系统 API、纯像素、flaky 等）并加强 Examples 或手动 test plan。

### 18.2 Bug 修复

| 类型 | 要求 |
|------|------|
| 可稳定复现的逻辑 bug | **必须** 附带 regression test（先 fail 再 pass） |
| UI 像素 / 动画 | Examples 或录屏 + 说明；test 可选 |
| 单例/时序 flaky | 先修 flaky 根因，再补 test |

### 18.3 覆盖率（仅本地趋势）

```bash
bash scripts/run-tests-with-coverage.sh
```

- **CI 不**启用 `-enableCodeCoverage`，**不**设 merge 覆盖率门槛。
- 发版前或大规模 refactor 后可选跑一遍，关注 FKCoreKit / FKUIKit **target 行覆盖率变化**，而非总行数 KPI。
- DerivedData 默认 `/tmp/DerivedData-FKKit`；可 `DERIVED_DATA_PATH=… SIMULATOR_NAME="iPhone 17" bash scripts/run-tests.sh` 覆盖。

### 18.4 日常命令

| 命令 | 用途 |
|------|------|
| `bash scripts/run-tests.sh` | 与 CI 一致的测试 |
| `bash scripts/run-tests-with-coverage.sh` | 测试 + 覆盖率摘要 |
| `Tests/README.md` | 英文目录速查 |

---

## 19. 参考链接

| 资源 | 路径 |
|------|------|
| 测试目录说明 | `Tests/README.md` |
| CI 工作流 | `.github/workflows/ci.yml` |
| 本地测试脚本 | `scripts/run-tests.sh` |
| 覆盖率脚本 | `scripts/run-tests-with-coverage.sh` |
| Snapshot 评估 | `docs/TESTING_SNAPSHOT_EVALUATION.md` |
| Package 定义 | `Package.swift` |
| Network 测试说明 | `Sources/FKCoreKit/Components/Network/README.md` |
| Agent 编译验证 | `.cursor/skills/FKKit/SKILL.md` § Verify |
| 组件路线图 | `docs/COMPONENT_ROADMAP.md` |
| Bug 报告模板 | `.github/ISSUE_TEMPLATE/bug_report.yml` |

---

## 20. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-06-16 | 初版：策略、目录、入门、优先级、分阶段计划 |
| 2026-06-16 | Phase 1 落地：Extension 拆分、Network 首批用例、Support 目录 |
| 2026-06-16 | Phase 2 落地：Storage/Security/Async/I18n 用例、Fixtures、PR 模板 |
| 2026-06-16 | Phase 3 落地：`FKUIKitTests`、ListKit/Button 试点、`@MainActor` checklist |
| 2026-06-16 | Phase 4 落地：维护决策门、Snapshot 评估、覆盖率脚本、Issue 模板 |
| 2026-06-16 | P2 组件测试：QRCode、BusinessKit、FileManager、ImageLoader、Refresh、EmptyState、Paging、SearchBar |
| 2026-06-16 | P3 组件测试：Pluggable、Permissions 模型、LocalNotification/BackgroundTask/BiometricAuth Mock、Logger、Player/Toast/Chip/Badge |
| 2026-06-16 | P4 组件测试：Date Extension、FeatureFlags/MockImageLoader、Alert/Search/TextField/ProgressBar/Skeleton/Divider/Rating/Widgets |
| 2026-06-16 | P5 组件测试：Calendar/FileStorage/Security/BusinessMasker、ActionSheet/Carousel/Callout/Flow/ImageView/PhotoPicker/Blur/CornerShadow/ExpandableText/QRCode/Avatar |
| 2026-06-16 | P6 组件测试：ValueParsing/Keychain/DeeplinkRouter、Sheet/TabBar/WebView/Marquee/ExpandableText/ActionSheet presentation |
| 2026-06-16 | P7 组件测试：Pluggable TextInput/RouteContext、BusinessTime/StartupTask、Refresh/Flow/Progress/Rating/Alert/Badge/Carousel/TabBar snapshot；新增 TESTING_COMPONENT_ISSUES.md |
| 2026-06-16 | P8 组件测试：URL Extension、LocalNotification/BackgroundTask/BiometricAuth 配置、Paging/Search/Flow Timeline/ProgressBar Layout+Motion/TextField Layout+Validation；合计 369 用例 |
| 2026-06-16 | P9 组件测试：Dictionary/Data/Number/TimeInterval Extension、ImageLoader/BusinessKit 配置、DeeplinkParser、Rating/Flow/Button/List/TextField/Carousel/Search/ActionSheet/Paging 配置；合计 409 用例 |
| 2026-06-16 | P10 组件测试：Encodable/Sequence/FloatingPoint/Error Extension、I18n/FileManager/Logger/SSL 配置、List/Search/Rating/Carousel/Progress/Alert/Player/PhotoPicker/Chip 配置；合计 454 用例 |
| 2026-06-16 | P11 组件测试：CoreGraphics/Set/IndexPath/String Extension、HTTP/RemoteConfig/BackgroundTask/Notification key、List search/empty/error/windowing、Avatar/Alert/Flow 配置；合计 503 用例 |
| 2026-06-16 | P12 组件测试：BinaryInteger/CGPoint/Character/NSRange/Comparable/Decimal/ProcessInfo/DeviceInfo、RemoteConfig/Analytics、TextField/ImageView/Alert/List/Carousel/Widgets/Flow/Sheet 配置；合计 553 用例 |
| 2026-06-16 | P13 组件测试：Locale/TimeZone/Bundle/StringValidation/UIEdgeInsets/UserDefaults、BuildTimeAppEnvironment、LocalNotification presentation options、TextField/ImageView/Carousel/Flow/Widgets/SearchBar/EmptyState 配置；合计 602 用例；发现 T-001（URL 正则无效） |
| 2026-06-17 | 修复 T-001（`Pattern.url` 转义 `[`）；P14 组件测试：DispatchQueue/FileManager/NSAttributedString/NotificationCenter、Retry/Background/Permissions/Session/QRCode/ZIP、Button/Callout/Flow/QR/PhotoPicker/Search/TabBar；合计 631 用例 |
| 2026-06-17 | **Batch-7 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7.6）：Theme color/resolver/metrics、Flow state applier + Timeline layout、Background session coordinator、Throttler zero-interval；**无新增组件缺陷**（2 项失败均为用例错误）；合计 **842 passed**（FKCoreKit 389 + FKUIKit 456；3 skipped） |
| 2026-06-17 | **Batch-6 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7.5）：SSL Pinning validator、Debouncer 边界、StartupTask 串行/delay、Toast queue actor、EmptyState layout metrics、StepIndicator layout engine；修复 **T-005**（Toast `.dropNew` 丢弃首条）；合计 **821 passed**（FKCoreKit 385 + FKUIKit 439；3 skipped） |
| 2026-06-17 | **Batch-5 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7.4）：Mock LocalNotification/BackgroundTask/BiometricAuth、TabBar reducer、Carousel loop adapter、ImageView retry、PhotoPicker selection policy；**无新增组件缺陷**（3 项失败均为用例问题，已修测试）；合计 **796 passed**（FKCoreKit 372 + FKUIKit 424；3 skipped） |
| 2026-06-17 | **Batch-4 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7.3）：ImageLoader `onEvent`、Refresh footer re-arm、TextField UI pipeline、Callout show/dismiss、Button gradient/content；**无新增组件缺陷**（2 项失败均为用例问题，已修测试）；合计 **773 passed**（FKCoreKit 361 + FKUIKit 412；3 skipped） |
| 2026-06-17 | **Batch-3 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7.2）：ImageLoader cache/cancel、Permissions prePrompt、ListKit diffable/presentation state、Alert coordinator、Paging controller、Sheet presets；修复 **T-003**（ImageLoader cancel）、**T-004**（prePrompt scene/presenter）；合计 **760 passed**（FKCoreKit 359 + FKUIKit 401；3 skipped） |
| 2026-06-17 | **Batch-2 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7.1）：Network interceptors/cache/configuration、Permissions batch+token、Player router/subtitle/QoE/resume、Alert resolver、Paging state machine、TextField composite validator、Refresh coordinator、Callout layout；**无新增组件缺陷**（2 项失败均为用例问题，已修测试）；合计 **736 passed**（FKCoreKit 346 + FKUIKit 390；3 skipped） |
| 2026-06-17 | **Batch-1 深度补测**（见 [`TESTING_COVERAGE_CHECKLIST.md`](TESTING_COVERAGE_CHECKLIST.md) §7）：Network dedup/retry/multipart、ImageLoader 行为、Player 纯逻辑、Refresh 状态机、ListKit mutation、Sheet sizing、TextField validator 扩展；修复 T-002（`FKMediaFormatProbe` MIME HLS）；合计 **691** 用例（FKCoreKit 335 + FKUIKit 356；3 skipped） |
