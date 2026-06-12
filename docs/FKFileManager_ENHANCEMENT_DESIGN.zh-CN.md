# FKFileManager — 模块增强设计需求文档

FKKit **`FKFileManager`** 的**增量增强**实现指导文档：交付可用的 **ZIP 压缩/解压** 实现，并完善 **后台传输、恢复与限制** 的文档与 API 门控；不改变现有文件 CRUD、断点上传下载的默认行为。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.9、§现有模块增强 — FKFileManager  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.zh-CN.md](COMPONENT_GAP_ANALYSIS.zh-CN.md) §8.4、§10.2  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 现状基线](#3-现状基线)
- [4. 增强项总览](#4-增强项总览)
- [5. ZIP 压缩与解压](#5-zip-压缩与解压)
- [6. 平台能力与门控](#6-平台能力与门控)
- [7. 后台传输与恢复](#7-后台传输与恢复)
- [8. 错误模型与行为](#8-错误模型与行为)
- [9. 模块边界与复用](#9-模块边界与复用)
- [10. 公开 API](#10-公开-api)
- [11. 配置扩展](#11-配置扩展)
- [12. 性能与磁盘空间](#12-性能与磁盘空间)
- [13. 安全注意事项](#13-安全注意事项)
- [14. 建议源码目录结构](#14-建议源码目录结构)
- [15. FKKitExamples 场景](#15-fkkitexamples-场景)
- [16. 待决问题](#16-待决问题)
- [17. 修订历史](#17-修订历史)

---

## 1. 概述

`FKFileManager`（`Sources/FKCoreKit/Components/FileManager/`）提供沙盒 I/O、断点下载/上传、缓存清理、Codable 持久化等能力，已是 FKCoreKit 中文件与传输的统一入口。

**当前缺口：**

| 问题 | 现状 |
|------|------|
| ZIP API | `zipItem(at:to:)` / `unzipItem(at:to:)` **已公开**，但 `FKFileStorageCore` **固定抛出** `FKFileManagerError.zipUnavailable` |
| 后台传输 | README 有 Background Modes 说明，缺**恢复流程**与**限制清单**的结构化文档 |
| 路线图风险 R2 | Archive.framework 可用性 vs 纯 Swift 回退未决 |

本设计文档规范 **ZIP 真正实现** 与 **传输文档化/API 门控** 的可验收需求。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **ZIP 可用** — 在支持的 OS 版本上，`zipItem` / `unzipItem` 成功完成典型目录/文件归档。
2. **明确门控** — 不支持的路径继续 `zipUnavailable`，README 与错误文案说明原因。
3. **磁盘安全** — 压缩/解压前 `ensureSufficientDiskSpace`（可配置系数）。
4. **后台传输文档** — 恢复、`handleEventsForBackgroundURLSession`、快照 `persistedTransfers()` 完整流程。
5. **零第三方** — 优先 **Archive.framework**；无则文档化不可用。
6. **Swift 6** — ZIP 选项 `Sendable`；IO 在合适 executor 不阻塞 MainActor（`FKFileStorageCore` 当前 `@MainActor` 需评估迁移或 `nonisolated` 子服务）。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| RAR / 7z / tar.gz | 仅 ZIP |
| 加密 ZIP | v2 |
| 分卷 ZIP | 不在范围 |
| iCloud 同步策略 | 宿主职责 |
| 替换 FKNetwork 上传 | 分工不变 |
| 修改 Upload/Download 公开签名 | 除非 ZIP 必需 |

### 2.3 成功标准

- [ ] iOS 15+ 真机/模拟器：Examples 压缩文件夹 → 解压 → 文件一致。
- [ ] 不支持环境：`zipUnavailable` 仍可用且测试覆盖。
- [ ] 大目录 ZIP 前磁盘不足 → `insufficientDiskSpace`。
- [ ] README 更新：ZIP 章节移除「placeholder」表述；Background 恢复逐步清单。
- [ ] `xcodebuild` BUILD SUCCEEDED。

---

## 3. 现状基线

### 3.1 模块布局

```text
Sources/FKCoreKit/Components/FileManager/
├── Core/              FKFileManager.swift, FKFileManagerProtocols.swift
├── Model/             FKFileManagerError, FKFileModels, transfer models
├── Configuration/     FKFileManagerConfiguration
├── Service/           FKFileStorageCore, FKFileUtilities
├── Download/          URLSession download
├── Upload/            multipart upload
└── Extension/         Convenience, share/preview
```

### 3.2 现有 ZIP 占位

```swift
// FKFileStorageCore.swift — 当前行为
func zipItem(at sourceURL: URL, to destinationURL: URL) async throws {
  guard fileManager.fileExists(atPath: sourceURL.path) else { throw .fileNotFound }
  throw FKFileManagerError.zipUnavailable
}
```

公开 API（`FKFileManager.shared`）：

- `zipItem(at:to:)`
- `unzipItem(at:to:)`

### 3.3 已有相关能力

- `ensureSufficientDiskSpace(requiredBytes:)`
- `directorySize(at:)` / 遍历
- MIME 表含 `"zip": "application/zip"`
- 错误 case：`zipUnavailable`

---

## 4. 增强项总览

| 增强项 | 交付 |
|--------|------|
| **ZIP 实现** | `FKZipService` + Archive（或回退） |
| **ZIP 选项** | 压缩级别、是否包含根目录名 |
| **能力探测** | `FKFileManager.isZipAvailable` |
| **后台传输** | 文档 + 可选 `FKBackgroundTransferRecoveryGuide` 类型别名文档；代码侧完善 delegate 回调导出 |
| **错误细化** | `zipCorrupted`, `zipPathTooLong`（可选） |

---

## 5. ZIP 压缩与解压

### 5.1 实现策略（按优先级）

| 优先级 | 方案 | 条件 |
|--------|------|------|
| **P0** | **Archive.framework** | iOS 13+ / macOS 10.15+，`import Archive` 可用 |
| **P1** | **Compression + 最小 ZIP 写入** | 仅当 Archive 不可用且产品同意维护成本 |
| **P2** | 保持 `zipUnavailable` | 明确文档 |

**路线图建议默认：P0** — Feature detect at runtime/build。

### 5.2 FKZipService（Internal）

```swift
protocol FKZipOperating: Sendable {
  func zipItem(at sourceURL: URL, to destinationURL: URL, options: FKZipOptions) async throws
  func unzipItem(at sourceURL: URL, to destinationURL: URL, options: FKUnzipOptions) async throws
}
```

**Final implementation：** `FKArchiveZipService` conforming。

### 5.3 行为要求

**压缩 `zipItem`：**

- `sourceURL` 为文件或目录；目录 **递归** 纳入；
- `destinationURL` 若已存在 → `fileAlreadyExists`（与 move/copy 一致）；
- 自动 `ensureParentDirectory`；
- 压缩前估算输出大小（启发式：目录 size × 0.9）调用 `ensureSufficientDiskSpace`；
- 原子性：先写临时文件 `*.zip.tmp` 再 move。

**解压 `unzipItem`：**

- 目标目录不存在则创建；
- **Zip slip 防护** — 解压条目路径不得逃逸 `destinationURL`（`..` 过滤）；
- 已存在同名文件策略：`FKUnzipOptions.overwritePolicy`（`.replace` / `.fail`）。

### 5.4 FKZipOptions / FKUnzipOptions

```swift
public struct FKZipOptions: Sendable, Equatable {
  public var includesRootDirectoryName: Bool  // 默认 true
  public var compressionMethod: FKZipCompressionMethod  // .default
}

public struct FKUnzipOptions: Sendable, Equatable {
  public enum OverwritePolicy: Sendable, Equatable {
    case replaceExisting
    case failIfExists
  }
  public var overwritePolicy: OverwritePolicy
}
```

### 5.5 公开 API 扩展（可选 overload）

保持现有签名；新增 options 重载：

```swift
public func zipItem(
  at sourceURL: URL,
  to destinationURL: URL,
  options: FKZipOptions = .default
) async throws
```

---

## 6. 平台能力与门控

### 6.1 FKFileManager.isZipAvailable

```swift
public extension FKFileManager {
  /// Returns whether ZIP compression is supported on the current OS/runtime.
  public static var isZipAvailable: Bool { get }
}
```

实现：`#if canImport(Archive)` + 运行时探测（必要时尝试创建空 archive）。

### 6.2 zipUnavailable 保留场景

- Archive 不可 import 的构建目标；
- 未来 watchOS 等未支持平台；
- 明确 disabled 的配置 `FKFileManagerConfiguration.isZipEnabled = false`（可选）。

### 6.3 文档要求

README 表格：

| 平台 | ZIP 支持 |
|------|----------|
| iOS 15+（FKKit 最低） | ✅ Archive |
| 更低 iOS | 不在 FKKit 支持范围 |

---

## 7. 后台传输与恢复

### 7.1 现状

- `FKFileManagerConfiguration.backgroundSessionIdentifier`；
- Download 使用 background `URLSessionConfiguration`；
- `persistedTransfers()` 返回快照；
- README **Background Modes Configuration** 章节较简。

### 7.2 文档增强（必须）

新增 README 章节 **「Background Transfer Recovery」**，逐步说明：

1. App Target 开启 Background Modes；
2. 配置 `backgroundSessionIdentifier` 唯一；
3. AppDelegate / SceneDelegate：

```swift
func application(
  _ application: UIApplication,
  handleEventsForBackgroundURLSession identifier: String,
  completionHandler: @escaping () -> Void
)
```

4. 将 completionHandler 传给 `FKFileManager` 内部 session delegate；
5. 冷启动调用 `persistedTransfers()` 恢复 UI；
6. **限制**：系统可能终止长时间任务；大文件需预期延迟。

### 7.3 代码增强（可选 v1.1）

```swift
public func registerBackgroundSessionCompletionHandler(
  _ handler: @escaping @Sendable () -> Void,
  forSessionWithIdentifier identifier: String
)
```

若 v1 仅文档，Design 仍列出 API 供后续 PR。

### 7.4 与 FKNetwork 分工

| 模块 | 职责 |
|------|------|
| FKNetwork | API JSON、小文件、通用 REST upload |
| FKFileManager | 大文件、断点、后台 download、沙盒 ZIP |

---

## 8. 错误模型与行为

### 8.1 现有

- `zipUnavailable`
- `insufficientDiskSpace(required:available:)`
- `fileNotFound` / `fileAlreadyExists`

### 8.2 建议新增

```swift
case zipCorrupted(archivePath: String)
case zipEntryPathUnsafe(entry: String)
case zipOperationFailed(underlying: String)
```

**FKI18n** 键：`fkcore.file.error.zip_*`。

---

## 9. 模块边界与复用

### 9.1 FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 磁盘检查 | **`ensureSufficientDiskSpace`** | 跳过检查 |
| 目录创建 | **`ensureParentDirectory`** 私有模式 | 重复实现 |
| 错误映射 | **`FKFileManagerError.mappingFileOperation`** | 平行 Error |
| 遍历 | 现有 **recursive enumeration** | 临时手写栈 |
| 日志 | **`FKLogger`** | print |
| 本地化 | **`FKI18n`** | 硬编码 |

### 9.2 不得依赖

- FKUIKit；
- 第三方 Zip 库。

---

## 10. 公开 API

```swift
// 能力
if FKFileManager.isZipAvailable {
  try await FKFileManager.shared.zipItem(at: folder, to: zipURL)
  try await FKFileManager.shared.unzipItem(at: zipURL, to: destDir)
} else {
  // 展示 FKI18n zip_unavailable
}
```

---

## 11. 配置扩展

```swift
public extension FKFileManagerConfiguration {
  /// When false, zip APIs throw zipUnavailable even if Archive is present.
  public var isZipEnabled: Bool  // 默认 true
  /// Multiplier for pre-zip disk space check (default 1.1)
  public var zipDiskSpaceSafetyFactor: Double
}
```

---

## 12. 性能与磁盘空间

- 大目录 ZIP 在 **后台 Task** 执行，进度回调 v1.1；
- 避免 MainActor 上读大文件 — `FKFileStorageCore` 的 `@MainActor` 隔离应在 ZIP 实现中通过 `nonisolated` service 或 actor  offload；
- 解压流式读取，避免整包读入内存（Archive API 允许 iterate entries）。

---

## 13. 安全注意事项

- **Zip slip** 必须防护（§5.3）；
- 不解压到 `tmp` 外未授权路径；
- 不执行 ZIP 内任何脚本；
- 日志不记录 ZIP 内用户文件名列表（debug 可 opt-in）。

---

## 14. 建议源码目录结构

```text
Sources/FKCoreKit/Components/FileManager/
├── Service/
│   ├── FKFileStorageCore.swift       # 委托 FKZipService
│   ├── FKZipService.swift            # 协议
│   ├── FKArchiveZipService.swift     # Archive 实现
│   └── FKUnavailableZipService.swift   # 统一 throw zipUnavailable
├── Model/
│   ├── FKZipOptions.swift
│   └── FKUnzipOptions.swift
└── README.md                          # ZIP + Background 章节更新
```

---

## 15. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/FileManager/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `ZipFolder` | 目录压缩 |
| 2 | `UnzipAndVerify` | 解压后哈希一致 |
| 3 | `ZipSingleFile` | 单文件 |
| 4 | `ZipUnavailableFallback` | 门控 / mock unavailable |
| 5 | `InsufficientDiskSpace` | 故意填满小分区或 mock |
| 6 | `ZipSlipBlocked` | 恶意条目拒绝 |
| 7 | `BackgroundDownloadRecovery` | 文档式 demo + 模拟快照 |
| 8 | `ShareZippedExport` | zip 后 `makeShareController` |

---

## 16. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Archive-only vs 纯 Swift 回退？ | Archive-only + zipUnavailable |
| Q2 | FKFileStorageCore 去掉 @MainActor？ | ZIP 用独立 actor，逐步迁移 |
| Q3 | 压缩进度 callback v1？ | v1.1 |
| Q4 | 加密 ZIP v2？ | 是 |

---

## 17. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版，源自 COMPONENT_ROADMAP §2.9 与 FileManager README |

---

## 相关文档

- [FileManager README](../Sources/FKCoreKit/Components/FileManager/README.md)
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [COMPONENT_GAP_ANALYSIS.zh-CN.md](COMPONENT_GAP_ANALYSIS.zh-CN.md)
