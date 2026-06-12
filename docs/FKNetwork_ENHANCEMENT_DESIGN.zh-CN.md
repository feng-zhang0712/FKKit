# FKNetwork — 模块增强设计需求文档

FKKit **`FKNetwork`** 的**增量增强**实现指导文档：在现有 URLSession 栈之上，交付 **SSL 证书固定（Pinning）**、**Multipart 上传辅助**、**生产级重试策略预设** 与 **Mock URLSession 模板**，不改变已有公开 API 的默认行为。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §现有模块增强 — FKNetwork  
**模块 README 路线图：** [Network/README.md](../Sources/FKCoreKit/Components/Network/README.md#roadmap)  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 现状基线](#3-现状基线)
- [4. 增强项总览](#4-增强项总览)
- [5. SSL Pinning](#5-ssl-pinning)
- [6. Multipart 上传辅助](#6-multipart-上传辅助)
- [7. 重试策略预设](#7-重试策略预设)
- [8. Mock URLSession 模板](#8-mock-urlsession-模板)
- [9. 模块边界与复用](#9-模块边界与复用)
- [10. 公开 API 草案](#10-公开-api-草案)
- [11. 错误模型扩展](#11-错误模型扩展)
- [12. 配置与集成](#12-配置与集成)
- [13. 安全注意事项](#13-安全注意事项)
- [14. 建议源码目录结构](#14-建议源码目录结构)
- [15. FKKitExamples 场景](#15-fkkitexamples-场景)
- [16. 待决问题](#16-待决问题)
- [17. 修订历史](#17-修订历史)

---

## 1. 概述

`FKNetwork`（`Sources/FKCoreKit/Components/Network/`）已是生产级网络栈：协议导向、`FKNetworkClient`、拦截器、缓存、Token 401 重试、去重、上传下载等。

README **Roadmap** 已列出四项增强，本设计文档将其规范化为可验收需求：

| 增强项 | 用户价值 |
|--------|----------|
| **SSL Pinning** | 金融/企业 App 防中间人；现有 `shouldPinSSLHost` 过弱 |
| **Multipart 辅助** | 图片/文件上传 Boundary 样板代码重复 |
| **Retry 预设** | 幂等 GET 退避重试无统一策略 |
| **Mock 模板** | 集成测试与 Examples 无标准 Mock 路径 |

**原则：** 全部为 **opt-in**；未配置时行为与当前发版 **完全一致**（semver minor）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **Public Key / Certificate Pinning** — 可配置 pin 集，失败映射到现有 `NetworkError` SSL 类错误。
2. **Multipart builder** — 生成分段 body、`Content-Type` boundary，与现有 upload API 衔接。
3. **RetryPolicy** — 声明式策略（次数、退避、可重试错误、仅幂等方法）。
4. **Mock 模板** — 文档 + 可拷贝 Examples 代码（可选入库 `Network/Examples/`）。
5. **零第三方** — 仅 Security / Foundation / Network。
6. **Swift 6** — 新类型 `Sendable`；Pin 配置不可变。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| HTTP/3 / QUIC 专用栈 | 跟随 URLSession |
| GraphQL 客户端 | 不在范围 |
| 替换现有 `FKNetworkClient` | 仅扩展 |
| 强制全局 Pinning | 必须显式配置 |
| WebSocket | 不在范围 |
| 入库 CI 测试 Target | Mock 模板以 Examples 为主 |

### 2.3 成功标准

- [ ] Pinning 集成示例：pin 失败 → 请求失败且错误可区分。
- [ ] Multipart 上传示例：单文件 + 多字段表单成功。
- [ ] Retry 预设：GET 503 指数退避 3 次后失败。
- [ ] 未配置增强项时现有 FKCoreKitTests / 编译通过。
- [ ] README Roadmap 四项标记为已交付并链到 Examples。

---

## 3. 现状基线

### 3.1 模块布局

```text
Sources/FKCoreKit/Components/Network/
├── Core/           NetworkClient, Protocols, Interceptors, URLSession+NetworkSession
├── Config/         NetworkConfiguration
├── Model/          HTTPDefinitions, NetworkError, NetworkEndpoint
└── Tool/           Cache, Logger, Deduplicator, Reachability, Service
```

### 3.2 现有 SSL 行为

`FKNetworkClient.urlSession(_:didReceive:completionHandler:)`：

- 仅处理 `NSURLAuthenticationMethodServerTrust`；
- `config.shouldPinSSLHost?(host) == false` 时 **默认系统校验**；
- 否则 `URLCredential(trust: trust)` — **信任服务器链，非真正 Pinning**。

### 3.3 现有上传

- Client 支持 upload task 与 progress；
- **无**标准 multipart body 构建器；业务方手拼 boundary。

### 3.4 现有重试

- **401 Token 刷新** 透明重试 1 次（内置）；
- **无**通用 HTTP 5xx/超时重试策略。

---

## 4. 增强项总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ FKNetworkClient（现有）                                         │
└────────────┬────────────────────────────────────────────────────┘
             │
   ┌─────────┼─────────┬─────────────────┐
   ▼         ▼         ▼                 ▼
FKSSLPinning  FKMultipart  FKRetryPolicy  FKMockURLSession
Validator     BodyBuilder  Interceptor    Template
```

| 组件 | 类型 | 接入点 |
|------|------|--------|
| `FKSSLPinningValidator` | 工具 + 配置 | `NetworkConfiguration` / delegate |
| `FKMultipartFormData` | 模型 + builder | Upload `URLRequest` body |
| `FKNetworkRetryPolicy` | 策略 + 拦截器 | Request 拦截链或 Client 包装 |
| `FKMockNetworkSession` | 示例模板 | 测试 / Examples |

---

## 5. SSL Pinning

### 5.1 需求

支持两种 pin 模式（可并存）：

| 模式 | 说明 |
|------|------|
| **Certificate Pinning** | 对比 DER 证书或 SPKI 哈希 |
| **Public Key Pinning** | 对比 `SecKey` 公钥哈希（推荐，证书轮换友好） |

### 5.2 FKSSLPinningConfiguration

```swift
public struct FKSSLPinningConfiguration: Sendable, Equatable {
  public var pinnedHosts: Set<String>
  public var certificateHashes: [String: [FKCertificatePin]]  // host → pins
  public var publicKeyHashes: [String: [FKPublicKeyPin]]
  public var enforceForSubdomains: Bool
  public var allowUserTrustEvaluationFallback: Bool  // 默认 false
}
```

**Pin 表示：**

```swift
public struct FKPublicKeyPin: Sendable, Equatable {
  public var algorithm: FKPinHashAlgorithm  // sha256
  public var base64Hash: String
}
```

### 5.3 验证流程

1. Challenge 进入 `FKNetworkClient`；
2. 若 host ∈ `pinnedHosts`，调用 `FKSSLPinningValidator.validate(trust:host:config:)`；
3. 成功 → `.useCredential`；失败 → `.cancelAuthenticationChallenge` + `NetworkError.sslPinningFailed`；
4. 未配置 host → 现有默认行为。

### 5.4 证书提取

- 使用 `SecTrustCopyCertificateChain` / `SecCertificateCopyData`；
- 公钥哈希算法：**SHA-256**（文档提供 openssl 生成命令，不写死在代码注释外的仓库脚本）。

### 5.5 Examples 交付

- `Examples/.../FKCoreKit/Network/Scenarios/FKNetworkSSLPinningExample`；
- 使用 **本地 mock server** 或 **bundled 自签证书**（仅 Examples 资源）；
- **禁止** 将生产 pin 写入源码。

---

## 6. Multipart 上传辅助

### 6.1 FKMultipartFormData

```swift
public struct FKMultipartFormData: Sendable {
  public mutating func append(
    _ data: Data,
    name: String,
    fileName: String? = nil,
    mimeType: String? = nil
  )
  public mutating func append(
    _ value: String,
    name: String
  )
  public func encode() -> (body: Data, contentType: String)
}
```

### 6.2 行为要求

- 自动生成 **UUID boundary**；
- CRLF 换行符合 RFC 7578；
- 文件名 URL 编码 / 引号处理；
- 大文件：**内存警告** — 文档建议 >10MB 使用 stream upload（v1 可整包 Data；stream 为 v1.1）。

### 6.3 与现有 Upload 集成

```swift
let form = FKMultipartFormData()
form.append("description", name: "desc")
form.append(imageData, name: "file", fileName: "photo.jpg", mimeType: "image/jpeg")
let (body, contentType) = form.encode()
var request = URLRequest(url: uploadURL)
request.httpMethod = "POST"
request.setValue(contentType, forHTTPHeaderField: "Content-Type")
request.httpBody = body
// 或 FKNetworkClient.upload(...)
```

### 6.4 MIME 类型

- 复用 **`FKFileManager`** / Extension 已有 MIME 映射（`FKFileUtilities` mime 表）；
- **禁止** 在 Network 模块复制完整 mime 字典 — 引用或薄封装。

---

## 7. 重试策略预设

### 7.1 FKNetworkRetryPolicy

```swift
public struct FKNetworkRetryPolicy: Sendable, Equatable {
  public var maxRetryCount: Int
  public var backoff: FKRetryBackoff
  public var retryableHTTPStatusCodes: Set<Int>
  public var retryableNetworkErrors: Set<FKRetryableNetworkErrorCategory>
  public var idempotentMethodsOnly: Bool  // 默认 true
}
```

**预设：**

```swift
extension FKNetworkRetryPolicy {
  public static let none: FKNetworkRetryPolicy
  public static let conservativeGET: FKNetworkRetryPolicy  // 3 次，指数退避，仅 GET/HEAD
  public static let aggressiveIdempotent: FKNetworkRetryPolicy
}
```

### 7.2 FKRetryBackoff

```swift
public enum FKRetryBackoff: Sendable, Equatable {
  case constant(TimeInterval)
  case exponential(base: TimeInterval, multiplier: Double, jitter: Double)
}
```

### 7.3 接入方式

**方案 A（推荐）：** `FKRequestIntercepting` 实现 `FKNetworkRetryInterceptor`，在 response 错误路径调度重试；

**方案 B：** `FKNetworkClient` 配置 `retryPolicy` 字段，内建执行。

**约束：**

- POST/PUT 默认 **不重试** 除非 `Requestable` 标记 `isIdempotent == true`；
- 与 **401 Token 刷新重试** 独立计数 — 先 Token 刷新，再 HTTP retry（文档顺序）；
- 与 **deduplication** 协调 — 重试不释放 dedup slot 直至终态（对齐现有 401 行为）。

### 7.4 可重试错误

| 类别 | 包含 |
|------|------|
| 超时 | `URLError.timedOut` |
| 连接丢失 | `networkConnectionLost`, `notConnectedToInternet` |
| 5xx | 502, 503, 504（可配置） |

---

## 8. Mock URLSession 模板

### 8.1 目标

降低集成测试与 Examples 搭建成本；**不强制**新增 Test Target。

### 8.2 FKMockNetworkSession（Examples / 文档）

```swift
public final class FKMockNetworkSession: NetworkSession {
  public var stubbedResponses: [URL: (Data, HTTPURLResponse)]
  public var delay: TimeInterval
  // 实现 dataTask / uploadTask，返回 stub
}
```

### 8.3 交付物

| 文件 | 位置 |
|------|------|
| `FKMockNetworkSession.swift` | `Network/Examples/` 或 `Network/Tool/Mock/`（`#if DEBUG` 或始终 public 文档注明仅测试） |
| Examples VC | `FKNetworkMockExampleViewController` |
| README 章节 | 「Testing & Mocking」 |

**Stub JSON：** 放 Examples bundle，不放 Tests/（除非用户明确要求测试）。

---

## 9. 模块边界与复用

### 9.1 FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 哈希 | **`String.fk_sha256`** / Security 模块 | 重复 Digest |
| MD5 签名 | 现有 **`MD5RequestSigner`** | 新签名器 |
| 错误 | 扩展 **`NetworkError`** | 平行错误 enum |
| 日志 | **`NetworkLogger`** | 裸 print |
| MIME | **FileManager/Extension** 映射 | 完整 duplicate mime 表 |
| 并发 | structured concurrency | 无取消的重试 loop |

### 9.2 与 Pluggable 关系

- `FKAPIClientProviding` 实现可包装增强后 Client；
- Pinning 配置由 App 组合根注入，非 Pluggable 新协议（v1）。

---

## 10. 公开 API 草案

```swift
// NetworkConfiguration 扩展
public extension NetworkConfiguration {
  public var sslPinning: FKSSLPinningConfiguration?
  public var retryPolicy: FKNetworkRetryPolicy
}

// Multipart
let form = FKMultipartFormData()
let encoded = form.encode()

// Pinning 工具（宿主也可 standalone 用于 NSURLSessionDelegate）
public enum FKSSLPinningValidator {
  public static func validate(
    serverTrust: SecTrust,
    host: String,
    configuration: FKSSLPinningConfiguration
  ) -> Result<Void, NetworkError>
}
```

---

## 11. 错误模型扩展

在 **`NetworkError`** 中新增（semver minor）：

```swift
case sslPinningFailed(host: String)
case sslPinningNotConfigured(host: String)  // 可选，调试
```

现有：

```swift
/// SSL trust validation failed.
```

文档区分 **系统信任失败** vs **pin mismatch**。

---

## 12. 配置与集成

### 12.1 App 启动示例

```swift
var config = NetworkConfiguration.production
config.sslPinning = FKSSLPinningConfiguration(
  pinnedHosts: ["api.example.com"],
  publicKeyHashes: ["api.example.com": [.init(algorithm: .sha256, base64Hash: "...")]]
)
config.retryPolicy = .conservativeGET
FKNetworkClient.shared.updateConfiguration(config)
```

### 12.2 证书轮换

README 章节：**双 pin 并存**、过期前发版、失败降级策略（仅文档，不自动 bypass pin）。

---

## 13. 安全注意事项

- Pin 哈希 **不要** 提交真实生产值到开源仓库；
- `allowUserTrustEvaluationFallback = true` 仅 debug；
- Multipart 日志 **禁止**  dump 二进制 body；
- 重试放大攻击面 — 限制 `maxRetryCount` ≤ 5（预设遵守）。

---

## 14. 建议源码目录结构

```text
Sources/FKCoreKit/Components/Network/
├── Tool/
│   ├── FKSSLPinningValidator.swift      # 新增
│   ├── FKSSLPinningConfiguration.swift
│   ├── FKMultipartFormData.swift        # 新增
│   ├── FKNetworkRetryPolicy.swift       # 新增
│   ├── FKNetworkRetryInterceptor.swift  # 新增
│   └── Mock/
│       └── FKMockNetworkSession.swift   # 新增
├── Examples/                             # 可选，exclude README
│   └── FKNetworkEnhancementExamples.swift
└── README.md                             # 更新 Roadmap
```

---

## 15. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/Network/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `SSLPinningSuccess` | 正确 pin 通过 |
| 2 | `SSLPinningFailure` | 错误 pin 失败 |
| 3 | `MultipartSingleFile` | 图片上传 |
| 4 | `MultipartMixedFields` | 文本 + 文件 |
| 5 | `RetryGET503` | 退避重试 |
| 6 | `RetryPOSTNoRetry` | POST 不重试 |
| 7 | `MockSessionStub` | Mock 模板 |
| 8 | `PinningWith401Refresh` | Pin + Token 刷新共存 |

---

## 16. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Retry 拦截器 vs Client 内建？ | 拦截器 |
| Q2 | Mock Session 是否 public？ | public，文档标注 testing |
| Q3 | Pin 失败是否回调 Pluggable？ | v1 否 |
| Q4 | Multipart streaming v1？ | v1.1 |

---

## 17. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版，源自 Network README Roadmap 与 COMPONENT_ROADMAP |

---

## 相关文档

- [Network README](../Sources/FKCoreKit/Components/Network/README.md)
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKSecurity README](../Sources/FKCoreKit/Components/Security/README.md)
