# FKNetwork — 模块设计需求文档

FKKit **`FKNetwork`** 的完整实现指导文档：规范 **已交付能力** 的行为边界、**增量增强**（SSL Pinning、Multipart、重试预设、Mock 模板）、**Pluggable 桥接** 与 **可达性统一**，补齐缺口分析中尚未文档化的能力描述。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §现有模块增强 — FKNetwork  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §10.1  
**模块 README：** [Network/README.md](../Sources/FKCoreKit/Components/Network/README.md)  
**增量增强专章：** 本文 §12–§15（原 [FKNetwork_ENHANCEMENT_DESIGN.md](FKNetwork_ENHANCEMENT_DESIGN.md) 已合并入本文）

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 已交付能力详表](#6-已交付能力详表)
- [7. 请求生命周期](#7-请求生命周期)
- [8. 配置与环境](#8-配置与环境)
- [9. 拦截器、签名与加密](#9-拦截器签名与加密)
- [10. 缓存与去重](#10-缓存与去重)
- [11. Token 刷新与凭证](#11-token-刷新与凭证)
- [12. 上传、下载与 Multipart（增强）](#12-上传下载与-multipart增强)
- [13. SSL 与证书固定（增强）](#13-ssl-与证书固定增强)
- [14. 重试策略预设（增强）](#14-重试策略预设增强)
- [15. Mock 与测试模板（增强）](#15-mock-与测试模板增强)
- [16. 可达性与离线策略](#16-可达性与离线策略)
- [17. Pluggable 集成与桥接](#17-pluggable-集成与桥接)
- [18. 错误模型](#18-错误模型)
- [19. 日志与可观测性](#19-日志与可观测性)
- [20. 并发与 Swift 6](#20-并发与-swift-6)
- [21. 安全注意事项](#21-安全注意事项)
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

中大型 iOS App 反复搭建 **URLSession** 网络层：环境切换、鉴权头、缓存、上传下载、Token 刷新、错误统一、调试日志。各团队实现分散，与 DI / 测试边界不一致。

**`FKNetwork`**（`Sources/FKCoreKit/Components/Network/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKNetworkClient`** | 核心调度：`Requestable` → `URLRequest` → `URLSession` |
| **`FKNetworkConfiguration`** | 运行时可变全局配置（环境、拦截器、Token、日志） |
| **`Networkable`** | 闭包 + `async/await` 双 API；上传/下载 |
| **`FKNetworkCache`** | 内存 + 磁盘两级缓存 |
| **`FKRequestDeduplicator`** | 幂等请求飞行中去重 |
| **`FKNetworkReachability`** | `NWPathMonitor` 可达性预检 |
| **`NetworkServiceProvidable`** | 仓储/Service 层便利协议 |

**关键约束：** 纯 Swift、**零第三方运行时依赖**、基于系统 `URLSession` / `Network` framework；Swift 6 `Sendable` 友好。

**成熟度：** 核心路径 **生产可用**；README Roadmap 四项增强与 Pluggable 桥接 **待交付**（见 §12–§17）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标（模块整体）

1. **协议导向** — `Requestable`、`NetworkSession`、`Cacheable`、拦截器链可注入、可 Mock。
2. **双 API 风格** — 闭包回调 + `async/await`（`send` 挂起直至完成）。
3. **多环境** — `development` / `testing` / `production` 映射 `baseURL`、超时、默认头。
4. **横切能力** — 缓存 TTL、去重、401 Token 刷新、MD5 签名、参数加密钩子、Mock 数据路径。
5. **文件传输** — 上传/下载进度、断点下载 `resumeData`。
6. **增量增强（opt-in）** — 真正 SSL Pinning、Multipart builder、HTTP 重试预设、Mock Session 模板。
7. **Pluggable 对齐** — `FKAPIClientProviding` 桥接、Reachability 双协议、`FKCredentialProviding` 与 `TokenStore` 文档化分工。
8. **Swift 6** — 新配置类型 `Sendable`；Client `@unchecked Sendable` + 锁保护可变映射。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| HTTP/3 / QUIC 专用栈 | 跟随 `URLSession` 系统行为 |
| GraphQL 客户端 | 不在范围；可用 `Requestable` 手建 body |
| WebSocket / 长连接 | v2 展望（§22），v1 不交付 |
| 替换 `FKFileManager` 传输 | 大文件后台传输仍走 FileManager |
| 强制全局 SSL Pinning | 必须显式配置 `sslPinning` |
| 第三方网络库适配层 | Alamofire 等由宿主自行包装 |
| 入库 CI 专用 Test Target | Mock 以 Examples + 可 public 的 Mock 类型为主 |

### 2.3 成功标准

**已交付能力（维持）：**

- [ ] 现有 `FKCoreKitTests` / `xcodebuild` 无回归。
- [ ] GET/POST + JSON 编解码 + 环境切换 Examples 可运行。

**增量增强（v1 增强 PR）：**

- [ ] Pinning：pin 失败 → `NetworkError.sslPinningFailed` 可区分。
- [ ] Multipart：单文件 + 多字段表单上传成功。
- [ ] Retry：`conservativeGET` 对 503 指数退避 3 次后失败；POST 默认不重试。
- [ ] Mock：`FKMockNetworkSession` Examples 演示 canned 响应。
- [ ] Pluggable：`FKNetworkClientPluggableAdapter` + Reachability 双符合。
- [ ] README Roadmap 四项标记已交付并链到 Examples。

---

## 3. 背景与问题陈述

### 3.1 与邻模块关系

| 模块 | 分工 |
|------|------|
| **`FKSecurity`** | 哈希、HMAC、AES — 签名与 Pin 哈希算法 |
| **`FKStorage` / Keychain** | Token 持久化 — 通过 `TokenStore` 或 Pluggable `FKCredentialProviding` |
| **`FKFileManager`** | 沙盒大文件、后台传输 — 与 Network 上传分工 |
| **`FKAsync`** | 业务层防抖/节流 — 非 Network 内部调度 |
| **`FKI18n`** | `NetworkError` 本地化文案 |
| **`FKPluggable`** | DI 边界 — Network 提供桥接，不重复定义 HTTP 协议 |
| **`FKImageLoader`** | 图片 HTTP — 可选注入同一 `FKNetworkReachability` |

### 3.2 当前文档缺口（本设计补齐）

| 缺口 | 本文章节 |
|------|----------|
| 请求管道各阶段行为 | §7 |
| 缓存/去重/TTL 语义 | §10 |
| Token 401 与通用 Retry 顺序 | §11、§14 |
| SSL「伪 Pinning」与真 Pinning 差异 | §13 |
| Multipart 缺失 | §12 |
| `NetworkStatusProviding` vs `FKNetworkReachabilityProviding` | §16、§17 |
| `TokenStore` vs `FKCredentialProviding` | §11、§17 |
| Mock 标准路径 | §15 |
| WebSocket 等未覆盖能力边界 | §22 |

---

## 4. 架构总览

### 4.1 分层

```text
┌─────────────────────────────────────────────────────────────────┐
│ 业务层：Repository / ViewModel conforming NetworkServiceProvidable │
└────────────────────────────┬────────────────────────────────────┘
                             │ Requestable 类型
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ FKNetworkClient (Networkable)                                    │
│  buildRequest → interceptors → signer → cache/dedup → URLSession │
└───┬─────────┬──────────┬──────────┬──────────┬────────────────┘
    │         │          │          │          │
    ▼         ▼          ▼          ▼          ▼
 FKNetwork  FKRequest  Token     FKNetwork   FKNetwork
 Cache      Dedup      Refresh   Reachability Logger
```

### 4.2 增强组件接入点（§12–§15）

```text
FKNetworkClient
    ├── FKSSLPinningValidator        ← URLSessionDelegate challenge
    ├── FKMultipartFormData            ← Upload body 构建
    ├── FKNetworkRetryInterceptor      ← 响应错误路径重试
    └── FKMockNetworkSession           ← NetworkSession 测试注入
```

---

## 5. 模块边界

### 5.1 源码布局（当前）

```text
Sources/FKCoreKit/Components/Network/
├── Core/
│   ├── NetworkClient.swift
│   ├── Protocols.swift
│   ├── Interceptors.swift
│   └── URLSession+NetworkSession.swift
├── Config/
│   └── NetworkConfiguration.swift
├── Model/
│   ├── HTTPDefinitions.swift
│   ├── NetworkError.swift
│   └── NetworkEndpoint.swift
└── Tool/
    ├── NetworkCache.swift
    ├── NetworkLogger.swift
    ├── NetworkReachability.swift
    ├── NetworkService.swift
    └── RequestDeduplicator.swift
```

### 5.2 增强后布局（§25）

新增 `Tool/` 下 Pinning、Multipart、Retry、Mock 子目录；可选 `Examples/`（README 纳入 `Package.swift` `exclude:`）。

### 5.3 不在本模块

- UI 层离线提示（`FKEmptyState`、`FKImageView` 失败态）— 消费 Reachability；
- 业务 JSON 信封解析 — `ResponseInterceptor` 或业务 Decodable；
- 证书文件打包到 App — 仅 Examples 自签资源。

---

## 6. 已交付能力详表

| 能力 | 公开类型 | 成熟度 | 说明 |
|------|----------|--------|------|
| 类型化请求 | `Requestable` | ✅ 生产 | path、method、query、body、headers、encoding |
| HTTP 方法 | `HTTPMethod` | ✅ | GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS |
| 参数编码 | `ParameterEncoding` | ✅ | query、json、formURLEncoded |
| 双 API | `Networkable.send` | ✅ | 闭包 + `async throws` |
| 环境配置 | `FKNetworkEnvironment` + `FKEnvironmentConfig` | ✅ | 三环境 baseURL、timeout、defaultHeaders |
| 全局配置 | `FKNetworkConfiguration.shared` | ✅ | 可变拦截器、Token、日志、Mock 开关 |
| 请求拦截 | `RequestInterceptor` | ✅ | 链式 `intercept(_:)` |
| 响应拦截 | `ResponseInterceptor` | ✅ | 解密/信封归一化 |
| 请求签名 | `RequestSigner` | ✅ | 含 MD5 签名实现 |
| 两级缓存 | `NetworkCachePolicy` + `FKNetworkCache` | ✅ | memory / disk / memoryAndDisk + TTL |
| 飞行去重 | `NetworkRequestBehavior.idempotentDeduplicated` | ✅ | 同 key 并发第二请求失败码 -2 |
| Token 401 重试 | `TokenStore` + `TokenRefresher` | ✅ | 透明刷新 1 次后重发 |
| 可达性预检 | `NetworkStatusProviding` | ✅ | `isReachable == false` → `.offline` |
| 上传 | `upload(_:fileURL:progress:)` | ✅ | 基于 `uploadTask(fromFile:)` |
| 下载 | `download(resumeData:)` | ✅ | 临时文件 URL + resumeData |
| 取消 | `Cancellable` | ✅ | 手动 `cancel()` |
| Mock 路径 | `enableMock` + `Requestable.mockData` | ✅ | 跳过网络返回 mock JSON |
| SSL challenge | `shouldPinSSLHost` | ⚠️ 弱 | 信任服务器链，非真 Pinning（§13） |
| 参数加密钩子 | `encryptParameters` | ✅ | body 编码前变换 |
| 服务层便利 | `NetworkServiceProvidable` | ✅ | `request(_:)` 转发 |
| 端点模型 | `NetworkEndpoint` | ✅ | 轻量 URL 构建辅助 |
| 富响应 | `NetworkResponse<T>` | ✅ | 含 statusCode、headers、rawData |
| Multipart 构建 | — | ❌ 待建 | §12 |
| HTTP 重试预设 | — | ❌ 待建 | §14（仅 401 Token 重试） |
| 真 SSL Pinning | — | ❌ 待建 | §13 |
| Mock Session 模板 | — | ❌ 待建 | §15 |
| Pluggable API 桥接 | — | ❌ 待建 | §17 |
| Pluggable Reachability | — | ❌ 待建 | §16 |

---

## 7. 请求生命周期

### 7.1 标准 `send` 管道（顺序固定）

1. **可达性预检** — `networkStatusProvider?.isReachable == false` → `.offline`（无请求发出）。
2. **构建 `URLRequest`** — `baseURL` + path + query + body（经 `encryptParameters` 钩子）+ 默认头。
3. **缓存读** — `cachePolicy` 非 `.none` 且命中 → 直接解码返回（HTTP 200 语义）。
4. **去重占位** — `behavior == .idempotentDeduplicated` 且 key 已占用 → `businessError(-2, deduplicated)`。
5. **Mock 短路** — `enableMock && mockData != nil` → 解码 mock 数据。
6. **请求拦截链** — `requestInterceptors` 顺序执行。
7. **签名** — `signer?.sign`（若配置）。
8. **URLSession 执行** — `dataTask`。
9. **响应拦截链** — `responseInterceptors`。
10. **状态码校验** — 非 2xx → `serverError`；**401** → Token 刷新流程（§11）。
11. **解码** — `JSONDecoder` → `R.Response`；失败 → `decodingFailed`。
12. **缓存写** — 按 `cachePolicy` 写入 memory/disk。
13. **释放去重 key** — 与 401 重试、终态失败/成功对齐。

### 7.2 回调队列

- `callbackOnMainQueue` 默认 `true` — 所有 `send` completion 经 `callbackQueue`（main 或 global）。
- `async` 版本在 Client 内部桥接，不保证 MainActor。

### 7.3 取消

- 返回 `Cancellable`；`cancel()` 取消 URLSession task。
- 取消映射 `NetworkError.requestCancelled`。
- 去重 key 在取消路径必须 `complete`（与现有 401 行为一致）。

---

## 8. 配置与环境

### 8.1 `FKNetworkConfiguration` 字段

| 字段 | 用途 |
|------|------|
| `environment` | 当前 `FKNetworkEnvironment` |
| `environmentMap` | 环境 → `FKEnvironmentConfig` |
| `commonQueryItems` | 全局 query 合并 |
| `requestInterceptors` / `responseInterceptors` | 拦截器数组 |
| `signer` | 可选 `RequestSigner` |
| `tokenStore` / `tokenRefresher` | 401 刷新 |
| `logger` | `NetworkLogger`（默认 `FKDefaultNetworkLogger`） |
| `networkStatusProvider` | 可达性预检 |
| `enableMock` | 全局 Mock 开关 |
| `shouldPinSSLHost` | SSL challenge 过滤（待 §13 增强） |
| `encryptParameters` | Body 参数加密钩子 |
| `callbackOnMainQueue` | 回调队列策略 |
| **`sslPinning`**（增强） | `FKSSLPinningConfiguration?` |
| **`retryPolicy`**（增强） | `FKNetworkRetryPolicy` |

### 8.2 与 `FKAppEnvironmentProviding` 对齐

| Pluggable / BusinessKit | FKNetwork |
|-------------------------|-----------|
| `FKAppEnvironmentProviding.apiBaseURL` | 宿主在启动时写入 `environmentMap[.production].baseURL` |
| 不建议 | Network 模块 **不** 直接依赖 `FKAppEnvironmentProviding` |

**推荐装配：**

```swift
let env = appEnvironmentProvider // FKBuildTimeAppEnvironment
config.environmentMap[.production] = FKEnvironmentConfig(baseURL: env.apiBaseURL)
```

### 8.3 线程安全

- `FKNetworkConfiguration.current` 通过 `NSLock` 读取 `environmentMap`。
- 运行时修改拦截器数组 — 文档建议仅在启动阶段或串行化配置更新。

---

## 9. 拦截器、签名与加密

### 9.1 内置拦截器（`Interceptors.swift`）

| 类型 | 职责 |
|------|------|
| Auth 拦截器 | 从 `TokenStore` 注入 `Authorization` 头 |
| 日志拦截器 | 请求/响应摘要（不含敏感 body） |
| JSON 响应拦截器 | 占位/轻量归一化 |

### 9.2 与 Pluggable 拦截器对应

| Pluggable | Network 原生 | 桥接（§17） |
|-----------|--------------|-------------|
| `FKRequestIntercepting` | `RequestInterceptor` | `FKRequestInterceptingAdapter` |
| `FKResponseIntercepting` | `ResponseInterceptor` | `FKResponseInterceptingAdapter` |
| `FKRequestSigning` | `RequestSigner` | `FKRequestSigningAdapter` |

### 9.3 MD5 签名

- 现有 `MD5RequestSigner`（或等价）— **禁止** 在增强 PR 中重复实现。
- 文档：签名参数顺序、编码与后端对齐。

### 9.4 `encryptParameters` 钩子

- 在 body **编码前** 对 `[String: Any]` 变换；
- 失败 → `NetworkError.encryptionFailed`；
- 与 `FKSecurity` AES 配合由宿主实现，Network 不内置算法。

---

## 10. 缓存与去重

### 10.1 `NetworkCachePolicy`

| 策略 | 行为 |
|------|------|
| `.none` | 不读不写 |
| `.memory(ttl:)` | 仅内存，`FKNetworkCache` |
| `.disk(ttl:)` | 磁盘持久化 |
| `.memoryAndDisk(ttl:)` | 双层写入 |

- TTL 过期后读视为未命中。
- 缓存 key 由 URL + method + 相关参数稳定哈希（见 Client `cacheKey` 实现）。

### 10.2 `FKRequestDeduplicator`

- 仅当 `NetworkRequestBehavior.idempotentDeduplicated` 启用；
- 同一 in-flight key 第二次 `send` 立即失败（非排队等待）；
- **401 重试** 与 **HTTP Retry（§14）** 期间保持 key 占用直至终态。

### 10.3 最佳实践（文档化）

- 列表/详情只读 GET 可设短 TTL memory cache；
- 写操作禁止 cache；
- 支付/下单类 POST **禁止** 去重行为误判 — 使用 `.normal`。

---

## 11. Token 刷新与凭证

### 11.1 401 流程

1. 收到 401；
2. 若 `tokenRefresher` 与 `tokenStore` 已配置 → 调用 `refreshToken(using:)`；
3. 成功 → 更新 `accessToken` → **重发原请求 1 次**；
4. 失败 → `NetworkError.tokenRefreshFailed`。

### 11.2 `TokenStore` vs Pluggable

| 类型 | 模块 | 用途 |
|------|------|------|
| `TokenStore` | Network 原生 | `FKNetworkConfiguration.tokenStore` |
| `FKCredentialProviding` | Pluggable | DI 边界、拦截器跨模块 |

**桥接：** `FKKeychainCredentialStore` 同时符合两者，或 `TokenStorePluggableAdapter` 包装 `FKCredentialProviding`（§17）。

### 11.3 与 HTTP Retry 顺序

文档强制顺序：

1. **401 Token 刷新重试**（内置，1 次）；
2. **HTTP Retry 策略**（§14，可多次）仅在 Token 路径不适用或仍失败后触发；
3. 两者独立计数。

---

## 12. 上传、下载与 Multipart（增强）

### 12.1 已交付：上传/下载

| API | 行为 |
|-----|------|
| `upload` | `URLRequest` + 本地 `fileURL`；`URLSessionTaskDelegate` 进度 |
| `download` | 临时文件路径；支持 `resumeData` 续传 |
| 注意 | 下载 `fileURL` 为临时目录 — 宿主需移动；续传需持久化 `resumeData` |

**限制（文档化）：**

- 当前 upload 路径适合 **已知文件 URL** 或已构建的 `httpBody`；
- **无** RFC 7578 Multipart 自动构建 — 本增强交付 `FKMultipartFormData`。

### 12.2 `FKMultipartFormData`（待交付）

```swift
public struct FKMultipartFormData: Sendable {
  public mutating func append(
    _ data: Data,
    name: String,
    fileName: String? = nil,
    mimeType: String? = nil
  )
  public mutating func append(_ value: String, name: String)
  public func encode() -> (body: Data, contentType: String)
}
```

| 行为要求 | 说明 |
|----------|------|
| Boundary | 自动生成 UUID |
| 换行 | CRLF，符合 RFC 7578 |
| 文件名 | 引号与编码处理 |
| MIME | 复用 **FileManager / Extension** MIME 表，禁止 Network 内复制完整字典 |
| 大文件 | v1 整包 `Data`；>10MB 文档建议 stream upload（v1.1） |

### 12.3 集成示例

```swift
var form = FKMultipartFormData()
form.append("description", name: "desc")
form.append(imageData, name: "file", fileName: "photo.jpg", mimeType: "image/jpeg")
let (body, contentType) = form.encode()
var request = URLRequest(url: uploadURL)
request.httpMethod = "POST"
request.setValue(contentType, forHTTPHeaderField: "Content-Type")
request.httpBody = body
client.upload(request, fileURL: tempFileURL, progress: nil, completion: ...)
```

---

## 13. SSL 与证书固定（增强）

### 13.1 现状（弱 challenge 处理）

`FKNetworkClient` 作为 `URLSessionDelegate`：

- 处理 `NSURLAuthenticationMethodServerTrust`；
- `shouldPinSSLHost?(host) == false` → 系统默认评估；
- 否则 `URLCredential(trust: trust)` — **信任服务器链，非 Pinning**。

README Notes 已提示需扩展 — 本设计规范 **真 Pinning**。

### 13.2 `FKSSLPinningConfiguration`（待交付）

```swift
public struct FKSSLPinningConfiguration: Sendable, Equatable {
  public var pinnedHosts: Set<String>
  public var certificateHashes: [String: [FKCertificatePin]]
  public var publicKeyHashes: [String: [FKPublicKeyPin]]
  public var enforceForSubdomains: Bool
  public var allowUserTrustEvaluationFallback: Bool  // 默认 false
}

public struct FKPublicKeyPin: Sendable, Equatable {
  public var algorithm: FKPinHashAlgorithm  // sha256
  public var base64Hash: String
}
```

### 13.3 验证流程

1. Challenge 进入 delegate；
2. host ∈ `pinnedHosts`（或子域规则）→ `FKSSLPinningValidator.validate(trust:host:config:)`；
3. 成功 → `.useCredential`；
4. 失败 → `.cancelAuthenticationChallenge` + `NetworkError.sslPinningFailed(host:)`；
5. 未配置 host → 保持现有默认行为（向后兼容）。

### 13.4 证书提取

- `SecTrustCopyCertificateChain` / `SecCertificateCopyData`；
- 公钥 Pin：**SHA-256**（README 提供 openssl 生成步骤，不写生产 pin 到仓库）。

### 13.5 证书轮换（仅文档）

- 双 pin 并存窗口；
- 过期前发版；
- **禁止** 生产环境自动 bypass pin。

---

## 14. 重试策略预设（增强）

### 14.1 现状

- 仅 **401 Token 刷新** 透明重试 1 次；
- 无通用 5xx/超时重试。

### 14.2 `FKNetworkRetryPolicy`（待交付）

```swift
public struct FKNetworkRetryPolicy: Sendable, Equatable {
  public var maxRetryCount: Int
  public var backoff: FKRetryBackoff
  public var retryableHTTPStatusCodes: Set<Int>
  public var retryableNetworkErrors: Set<FKRetryableNetworkErrorCategory>
  public var idempotentMethodsOnly: Bool  // 默认 true
}

public enum FKRetryBackoff: Sendable, Equatable {
  case constant(TimeInterval)
  case exponential(base: TimeInterval, multiplier: Double, jitter: Double)
}

extension FKNetworkRetryPolicy {
  public static let none: FKNetworkRetryPolicy
  public static let conservativeGET: FKNetworkRetryPolicy   // 3 次，指数退避，仅 GET/HEAD
  public static let aggressiveIdempotent: FKNetworkRetryPolicy
}
```

### 14.3 接入方式

**推荐：** `FKNetworkRetryInterceptor` 实现 `RequestInterceptor` 或在 Client 响应错误路径包装重试循环。

**约束：**

| 规则 | 说明 |
|------|------|
| 幂等 | POST/PUT 默认不重试；`Requestable` 可扩展 `isIdempotent`（增强 PR 可选） |
| 与 401 顺序 | 先 Token 刷新，再 HTTP Retry（§11.3） |
| 与去重 | 重试期间保持 dedup slot |
| 上限 | `maxRetryCount` ≤ 5（预设遵守） |
| 可重试错误 | 超时、`networkConnectionLost`、502/503/504（可配置） |

### 14.4 可重试错误类别

```swift
public enum FKRetryableNetworkErrorCategory: Sendable, Hashable {
  case timedOut
  case connectionLost
  case notConnectedToInternet
  case httpStatus(Int)
}
```

---

## 15. Mock 与测试模板（增强）

### 15.1 已交付：Request 级 Mock

- `FKNetworkConfiguration.enableMock = true`；
- `Requestable.mockData` 提供 JSON `Data`；
- 跳过 URLSession，直接解码。

**局限：** 无 transport 层 stub、无法模拟延迟/错误序列。

### 15.2 `FKMockNetworkSession`（待交付）

```swift
public final class FKMockNetworkSession: NetworkSession, @unchecked Sendable {
  public var stubbedResponses: [URL: (Data, HTTPURLResponse)]
  public var delay: TimeInterval
  public var errorStub: Error?
  // dataTask / uploadTask / downloadTask 返回 stub
}
```

| 交付物 | 位置 |
|--------|------|
| `FKMockNetworkSession.swift` | `Network/Tool/Mock/` |
| Examples VC | `FKNetworkMockExampleViewController` |
| README | 「Testing & Mocking」章节 |

- **public** 类型，文档标注 **testing / Examples only**；
- Stub JSON 放 Examples bundle，非强制 `Tests/`。

### 15.3 与 `enableMock` 选型

| 场景 | 推荐 |
|------|------|
| 单元 Decodable / 业务解码 | `enableMock` + `mockData` |
| 集成管道（拦截器、状态码、重试） | `FKMockNetworkSession` 注入 Client |
| Pluggable `FKAPIClientProviding` 测试 | `FKMockAPIClient`（Pluggable/Mock，§17） |

---

## 16. 可达性与离线策略

### 16.1 `FKNetworkReachability`

- 基于 `NWPathMonitor`；
- `isReachable` 默认 `true`（避免首次回调前误杀请求）；
- 符合 `NetworkStatusProviding`。

### 16.2 预检 vs 强离线策略

| 层级 | 行为 |
|------|------|
| Client 预检 | 仅 `isReachable == false` 时 fast-fail `.offline` |
| UI 离线态 | `FKImageView`、`FKWebView` 等注入同一 Reachability 显示失败/重试 |
| 弱网 | 不区分 Wi-Fi / 蜂窝 — 仅 `path.status == .satisfied` |

### 16.3 Pluggable 双符合（待交付）

```swift
extension FKNetworkReachability: FKNetworkReachabilityProviding {
  // isReachable 已满足 Pluggable 协议
}
```

**文档：** App 组合根创建 **单例** `FKNetworkReachability`，同时注入：

- `FKNetworkConfiguration.networkStatusProvider`
- `FKImageLoaderConfiguration.useNetworkReachability(...)`
- 可选 `FKWebView` 离线配置

### 16.4 `FKReachabilityObserving`（v2 可选）

- 观察 `isReachable` 变化流 — 非 v1 必需；
- UI 可用 `Notification` 或自建 KVO 包装（文档示例）。

---

## 17. Pluggable 集成与桥接

详见 [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) §10；Network 侧交付：

### 17.1 `FKNetworkClientPluggableAdapter`

**符合：** `FKAPIClientProviding`

```swift
public struct FKNetworkClientPluggableAdapter: FKAPIClientProviding, Sendable {
  public init(client: FKNetworkClient = .shared)
  public func perform(_ request: FKAPIRequest) async throws -> FKAPIResponse
}
```

- `FKAPIRequest` → 内部 `Requestable` 匿名类型或 `NetworkEndpoint`；
- 错误：`NetworkError` 向上抛出，Pluggable 层不二次包装（v1）。

### 17.2 凭证桥接

| 组件 | 符合 | 说明 |
|------|------|------|
| `FKKeychainCredentialStore` | `FKCredentialProviding` + `TokenStore` | Pluggable/Implementations |
| `TokenStorePluggableAdapter` | `TokenStore` | 包装 `FKCredentialProviding` |

### 17.3 拦截器桥接

```swift
public struct FKRequestInterceptingAdapter: RequestInterceptor, Sendable {
  public init(interceptor: any FKRequestIntercepting)
  public func intercept(_ request: URLRequest) throws -> URLRequest
}
```

响应、签名同理。

### 17.4 选型决策树

| 需求 | 选用 |
|------|------|
| Feature 模块内 REST + 缓存 + 401 | `FKNetworkClient` / `Networkable` |
| 跨模块 DI、Swift Package 边界 | `FKAPIClientProviding` + Adapter |
| Token 存 Keychain | `FKKeychainCredentialStore` 注入 Configuration |
| 仅测试 HTTP | `FKMockAPIClient` 或 `FKMockNetworkSession` |

---

## 18. 错误模型

### 18.1 现有 `NetworkError`

| Case | 含义 |
|------|------|
| `invalidURL` | URL 构建失败 |
| `invalidResponse` | 非 HTTPURLResponse |
| `requestCancelled` | 取消 |
| `noData` | 空 body |
| `decodingFailed` | Codable 失败 |
| `serverError` | 非 2xx |
| `businessError` | 业务码（含去重 -2） |
| `sslValidationFailed` | 系统 SSL 失败 |
| `offline` | 预检不可达 |
| `tokenRefreshFailed` | 刷新失败 |
| `signingFailed` | 签名失败 |
| `encryptionFailed` | 加密钩子失败 |
| `underlying` | 包装 Error |

文案经 **FKI18n**（`fkcore.network.error.*`）。

### 18.2 增强扩展（semver minor）

```swift
case sslPinningFailed(host: String)
case sslPinningNotConfigured(host: String)  // 可选，调试用
case retryExhausted(lastError: NetworkError)  // 可选
```

文档区分：`sslValidationFailed`（系统信任）vs `sslPinningFailed`（pin mismatch）。

---

## 19. 日志与可观测性

### 19.1 `NetworkLogger`

- 默认 `FKDefaultNetworkLogger` → `print` 或 OSLog（以实现为准）；
- 记录：cache hit、URL 摘要、状态码 — **禁止** Multipart 二进制 dump。

### 19.2 与 `FKPluggableLogging` 桥接

- 可选 `FKLoggerPluggableAdapter` 注入自定义 `NetworkLogger` 包装；
- Network 模块 **不强制** 依赖 Pluggable Logging 协议（避免环）。

### 19.3 链路追踪（v2）

- `FKRequestIntercepting` 注入 `trace-id` / `X-Request-ID` — 文档示例，非内置。

---

## 20. 并发与 Swift 6

| 组件 | 策略 |
|------|------|
| `FKNetworkClient` | `@unchecked Sendable`；handler 字典 `NSLock` |
| `FKNetworkConfiguration` | `@unchecked Sendable`；`current` 加锁 |
| `FKNetworkReachability` | 后台 queue 更新 `isReachable` |
| `TokenRefresher` | completion 回调线程文档化（宜主线程若触 UI） |
| 新增强类型 | `Sendable` struct 配置 |
| Verify | `SWIFT_STRICT_CONCURRENCY=complete` |

---

## 21. 安全注意事项

- Pin 哈希、生产 API 密钥 **不得** 进入开源仓库；
- `allowUserTrustEvaluationFallback` 仅 DEBUG；
- Multipart / Token 日志脱敏；
- 重试放大攻击面 — 限制次数与仅幂等方法；
- `encryptParameters` 与后端算法对齐审查；
- 下载临时文件权限 — 及时移动或删除。

---

## 22. v2 能力展望（非 v1 交付）

按需评估；写入文档避免集成方重复提 Issue。

| 能力 | 说明 | 优先级 |
|------|------|--------|
| **WebSocket** | 长连接、实时消息；独立 `FKWebSocketClient` 或 Network 子模块 | 中 |
| **GraphQL** | 专用 Requestable 预设，非完整客户端 | 低 |
| **Circuit Breaker** | 连续失败后熔断窗口 | 低 |
| **Rate Limiting** | 客户端侧 QPS 限制 | 低 |
| **Multipart Streaming** | 大文件边读边传 | 中 |
| **Reachability 细粒度** | 区分 expensive / constrained | 低 |
| **HTTP/3 显式配置** | 跟随 URLSession 即可 | 低 |
| **Network 指标导出** | 延迟直方图、Pluggable 回调 | 低 |

---

## 23. FKCoreKit 复用要求

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 哈希 / Pin | `String.fk_sha256` / `FKSecurity` | 重复 Digest |
| MD5 签名 | 现有 `MD5RequestSigner` | 新签名器 |
| MIME | FileManager / Extension | Network 内完整 mime 表 |
| 错误文案 | `FKI18n` | 硬编码英文 |
| 日志 | `NetworkLogger` | 裸 `print` 散落 |
| 并发重试 | `Task.sleep` + 取消感知 | 无取消的阻塞 loop |

---

## 24. 公开 API 索引

| 分类 | 类型 |
|------|------|
| 客户端 | `FKNetworkClient`, `Networkable`, `Cancellable` |
| 配置 | `FKNetworkConfiguration`, `FKEnvironmentConfig`, `FKNetworkEnvironment` |
| 请求 | `Requestable`, `HTTPMethod`, `ParameterEncoding`, `NetworkCachePolicy`, `NetworkRequestBehavior` |
| 响应 | `NetworkResponse<T>`, `NetworkEndpoint` |
| 协议 | `NetworkSession`, `Cacheable`, `RequestInterceptor`, `ResponseInterceptor`, `RequestSigner`, `TokenStore`, `TokenRefresher`, `NetworkStatusProviding`, `NetworkLogger` |
| 工具 | `FKNetworkCache`, `FKRequestDeduplicator`, `FKNetworkReachability`, `NetworkServiceProvidable` |
| 错误 | `NetworkError` |
| 增强（待建） | `FKSSLPinningConfiguration`, `FKMultipartFormData`, `FKNetworkRetryPolicy`, `FKMockNetworkSession`, `FKNetworkClientPluggableAdapter` |

---

## 25. 建议源码目录结构

```text
Sources/FKCoreKit/Components/Network/
├── Core/                              # 现有
├── Config/
│   └── NetworkConfiguration.swift     # + sslPinning, retryPolicy
├── Model/
│   └── NetworkError.swift               # + sslPinningFailed
├── Tool/
│   ├── FKSSLPinningValidator.swift    # 新增
│   ├── FKSSLPinningConfiguration.swift
│   ├── FKMultipartFormData.swift      # 新增
│   ├── FKNetworkRetryPolicy.swift     # 新增
│   ├── FKNetworkRetryExecutor.swift   # 新增（或 Interceptor）
│   ├── Mock/
│   │   └── FKMockNetworkSession.swift
│   ├── FKNetworkReachability+Pluggable.swift  # 新增
│   └── ...                            # 现有 Cache, Logger, Service, Dedup
├── Bridge/                            # 新增（或放 Pluggable/Implementations/Networking）
│   └── FKNetworkClientPluggableAdapter.swift
├── Examples/                          # 可选
│   └── FKNetworkEnhancementExamples.swift
└── README.md                          # Roadmap 更新 + 链到本文
```

---

## 26. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/Network/`

### 26.1 基线能力（已交付 — 补齐演示）

| # | 场景 | 验证点 |
|---|------|--------|
| B1 | `BasicGET` | 环境 + JSON 解码 |
| B2 | `POSTJSON` | body 编码 |
| B3 | `CacheTTL` | memory cache 命中 |
| B4 | `DeduplicatedRequest` | 并发去重失败 |
| B5 | `Token401Refresh` | 刷新后重试 |
| B6 | `OfflinePreflight` | Reachability fast-fail |
| B7 | `UploadDownload` | 进度 + resumeData |
| B8 | `RequestMockData` | `enableMock` 路径 |

### 26.2 增量增强（待交付）

| # | 场景 | 验证点 |
|---|------|--------|
| E1 | `SSLPinningSuccess` | 正确 pin |
| E2 | `SSLPinningFailure` | pin mismatch |
| E3 | `MultipartSingleFile` | 图片上传 |
| E4 | `MultipartMixedFields` | 文本 + 文件 |
| E5 | `RetryGET503` | 退避重试 |
| E6 | `RetryPOSTNoRetry` | POST 不重试 |
| E7 | `MockSessionStub` | `FKMockNetworkSession` |
| E8 | `PinningWith401Refresh` | Pin + Token 共存 |
| E9 | `PluggableAPIClient` | Adapter 注入 |

---

## 27. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **N0** | 基线 Examples B1–B8 | 已交付能力文档化演示 |
| **N1** | Multipart + Retry + Mock Session | 高频增强 |
| **N2** | SSL Pinning + 错误扩展 | 安全敏感 |
| **N3** | Pluggable 桥接 + Reachability 双符合 | DI 对齐 |
| **N4** | README Roadmap 勾选 + 根 README | 发布卫生 |

每阶段：`xcodebuild` → `CHANGELOG` → Examples Hub。

---

## 28. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Retry 拦截器 vs Client 内建？ | 独立 `FKNetworkRetryExecutor` 包装 send |
| Q2 | Mock Session 是否 public？ | public，文档标注 testing |
| Q3 | Pin 失败是否回调 Pluggable？ | v1 否 |
| Q4 | Multipart streaming v1？ | v1.1 |
| Q5 | `Bridge/` 在 Network vs Pluggable/Implementations？ | Adapter 放 **Pluggable/Implementations/Networking**；Pinning/Multipart 留 Network |
| Q6 | `Requestable.isIdempotent` 是否新增？ | v1 增强 PR 增加可选属性，默认 false |
| Q7 | 基线 Examples B1–B8 是否与 N1 同 PR？ | 可独立 docs+examples PR 先行 |

---

## 29. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | `FKNetwork_ENHANCEMENT_DESIGN.md` 初版（四项 Roadmap 增强） |
| 2026-06-14 | 合并为完整模块设计：已交付能力详表、生命周期、Pluggable/Reachability、基线 Examples、v2 展望 |

---

## 30. 相关文档

| 文档 | 内容 |
|------|------|
| [Network/README.md](../Sources/FKCoreKit/Components/Network/README.md) | 使用指南与 Roadmap |
| [FKNetwork_ENHANCEMENT_DESIGN.md](FKNetwork_ENHANCEMENT_DESIGN.md) | 增量增强索引（指向本文 §12–§15） |
| [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) | Network 桥接 §17 |
| [FKSecurity README](../Sources/FKCoreKit/Components/Security/README.md) | 哈希与 Pin 算法 |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §10.1 Network 增强 |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | 现有模块增强 |
