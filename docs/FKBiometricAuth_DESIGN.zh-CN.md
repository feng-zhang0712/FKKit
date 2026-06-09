# FKBiometricAuth — 设计需求文档

FKKit **`FKBiometricAuth`** 的实现指导文档：面向生产的 **`LocalAuthentication`** 封装，用于设备持有者验证（Face ID、Touch ID、Optic ID）及设备密码回退，提供类型化错误与 Keychain / Storage 配对说明。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.7  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 能力探测](#6-能力探测)
- [7. 认证生命周期与状态](#7-认证生命周期与状态)
- [8. 生物识别策略](#8-生物识别策略)
- [9. 公开 API](#9-公开-api)
- [10. 错误分类与 LAError 映射](#10-错误分类与-laerror-映射)
- [11. 配置模型](#11-配置模型)
- [12. LAContext 管理](#12-lacontext-管理)
- [13. Keychain 与 Storage 集成](#13-keychain-与-storage-集成)
- [14. Token 解锁模式](#14-token-解锁模式)
- [15. 安全与隐私](#15-安全与隐私)
- [16. 并发与线程](#16-并发与线程)
- [17. Pluggable 与依赖注入](#17-pluggable-与依赖注入)
- [18. 本地化（FKI18n）](#18-本地化fki18n)
- [19. 设备、模拟器与系统版本](#19-设备模拟器与系统版本)
- [20. UIKit / SwiftUI 宿主指引](#20-uikit--swiftui-宿主指引)
- [21. 建议源码目录结构](#21-建议源码目录结构)
- [22. FKKitExamples 场景](#22-fkkitexamples-场景)
- [24. 待决问题](#24-待决问题)
- [25. 修订历史](#25-修订历史)

---

## 1. 概述

金融、钱包与账号类 App 反复集成 **`LAContext`**，用于：

- 解锁敏感页面（资产、转账确认）
- 访问 Keychain 中的 Token
- 从后台返回后的再认证

**`FKSecurity`** 覆盖密码学（Hash、AES、RSA、HMAC），**`FKKeychainKeyStore`** / **`FKKeychainStorage`** 负责持久化机密 — 但 FKKit **尚无**统一的 LocalAuthentication 层。各团队对能力检测、策略选择、错误映射、Keychain 配对的实现不一致。

**`FKBiometricAuth`**（`Sources/FKCoreKit/Components/BiometricAuth/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKBiometricCapability`** | Sendable 快照：硬件类型、是否录入、策略是否可评估 |
| **`FKBiometricPolicy`** | 映射 `LAPolicy`，明确密码回退语义 |
| **`FKBiometricAuthenticating`** | `Sendable` 协议，便于 Pluggable 注入 |
| **`FKBiometricAuth`** | 默认 `LAContext` 编排实现 |
| **`FKBiometricError`** | 稳定、面向集成方的错误分类 |

**关键约束：** 本模块仅做**认证**，不存储、处理或传输生物特征模板；生物特征由 Apple Secure Enclave 管理。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **静默能力探测** — `canEvaluatePolicy` / 能力快照**不触发**系统 UI。
2. **`async` 认证** — `authenticate(reason:)` 挂起直至成功、类型化失败或取消。
3. **显式策略模型** — 仅生物识别 / 生物识别或密码 / 仅设备密码；宿主 App 不直接拼 `LAPolicy` 魔法字符串。
4. **完整 `LAError` 映射** — 取消、回退、锁定、未录入、不可用、未设密码、App 取消、无效 Context 等。
5. **Keychain 配对文档** — 说明认证成功后如何读取 `FKKeychainStorage` / `FKKeychainKeyStore`（v1 不自动代读 Keychain）。
6. **Swift 6** — 配置与错误 `Sendable`；本模块无 UI，不要求 `@MainActor`。
7. **FKI18n** — 兜底 reason 与错误描述；每次调用仍可由集成方传入自定义 reason。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 自定义生物识别 UI（仿 Face ID 动画） | 仅系统 `LAContext` UI |
| 活体检测 / 人脸比对算法 | 仅 Apple 提供 |
| 存储生物特征模板或分数 | **禁止** |
| v1 扩展 `FKKeychainStorage` 的 `kSecAccessControl` 生物识别标志 | 文档配方；可选 v1.1 API |
| watchOS 配套认证 | 仅 iOS 15+ |
| macOS / Catalyst LocalAuthentication | 仅 iOS |
| 越狱检测（超出既有 `FKSecurity` 工具） | 不在范围 |
| 自动监听 `UIApplication` 生命周期再认证 | 宿主职责；提供文档与钩子说明 |

### 2.3 成功标准

- [ ] 能力 API 在 Face ID / Touch ID 设备上返回正确 `biometryType`，且不出现 UI。
- [ ] 成功 `authenticate` 以 `async` 正常返回。
- [ ] 用户取消映射为 `FKBiometricError.userCancelled`（非泛化失败）。
- [ ] 锁定映射为 `FKBiometricError.biometryLockout`，README 含恢复指引。
- [ ] Examples：能力检测、成功、取消、锁定（必要时 Mock）。
- [ ] README Keychain 章节引用 `FKKeychainStorage` 与 `FKKeychainKeyStore`。
- [ ] 正式环境 API 不记录含用户 PII 的 `reason` 全文。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 领域 | 状态 |
|------|------|
| `Sources/` 内 `LocalAuthentication` | **无** |
| `FKSecurity` | Hash、AES、RSA、签名、脱敏、安全随机 |
| `FKKeychainKeyStore` | 原始密钥字节；默认可访问性 `AfterFirstUnlockThisDeviceOnly` |
| `FKKeychainStorage` | Codable 机密 + TTL；默认同上 |
| `FKI18n` | 错误与兜底文案共享本地化 |

### 3.2 重复集成痛点

| 痛点 | 影响 |
|------|------|
| 探测时误调 `evaluatePolicy` | 启动时意外弹出 Face ID |
| 支付确认选错 `LAPolicy` | 该要密码时出现生物识别，或相反 |
| 直接向 UI 抛 `LAError` | 文案不一致；锁定未处理 |
| 失败后复用 `LAContext` | `invalidContext` 崩溃或静默失败 |
| Keychain `kSecAccessControl` 与 LA 不匹配 | 双重弹窗或读不到机密 |
| 模拟器「未录入」 | 无 Mock Provider 时开发体验差 |

### 3.3 与路线图风险 R4 的关系

锁定持续时间与回退行为因 iOS 版本与设备而异。**必须**显式映射 `LAError.biometryLockout`，并文档说明仅能通过设备密码或等待系统策略解除锁定 — FKBiometricAuth **不能**绕过 Apple 策略。

---

## 4. 架构总览

```text
┌──────────────────────────────────────────────────────────────────┐
│ 宿主 App（UIKit / SwiftUI）                                      │
│  - 展示敏感界面                                                  │
│  - 调用 FKBiometricAuth.authenticate(reason:)                    │
│  - 成功后读取 FKKeychainStorage / 继续业务                       │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│ FKBiometricAuth（FKCoreKit）                                     │
│  FKBiometricCapabilityProbe  → canEvaluatePolicy（无 UI）        │
│  FKBiometricContextFactory   → 每次认证新建 LAContext            │
│  FKBiometricErrorMapper      → LAError → FKBiometricError        │
└────────────────────────────┬─────────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│ LocalAuthentication.framework                                    │
│  LAContext.evaluatePolicy / evaluateAccessControl                 │
│  系统 UI（Face ID / Touch ID / 设备密码）                        │
└──────────────────────────────────────────────────────────────────┘
```

**典型解锁数据流：**

1. 宿主 `capability()` → 未录入则引导前往设置。
2. 宿主 `authenticate(reason: "确认转账")`。
3. 系统 UI → 用户成功。
4. 宿主从 `FKKeychainStorage` 读取 Token（v1 应用层门控）或执行业务逻辑。

Keychain 绑定机密（`SecAccessControl`）的协调见 §13。

---

## 5. 模块边界

| 关注点 | FKBiometricAuth | FKSecurity | FKStorage |
|--------|-----------------|------------|-----------|
| 设备持有者认证 | **是** | 否 | 否 |
| 密码学运算 | 否 | **是** | 否 |
| 机密持久化 | 否 | Keychain 存密钥字节 | **是** |
| 系统认证 UI | 委托给 LA | 否 | 否 |
| 错误类型 | `FKBiometricError` | `FKSecurityError` | `FKStorageError` |

仅在 BiometricAuth 源文件中 `import LocalAuthentication`；**不**依赖 UIKit。

### 5.1 FKCoreKit 复用要求（强制）

本模块**位于 FKCoreKit**；实现时必须复用同模块已有能力，**禁止**重复造轮子：

| 能力 | 必须使用（FKCoreKit） | 禁止 |
|------|----------------------|------|
| 安全/密钥 | **`FKSecurity`**、`FKStorage`/Keychain | 平行 Keychain 封装 |
| 错误映射 | 统一 **`FKBiometricError`** | 泄漏原始 LAError 到公开 API |
| 并发 | **`FKAsync`** / structured concurrency | 无隔离的 GCD |
| 本地化 | **`FKI18n`**（`localizedReason` 由宿主传入，键表在 Core） | — |
| Pluggable | **`FKBiometricAuthenticating`** | 第二套 DI 协议 |

**不得** import FKUIKit；UI 提示由 LocalAuthentication 系统 UI 或宿主负责。

---

## 6. 能力探测

### 6.1 要求

能力探测**不得**调用会展示 UI 的 API。允许：

- `LAContext.canEvaluatePolicy(_:error:)`
- 读取 `LAContext.biometryType`（在策略检查之后或新建 Context 上）
- 可选：由 `LAError.biometryNotEnrolled` 推断未录入

**禁止用于探测：**

- `evaluatePolicy(_:localizedReason:reply:)`
- `evaluateAccessControl(_:operation:localizedReason:reply:)`

### 6.2 能力模型

```swift
/// 设备生物识别就绪状态快照。获取时不展示认证 UI。
public struct FKBiometricCapability: Sendable, Equatable {
  /// 当请求的策略可评估时为 true（后续仍可能弹出 UI）。
  public var canAuthenticate: Bool
  /// 本机生物识别硬件类型。
  public var biometryType: FKBiometryType
  /// 是否已录入 Face ID / Touch ID。
  public var isBiometryEnrolled: Bool
  /// 是否已设置设备密码（生物识别之前提）。
  public var isPasscodeSet: Bool
  /// 本次快照使用的策略。
  public var evaluatedPolicy: FKBiometricPolicy
  /// canAuthenticate == false 时的探测错误（已映射，可选）。
  public var probeError: FKBiometricError?
}

public enum FKBiometryType: Sendable, Equatable {
  case none
  case touchID
  case faceID
  case opticID   // 支持设备上映射 LABiometryType.opticID
}
```

### 6.3 探测 API

```swift
public protocol FKBiometricAuthenticating: Sendable {
  /// 对 policy 做能力探测，不展示认证 UI。
  func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability

  /// 使用 configuration.defaultPolicy 探测。
  func capability() -> FKBiometricCapability
}
```

### 6.4 录入语义

| `isBiometryEnrolled` | 推断方式 |
|----------------------|----------|
| `true` | `canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` 成功 |
| `false` | 失败且为 `.biometryNotEnrolled` 或生物识别不可用 |

**模拟器**常报告未录入 — Examples 使用 Mock Provider。

### 6.5 缓存

**不得**在系统重大事件后长期缓存能力结果。仅允许单次调用链内的极短缓存（如 1s）。宿主应在从设置返回或 `didBecomeActive` 后重新探测。

---

## 7. 认证生命周期与状态

### 7.1 结果类型

规范 API 采用 **`async throws`**（与 FKCoreKit 其他 async API 一致）：

```swift
/// 失败时抛出 FKBiometricError；成功时正常返回。
func authenticate(
  reason: String,
  policy: FKBiometricPolicy,
  options: FKBiometricAuthOptions
) async throws
```

### 7.2 状态（内部）

```text
idle → authenticating → success
                     ↘ failure（类型化错误）
```

每个 `FKBiometricAuth` 实例同一时刻仅允许**一次**进行中的 `authenticate`；第二次调用在**串行队列**上等待（默认行为，须在 README 说明）。

### 7.3 Reason 字符串

- **必填**非空 `reason`，显示在系统 UI（与 Info.plist `NSFaceIDUsageDescription` 无关，后者单独配置）。
- 去除首尾空白；空 reason → `FKBiometricError.invalidReason`。
- 实践上建议 ≤128 字符，避免系统 UI 截断。

### 7.4 取消

```swift
public func cancelAuthentication()
```

对活动 `LAContext` 调用 `invalidate()` → 进行中的 `authenticate` 以 `FKBiometricError.appCancelled` 结束。

---

## 8. 生物识别策略

### 8.1 策略枚举

```swift
/// 映射 Apple LAPolicy，并文档化密码回退行为。
public enum FKBiometricPolicy: Sendable, Equatable {
  /// 仅 Face ID / Touch ID；生物识别不可用时不回退密码。
  case biometricsOnly
  /// 生物识别，失败可回退设备密码（最常见「解锁 App」）。
  case biometricsOrPasscode
  /// 仅设备密码（不要求生物识别）。
  case devicePasscode
}
```

### 8.2 LAPolicy 映射（规范）

| `FKBiometricPolicy` | `LAPolicy` |
|---------------------|------------|
| `.biometricsOnly` | `.deviceOwnerAuthenticationWithBiometrics` |
| `.biometricsOrPasscode` | `.deviceOwnerAuthentication` |
| `.devicePasscode` | `.deviceOwnerAuthentication`（配合 Context 标志尽量仅密码路径） |

`.devicePasscode` 在部分系统版本仍可能涉及生物识别路径 — README 说明与 `.biometricsOnly` 的差异。

### 8.3 场景指引

| 场景 | 推荐策略 |
|------|----------|
| App 解锁 / 查看余额 | `.biometricsOrPasscode` |
| 高风险确认（大额转账） | 已录入时用 `.biometricsOnly`；否则拦截 |
| 设备无生物识别 | `.devicePasscode` 或禁用功能 |
| 设置项「需要 Face ID」 | 宿主存偏好；运行时仍用 `.biometricsOrPasscode` |

### 8.4 回退按钮

`.biometricsOnly` 时系统可能不显示「输入密码」。`FKBiometricAuthOptions.allowPasscodeFallback` 仅对支持回退的策略生效。

---

## 9. 公开 API

### 9.1 协议

```swift
public protocol FKBiometricAuthenticating: Sendable {
  func capability(for policy: FKBiometricPolicy) -> FKBiometricCapability
  func capability() -> FKBiometricCapability

  func authenticate(
    reason: String,
    policy: FKBiometricPolicy,
    options: FKBiometricAuthOptions
  ) async throws

  func authenticate(reason: String) async throws

  func cancelAuthentication()
}
```

### 9.2 具体类型

```swift
public final class FKBiometricAuth: FKBiometricAuthenticating, @unchecked Sendable {
  public init(configuration: FKBiometricAuthConfiguration = .init())
  public static let shared: FKBiometricAuth
}
```

内部用串行 `DispatchQueue` 或 actor 保证 `LAContext` 安全；模式对齐 `FKKeychainStorage`。

### 9.3 便捷扩展

```swift
extension FKBiometricAuthenticating {
  /// 先探测再认证；不可用时抛出 probeError。
  public func authenticateIfAvailable(reason: String) async throws
}
```

### 9.4 闭包重载（v1 可选）

```swift
public func authenticate(
  reason: String,
  completion: @escaping @Sendable (Result<Void, FKBiometricError>) -> Void
)
```

内部 `Task` 调度；若与 `async` 并存，文档建议优先 `async`。

---

## 10. 错误分类与 LAError 映射

### 10.1 错误枚举

```swift
public enum FKBiometricError: Error, Sendable, Equatable {
  case biometryNotAvailable
  case biometryNotEnrolled
  case biometryLockout
  case passcodeNotSet
  case authenticationFailed
  case userCancelled
  case userFallback          // 用户选择「输入密码」（若可用）
  case systemCancelled
  case appCancelled
  case invalidContext
  case notInteractive        // App 非活跃 / 无法展示 UI
  case invalidReason
  case authenticationInProgress
  case watchNotAvailable
  case underlying(code: Int, domain: String)
}
```

### 10.2 LAError 映射表（规范）

| `LAError.Code` | `FKBiometricError` |
|----------------|-------------------|
| `.authenticationFailed` | `.authenticationFailed` |
| `.userCancel` | `.userCancelled` |
| `.userFallback` | `.userFallback` |
| `.systemCancel` | `.systemCancelled` |
| `.passcodeNotSet` | `.passcodeNotSet` |
| `.biometryNotAvailable` | `.biometryNotAvailable` |
| `.biometryNotEnrolled` | `.biometryNotEnrolled` |
| `.biometryLockout` | `.biometryLockout` |
| `.appCancel` | `.appCancelled` |
| `.invalidContext` | `.invalidContext` |
| `.notInteractive` | `.notInteractive` |
| `.watchNotAvailable` | `.watchNotAvailable` |
| 其他 | `.underlying(code:domain:)` |

### 10.3 LocalizedError

通过 `FKI18n` 键 `fkcore.biometric.error.*` 实现。**不得**把 LA 原始 `localizedReason` 直接当用户文案。

### 10.4 宿主 UX 指引（README）

| 错误 | 建议宿主行为 |
|------|--------------|
| `.userCancelled` | 静默退出流程，不必弹窗 |
| `.biometryLockout` | 说明等待或使用密码；可链到设置 |
| `.biometryNotEnrolled` | 引导 设置 → Face ID 与密码 |
| `.passcodeNotSet` | 引导设置设备密码 |
| `.notInteractive` | App 活跃后重试 |

---

## 11. 配置模型

```swift
public struct FKBiometricAuthConfiguration: Sendable, Equatable {
  public var defaultPolicy: FKBiometricPolicy
  public var reuseDuration: TimeInterval?  // LAContext 允许复用最近认证的时间窗
  public var localizedFallbackTitle: String?
  public var invalidateContextAfterSuccess: Bool  // 默认 true
  public var invalidateContextAfterFailure: Bool // 默认 true
}

public struct FKBiometricAuthOptions: Sendable, Equatable {
  public var policy: FKBiometricPolicy?  // nil → configuration.defaultPolicy
  public var allowPasscodeFallback: Bool
  public var reuseDuration: TimeInterval?
  public var localizedFallbackTitle: String?
}
```

### 11.1 复用时间窗

`reuseDuration > 0` 时在 evaluate 前写入 `LAContext`，窗口内可能不再弹 UI（行为以 Apple 文档为准）。默认 `nil`（每次都提示）。

### 11.2 回退标题

映射到 `LAContext.localizedFallbackTitle`（「输入密码」类入口）。

---

## 12. LAContext 管理

### 12.1 Context 工厂（内部）

- 每次 `authenticate` **新建** `LAContext`（除非显式配置复用窗口）。
- evaluate 前设置 `localizedReason`、`localizedFallbackTitle`、复用时长。
- 完成后按配置标志 `invalidate`。

### 12.2 为何使用新 Context

`.biometryLockout` 或 `.invalidContext` 后复用旧 Context 会失败。FKBiometricAuth 对宿主隐藏该细节。

### 12.3 Info.plist

| 键 | 何时需要 |
|----|----------|
| `NSFaceIDUsageDescription` | 支持 Face ID / Optic ID 的设备 |

Touch ID 在现代 iOS 上无单独 usage 字符串，README 仍应说明 App Store 审核对认证 UX 的期望。

---

## 13. Keychain 与 Storage 集成

### 13.1 v1 范围

**v1** **不修改** `FKKeychainStorage` / `FKKeychainKeyStore` 实现；集成以**文档模式**为主。

### 13.2 模式 A — 应用层门控（v1 推荐）

1. 用现有 `FKKeychainStorage(service:)` 存储（无生物识别 AccessControl）。
2. 敏感读取前先 `FKBiometricAuth.authenticate`。
3. 成功后 `try storage.value(key:as:)`。

**优点：** 简单、单次弹窗。**缺点：** 读入内存后由宿主负责清零。

### 13.3 模式 B — Keychain AccessControl（文档 / v1.1）

写入时使用 `SecAccessControl`（如 `.biometryCurrentSet`、`.userPresence`）：

```swift
// 示意 — 宿主或未来 FKKeychainStorage API
let access = SecAccessControlCreateWithFlags(
  nil,
  kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
  .biometryCurrentSet,
  nil
)
```

`SecItemCopyMatching` 可能自动弹窗 — 须与 FKBiometricAuth 协调，避免**双重弹窗**（一次认证 + reuse 窗口内读 Keychain，或仅依赖 Keychain 弹窗）。

### 13.4 FKKeychainKeyStore

对原始 AES 密钥字节适用模式 A：认证后再 `key(forKey:)`。

### 13.5 登出

`FKKeychainStorage.removeAll()` + 清除内存缓存；可选 `cancelAuthentication()`。

---

## 14. Token 解锁模式

### 14.1 会话解锁

```text
用户打开 App
  → capability()：未录入 → 引导
  → authenticate(reason:)
  → 成功 → 从 FKKeychainStorage 加载 refresh token
  → FKNetwork 附加 Token
```

### 14.2 后台再认证

宿主监听 `willEnterForeground`：空闲超过 N 分钟再次 `authenticate`。本模块**不**注册生命周期（保持纯净）。

### 14.3 失败退避

反复 `.authenticationFailed` 时宿主应做 UI 退避；FKBiometricAuth 不节流（Apple 可能锁定生物识别）。

---

## 15. 安全与隐私

### 15.1 不存储生物特征

**禁止**持久化 Face ID 模板、分数或 LA 产物。API 边界仅传递成功/失败布尔语义。

### 15.2 日志

**禁止：**

- Keychain 解锁后的机密值
- Release 日志中完整的、含账号标识的 `reason`

**允许：** 错误枚举名、`biometryType`、策略枚举。

### 15.3 越狱

FKBiometricAuth 不承担越狱检测；需要时参阅 `FKSecurity` 反调试工具。

### 15.4 威胁模型（README）

- 结合应用层门控，缓解**他人随手解锁**与**肩窥**。
- **不能**替代服务端鉴权，也不能单独防 Root/越狱。

---

## 16. 并发与线程

- 公开 API 可从任意线程调用；内部串行队列保护 `LAContext`。
- `authenticate` 的 `async` 恢复在协作式线程池，**不保证主线程** — UI 更新由宿主 `@MainActor` 执行。
- 类型不加 `@MainActor` — 符合 FKCoreKit 非 UI 模块约定。

---

## 17. Pluggable 与依赖注入

### 17.1 协议注册

可选 Pluggable 槽位：

```text
Sources/FKCoreKit/Components/Pluggable/Security/FKBiometricAuthenticating.swift
```

宿主注册 `FKBiometricAuth.shared` 或 Mock 实现。

### 17.2 Mock 实现

```swift
public struct FKMockBiometricAuthenticator: FKBiometricAuthenticating {
  public var capabilityResult: FKBiometricCapability
  public var authenticateOutcome: Result<Void, FKBiometricError>
}
```

建议 **公开** 供集成方与 Examples 使用（见待决问题 Q3）。

---

## 18. 本地化（FKI18n）

### 18.1 键（加入 FKCoreKit 包）

| 键 | 用途 |
|----|------|
| `fkcore.biometric.error.user_cancelled` | 错误描述 |
| `fkcore.biometric.error.biometry_lockout` | 锁定说明 |
| `fkcore.biometric.error.biometry_not_enrolled` | 设置引导 |
| `fkcore.biometric.reason.unlock_app` | 默认解锁 reason |
| `fkcore.biometric.reason.confirm_action` | 通用确认 |

### 18.2 Reason 辅助

```swift
public enum FKBiometricReason {
  public static func unlockApp() -> String
  public static func confirmAction() -> String
  public static func custom(_ key: String) -> String
}
```

集成方仍可向 `authenticate(reason:)` 传入任意已本地化 `String`。

---

## 19. 设备、模拟器与系统版本

| 环境 | 能力 | 认证 |
|------|------|------|
| Face ID 真机 | `.faceID` | 系统 UI |
| Touch ID 真机 | `.touchID` | 系统 UI |
| 模拟器 | 常 `.none` / 未录入 | Features → Face ID → Enrolled 或 Mock |
| 未设密码 | `passcodeNotSet` | 探测失败 |

最低 **iOS 15+**；SDK 提供时映射 `LABiometryType.opticID`。

---

## 20. UIKit / SwiftUI 宿主指引

本模块**无** UIView：

- **UIKit：** 在按钮或 `viewDidAppear` 调用；未录入可用 **`FKEmptyState`**（FKUIKit）提示。
- **SwiftUI：** 敏感视图 `.task { try await auth.authenticate(...) }`。
- **防重复：** 认证进行中禁用按钮。

可选未来 **`FKBiometricGate`**（FKUIKit）— **非 v1 目标**。

---

## 21. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

```text
Sources/FKCoreKit/Components/BiometricAuth/
├── README.md
├── Public/
│   ├── FKBiometricAuth.swift
│   ├── FKBiometricCapability.swift
│   ├── FKBiometricPolicy.swift
│   ├── FKBiometricError.swift
│   ├── FKBiometricAuthConfiguration.swift
│   ├── FKBiometricAuthOptions.swift
│   ├── FKBiometryType.swift
│   ├── FKBiometricReason.swift
│   └── FKBiometricAuthenticating.swift
├── Internal/
│   ├── FKBiometricContextFactory.swift
│   ├── FKBiometricCapabilityProbe.swift
│   ├── FKBiometricErrorMapper.swift
│   └── FKLAContext+FKBiometric.swift
└── Extension/
    └── FKBiometricAuthenticating+Convenience.swift
```

---

## 22. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/BiometricAuth/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `CapabilityInspection` | biometryType、录入、密码 — 无 UI |
| 2 | `SuccessfulAuthentication` | `async` 成功路径 |
| 3 | `UserCancel` | `.userCancelled` |
| 4 | `PolicyComparison` | biometricsOnly vs biometricsOrPasscode |
| 5 | `MockLockout` | Mock 锁定 UX 文案 |
| 6 | `KeychainUnlockPattern` | 认证后 `FKKeychainStorage` 读取 |
| 7 | `NotEnrolledHint` | 能力 false → 设置引导 |
| 8 | `CancelInFlight` | `cancelAuthentication()` |
| 9 | `ReuseDuration` | 窗口内二次认证 |
| 10 | `LocalizedReasons` | FKI18n 兜底 reason |

Hub 与 `FKSecurity` 示例并列。

---

## 24. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | `async throws` 还是 `Result`？ | `async throws` |
| Q2 | v1 扩展 `FKKeychainStorage` AccessControl？ | 仅文档；v1.1 API |
| Q3 | 公开 `FKMockBiometricAuthenticator`？ | 公开于 FKCoreKit，供 Examples 与 DI |
| Q4 | 单例 `shared`？ | 是，对齐 `FKSecurity.shared` |
| Q5 | Actor 还是队列 Sendable？ | 串行队列 `@unchecked Sendable` |
| Q6 | FKUIKit `FKBiometricGate`？ | v1 之后 |

---

## 25. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.7 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKSecurity README](../Sources/FKCoreKit/Components/Security/README.md)
- [FKStorage README](../Sources/FKCoreKit/Components/Storage/README.md)
- [FKWebView_DESIGN.zh-CN.md](FKWebView_DESIGN.zh-CN.md)
