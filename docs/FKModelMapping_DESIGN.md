# FKModelMapping — 模块设计需求文档

FKKit **`FKModelMapping`** 的完整实现指导文档：规范 **JSON / Dictionary ↔ Swift 模型** 的双向转换、**非标准 API 载荷** 的容错映射、**响应信封** 解包、**类型强制转换** 与 **Codable 增强**，并与 **`FKNetwork` / `FKStorage` / `Extension`** 明确分工。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) — 建议纳入 Tier 1 基础设施（待维护者确认）  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) — 网络层仅提供 `JSONDecoder`，缺少独立映射层  
**模块 README（待建）：** `Sources/FKCoreKit/Components/ModelMapping/README.md`

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 映射策略与选型决策树](#6-映射策略与选型决策树)
- [7. 核心能力 — Codable 路径](#7-核心能力--codable-路径)
- [8. 核心能力 — 动态 Dictionary 路径](#8-核心能力--动态-dictionary-路径)
- [9. 键名与路径映射](#9-键名与路径映射)
- [10. 类型转换与 Transform](#10-类型转换与-transform)
- [11. 响应信封与业务码](#11-响应信封与业务码)
- [12. 嵌套、集合与多态](#12-嵌套集合与多态)
- [13. 容错、默认值与部分映射](#13-容错默认值与部分映射)
- [14. 编码（Model → JSON）](#14-编码model--json)
- [15. 与 FKNetwork 集成](#15-与-fknetwork-集成)
- [16. 与 FKStorage / FileManager 集成](#16-与-fkstorage--filemanager-集成)
- [17. 调试、日志与 Mock](#17-调试日志与-mock)
- [18. 错误模型](#18-错误模型)
- [19. 并发与 Swift 6](#19-并发与-swift-6)
- [20. 安全注意事项](#20-安全注意事项)
- [21. v2 能力展望（非 v1 交付）](#21-v2-能力展望非-v1-交付)
- [22. FKCoreKit 复用要求](#22-fkcorekit-复用要求)
- [23. 公开 API 索引](#23-公开-api-索引)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [26. 分阶段交付计划](#26-分阶段交付计划)
- [27. 待决问题](#27-待决问题)
- [28. 修订历史](#28-修订历史)
- [29. 相关文档](#29-相关文档)

---

## 1. 概述

中大型 iOS App 在接入 REST / GraphQL-over-HTTP / 推送 Payload 时，反复实现同一套逻辑：

- 把 `Data` / `[String: Any]` 转成业务 `struct` / `class`；
- 处理 **字段名不一致**（`user_name` vs `userName` vs `UserName`）；
- 处理 **类型不一致**（`"123"` vs `123`、`""` vs `null`）；
- 解包 **`{ code, message, data }`** 信封后再解码；
- 映射失败时给出 **可定位的字段路径**；
- 本地缓存、埋点、Mock 与网络层 **共用同一套解码规则**。

系统 **`Codable`** 在标准 JSON 下足够，但真实后端载荷经常 **不符合** `Decodable` 的严格假设。各团队引入第三方 Mapper 或复制粘贴 `JSONSerialization` + 强制转换，与 FKKit **零第三方** 原则冲突，且与 `FKNetwork` 的 `JSONDecoder` 注入点未形成统一故事。

**`FKModelMapping`**（建议路径 `Sources/FKCoreKit/Components/ModelMapping/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKModelMapper`** | 统一门面：配置 + 解码/编码入口 |
| **`FKModelMappingConfiguration`** | 全局/ per-request 映射策略（键策略、日期、容错、信封） |
| **`FKJSONCodec`** | `Data` / `String` / `[String: Any]` ↔ 模型的薄封装 |
| **`FKResponseEnvelope`** | 可配置信封解包 + 业务码判定 |
| **`FKValueTransform` 注册表** | Date / URL / Bool / Enum / 自定义类型转换 |
| **Property Wrappers** | `@FKMappedKey` / `@FKDefault` / `@FKTransform` 等 Codable 增强 |
| **`FKMappable`（可选）** | 手写 `map(from:)` 的显式映射协议 |
| **`FKMappingError`** | 带 `codingPath` / `underlying` 的结构化错误 |

**关键约束：** 纯 Swift、`Foundation`；**零第三方运行时依赖**；Swift 6 `Sendable` 配置；iOS 15+；公开 API 与 DocComment **英文**（与 FKKit 库源码一致；本文档为中文设计说明）。

**成熟度：** **待建** — 本设计为 v1 交付规范；实现前无源码。

---

## 2. 目标、非目标与成功标准

### 2.1 目标（模块整体）

1. **双向映射** — JSON `Data` / UTF-8 `String` / `[String: Any]` ↔ Swift 模型（`struct` 为主，`class` 可选支持）。
2. **双路径策略** — **Codable 优先**（标准 API）+ **动态 Dictionary 映射**（非标准 API）；同一配置下行为一致。
3. **键名与路径** — snake_case 自动转换、显式 `@FKMappedKey("server_field")`、嵌套路径 `"a.b.c"`、数组下标 `"items[0].id"`。
4. **宽松类型转换** — 复用 `FKValueParsing`；String↔Number、空字符串→nil、NSNumber 桥接等可配置。
5. **响应信封** — 内置常见 `{ code, msg, data }` / `{ success, result }` 模板；可自定义键名与成功判定。
6. **Transform 体系** — ISO8601 / 自定义 DateFormat、URL、Base64 `Data`、RawRepresentable Enum、Bool（0/1、"true"/"false"）。
7. **容错模式** — 忽略未知键；单字段失败时使用默认值或跳过（可配置 strict vs lenient）。
8. **错误可诊断** — `FKMappingError` 含字段路径、期望/实际类型摘要、原始键名。
9. **FKNetwork 对齐** — 提供 `ResponseInterceptor` 工厂、`JSONDecoder` 预设、与 `NetworkError.decodingFailed` 的桥接。
10. **Swift 6** — 配置 struct `Sendable`；Mapper 无全局可变单例状态（或文档化线程安全策略）。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| 替代 `FKNetwork` 传输层 | 只负责 **载荷语义**；HTTP 状态码、重试、缓存仍属 Network |
| ORM / 数据库对象映射 | Core Data / SwiftData 不在范围 |
| XML / Protobuf / MessagePack | v1 仅 JSON 语义（`Data` 入口可扩展） |
| GraphQL 专用客户端 | 可用 `[String: Any]` + Mapper 手建 |
| 运行时反射自动生成 Codable | Swift 无稳定公共反射；v1 不承诺 Mirror 全自动 |
| `@objc` / KVC 模型 | 非 Codable 的 ObjC 模型由宿主自行桥接 |
| 第三方 Mapper 兼容层 | HandyJSON / ObjectMapper API 不复刻 |
| 强制全局 Mapper 单例 | 提供 `FKModelMapper.shared` **便利**入口，但必须支持注入与独立配置 |
| Property Wrapper 覆盖所有 Swift 类型组合 | v1 覆盖常见标量 + 嵌套 Codable；极端泛型组合文档化限制 |

### 2.3 成功标准

**v1 交付：**

- [ ] `xcodebuild` + `SWIFT_STRICT_CONCURRENCY=complete` **BUILD SUCCEEDED**。
- [ ] Examples Hub ≥ 12 场景（§25）可运行。
- [ ] README 含目录布局、与 Network/Storage 决策树、API 速查。
- [ ] 典型非标准 JSON 样例（字符串数字、空串、嵌套信封、字段重命名）全部通过。
- [ ] strict 模式下类型错误抛出 `FKMappingError.typeMismatch` 且 `codingPath` 可定位。
- [ ] lenient 模式下可配置默认值，不崩溃。
- [ ] `FKNetworkClient` 注入 `decoder` + `ResponseInterceptor` 端到端 Examples 成功。
- [ ] 根 `README.md` 与 `CHANGELOG.md` 索引更新。

---

## 3. 背景与问题陈述

### 3.1 痛点

| 痛点 | 现状（FKKit） | FKModelMapping 回应 |
|------|---------------|---------------------|
| 字段 snake_case | `JSONDecoder.fk_applySnakeCaseKeys()` 扩展 | 纳入统一 `FKModelMappingConfiguration.keyStrategy` |
| 动态 `[String: Any]` | `Dictionary.fk_decodeJSON` 二次序列化 | 原生 Dictionary 映射器，避免无效 `JSONSerialization` 往返 |
| 类型松散 | `FKValueParsing` 散落调用 | Transform 注册表 + Property Wrapper 统一入口 |
| 信封解包 | 各 Repository 手写 | `FKResponseEnvelope` + Interceptor |
| 错误难查 | `DecodingError` 上下文不足 | `FKMappingError` 增强路径与摘要 |
| Network / Storage 规则不一致 | 各自 `JSONDecoder()` | 共享 `FKJSONCodec` 与 Configuration |
| Mock 测试 | 手写字典 | `FKMappingFixture` / 字典 Builder（§17） |

### 3.2 与邻模块关系

| 模块 | 分工 |
|------|------|
| **`FKNetwork`** | HTTP 传输、`URLSession`、状态码；解码前可经 `ResponseInterceptor` 解信封 |
| **`FKStorage` / `FKFileManager`** | 持久化；可注入与 Network 相同的 `FKJSONCodec` |
| **`Extension`（`JSONDecoder+` / `Encodable+` / `FKValueParsing`）** | 底层便利 API；ModelMapping **组合**而非复制 |
| **`FKI18n`** | `FKMappingError` 面向用户的本地化 key |
| **`FKLogger`** | Debug 映射轨迹（opt-in，禁止生产 dump 全量 PII） |
| **`FKPluggable`** | 可选 `FKJSONCodecProviding` 契约（v1.1），供 DI 注入 |

### 3.3 真实 API 载荷分类（设计必须覆盖）

| 类型 | 示例 | 推荐路径 |
|------|------|----------|
| **标准 Codable JSON** | RESTful 资源，字段与 Swift 模型一致 | Codable + Configuration |
| **命名不一致** | `user_id` → `userId` | KeyStrategy + `@FKMappedKey` |
| **类型不一致** | `"price": "9.99"` | Transform + lenient |
| **空值语义混乱** | `""`、`null`、键缺失 三义 | `@FKDefault` + nil 策略 |
| **嵌套信封** | `{ "code":0, "data":{...} }` | Envelope + Interceptor |
| **多态数组** | `type` 字段区分子模型 | Discriminator（§12.3） |
| **扁平化需求** | 服务器嵌套，客户端想扁平 | `@FKMappedKey("user.name")` 或 Manual `FKMappable` |
| **仅下行** | 上报埋点只需 Encodable | Encode 路径 + snake 输出 |

---

## 4. 架构总览

### 4.1 分层

```text
┌────────────────────────────────────────────────────────────────────┐
│ 业务层：Repository / Service / ViewModel                            │
│   user = try mapper.decode(User.self, from: networkData)           │
└───────────────────────────────┬────────────────────────────────────┘
                                │
┌───────────────────────────────▼────────────────────────────────────┐
│ FKModelMapper（门面）                                               │
│   configuration: FKModelMappingConfiguration                       │
│   decode / encode / decodeEnvelope / decodeDictionary              │
└───────┬─────────────────┬─────────────────┬────────────────────────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────────────────────┐
│ FKJSONCodec   │ │ FKDictionary  │ │ FKResponseEnvelope            │
│ Data/String   │ │ Mapper        │ │ unwrap + business code check  │
│ ↔ Codable     │ │ [String:Any]  │ │                               │
└───────┬───────┘ └───────┬───────┘ └───────────────────────────────┘
        │                 │
        ▼                 ▼
┌────────────────────────────────────────────────────────────────────┐
│ 增强层：Property Wrappers / FKMappable / Transform Registry         │
│ FKValueParsing · JSONDecoder/Encoder presets · CodingPath 追踪      │
└────────────────────────────────────────────────────────────────────┘
```

### 4.2 数据流（解码）

```text
HTTP Body (Data)
    │
    ├─[可选] FKResponseEnvelopeInterceptor ──► 剥离 envelope，提取 payload Data
    │
    ├─ 路径 A：FKJSONCodec.decode(Codable) ──► JSONDecoder + configuration
    │
    └─ 路径 B：JSONSerialization ──► [String: Any] ──► FKDictionaryMapper ──► Model
```

### 4.3 设计原则

| 原则 | 说明 |
|------|------|
| **Codable 优先** | 能标准解码的不引入运行时映射；增强通过 Wrapper 与 Decoder 配置 |
| **显式优于魔法** | 非标准字段必须 `@FKMappedKey` 或 `FKMappable`，避免 silent 丢字段 |
| **配置可注入** | 禁止隐式依赖未文档化的全局 DateFormatter |
| **失败可观测** | strict 模式失败即 throw；lenient 可 `FKMappingResult` 携带 warnings |
| **零第三方** | 不引入 SwiftyJSON / ObjectMapper 等 |

---

## 5. 模块边界

### 5.1 本模块负责

- JSON 语义下的 **模型 ↔ 数据** 转换；
- 键名、类型、日期、枚举、URL 等 **字段级** 策略；
- API **响应信封** 解包与业务错误码映射钩子；
- 为 `FKNetwork` 提供 **解码前** 数据规范化；
- 映射 **错误 taxonomy** 与 Debug 辅助。

### 5.2 本模块不负责

| 事项 | 负责模块 |
|------|----------|
| HTTP 请求构建、TLS、重试 | `FKNetwork` |
| 磁盘/Keychain 读写 | `FKStorage` / `FKFileManager` |
| 业务规则（「该错误码是否弹 Toast」） | 业务层 / `FKBusinessKit` |
| UI 展示解码错误 | `FKAlert` / `FKToast` |
| 图片 Base64 解码为 `UIImage` | `FKUIKit` / 业务层 |

### 5.3 与 Extension 的边界

| 已有 API | 关系 |
|----------|------|
| `JSONDecoder.fk_applyCommonAPIDecodingDefaults()` | ModelMapping **内部调用**；保留 Extension 作为轻量独立入口 |
| `Encodable.fk_jsonData()` / `Decodable.fk_decoded()` | 简单场景仍可直接使用；复杂场景走 `FKModelMapper` |
| `FKValueParsing` | Dictionary 路径 **必须** 委托 |
| `Dictionary.fk_decodeJSON` | 标记为「便捷但二次序列化」；README 引导至 ModelMapping |

---

## 6. 映射策略与选型决策树

```text
载荷是否为合法 JSON 且字段/类型与 Swift 模型一致？
├─ 是 → Codable 路径（FKJSONCodec + Configuration）
└─ 否 → 是否存在可枚举的键名/类型差异？
    ├─ 仅键名/日期/枚举 → Property Wrappers + Configuration
    ├─ 大量类型松散 → Dictionary 路径 或 lenient + Transform
    ├─ 信封包裹 → FKResponseEnvelope 后再解码
    └─ 结构完全不规则 → FKMappable 手写 map(from:)
```

| 需求 | 选用 |
|------|------|
| 标准 REST 资源 | `Codable` + `mapper.decoderPreset` |
| snake_case API | `configuration.keyStrategy = .convertFromSnakeCase` |
| 单字段重命名 | `@FKMappedKey("server_key")` |
| `"123"` → `Int` | `@FKTransform(FKIntTransform.lenient)` |
| 解包 `{data:{...}}` | `FKResponseEnvelope.standard` + Interceptor |
| 推送 Payload 字典 | `mapper.decode(User.self, from: userInfo)` |
| 模型 → 上报 JSON | `mapper.encode(model)` + snake 输出 |

---

## 7. 核心能力 — Codable 路径

### 7.1 FKJSONCodec

**职责：** 在 `Data` / `String` 与 `Codable` 模型间转换，应用 `FKModelMappingConfiguration` 到 `JSONDecoder` / `JSONEncoder`。

```swift
public struct FKJSONCodec: Sendable {
  public init(configuration: FKModelMappingConfiguration = .init())

  public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
  public func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T
  public func encode<T: Encodable>(_ value: T) throws -> Data
  public func encode<T: Encodable>(_ value: T) throws -> String

  /// Exposes a decoder configured for FKNetwork injection.
  public var makeDecoder: () -> JSONDecoder
  public var makeEncoder: () -> JSONEncoder
}
```

**要求：**

- 每次 `makeDecoder()` 返回 **新实例**（`JSONDecoder` 非线程安全，与 `StorageCodec` 策略一致）；
- 支持 `configuration` 快照；`FKModelMapper` 持有 `Sendable` 配置副本。

### 7.2 FKModelMappingConfiguration

```swift
public struct FKModelMappingConfiguration: Sendable, Equatable {
  public enum KeyStrategy: Sendable, Equatable {
    case useDefaultKeys
    case convertFromSnakeCase
    case convertToSnakeCase  // encode
  }

  public enum UnknownKeyStrategy: Sendable, Equatable {
    case ignore          // 默认
    case fail            // strict
  }

  public enum NilValueStrategy: Sendable, Equatable {
    case treatNullAsNil
    case treatEmptyStringAsNil
    case treatNSNumberZeroAsNil  // opt-in，默认 false
  }

  public var keyStrategy: KeyStrategy
  public var unknownKeyStrategy: UnknownKeyStrategy
  public var nilValueStrategy: NilValueStrategy
  public var dateDecoding: FKDateDecodingStrategy
  public var dateEncoding: FKDateEncodingStrategy
  public var dataDecoding: FKDataDecodingStrategy  // base64
  public var boolDecoding: FKBoolDecodingStrategy  // 0/1, "true"/"false"
  public var lenientNumberParsing: Bool
  public var envelope: FKResponseEnvelopeConfiguration?

  public static let standard: Self
  public static let lenientAPI: Self   // snake + 宽松数字 + 空串 nil
  public static let strict: Self
}
```

### 7.3 Property Wrappers（Codable 增强）

| Wrapper | 作用 |
|---------|------|
| `@FKMappedKey("remote_key")` | 单字段 CodingKey 重命名 |
| `@FKMappedKey("profile.display_name")` | 嵌套路径读取（decode）；encode 时写回同路径 |
| `@FKDefault(defaultValue)` | 缺失或 null 时使用默认值 |
| `@FKTransform(_ transform: FKValueTransform)` | 字段级 Transform |
| `@FKOptional` | 与 `NilValueStrategy` 联动（空串→nil） |
| `@FKLossyArray` | 数组元素单个失败时跳过而非整体失败（opt-in） |

**实现要求：**

- 基于 `Codable` synthesis + custom `init(from:)` / `encode(to:)` 生成或宏替代（v1 手写 Wrapper 模板）；
- 每个 Wrapper 提供 **英文 DocComment** 与 thread-safety 说明（无共享状态）。

### 7.4 与系统 DecodingError 的关系

- Codable 路径失败时，**包装**为 `FKMappingError.decodingFailed(underlying:codingPath:)`；
- 保留 `underlying` 供高级用户 `switch` 原 `DecodingError`；
- 对外推荐捕获 `FKMappingError`。

---

## 8. 核心能力 — 动态 Dictionary 路径

### 8.1 动机

`Dictionary.fk_decodeJSON` 通过 `JSONSerialization` → `Data` → `JSONDecoder` **二次序列化**，存在：

- 性能损耗；
- `JSONSerialization` 不支持的类型（如嵌套结构边界情况）；
- 无法在中间步骤做 **路径级** 宽松转换。

**FKDictionaryMapper** 直接从 `[String: Any]`（或 `[String: Any?]`）映射到模型。

### 8.2 FKJSONObject（可选薄封装）

```swift
/// Sendable-friendly JSON object view; internally wraps [String: Any] for dynamic access.
public struct FKJSONObject: Sendable {
  public subscript(path: String) -> FKJSONValue?  // 支持 "a.b[0].c"
  public var dictionary: [String: Any] { get }
}
```

- v1 可先用 `[String: Any]` 公开 API，内部再引入 `FKJSONObject`；
- 下标路径语法与 `@FKMappedKey` 路径 **一致**。

### 8.3 FKMappable 协议（Manual 映射）

```swift
public protocol FKMappable {
  init(map: FKMap) throws
}

public struct FKMap {
  public func value<T>(_ key: String, as type: T.Type = T.self) throws -> T
  public func value<T>(_ key: String, as type: T.Type, default defaultValue: T) -> T
  public func nestedObject(_ key: String) -> FKMap?
  public func array<T: FKMappable>(_ key: String, as element: T.Type) throws -> [T]
}
```

**适用：** 条件分支、同一字段多种形态、需读取多个键合并。

**要求：**

- `FKMap` 只读；不持有外部可变字典引用跨线程；
- 提供 `FKMap` → Codable 的互操作：模型可 `struct User: Codable, FKMappable`。

### 8.4 Dictionary ↔ Codable 互转

- `mapper.dictionary(from: model) throws -> [String: Any]` — Encodable + 可选 snake；
- `mapper.decode(T.self, from: dictionary)` — 优先 Dictionary 路径，必要时 fallback Codable。

---

## 9. 键名与路径映射

### 9.1 KeyStrategy

| 策略 | Decode | Encode |
|------|--------|--------|
| `useDefaultKeys` | 原样 | 原样 |
| `convertFromSnakeCase` | snake → camel | — |
| `convertToSnakeCase` | — | camel → snake |
| 双向 snake | 组合配置或 `.apiDefault` preset | 同上 |

与 `JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase` **对齐语义**，避免与 `@FKMappedKey` 冲突：

- **显式 `@FKMappedKey` 优先于** KeyStrategy；
- 文档说明：二者同时作用于同一字段时，以 MappedKey 为准。

### 9.2 路径语法规范

| 路径 | 含义 |
|------|------|
| `user.name` | 嵌套字典 |
| `items[0].id` | 数组下标（越界 → missing 或 throw） |
| `items[]` | 不支持；必须显式索引或映射整个数组 |

**错误：**

- 路径中断（中间非 Dictionary）→ `FKMappingError.invalidPath(path:reason:)`。

### 9.3 CodingKeys 生成

- 不引入编译期代码生成工具（Sourcery 等）；
- 文档提供 **推荐模板**（Xcode snippet）；
- v2 评估 Swift Macro（§21）。

---

## 10. 类型转换与 Transform

### 10.1 FKValueTransform 协议

```swift
public protocol FKValueTransform: Sendable {
  associatedtype Object
  associatedtype JSON

  func transformFromJSON(_ value: Any?) throws -> Object?
  func transformToJSON(_ value: Object?) throws -> Any?
}
```

### 10.2 内置 Transform（v1 必须）

| Transform | JSON → Swift | Swift → JSON |
|-----------|--------------|--------------|
| `FKIntTransform` | String/Double/NSNumber → Int | Int |
| `FKDoubleTransform` | 同上 | Double |
| `FKBoolTransform` | 0/1, "0"/"1", true/false 字符串 | 依 configuration |
| `FKStringTransform` | 任意 `CustomStringConvertible` | String |
| `FKDateTransform` | ISO8601 + 自定义 format | ISO8601 |
| `FKURLTransform` | String → URL | absoluteString |
| `FKDataTransform` | Base64 String → Data | Base64 |
| `FKEncodableTransform<T: RawRepresentable>` | RawValue 宽松 | RawValue |

**实现：** JSON → Swift 分支 **必须** 调用 `FKValueParsing` 再扩展。

### 10.3 FKDateDecodingStrategy

```swift
public enum FKDateDecodingStrategy: Sendable, Equatable {
  case iso8601
  case secondsSince1970
  case millisecondsSince1970
  case formatted(FKDateFormatConfiguration)  // Sendable: format + locale + timeZone
  case custom(@Sendable (Any?) throws -> Date?)  // 高级；文档警告逃逸隔离
}
```

- 默认 `.iso8601`，与 `JSONDecoder.fk_applyISO8601DateStrategy()` 一致；
- 支持 **多种 format 尝试**（`[.iso8601, .custom("yyyy-MM-dd")]`）作为 v1.1 增强。

### 10.4 全局 Transform 注册表

```swift
public struct FKTransformRegistry: Sendable {
  public mutating func register<T>(_ transform: T.Type, for type: Any.Type)
  public func transform(for type: Any.Type) -> (any FKValueTransform)?
}
```

- 默认内置注册；
- 宿主可扩展 `CLLocationCoordinate2D` 等 **业务类型**（通过 extension 注册，不修改核心库）。

---

## 11. 响应信封与业务码

### 11.1 问题

常见 API  body 结构：

```json
{ "code": 0, "message": "ok", "data": { "id": 1, "name": "Ann" } }
{ "success": true, "result": [...] }
{ "errno": 1001, "errmsg": "token expired", "data": null }
```

`FKNetwork` 在 HTTP 200 时仍可能 **业务失败**；信封解包应在 **Codable 之前** 完成。

### 11.2 FKResponseEnvelopeConfiguration

```swift
public struct FKResponseEnvelopeConfiguration: Sendable, Equatable {
  public var payloadKey: String           // default "data"
  public var codeKey: String              // default "code"
  public var messageKey: String           // default "message"
  public var successCodes: Set<Int>       // default [0]
  public var successBoolKey: String?      // optional "success"
  public var nestedPayloadPath: String?   // e.g. "result.items"

  public static let standard: Self
  public static let successFlag: Self
}
```

### 11.3 FKResponseEnvelopeProcessor

```swift
public struct FKResponseEnvelopeProcessor: Sendable {
  public func process(data: Data) throws -> FKEnvelopeResult

  public struct FKEnvelopeResult: Sendable {
    public var payload: Data
    public var businessCode: Int?
    public var businessMessage: String?
  }
}
```

**行为：**

1. 解析顶层 JSON Dictionary；
2. 读取 `codeKey` / `successBoolKey` 判定业务成功；
3. 失败 → `FKMappingError.businessFailure(code:message:payload:)`（**非** HTTP 层 `NetworkError.businessError`，但可桥接）；
4. 成功 → 提取 `payloadKey`（或 `nestedPayloadPath`）并 re-serialize 为 `Data` 供解码；
5. `data: null` → 空 payload 或 `Void` 模型策略文档化。

### 11.4 与 NetworkError 桥接

提供：

```swift
public extension FKMappingError {
  func asNetworkError() -> NetworkError
}
```

- 业务码失败 → `NetworkError.businessError`；
- 纯解码失败 → `NetworkError.decodingFailed`。

---

## 12. 嵌套、集合与多态

### 12.1 嵌套模型

- 嵌套 `struct` 遵循 `Codable` 自动合成；
- Dictionary 路径递归 `FKDictionaryMapper`；
- `@FKMappedKey("address.city")` 支持 **扁平模型 + 嵌套 JSON**。

### 12.2 集合

| 类型 | 要求 |
|------|------|
| `[T]` | 元素失败策略：`failFast` vs `@FKLossyArray` |
| `[String: T]` | String 键；非 String 键 JSON 对象 stringify 策略文档化 |
| `Set<T>` | T: Hashable & Codable |
| 可选数组 | `null` vs `[]` 等价策略可配置 |

### 12.3 多态（Discriminator）

```swift
public protocol FKPolymorphicDecodable {
  static var discriminatorKey: String { get }
  static func decode(from map: FKMap, typeValue: String) throws -> Self
}
```

**示例：** `type: "image" | "video"` → `FKMediaItem` 枚举或协议 existential。

- v1 支持 **枚举 + 静态注册表**；
- 协议 existential 自动注册 **不** 承诺（Swift 限制）。

### 12.4 泛型容器

```swift
public struct FKPage<T: Decodable & Sendable>: Decodable, Sendable {
  public let items: [T]
  public let total: Int
}
```

- 提供标准 `FKPage`、`FKListResponse` 模板 struct（可选）；
- 信封 + 分页字段键名可配置。

---

## 13. 容错、默认值与部分映射

### 13.1 Strict vs Lenient

| 模式 | 行为 |
|------|------|
| **strict**（默认） | 任一字段类型错误 → throw |
| **lenient** | 单字段失败 → 默认值 / skip；收集 `FKMappingWarning` |

```swift
public struct FKMappingResult<T: Sendable>: Sendable {
  public let value: T
  public let warnings: [FKMappingWarning]
}
```

### 13.2 默认值来源优先级

1. `@FKDefault`
2. `FKMap.value(_:default:)`
3. Optional → `nil`
4. lenient 下标量非 Optional → 类型零值（**文档警告**：仅 lenient）

### 13.3 未知键

- 默认 **ignore**（与 JSONDecoder 一致）；
- strict 配置 + `@FKStrictKeys`  opt-in 模型级校验（v1.1）。

### 13.4 部分模型更新

- `mapper.patch(into: &model, from: dictionary)` — 仅更新 dictionary 中存在的键（v1.1）；
- v1 文档标注为展望，若实现成本高可推迟。

---

## 14. 编码（Model → JSON）

### 14.1 要求

- 对称支持 `encode(model) -> Data / String / [String: Any]`；
- `keyStrategy.convertToSnakeCase` 作用于 encode；
- `@FKMappedKey` encode 写回 **远程键名**；
- `@FKTransform` 逆向 `transformToJSON`；
- 可选 `outputFormatting: [.sortedKeys, .prettyPrinted]` 用于 Debug。

### 14.2 Null 与 omit 策略

```swift
public enum FKEncodeNullStrategy: Sendable, Equatable {
  case encodeNull
  case omitKey
}
```

- 默认 `encodeNull`；
- 部分后端要求 omit → 配置或 `@FKOmitIfNil`。

### 14.3 敏感字段

- 提供 `@FKRedacted` Debug 描述脱敏（日志用，不影响 encode）— 可选 v1.1；
- 文档提醒：encode 结果勿写入 `FKLogger` 全量。

---

## 15. 与 FKNetwork 集成

### 15.1 推荐集成方式

```swift
let mappingConfig = FKModelMappingConfiguration.lenientAPI
let codec = FKJSONCodec(configuration: mappingConfig)
let client = FKNetworkClient(decoder: codec.makeDecoder())

// 若 API 有信封：
let envelopeInterceptor = FKResponseEnvelopeInterceptor(configuration: .standard)
// 注册到 FKNetworkConfiguration.responseInterceptors
```

### 15.2 FKResponseEnvelopeInterceptor

```swift
public struct FKResponseEnvelopeInterceptor: ResponseInterceptor {
  public init(configuration: FKResponseEnvelopeConfiguration)
  public func intercept(data: Data, response: HTTPURLResponse) throws -> Data
}
```

- 仅处理 **HTTP 2xx** body（与 Network 管道顺序文档化）；
- HTTP 非 2xx 时不解信封，由 Network 先失败。

### 15.3 Requestable 模型声明

保持现有模式：

```swift
struct FetchUserEndpoint: Requestable {
  typealias Response = User
  // ...
}
```

- `User` 的映射规则在 **模型定义处**（Wrapper / FKMappable）；
- Network **不** 内置业务 JSON 信封解析（设计文档 §FKNetwork 明确）。

### 15.4 Mock 数据

- `Requestable.mockData` 仍用 `Data`；
- Examples 用 `FKMappingFixture.json(named:)` 加载 bundle 资源。

---

## 16. 与 FKStorage / FileManager 集成

| 场景 | 建议 |
|------|------|
| UserDefaults / Keychain Codable | 注入与线上一致的 `FKJSONCodec` |
| `FKFileManager.readModel` / `writeModel` | v1.1 可选 overload 接受 `FKModelMappingConfiguration` |
| 缓存 DTO 与 API DTO 同构 | 同一 `User` 模型 + 同一 Configuration |

**禁止：** ModelMapping 直接依赖 Storage 类型（保持单向：Storage → 可选使用 Codec）。

---

## 17. 调试、日志与 Mock

### 17.1 FKMappingLogger（opt-in）

```swift
public protocol FKMappingLogging: Sendable {
  func didDecode(type: Any.Type, path: String?, duration: TimeInterval)
  func didFail(error: FKMappingError, preview: Data?)
}
```

- 默认 `FKNoOpMappingLogger`；
- Debug 实现可打印 **字段路径** 与 **payload 前 N 字节**（禁止默认开启）。

### 17.2 FKMappingFixture

```swift
public enum FKMappingFixture {
  public static func data(named name: String, bundle: Bundle = .main) -> Data
  public static func dictionary(named name: String, bundle: Bundle = .main) -> [String: Any]
}
```

- Examples 与单元测试（若未来添加）共用 JSON 资源；
- 资源放 `Examples/.../ModelMapping/Resources/`。

### 17.3 差异对比（Debug）

- `FKMappingDiff` 比较两个模型的 encoded JSON 键集合（v1.1）；
- v1 不阻塞交付。

---

## 18. 错误模型

### 18.1 FKMappingError

```swift
public enum FKMappingError: Error, Sendable {
  case invalidJSON(underlying: Error?)
  case invalidPath(path: String, reason: String)
  case keyNotFound(path: String)
  case typeMismatch(path: String, expected: String, actual: String)
  case valueNotFound(path: String)
  case businessFailure(code: Int, message: String?, payload: Data?)
  case decodingFailed(underlying: Error, codingPath: [String])
  case encodingFailed(underlying: Error)
  case nested(error: FKMappingError)
}
```

### 18.2 用户可见文案

- 经 **FKI18n**（`fkcore.mapping.error.*`）；
- `businessFailure` 的 `message` 优先服务端文案，fallback 本地化。

### 18.3 与 DecodingError 映射

| DecodingError | FKMappingError |
|---------------|----------------|
| `.keyNotFound` | `.keyNotFound` + codingPath |
| `.typeMismatch` | `.typeMismatch` |
| `.valueNotFound` | `.valueNotFound` |
| `.dataCorrupted` | `.invalidJSON` / nested |

---

## 19. 并发与 Swift 6

| 组件 | 策略 |
|------|------|
| `FKModelMappingConfiguration` | `Sendable` struct |
| `FKModelMapper` | `Sendable` struct 或 final class + 不可变 config |
| `JSONDecoder` / `Encoder` | 每操作新建（与 StorageCodec 一致） |
| `FKTransformRegistry` | 不可变快照或 `Mutex` 保护注册（prefer 启动期注册） |
| `@Sendable` closure Transform | 仅高级 API；文档化逃逸检查 |
| Verify | `SWIFT_STRICT_CONCURRENCY=complete` |

**禁止：** 全局可变 `DateFormatter` 无保护共享（使用 `FKDateFormatConfiguration` + 线程局部或 lock）。

---

## 20. 安全注意事项

- 解码 **不可信** JSON 时，限制嵌套深度与数组长度（可配置 `maxDepth` / `maxArrayCount`，默认 generous 但 finite）；
- 防止 ** billion laughs ** 式巨型数组导致 OOM — lenient 数组 cap；
- 日志禁止默认输出完整 payload（PII、token）；
- Base64 `Data` 解码需限制最大长度；
- **不** 在映射层执行 HTML/script 清洗 — 属业务/ WebView 层；
- 多态注册表禁止从 **不可信 type 字符串** 实例化任意类型（仅允许 preregistered 类型映射）。

---

## 21. v2 能力展望（非 v1 交付）

| 能力 | 说明 | 优先级 |
|------|------|--------|
| **Swift Macro `@FKAutoMappable`** | 编译期生成 Wrapper / Keys | 高 |
| **JSON Schema 校验** | decode 前 schema 校验 | 中 |
| **Codable + Dictionary 统一 IR** | 内部中间表示优化性能 | 中 |
| **`patch` 部分更新** | PATCH API 场景 | 中 |
| **Pluggable `FKJSONCodecProviding`** | DI 统一注入 | 中 |
| **PropertyList / NSDictionary** | 非 JSON 配置 | 低 |
| **AsyncSequence 流式 JSON** | 超大 JSON 分块 | 低 |
| **自动生成 Mock  from model** | 测试辅助 | 低 |

---

## 22. FKCoreKit 复用要求

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 宽松标量解析 | `FKValueParsing` | 复制 int/string/double 转换 |
| Decoder 预设 | `JSONDecoder.fk_applyCommonAPIDecodingDefaults()` | 重复 extension 逻辑 |
| Encodable 便利 | `Encodable.fk_jsonData()` 等（简单路径） | 平行 Error enum |
| 错误文案 | `FKI18n` | 硬编码用户可见英文 |
| Debug 日志 | `FKLogger` / `FKMappingLogging` | 裸 `print` |
| Network 解包 | `ResponseInterceptor` 协议 | 修改 `FKNetworkClient` 硬编码信封 |
| 字符串空白 | `String.fk_isBlank` | 自建 trim |

---

## 23. 公开 API 索引

| 分类 | 类型 |
|------|------|
| 门面 | `FKModelMapper`, `FKJSONCodec` |
| 配置 | `FKModelMappingConfiguration`, `FKResponseEnvelopeConfiguration` |
| 信封 | `FKResponseEnvelopeProcessor`, `FKResponseEnvelopeInterceptor` |
| Dictionary | `FKDictionaryMapper`, `FKMap`, `FKJSONObject`, `FKMappable` |
| Transform | `FKValueTransform`, `FKIntTransform`, `FKDateTransform`, `FKTransformRegistry` |
| Wrapper | `@FKMappedKey`, `@FKDefault`, `@FKTransform`, `@FKOptional`, `@FKLossyArray` |
| 多态 | `FKPolymorphicDecodable` |
| 模板 | `FKPage`, `FKListResponse`（可选） |
| 结果 | `FKMappingResult`, `FKMappingWarning` |
| 错误 | `FKMappingError` |
| 调试 | `FKMappingLogging`, `FKMappingFixture` |
| 桥接 | `FKMappingError.asNetworkError()`, `FKResponseEnvelopeInterceptor` |

---

## 24. 建议源码目录结构

```text
Sources/FKCoreKit/Components/ModelMapping/
├── Core/
│   ├── FKModelMapper.swift
│   ├── FKJSONCodec.swift
│   └── FKModelMappingConfiguration.swift
├── Codable/
│   ├── PropertyWrappers/
│   │   ├── FKMappedKey.swift
│   │   ├── FKDefault.swift
│   │   ├── FKTransform.swift
│   │   └── FKLossyArray.swift
│   └── FKDecodingError+Mapping.swift
├── Dictionary/
│   ├── FKDictionaryMapper.swift
│   ├── FKMap.swift
│   └── FKJSONObject.swift
├── Envelope/
│   ├── FKResponseEnvelopeConfiguration.swift
│   ├── FKResponseEnvelopeProcessor.swift
│   └── FKResponseEnvelopeInterceptor.swift
├── Transform/
│   ├── FKValueTransform.swift
│   ├── FKBuiltInTransforms.swift
│   ├── FKDateDecodingStrategy.swift
│   └── FKTransformRegistry.swift
├── Polymorphic/
│   └── FKPolymorphicDecodable.swift
├── Model/
│   ├── FKMappingError.swift
│   ├── FKMappingWarning.swift
│   └── FKPage.swift
├── Support/
│   ├── FKMappingFixture.swift
│   └── FKMappingLogging.swift
├── Bridge/
│   └── FKMappingError+Network.swift
└── README.md
```

> 目录为 **建议架构**；实现时可按 [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) 组件目录规范灵活调整，**必须在 README 中文档化最终结构**。

---

## 25. FKKitExamples 场景

路径建议：`Examples/FKKitExamples/FKKitExamples/Examples/FKCoreKit/ModelMapping/`

| # | 场景 | 验证点 |
|---|------|--------|
| M1 | `StandardCodable` | 标准 JSON ↔ 模型 |
| M2 | `SnakeCaseAPI` | KeyStrategy + Network 注入 |
| M3 | `MappedKeys` | `@FKMappedKey` 重命名与嵌套路径 |
| M4 | `LenientNumbers` | `"123"` → Int，`""` → nil |
| M5 | `DateFormats` | ISO8601 + 自定义 format |
| M6 | `ResponseEnvelope` | code/msg/data 解包 + 业务失败 |
| M7 | `DictionaryMapping` | `[String: Any]` 直映射 |
| M8 | `ManualFKMappable` | 条件映射 / 多键合并 |
| M9 | `PolymorphicArray` | discriminator 多态 |
| M10 | `EncodeToSnake` | 模型 → 请求 body JSON |
| M11 | `NetworkIntegration` | Client + Interceptor + Endpoint |
| M12 | `StrictVsLenient` | 同一 JSON 两种模式对比 |

Hub 卡片：**Model Mapping** — 列出上述场景；每场景展示输入 JSON（pretty）与输出模型摘要。

---

## 26. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **MM0** | `FKJSONCodec` + Configuration + Error | Codable 路径 + Network decoder 注入 |
| **MM1** | Property Wrappers + Built-in Transforms | 非标准字段覆盖 80% |
| **MM2** | Envelope + Interceptor | 国内常见 API 信封 |
| **MM3** | Dictionary Mapper + FKMappable | 动态 Payload |
| **MM4** | Polymorphic + FKPage 模板 | 列表/多态 |
| **MM5** | Examples M1–M12 + README + 根索引 | 发布卫生 |

每阶段：`xcodebuild` → `CHANGELOG` → Examples 可演示。

---

## 27. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 模块命名 `FKModelMapping` vs `FKJSONMapping`？ | **`FKModelMapping`**（涵盖未来非 JSON IR） |
| Q2 | `@FKMappedKey` 嵌套路径 encode 是否写回嵌套结构？ | **是** — 保持对称 |
| Q3 | lenient 下非 Optional 标量失败默认值？ | **throw**（lenient 仅放宽 **类型转换**，不伪造零值） |
| Q4 | `FKModelMapper.shared` 默认 configuration？ | `.lenientAPI` |
| Q5 | 业务失败用 `FKMappingError` 还是仅 `NetworkError`？ | Repository 层捕获 Mapping → `asNetworkError()` |
| Q6 | Dictionary 路径与 Codable 自动选择？ | 显式 API；不自动猜测 |
| Q7 | v1 是否包含 `FKJSONObject`？ | 可选；优先 `[String: Any]` 降低 surface |
| Q8 | 是否提供 Tests Target？ | 默认否；Examples + Fixture 为主 |
| Q9 | Macro 是否进入 v1？ | **否** — v2 |
| Q10 | 与 `Dictionary.fk_decodeJSON` 关系？ | 保留；README 标记 legacy 便捷 API |

---

## 28. 修订历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1 | 2026-06-17 | 初稿：模块边界、双路径映射、信封、Transform、Network 集成、Examples 与交付计划 |

---

## 29. 相关文档

| 文档 | 关系 |
|------|------|
| [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md) | HTTP 管道、`ResponseInterceptor`、decoder 注入 |
| [FKNetwork_ENHANCEMENT_DESIGN.md](FKNetwork_ENHANCEMENT_DESIGN.md) | Mock Session 与解码联调 |
| [FKFileManager_DESIGN.md](FKFileManager_DESIGN.md) | `readModel` / `writeModel` Codable |
| [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) | 可选 `FKJSONCodecProviding` |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | 优先级与目录规范 |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | 基础设施缺口 |
| `Sources/FKCoreKit/Components/Extension/` | `FKValueParsing`、`JSONDecoder+`、`Encodable+` |
