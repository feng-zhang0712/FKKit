# FKImageLoader 与 FKImageView — 设计需求文档

FKKit 图片加载栈的实现指导文档：**FKCoreKit** 中的默认 `FKImageLoading` / `FKImageCaching` 实现，以及 **FKUIKit** 中的 **`FKImageView`** UI 组件。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.1  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. FKImageLoader — 功能需求](#6-fkimageloader--功能需求)
- [7. FKImageLoader — 缓存需求](#7-fkimageloader--缓存需求)
- [8. FKImageLoader — 并发与线程](#8-fkimageloader--并发与线程)
- [9. FKImageLoader — 配置与 API 面](#9-fkimageloader--配置与-api-面)
- [10. FKImageLoader — 错误模型与可观测性](#10-fkimageloader--错误模型与可观测性)
- [11. FKImageView — 状态机](#11-fkimageview--状态机)
- [12. FKImageView — 视觉与布局能力](#12-fkimageview--视觉与布局能力)
- [13. FKImageView — 加载生命周期](#13-fkimageview--加载生命周期)
- [14. FKImageView — 占位、进度、失败与重试](#14-fkimageview--占位进度失败与重试)
- [15. FKImageView — 与现有 FKUIKit 集成](#15-fkimageview--与现有-fkuikit-集成)
- [16. FKImageView — 列表与 Cell 复用行为](#16-fkimageview--列表与-cell-复用行为)
- [17. FKImageView — 交互与手势](#17-fkimageview--交互与手势)
- [18. FKImageView — 无障碍](#18-fkimageview--无障碍)
- [19. FKImageView — 配置与 API 面](#19-fkimageview--配置与-api-面)
- [20. SwiftUI 桥接](#20-swiftui-桥接)
- [21. 全局默认值与依赖注入](#21-全局默认值与依赖注入)
- [22. 性能与资源预算](#22-性能与资源预算)
- [23. 安全与隐私](#23-安全与隐私)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [27. 待决问题](#27-待决问题)
- [28. 修订历史](#28-修订历史)

---

## 1. 概述

FKKit 在 Pluggable 中已定义 **`FKImageLoading`** 与 **`FKImageCaching`**，但**未提供默认实现**，也**没有可复用的图片视图**。因此，每个信息流、头像、Banner、商品图场景都要重复实现 URLSession 拉取、缓存 Key、降采样、占位、取消与失败 UI。

本设计规定两个交付物：

| 交付物 | 模块 | 职责 |
|--------|------|------|
| **`FKImageLoader`** | FKCoreKit | `FKImageLoading` + `FKImageCaching` 的生产级默认实现：网络/本地读取、解码、降采样、内存+磁盘缓存、请求合并、取消。 |
| **`FKImageView`** | FKUIKit | 配置驱动的视图，将加载状态绑定到 UI：占位、可选骨架屏、过渡动画、失败/重试、样式、无障碍、SwiftUI 桥接。 |

Loader 必须在 App 组合根**可替换**；View **不得**硬编码 Kingfisher/SDWebImage 或任何第三方 SDK。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **补齐 Pluggable 空洞** — 提供集成方可开箱即用、也可替换的 `FKImageLoader` 参考实现。
2. **覆盖 80% 场景** — 列表与详情中的远程 HTTPS 图片，复用与取消行为正确。
3. **对齐 FKKit 模式** — 分层 `Sendable` 配置、`@MainActor` UI、英文文档、FKKitExamples 全覆盖、复用 `FKAsync` / Extension / 邻域组件。
4. **生产级默认行为** — 有界内存、磁盘淘汰、大图不在主线程解码、错误类型明确。
5. **可组合** — `FKImageView` 可独立使用；`FKImageLoader` 可不依赖 View 单独用于预取与编程式加载。

### 2.2 非目标（v1）

- GIF/APNG/WebP 动画播放（仅静态 `UIImage`，除非系统解码器原生支持该格式）。
- 图片编辑流水线（滤镜、裁剪 UI、标注）。
- 完整图片浏览器 / 缩放画廊（留给未来 `FKCarousel` 或独立组件）。
- SVG / PDF 矢量渲染。
- 第三方 CDN 专用 URL 变换（Cloudinary 类）— 宿主可在传入 FKKit 前预处理 URL。
- 使用 Background URLSession 做离线图库（请用 `FKFileManager` / `FKNetwork`）。
- tvOS / macOS 产品目标（本组件仅 iOS 15+ UIKit）。

### 2.3 成功标准

实现完成当且仅当：

- [ ] `FKImageLoader` 遵循 `FKImageLoading`、`FKImageCaching`，满足 §6–10 行为。
- [ ] `FKImageView` 实现 §11–19，并交付 `FKImageViewRepresentable`。
- [ ] 列表快速滚动场景：取消过期加载，**不出现错图**（身份校验）。
- [ ] 压力场景下内存缓存遵守配置的成本上限。
- [ ] FKKitExamples Hub 覆盖 §25 中每项主要能力。
- [ ] 组件 README（含目录说明）；根 README 索引已更新。

---

## 3. 背景与问题陈述

### 3.1 现状

`Sources/FKCoreKit/Components/Pluggable/Media/FKImageLoading.swift` 定义：

- `FKImageLoadRequest` — `url`、可选 `targetWidth` / `targetHeight`、可选 `cacheKey`。
- `FKImageLoading` — `loadImage(for:)` async throws、`cancelLoad(for:)`。
- `FKImageCaching` — 按字符串 Key 的 get/store/remove/removeAll。

**仓库内无任何类型实现上述协议。**

`FKCoreKit/Extension/UIKit/UIImage.swift` 提供缩放、着色、圆角、裁剪、JPEG 等辅助 — Loader/View **必须复用**，禁止重复实现位图工具。

`FKSkeleton` 对 `UIImageView` 有便利 API — `FKImageView` **可**在配置启用时将加载闪烁委托给 Skeleton 叠加层。

### 3.2 用户痛点

| 痛点 | 频率 | 无 FKKit 时 |
|------|------|-------------|
| 复用 Cell 显示错图 | 极高 | 手动请求 Token / URL 身份校验 |
| 滚 feed 内存暴涨 | 高 | 无界缓存或全尺寸解码 |
| 重复网络请求 | 高 | 每屏各自维护 in-flight 映射 |
| 占位/失败 UI 不一致 | 高 | 各业务线各写一套 |
| 无法单测或替换 CDN 策略 | 中 | VC 内直接 URLSession |

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ App 组合根                                                      │
│   var imageLoader: any FKImageLoading = FKImageLoader.shared      │
└────────────────────────────┬────────────────────────────────────┘
                             │ 注入
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ FKImageView（FKUIKit，@MainActor）                              │
│   状态机 · 占位 · 重试 · 样式 · 无障碍                          │
└────────────────────────────┬────────────────────────────────────┘
                             │ FKImageLoadRequest
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ FKImageLoader（FKCoreKit）                                      │
│   合并 · 拉取 · 解码/降采样 · 内存缓存 · 磁盘                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         URLSession    FileManager      NSCache + 磁盘索引
         (remote)      (file://)        (FKImageDiskCache)
```

**数据流**

1. 宿主设置 `url`（及可选 `targetSize`）。
2. View 按布局策略计算有效目标尺寸（如 `layoutSubviews` 后）。
3. View 构建 `FKImageLoadRequest`（缓存 Key 策略来自配置）。
4. 若启用，经 Loader/Cache 协议同步查询内存缓存预览。
5. View 通过注入的 `FKImageLoading` 发起异步加载。
6. 成功时，**校验请求身份**（URL/Key/尺寸）仍与当前一致后再设置 `UIImage`。
7. 失败时，按配置进入失败 UI。

---

## 5. 模块边界

| 关注点 | FKCoreKit（`FKImageLoader`） | FKUIKit（`FKImageView`） |
|--------|------------------------------|--------------------------|
| URLSession / 文件读取 | 是 | 否 |
| 解码与降采样 | 是 | 否 |
| 内存 + 磁盘缓存 | 是 | 否 |
| 进行中请求合并 | 是 | 否 |
| UIView 层级 | 否 | 是 |
| 占位 / 失败层 | 否 | 是 |
| 圆角、边框、阴影 | 否（可预处理 UIImage） | 是（视图层 + 可选预处理） |
| Skeleton 闪烁 | 否 | 是（经 `FKSkeleton`） |
| SwiftUI Representable | 否 | 是 |
| VoiceOver 呈现 | 否 | 是 |

**依赖规则：** `FKImageView` 仅 import `FKCoreKit`、`FKUIKit`；`FKImageLoader` **不得** import `FKUIKit`。

### 5.1 FKCoreKit 复用要求（强制）

`FKImageLoader` 位于 **FKCoreKit**；实现时**必须**复用 Pluggable 契约与 Extension，**禁止**在 Loader/View 内重复位图与缓存工具：

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 加载协议 | **`FKImageLoading`**、**`FKImageCaching`**（Pluggable） | 平行协议 |
| 位图操作 | **`UIImage.fk_*`**（`FKCoreKit/Extension/UIKit/UIImage.swift`） | FKUIKit 内复制 |
| 并发/合并 | **`FKAsync`**、请求 dedup 模式（参考 Network） | 无取消加载 |
| 磁盘路径 | **`FKFileManager`** 惯例 / Storage 工具 | 硬编码 Caches 路径 |

**禁止**在 FKUIKit 重复实现 `UIImage.fk_*` — 预处理位图走 FKCoreKit Extension（见 §15）。

---

## 6. FKImageLoader — 功能需求

### 6.1 加载来源

Loader **必须**支持：

| 来源 | 协议/输入 | 行为 |
|------|-----------|------|
| 远程 HTTP/HTTPS | `https://`、`http://` | `URLSession.data(for:)`（或配置中的共享 Session） |
| 本地文件 | `file://` | 在解码队列同步读盘，不走网络 |
| 已存在本地路径 | 指向已有文件的 `URL` | 同文件 |
| 内存缓存命中 | — | 无 I/O 立即返回 |
| 磁盘缓存命中 | — | 后台读 Data，解码队列解码 |

v1 **不得**拉取非 file / 非 http(s) 协议；应返回类型化错误（如 `FKImageLoaderError.unsupportedURLScheme`）。

### 6.2 请求身份与缓存 Key

当 `FKImageLoadRequest.cacheKey == nil` 时，**默认缓存 Key**：

```text
{absoluteURLString}|w={targetWidth}|h={targetHeight}
```

- 尺寸使用稳定字符串格式（如 `%g` 或固定小数位）。
- 某维度为 `nil` 时省略对应段（全尺寸桶）。

**自定义 cacheKey** — 由集成方提供时，内存与磁盘映射均使用该 Key（集成方保证唯一性）。

### 6.3 进行中请求合并（去重）

多个并发调用方请求**相同缓存 Key** 时：

- 底层仅 **一次** fetch/decode。
- 所有调用方 await 同一 `Task` 结果。
- 某调用方 cancel 时，按 **调用方 Token** 处理（§6.5）；推荐策略：**共享 Task 继续**，直到所有等待者均取消才中止底层 URLSession。

### 6.4 解码与降采样

**必须：**

- 解码不在主线程（专用串行或限并发解码队列）。
- 当设置 `targetWidth` / `targetHeight` 时，在或于解码过程中降采样，使峰值内存 ≈ 目标像素缓冲，而非源图全尺寸。
- 优先 `CGImageSource` 增量/降采样 API；必要时才 decode 后 `fk_resized(to:)`。
- `UIImage.scale` 与屏幕 scale 一致（已知时用主屏 scale；可配置默认 scale）。
- 尊重 EXIF 方向（输出用于展示的正向 `UIImage`）。

**应当：**

- 仅设 `targetWidth` 或仅设 `targetHeight` 时，从元数据按比例推算另一维。
- 非正目标尺寸 → 校验错误。

### 6.5 取消

`cancelLoad(for request:)` **必须**：

- 按解析后的 cache key 取消。
- 无其他合并等待者时，取消关联 `URLSessionDataTask`。
- 已取消的等待者不得再收到结果（structured concurrency 取消检查）。

`loadImage(for:)` **必须**响应 `Task.isCancelled`，抛出 `CancellationError` 或 `FKImageLoaderError.cancelled`。

### 6.6 HTTP 行为

配置 **必须**暴露：

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `URLSessionConfiguration` 或共享 Session | `.default` ephemeral | 可注入 Cookie/鉴权 |
| 单次请求超时 | 60s | 可调 |
| `URLRequest.CachePolicy` | `.useProtocolCachePolicy` | |
| 可选 HTTP 头 | `[:]` | Auth、User-Agent |
| 可接受状态码 | 2xx | 其余映射 HTTP 错误 |

**应当**支持可选 `FKNetworkReachability` 预检（注入闭包或 Provider）— 离线时快速失败 `FKImageLoaderError.offline`，不启动 URLSession（配置 opt-in）。

### 6.7 本地文件行为

- 后台队列读文件。
- 与网络相同的解码/降采样路径。
- 文件不存在 → `FKImageLoaderError.fileNotFound`。
- 无权限 → `FKImageLoaderError.fileReadFailed`。

### 6.8 预取 API

Loader 提供不依赖 View 的显式预取：

```swift
func prefetch(_ request: FKImageLoadRequest) async
func prefetch(urls: [URL], targetSize: CGSize?) async
```

- 仅填充缓存，不回调 UI。
- 遵守缓存上限，与进行中加载合并。
- v1 可选 `cancelPrefetch(for:)`（范围紧时可延后）。

### 6.9 仅查缓存

支持同步内存读取以便 UI 瞬时展示：

```swift
func cachedImage(for request: FKImageLoadRequest) -> UIImage?
```

按解析 Key 查内存；可选同步读盘（配置项，默认 **仅内存**，避免主线程 I/O — 若允许同步读盘，文档禁止在主线程调用）。

### 6.10 Pluggable 一致性

`FKImageLoader` **必须**遵循：

- `FKImageLoading`
- `FKImageCaching`（缓存关闭时 store/get 为 no-op / nil）

支持 **关闭缓存**（`FKImageLoaderConfiguration.isCachingEnabled = false`）。

---

## 7. FKImageLoader — 缓存需求

### 7.1 内存缓存

**必须：**

- `NSCache` 或等价实现，**总成本**与**数量**上限来自配置。
- 成本函数默认：`pixelWidth * pixelHeight * 4`（RGBA 字节），可覆盖。
- 线程安全（锁或队列）；协议 `@MainActor` 表面可委托内部 actor。
- `removeImage(forKey:)`、`removeAllImages()` 清除内存项。

**默认配置（起点，可调）：**

| 参数 | 默认 |
|------|------|
| `memoryCostLimit` | 100 MB |
| `memoryCountLimit` | 200 |

### 7.2 磁盘缓存

**必须：**

- 在 Caches 子目录（如 `FKImageLoader/DiskCache/`）存原始字节（网络收到的 Data；JPEG/PNG 原样）。
- 文件名：SHA256(cacheKey) 或安全哈希 — 对齐 `FKFileStorage` 命名规范。
- 轻量索引（内存 + 可选 JSON）用于枚举与淘汰。
- **磁盘总大小**上限与**条目 TTL**（可选）。
- 超预算时 LRU 或近似 LRU 淘汰。
- `removeAllImages()` 清内存 + 磁盘。
- 磁盘 I/O 仅后台队列。

**默认配置：**

| 参数 | 默认 |
|------|------|
| `diskSizeLimit` | 200 MB |
| `diskEntryTTL` | 7 天（可选） |

### 7.3 单请求缓存策略（可选扩展）

可在实现中扩展 `FKImageLoadRequest` 或并行类型（若改 Pluggable 需单独 semver 决策）：

| 策略 | 行为 |
|------|------|
| `.default` | 内存 → 磁盘 → 网络 |
| `.reloadIgnoringCache` | 跳过读缓存；成功后仍写入 |
| `.cacheOnly` | 未命中则失败 |

若 v1 不改 Pluggable 请求体，可用并行 API：

```swift
func loadImage(for request: FKImageLoadRequest, options: FKImageLoadOptions) async throws -> UIImage
```

实现 PR 中记录决策。

### 7.4 淘汰与内存警告

**必须**监听 `UIApplication.didReceiveMemoryWarningNotification`（优先用现有 Extension 辅助），裁剪内存缓存。

**应当**暴露 `trimMemoryCache(toCost:)` 供宿主手动调用。

---

## 8. FKImageLoader — 并发与线程

| 操作 | 线程 |
|------|------|
| `loadImage` 入口 | 协议 `@MainActor`；跳转到内部 actor |
| URLSession 回调 | Session 队列 → 内部 |
| 磁盘读写 | 串行后台队列 |
| 解码/降采样 | 限并发后台队列（建议 max 3–4） |
| NSCache | 锁保护 |
| 恢复 awaiter | 协议要求时在 `@MainActor` resume |

**Swift 6：** 内部状态用 `actor FKImageLoaderEngine` 或 class+锁；公开 `FKImageLoader` 标 `@MainActor` 对齐 Pluggable。

**无循环引用：** Task 弱引用 Loader；View 注入 Loader，避免强单例环。

---

## 9. FKImageLoader — 配置与 API 面

### 9.1 核心类型（规范命名）

```swift
// FKCoreKit — Components/ImageLoader/

public struct FKImageLoaderConfiguration: Sendable, Equatable { ... }

public enum FKImageLoaderError: Error, Sendable, Equatable {
  case unsupportedURLScheme(String)
  case invalidTargetDimensions
  case httpStatus(code: Int)
  case network(underlying: Error)
  case decodeFailed
  case fileNotFound
  case fileReadFailed
  case offline
  case cancelled
  case cacheMissUnderCacheOnlyPolicy
}

@MainActor
public final class FKImageLoader: FKImageLoading, FKImageCaching {
  public static let shared: FKImageLoader
  public var configuration: FKImageLoaderConfiguration
  public init(configuration: FKImageLoaderConfiguration = .init())
  // 协议方法 + prefetch + trim API
}
```

### 9.2 配置字段（最低集）

| 字段 | 类型 | 用途 |
|------|------|------|
| `memoryCostLimit` | Int | NSCache 成本上限 |
| `memoryCountLimit` | Int | NSCache 数量上限 |
| `diskSizeLimit` | Int | 字节 |
| `diskEntryTTL` | TimeInterval? | 可选过期 |
| `isCachingEnabled` | Bool | 开关缓存 |
| `sessionConfiguration` | URLSessionConfiguration | 或回调 Provider |
| `defaultHeaders` | [String: String] | HTTP 头 |
| `requestTimeout` | TimeInterval | 单次超时 |
| `maxConcurrentDecodes` | Int | 背压 |
| `reachabilityFastFail` | Bool | 离线快速失败 |
| `diskCacheDirectoryURL` | URL? | 覆盖目录 |

通过 `configuration` 或 `apply(_:)` 更新，对齐邻域组件。

---

## 10. FKImageLoader — 错误模型与可观测性

### 10.1 错误映射

底层 `Error` 不可 equatable 时，使用分类 case（§9.1）。

### 10.2 日志（可选）

**应当**在 Debug 级对接 `FKLogger`：

- 缓存命中/未命中（内存/磁盘）
- 拉取开始/完成/取消
- 淘汰事件

日志中**不得**出现 URL 凭证或 Auth 头。

### 10.3 指标钩子（可选）

```swift
var onEvent: (@Sendable (FKImageLoaderEvent) -> Void)?
```

事件：`.cacheHit(level:)`、`.fetchStarted`、`.fetchCompleted(duration:)`、`.fetchFailed`、`.evicted(count:)`。

默认 `nil`（零开销）。

---

## 11. FKImageView — 状态机

### 11.1 状态

```swift
public enum FKImageViewState: Equatable, Sendable {
  case idle           // 未设 URL 或已清空
  case placeholder    // 已设 URL，仅占位（缓存未命中且尚未加载）
  case loading        // 加载中；可叠占位与 skeleton/进度
  case success(UIImage)
  case failure(FKImageViewFailureReason)
}

public enum FKImageViewFailureReason: Equatable, Sendable {
  case network
  case decode
  case cancelled
  case offline
  case custom(message: String?)
}
```

### 11.2 状态转移

| 自 | 事件 | 至 |
|----|------|-----|
| idle | 设置 `url` | placeholder 或 loading（缓存命中 → success） |
| placeholder | 开始加载 | loading |
| loading | 成功且身份匹配 | success |
| loading | 失败 | failure |
| loading | url 变更 / 取消 | placeholder（新 url）或 idle |
| success | url 变更 | placeholder → loading |
| failure | 点击重试 | loading |
| 任意 | `url = nil` | idle |

**身份规则：** 写入图层前校验 `currentLoadToken` 或 `(url, cacheKey, targetSize)` 三元组；不匹配则丢弃结果（仅 Debug 日志）。

### 11.3 对外状态

- `public private(set) var state: FKImageViewState`
- 可选 `var onStateChange: (@MainActor (FKImageViewState) -> Void)?`

---

## 12. FKImageView — 视觉与布局能力

### 12.1 图片呈现

**必须支持：**

| 能力 | 说明 |
|------|------|
| `contentMode` | 完整 `UIView.ContentMode` |
| `clipsToBounds` | 圆角 > 0 时默认 `true` |
| `tintColor` / 模板渲染 | 单色图标可选模板模式 |
| 高亮变暗 | 可点击图可选按下变暗 |
| `preferredImageDynamicRange` | iOS 17+ 可用时透传 |

### 12.2 圆角

**必须支持（配置驱动）：**

| 模式 | 行为 |
|------|------|
| `.none` | 直角 |
| `.fixed(CGFloat)` | 统一半径 |
| `.capsule` | min(w,h)/2 |
| `.perCorner(UIRectCorner, radius)` | 部分圆角 |

可用 layer `cornerRadius` + `maskedCorners`，或与 `FKCornerShadow` 共配边框/阴影时用 mask。

### 12.3 边框

复用 `FKLayerBorderStyle` 或对齐 `FKButton`：颜色、线宽、对齐方式。

### 12.4 阴影

可选 `FKLayerShadowStyle` 于外层容器；图片内层裁剪。

### 12.5 背景

`scaleAspectFit` 时 letterbox 区域可见背景色/图。

### 12.6 成功过渡动画

| 过渡 | 说明 |
|------|------|
| `.none` | 立即显示 |
| `.crossDissolve(duration:)` | UIView 过渡 |
| `.fadeIn(duration:)` | 透明度动画 |

默认 `.crossDissolve(0.2)`；`UIAccessibility.isReduceMotionEnabled` 时强制 `.none`。

### 12.7 固有尺寸

- 无固定约束时：由图片或占位提示决定 intrinsic size。
- 支持 content hugging / compression resistance，行为类似 `UIImageView`。

---

## 13. FKImageView — 加载生命周期

### 13.1 公开加载 API

```swift
public var url: URL? { get set }
public var image: UIImage? { get }
public func load(url: URL?, placeholder: UIImage? = nil)
public func cancelLoad()
public func reload() // 按策略忽略内存重新拉取
public func reset() // 清空 url、image，回到 idle
```

`loadsAutomatically` 默认 `true` 时，设置 `url` 即触发加载。

### 13.2 目标尺寸策略

| 策略 | 计算时机 |
|------|----------|
| `.automaticFromBounds` | layout 后；bounds × screen scale |
| `.explicit(CGSize)` | 宿主指定 |
| `.none` | 全分辨率（远程不推荐；文档性能警告） |

自动策略下，bounds 变化超过阈值（如 10%）应重新加载。

### 13.3 Loader 注入

```swift
public var imageLoader: (any FKImageLoading)?
```

默认 `FKImageLoader.shared`；CDN 客户端或其他实现可替换。

### 13.4 视图层级生命周期

- `willMove(toWindow:)` — 可选离屏暂停（v1 默认 `pausesLoadingWhenOffscreen = false`）。
- `deinit` — 取消进行中的 load token。

---

## 14. FKImageView — 占位、进度、失败与重试

### 14.1 占位

配置支持：

| 占位类型 | 支持 |
|----------|------|
| 静态 `UIImage` | 是 |
| 纯色 | 是 |
| SF Symbol | 是 |
| 首字母 + 字体/颜色 | 是（头像） |
| 自定义 `UIView` Provider | 可选高级插槽 |

显示于：`idle`（可选）、`placeholder`、`loading`（进度/skeleton 之下）。

### 14.2 进度指示

| 模式 | UI |
|------|-----|
| `.none` | 默认 |
| `.activityIndicator` | 居中菊花 |
| `.linearProgress(...)` | 底边细条（可接 `FKProgressBar`） |

v1 仅**不确定**进度；字节级进度后续版本。

### 14.3 Skeleton 集成

`loadingPresentation.includesSkeleton == true` 时：

- 对图片区域 `fk_showSkeleton` 或使用 `FKSkeletonPresets` 形状。
- 图片 cross-dissolve 前隐藏 skeleton。
- `reset()` / 复用后不得残留 skeleton 层。

### 14.4 失败呈现

| 元素 | 要求 |
|------|------|
| 失败图标 | 可配 SF Symbol / 图片 |
| 文案 | 可选短文本（`FKUIKitI18n` + 自定义） |
| 重试 | `isRetryEnabled` 时按钮或点击图区域 |
| 离线 | `failureReason == .offline` 时用 i18n 文案 |

### 14.5 重试

- 点击或 `retry()` → `loading`；按配置用 `reloadIgnoringCache` 或普通加载。
- 重试点击防抖 300ms。

---

## 15. FKImageView — 与现有 FKUIKit 集成

| 组件 | 集成方式 |
|------|----------|
| **FKSkeleton** | 加载闪烁；`UIView+FKSkeleton` |
| **FKCornerShadow** | 可选圆角+阴影容器 |
| **FKProgressBar** | 可选底边进度 |
| **FKButton** | 可选重试按钮样式 |
| **FKBadge** | v1 不在 View 内；Examples 文档化头像角标叠加 |
| **FKBlurView** | v1 不要求 |
| **FKUIKitI18n** | 失败/重试文案 |

**禁止**在 FKUIKit 重复实现 `UIImage.fk_*` — 预处理位图走 FKCoreKit Extension。

---

## 16. FKImageView — 列表与 Cell 复用行为

### 16.1 要求

**必须：**

- 公开 `resetForReuse()`：清 url、取消加载、回占位、移除 skeleton/进度。
- 变更 `url` 时在主线程**同步**取消旧 token 再启新加载。
- **绝不**展示与当前 `url` 不符的图片。

### 16.2 UITableView / UICollectionView

文档示例（不必提供子类）：

```swift
override func prepareForReuse() {
  super.prepareForReuse()
  imageView.resetForReuse()
}
```

### 16.3 预取

文档说明配合 `UITableViewDataSourcePrefetching`：

- `prefetchItemsAt` → `FKImageLoader.prefetch`
- `cancelPrefetchingForItemsAt` → `cancelPrefetch`（若已实现）

---

## 17. FKImageView — 交互与手势

| 特性 | v1 |
|------|-----|
| 点击回调 | 可选 `onTap` |
| 失败重试点击 | 启用时必须 |
| 长按 | v1 不做 |
| 按下高亮 | 可选透明度动画 |

`UIControl` 子类或 `UIView` + 点击手势均可；若用 `UIView`，须保证无障碍可激活。

---

## 18. FKImageView — 无障碍

**必须：**

- `accessibilityLabel` 来自配置或宿主 `accessibilityImageDescription`。
- `loading` 时可选在加载完成发 `UIAccessibilityLayoutChangedNotification`（默认 false，避免噪音）。
- 失败态：`accessibilityHint` 提示可重试。
- 纯装饰占位：`accessibilityElementsHidden = true`（宿主标记 decorative 时）。
- 失败文案支持 Dynamic Type；图片内容本身不适用 Dynamic Type。

**Traits：** 成功 `.image`；可重试 `.button`。

---

## 19. FKImageView — 配置与 API 面

### 19.1 分层配置（对齐 FKButton / FKEmptyState）

```swift
public struct FKImageViewConfiguration: Sendable, Equatable {
  public var appearance: FKImageViewAppearanceConfiguration
  public var loading: FKImageViewLoadingConfiguration
  public var failure: FKImageViewFailureConfiguration
  public var layout: FKImageViewLayoutConfiguration
  public var accessibility: FKImageViewAccessibilityConfiguration
  public var interaction: FKImageViewInteractionConfiguration
}

public enum FKImageViewDefaults {
  public static var defaultConfiguration: FKImageViewConfiguration
}
```

### 19.2 外观配置

| 字段 | 说明 |
|------|------|
| `cornerStyle` | §12.2 |
| `borderStyle` | 可选 |
| `shadowStyle` | 可选 |
| `backgroundColor` | Letterbox 填充 |
| `contentMode` | 默认 `.scaleAspectFill` |
| `successTransition` | §12.6 |
| `tintColor` | 模板图 |

### 19.3 加载配置

| 字段 | 说明 |
|------|------|
| `placeholder` | 图/色/Symbol/首字母 |
| `targetSizePolicy` | §13.2 |
| `loadsAutomatically` | 默认 true |
| `loadingPresentation` | 进度模式、skeleton 开关 |
| `cachePolicy` | 单 View 覆盖（若支持） |

### 19.4 失败配置

| 字段 | 说明 |
|------|------|
| `isRetryEnabled` | 默认 true |
| `icon` | SF Symbol |
| `message` | 可选 |
| `retryButtonTitle` | nil 表示点击图片重试 |

### 19.5 便捷 API

```swift
public final class FKImageView: UIView {
  public var configuration: FKImageViewConfiguration { get set }
  public func apply(_ configuration: FKImageViewConfiguration)
  public func apply(_ block: (inout FKImageViewConfiguration) -> Void)
}
```

---

## 20. SwiftUI 桥接

在 `FKUIKit/Components/ImageView/Public/Bridge/` 交付 **`FKImageViewRepresentable`**：

```swift
public struct FKImageViewRepresentable: UIViewRepresentable {
  public var url: URL?
  public var configuration: FKImageViewConfiguration
  public var onStateChange: ((FKImageViewState) -> Void)?
}
```

**必须**在 `updateUIView` 中响应 url/配置变化。

可选 **`FKAsyncImage`** 风格封装（v1 加分项；Representable 为必选项）。

---

## 21. 全局默认值与依赖注入

### 21.1 进程级默认

```swift
public enum FKImageViewDefaults {
  public static var defaultConfiguration: FKImageViewConfiguration
  public static var sharedImageLoader: any FKImageLoading
}
```

App 启动时在主线程修改一次。

### 21.2 组合根示例

```swift
FKImageLoader.shared.configuration.memoryCostLimit = 80 * 1024 * 1024
FKImageViewDefaults.sharedImageLoader = FKImageLoader.shared
FKImageViewDefaults.defaultConfiguration.appearance.cornerStyle = .fixed(8)
```

自定义 Loader：

```swift
final class CDNImageLoader: FKImageLoading { ... }
imageView.imageLoader = CDNImageLoader()
```

---

## 22. 性能与资源预算

| 指标 | 目标 |
|------|------|
| 主线程解码 | 网络/文件 payload **禁止** |
| 默认内存缓存 | 100 MB（可配） |
| 默认磁盘缓存 | 200 MB |
| 相同 Key 并发 | 仅 1 次网络请求 |
| 复用错图率 | Examples 压测为 0 |
| 首帧占位 | 设 url 后主线程 < 1 帧 |

**滚动：** 50+ 可见+预取 Cell 不得突破并发解码上限。

---

## 23. 安全与隐私

- **默认 HTTPS** — http 仅当宿主显式使用 http URL。
- **禁止日志** Authorization、Cookie、签名 Query。
- **file URL** — 不跟随指向沙盒外的 symlink。
- **ATS** — 尊重宿主 ATS 配置。
- **敏感图** — v1 文档说明：鉴权 URL 用自定义 cacheKey + 禁用磁盘或全局钩子；后续可加 per-request `excludesFromDiskCache`。

---

## 24. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

### FKCoreKit

```text
Sources/FKCoreKit/Components/ImageLoader/
├── README.md
├── Public/
│   ├── FKImageLoader.swift
│   ├── FKImageLoaderConfiguration.swift
│   ├── FKImageLoaderError.swift
│   ├── FKImageLoadOptions.swift
│   └── FKImageLoaderEvent.swift
├── Internal/
│   ├── FKImageLoaderEngine.swift
│   ├── FKImageMemoryCache.swift
│   ├── FKImageDiskCache.swift
│   ├── FKImageDecoder.swift
│   └── FKImageCacheKeyBuilder.swift
└── Extension/
    └── FKImageLoader+Prefetch.swift
```

`Package.swift` 的 `readmeExcludes` 增加 `Components/ImageLoader`。

### FKUIKit

```text
Sources/FKUIKit/Components/ImageView/
├── README.md
├── Public/
│   ├── FKImageView.swift
│   ├── FKImageViewState.swift
│   ├── Configuration/...
│   └── Bridge/FKImageViewRepresentable.swift
├── Internal/
│   ├── FKImageViewLoadCoordinator.swift
│   ├── FKImageViewPlaceholderView.swift
│   └── FKImageViewFailureView.swift
└── Extension/FKImageView+Convenience.swift
```

---

## 25. FKKitExamples 场景

路径：`Examples/FKKitExamples/.../FKUIKit/ImageView/`，每场景独立 VC。

| # | 场景 ID | 标题 | 验证点 |
|---|---------|------|--------|
| 1 | `BasicsRemoteURL` | 远程 URL + 占位 | 默认加载、占位、成功过渡 |
| 2 | `CornerRadiusBorder` | 圆角与边框 | 外观配置矩阵 |
| 3 | `ListReuseStress` | 快速滚动列表 | 取消、无错图 |
| 4 | `FailureRetry` | 失败与重试 | 模拟 404 / 离线 |
| 5 | `SkeletonLoading` | Skeleton 叠加 | FKSkeleton 集成 |
| 6 | `Prefetch` | 表预取 | Loader prefetch API |
| 7 | `LocalFile` | file:// | 本地路径 |
| 8 | `SwiftUI` | SwiftUI 宿主 | Representable |
| 9 | `CustomLoader` | 注入 Loader | Pluggable 替换 |
| 10 | `CacheInspector` | 缓存命中 | 二次加载瞬时显示 |

Hub：**ImageView**，副标题说明 Loader + View 栈。

---

## 27. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Pluggable 是否扩展 `FKImageLoadRequest` 缓存策略？ | v1 仅用 FKCoreKit 侧 `FKImageLoadOptions` |
| Q2 | 磁盘缓存独立目录 vs `FKFileStorage`？ | Caches 下独立目录，淘汰更简单 |
| Q3 | 继承 `UIImageView` vs 组合？ | 组合（容器 + 图层 + 占位/失败 overlay） |
| Q4 | v1 字节进度？ | 延后；仅不确定进度 |
| Q5 | 与 `FKNetworkClient` 共享 URLSession？ | 默认独立 Session；可配置注入 |

---

## 28. 修订历史

| 日期 | 说明 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.1 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 项目路线图（中文）
- [Pluggable FKImageLoading](../Sources/FKCoreKit/Components/Pluggable/Media/FKImageLoading.swift) — 协议契约
- [FKSkeleton README](../Sources/FKUIKit/Components/Skeleton/README.md) — 骨架屏集成
