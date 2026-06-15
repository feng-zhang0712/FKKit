# FKFileManager — 模块设计需求文档

FKKit **`FKFileManager`** 的完整实现指导文档：规范 **已交付能力** 的行为边界、**增量增强**（ZIP 真正实现、后台传输恢复、Multipart 统一）、与 **`FKNetwork` / `FKStorage` / Pluggable** 的分工，补齐缺口分析中尚未文档化的能力描述。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.9、§现有模块增强 — FKFileManager  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) §8.4、§10.2  
**模块 README：** [FileManager/README.md](../Sources/FKCoreKit/Components/FileManager/README.md)  
**增量增强专章：** 本文 §13–§15（原 [FKFileManager_ENHANCEMENT_DESIGN.md](FKFileManager_ENHANCEMENT_DESIGN.md) 已合并入本文）

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 已交付能力详表](#6-已交付能力详表)
- [7. 沙盒与文件 CRUD](#7-沙盒与文件-crud)
- [8. 内容序列化](#8-内容序列化)
- [9. 目录遍历与缓存管理](#9-目录遍历与缓存管理)
- [10. 断点下载与后台会话](#10-断点下载与后台会话)
- [11. Multipart 上传](#11-multipart-上传)
- [12. 传输持久化与恢复](#12-传输持久化与恢复)
- [13. ZIP 压缩与解压（增强）](#13-zip-压缩与解压增强)
- [14. 后台传输恢复 API（增强）](#14-后台传输恢复-api增强)
- [15. Multipart 与 MIME 统一（增强）](#15-multipart-与-mime-统一增强)
- [16. iOS 分享与预览](#16-ios-分享与预览)
- [17. 与 FKNetwork / FKStorage 分工](#17-与-fknetwork--fkstorage-分工)
- [18. 协议导向设计](#18-协议导向设计)
- [19. 错误模型](#19-错误模型)
- [20. 配置模型](#20-配置模型)
- [21. 并发与 Swift 6](#21-并发与-swift-6)
- [22. 安全注意事项](#22-安全注意事项)
- [23. v2 能力展望（非 v1 交付）](#23-v2-能力展望非-v1-交付)
- [24. FKCoreKit 复用要求](#24-fkcorekit-复用要求)
- [25. 公开 API 索引](#25-公开-api-索引)
- [26. 建议源码目录结构](#26-建议源码目录结构)
- [27. FKKitExamples 场景](#27-fkkitexamples-场景)
- [28. 分阶段交付计划](#28-分阶段交付计划)
- [29. 待决问题](#29-待决问题)
- [30. 修订历史](#30-修订历史)
- [31. 相关文档](#31-相关文档)

---

## 1. 概述

UGC、离线包、日志打包、大文件分发等场景需要统一的 **沙盒 I/O + 大文件传输** 层。各 App 重复实现 `FileManager` 封装、`URLSession` 断点下载、Multipart 上传、缓存清理与分享预览。

**`FKFileManager`**（`Sources/FKCoreKit/Components/FileManager/`）提供：

| 交付物 | 职责 |
|--------|------|
| **`FKFileManager.shared`** | 统一入口：`@MainActor` 门面 |
| **`FKFileStorageCore`** | 沙盒路径、CRUD、序列化、遍历（ZIP 占位） |
| **`FKDownloadService`** | 断点下载、前台/后台 `URLSession`、快照持久化 |
| **`FKUploadServiceCore`** | Multipart 上传、进度、快照 |
| **`FKFileMimeResolver`** | 扩展名 → MIME（`UTType` + 回退表） |
| **iOS 扩展** | `UIActivityViewController`、Quick Look 预览 |

**关键约束：** `Foundation` + `URLSession` + `UniformTypeIdentifiers`；**零第三方**；Swift 6；iOS 15+（与 FKKit 包一致）。

**成熟度：** 沙盒 I/O、断点下载、Multipart 上传、缓存工具 **生产可用**；ZIP API **已公开但固定 `zipUnavailable`**；后台 `handleEventsForBackgroundURLSession` **未导出**（§14）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标（模块整体）

1. **统一沙盒入口** — `home` / `documents` / `caches` / `temporary`。
2. **完整文件 CRUD** — 创建目录、删/移/拷/改名、存在性、元数据。
3. **Codable 持久化** — `writeModel` / `readModel`、text/data/json 内容写入。
4. **大文件下载** — 暂停/恢复/取消、`resumeData`、可选后台 Session。
5. **Multipart 上传** — 多文件 + 表单字段、进度回调。
6. **传输快照** — `FKPersistedTransfer` + UserDefaults 持久化、冷启动 `reconnectBackgroundTasks`。
7. **磁盘护栏** — `ensureSufficientDiskSpace`、`directorySize`、缓存/临时目录清理。
8. **增量增强** — Archive.framework ZIP、Zip slip 防护、后台 completion 回调注册、MIME 与 Network Multipart 统一（§13–§15）。
9. **Swift 6** — 公开模型 `Sendable`；传输回调 `@Sendable`；ZIP 服务不阻塞 MainActor（§21）。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| RAR / 7z / tar.gz | 仅 ZIP |
| 加密 ZIP | v2（§23） |
| iCloud / CloudKit 同步策略 | 宿主职责 |
| 替换 `FKNetwork` REST 小文件 API | 分工见 §17 |
| `FKStorage` Codable 键值后端 | 大文件/路径型 I/O 用 FileManager |
| UIKit 文档选择器 / `UIDocumentPicker` | v2 或 FKUIKit `FKShareSheet` |
| watchOS 文件传输 | FKKit iOS-only 产品 |
| 第三方 Zip 库 | 零第三方约束 |

### 2.3 成功标准

**已交付（维持）：**

- [ ] 现有编译与行为无回归；README 示例 API 名与实现一致（`download`/`upload`，非 `startDownload`）。

**增量增强（v1 增强 PR）：**

- [ ] iOS 15+：Examples 目录 ZIP → 解压 → 内容一致。
- [ ] `zipUnavailable` 在不支持环境仍可触发且文案清晰。
- [ ] ZIP 前磁盘不足 → `insufficientDiskSpace`。
- [ ] Zip slip 恶意包 → `zipEntryPathUnsafe` 或等价拒绝。
- [ ] README：ZIP 章节移除 placeholder 表述；Background Recovery 逐步清单。
- [ ] 可选：`registerBackgroundSessionCompletionHandler` 或等价 API（§14）。
- [ ] `xcodebuild` **BUILD SUCCEEDED**。

---

## 3. 背景与问题陈述

### 3.1 与邻模块关系

| 模块 | 分工 |
|------|------|
| **FKNetwork** | REST JSON、小体积 upload、`Requestable` 缓存、API 401 刷新 |
| **FKFileManager** | 沙盒路径、大文件、断点、后台下载、ZIP 离线包 |
| **FKStorage** | 小体积 Codable/Keychain/UserDefaults |
| **FKUIKit PhotoPicker** | 相册/相机选图 — 非沙盒写入编排 |
| **Pluggable** | 无专用 File 协议；大文件 URL 由业务注入 |

### 3.2 当前文档与实现缺口（本设计补齐）

| 缺口 | 本文章节 |
|------|----------|
| ZIP API 欠债 | §13 |
| 后台 `handleEventsForBackgroundURLSession` 未接线 | §12、§14 |
| 上传仅前台 Session | §11、§23 |
| Upload 内置 Multipart vs Network 计划 `FKMultipartFormData` 重复 | §15、§17 |
| README `startDownload` 与实现 `download` 不一致 | §25、README 修正 |
| `FKShareSheet` Tier 3 vs 已有 `makeShareController` | §16 |
| `@MainActor` 全模块与 ZIP 大 IO | §21 |

---

## 4. 架构总览

### 4.1 分层

```text
┌─────────────────────────────────────────────────────────────┐
│ FKFileManager (@MainActor 门面)                              │
│  FKFileOperating · FKFileContentStoring · FKTransferManaging │
└────────────┬──────────────────────┬─────────────────────────┘
             │                      │
             ▼                      ▼
   FKFileStorageCore          FKDownloadService
   (沙盒/CRUD/序列化/ZIP)    FKUploadServiceCore
             │                      │
             ▼                      ▼
   Foundation.FileManager     URLSession (foreground + background)
   FKFileMimeResolver         FKTransferPersistenceStore (UserDefaults)
```

### 4.2 增强组件（§13–§15）

```text
FKFileStorageCore
    └── FKZipOperating
            ├── FKArchiveZipService      (Archive.framework)
            └── FKUnavailableZipService  (zipUnavailable)
```

---

## 5. 模块边界

### 5.1 源码布局（当前）

```text
Sources/FKCoreKit/Components/FileManager/
├── Core/
│   ├── FKFileManager.swift
│   └── FKFileManagerProtocols.swift
├── Model/
│   ├── FKFileModels.swift
│   ├── FKFileManagerError.swift
│   └── FKTransferModels.swift
├── Configuration/
│   └── FKFileManagerConfiguration.swift
├── Service/
│   ├── FKFileStorageCore.swift
│   └── FKFileUtilities.swift          # MIME + persistence actor
├── Download/
│   └── FKDownloadService.swift
├── Upload/
│   └── FKUploadServiceCore.swift
└── Extension/
    ├── FKFileManager+Convenience.swift
    └── FKFileManager+iOS.swift
```

### 5.2 增强后布局（§26）

`Service/` 下新增 `FKZipService`、`FKArchiveZipService`；`Model/` 下 `FKZipOptions`；可选 `Background/` 会话 completion 注册。

---

## 6. 已交付能力详表

| 能力 | 公开 API / 类型 | 成熟度 | 说明 |
|------|-----------------|--------|------|
| 沙盒目录 | `directoryURL(_:)` | ✅ | home/documents/caches/temporary |
| 目录创建 | `createDirectory` | ✅ | `intermediate` 支持 |
| 删/移/拷/改名 | `remove/move/copy/rename` | ✅ | 存在性检查 + 错误映射 |
| 文件元数据 | `fileInfo` → `FKFileInfo` | ✅ | 大小、扩展名、MIME、修改时间 |
| 存在性 | `exists(at:)` | ✅ | 同步 |
| 文本/Data/JSON 写 | `writeContent` | ✅ | 原子写可选 |
| Codable 读写 | `writeModel` / `readModel` | ✅ | JSONEncoder/Decoder |
| 目录遍历 | `enumerateFiles` | ✅ | 递归、扩展名过滤、隐藏文件 |
| 目录大小 | `directorySize` | ✅ | 递归累加 |
| 清缓存/临时 | `clearCaches` / `clearTemporaryFiles` | ✅ | 清空目录内容 |
| 磁盘检查 | `ensureSufficientDiskSpace` | ✅ | 默认 50MB 阈值可配置 |
| 图片判断 | `isImageFile` | ✅ | MIME `image/` 前缀 |
| 断点下载 | `download` + pause/resume | ✅ | `resumeData` 持久化路径 |
| 后台下载 | `allowsBackground` | ✅ | 独立 background `URLSession` |
| Multipart 上传 | `upload` | ✅ | 内置 boundary 构建 |
| 上传进度 | `FKTransferProgress` | ✅ | 0…1 + 字节数 |
| 任务取消 | `cancel` / `cancelAll` | ✅ | 下载+上传 |
| 传输快照 | `persistedTransfers()` | ✅ | 下载+上传合并排序 |
| 冷启动重连 | `reconnectBackgroundTasks` | ⚠️ 内部 | 无 AppDelegate 回调导出 |
| iOS 分享 | `makeShareController` | ✅ | `UIActivityViewController` |
| iOS 预览 | `makePreviewController` | ✅ | Quick Look 单文件 |
| 闭包便利 API | `FKFileManager+Convenience` | ✅ | `deliverResult` 主线程 |
| ZIP 压缩/解压 | `zipItem` / `unzipItem` | ❌ 占位 | 固定 `zipUnavailable` |
| 后台 completion Handler | — | ❌ 待建 | §14 |
| 上传后台 Session | — | ❌ v2 | 仅前台 §23 |
| 统一 Multipart 工具 | Upload 内部 | ⚠️ | 与 Network 待统一 §15 |

图例：✅ 生产可用；⚠️ 部分能力；❌ 待交付。

---

## 7. 沙盒与文件 CRUD

### 7.1 `FKSandboxDirectory`

| Case | 系统映射 |
|------|----------|
| `home` | `NSHomeDirectory()` |
| `documents` | `.documentDirectory` |
| `caches` | `.cachesDirectory` |
| `temporary` | `temporaryDirectory` |

### 7.2 CRUD 行为契约

| 操作 | 源不存在 | 目标已存在 | 错误 |
|------|----------|------------|------|
| `remove` | `fileNotFound` | — | `mappingFileOperation` |
| `move`/`copy` | `fileNotFound` | `fileAlreadyExists` | 同上 |
| `rename` | `fileNotFound` | 新名冲突 → `fileAlreadyExists` | 返回新 URL |

### 7.3 父目录

- `writeContent` / `writeModel` 自动 `ensureParentDirectory`；
- 与 ZIP 增强共用同一私有逻辑（§13）。

---

## 8. 内容序列化

### 8.1 `FKFileContent`

| Case | 编码 |
|------|------|
| `.text` | 指定 `String.Encoding` → Data |
| `.data` | 原始写入 |
| `.jsonObject` | `JSONSerialization` prettyPrinted |

### 8.2 Codable

- 写入：`JSONEncoder` + `.atomic`；
- 读取：`JSONDecoder`；
- 模型须 `Codable & Sendable`（公开 API 约束）。

### 8.3 与 `FKStorage` 选型

| 场景 | 选用 |
|------|------|
| 小配置、键值 TTL | `FKUserDefaultsStorage` / `FKFileStorage`（Storage 模块） |
| 用户导出文件、离线包、日志目录 | **FKFileManager** 路径 API |
| 单 JSON 模型文件 | 两者皆可；FileManager 更直观路径 |

---

## 9. 目录遍历与缓存管理

### 9.1 `FKFileTraversalOptions`

| 字段 | 默认 | 说明 |
|------|------|------|
| `recursive` | `true` | 递归子目录 |
| `includeHiddenFiles` | `false` | 跳过隐藏项 |
| `allowedExtensions` | `[]` | 空=不过滤；小写归一化 |

- 遍历结果 **仅文件**，跳过目录项；
- 用于 `directorySize`、`enumerateFiles`。

### 9.2 缓存清理

- `clearCaches()` — 清空 **整个** Caches 沙盒目录内容（非仅 FK 子目录）— **文档警告**宿主勿放非缓存数据于根 Caches；
- `clearTemporaryFiles()` — 系统临时目录；
- 推荐：业务文件放在 `documents/FKApp/...` 子路径，Caches 仅可删数据。

### 9.3 `workingDirectoryName`

- 默认 `FKFileManager` 子目录于 Caches — 存放 resumeData、传输工作文件；
- 配置项 `FKFileManagerConfiguration.workingDirectoryName`。

---

## 10. 断点下载与后台会话

### 10.1 `FKDownloadRequest`

| 字段 | 说明 |
|------|------|
| `sourceURL` | HTTP(S) 资源 |
| `destinationDirectory` | 目标目录（自动创建） |
| `fileName` | 可选文件名；默认 URL 最后段 |
| `allowsBackground` | `true` → `backgroundSession` |

### 10.2 生命周期

```text
download → running → completed | failed | cancelled
              ↓ pause
            paused → resume → running
```

- **暂停：** `cancelByProducingResumeData()`，resumeData 写入 working 目录；
- **恢复：** `downloadTask(withResumeData:)`；
- **完成：** 临时下载文件 move 到 `destinationDirectory`。

### 10.3 Session 配置

| Session | 用途 |
|---------|------|
| `foregroundSession` | 默认 `URLSessionConfiguration.default` |
| `backgroundSession` | `background(withIdentifier:)` + `isDiscretionary` 等系统默认 |

- `backgroundSessionIdentifier` 来自 `FKFileManagerConfiguration`；
- **必须** App 唯一，与 `handleEventsForBackgroundURLSession` 一致（§14）。

### 10.4 磁盘预检

- `FKFileManager.download` 调用前 `ensureSufficientDiskSpace()`（默认阈值 50MB）。

---

## 11. Multipart 上传

### 11.1 `FKUploadRequest`

| 字段 | 说明 |
|------|------|
| `urlRequest` | 含 URL、method、headers |
| `files` | `[FKUploadFile]` fieldName + fileURL + 可选 mime |
| `formFields` | 额外文本字段 |

### 11.2 内置 Multipart 构建（`FKUploadServiceCore`）

- 自动生成 `FKBoundary-{UUID}`；
- `Content-Type: multipart/form-data; boundary=...`；
- Body 在内存中组装 → `uploadTask(with:from:)`；
- MIME：文件扩展名 → `FKFileMimeResolver`。

### 11.3 与下载的差异

| 维度 | 下载 | 上传 |
|------|------|------|
| 后台 Session | ✅ 可选 | ❌ 仅 `default` 前台 |
| 断点恢复 | ✅ resumeData | ❌ 取消即失败 |
| 持久化快照 | ✅ | ✅（元数据，非可恢复上传） |

### 11.4 大文件注意

- 整包 `Data` 上传 — 极大文件可能内存压力；
- v2：stream 或 background upload（§23）；
- 文档：>100MB 评估分片或专用后台 API。

---

## 12. 传输持久化与恢复

### 12.1 `FKPersistedTransfer`

| 字段 | 说明 |
|------|------|
| `id` | `URLSessionTask.taskIdentifier` |
| `kind` | `.download` / `.upload` |
| `state` | idle/running/paused/completed/cancelled/failed |
| `sourceURL` | 下载源或上传 URL |
| `destinationPath` | 下载目标目录路径 |
| `updatedAt` | 排序用 |

### 12.2 存储

- `FKTransferPersistenceStore`（`actor`）+ `UserDefaults`；
- 下载 key：`configuration.persistenceKey`；
- 上传 key：`persistenceKey + ".upload"`。

### 12.3 冷启动 `reconnectBackgroundTasks`

- 下载服务 init 时 `restoreSnapshots` + `reconnectBackgroundTasks`；
- 将系统仍存活的后台 task 并入 `snapshots`；
- **不** 自动重新绑定 UI progress/completion 闭包 — 宿主须根据 `persistedTransfers()` 重建 UI。

### 12.4 缺失：系统后台唤醒回调（§14）

当前 **无** 公开 API 接收：

```swift
application(_:handleEventsForBackgroundURLSession:completionHandler:)
```

导致后台 Session 事件结束时可能无法调用系统 `completionHandler` — **v1 增强应补齐**（§14）。

---

## 13. ZIP 压缩与解压（增强）

### 13.1 现状（占位）

```swift
// FKFileStorageCore — 当前
func zipItem(at sourceURL: URL, to destinationURL: URL) async throws {
  guard fileManager.fileExists(atPath: sourceURL.path) else { throw .fileNotFound }
  throw FKFileManagerError.zipUnavailable
}
```

公开 API：`FKFileManager.zipItem` / `unzipItem` 委托 storage。

### 13.2 实现策略

| 优先级 | 方案 | 条件 |
|--------|------|------|
| **P0** | **Archive.framework** | `#if canImport(Archive)`，iOS 13+ |
| **P2** | 保持 `zipUnavailable` | Archive 不可用平台 |

**默认：P0 only** — 不维护纯 Swift ZIP 写入（路线图 R2）。

### 13.3 `FKZipOperating`（Internal）

```swift
protocol FKZipOperating: Sendable {
  func zipItem(at sourceURL: URL, to destinationURL: URL, options: FKZipOptions) async throws
  func unzipItem(at sourceURL: URL, to destinationURL: URL, options: FKUnzipOptions) async throws
}
```

实现：`FKArchiveZipService`、`FKUnavailableZipService`。

### 13.4 压缩行为

- 源：文件或目录（**递归**）；
- 目标已存在 → `fileAlreadyExists`；
- 先写 `*.zip.tmp` 再 `move`（原子性）；
- 压缩前：`directorySize × zipDiskSpaceSafetyFactor` → `ensureSufficientDiskSpace`。

### 13.5 解压行为

- 目标目录不存在则创建；
- **Zip slip 防护** — 条目路径不得逃逸 `destinationURL`（`..`、绝对路径拒绝）；
- `FKUnzipOptions.overwritePolicy`：`.replaceExisting` / `.failIfExists`。

### 13.6 公开选项

```swift
public struct FKZipOptions: Sendable, Equatable {
  public var includesRootDirectoryName: Bool  // default true
  public var compressionMethod: FKZipCompressionMethod
}

public struct FKUnzipOptions: Sendable, Equatable {
  public enum OverwritePolicy: Sendable, Equatable {
    case replaceExisting
    case failIfExists
  }
  public var overwritePolicy: OverwritePolicy
}
```

保持无 options 签名；新增带 `options` 重载，`default` 参数。

### 13.7 能力探测

```swift
public extension FKFileManager {
  /// Whether ZIP is supported on the current OS/runtime/configuration.
  public static var isZipAvailable: Bool { get }
}
```

- `#if canImport(Archive)` + 可选 `configuration.isZipEnabled`。

---

## 14. 后台传输恢复 API（增强）

### 14.1 README 必须新增章节「Background Transfer Recovery」

逐步清单：

1. Target → Background Modes → 按需勾选；
2. 配置唯一 `backgroundSessionIdentifier`；
3. AppDelegate：

```swift
func application(
  _ application: UIApplication,
  handleEventsForBackgroundURLSession identifier: String,
  completionHandler: @escaping () -> Void
) {
  FKFileManager.shared.registerBackgroundSessionCompletionHandler(
    completionHandler,
    forSessionWithIdentifier: identifier
  )
}
```

4. 冷启动：`persistedTransfers()` 恢复 UI 列表；
5. 重新 `download` 时绑定新 progress/completion；
6. **限制**：系统可延迟/终止；用户可能需手动重试。

### 14.2 建议公开 API（v1 增强）

```swift
public extension FKFileManager {
  /// Stores the system completion handler until background URLSession events finish.
  public func registerBackgroundSessionCompletionHandler(
    _ handler: @escaping @Sendable () -> Void,
    forSessionWithIdentifier identifier: String
  )
}
```

- `FKDownloadService` 在 `urlSessionDidFinishEventsForBackgroundURLSession` 调用 stored handler；
- identifier 不匹配则 no-op 或 debug log。

### 14.3 若 v1 仅文档

- Design 仍记录 API；代码 PR 可 follow-up；
- Examples 场景 7 以「文档式 Demo + 模拟快照」交付。

---

## 15. Multipart 与 MIME 统一（增强）

### 15.1 现状

- **Upload：** `FKUploadServiceCore.buildMultipartBody` 私有实现；
- **Network（计划）：** `FKMultipartFormData`（见 [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md) §12）。

### 15.2 统一策略（推荐）

| 步骤 | 动作 |
|------|------|
| 1 | 在 **FKCoreKit 共享层** 实现 `FKMultipartFormData`（可放 `FileManager/Service/` 或 `FKCoreKit/Components/Utils/`） |
| 2 | Network upload 与 FileManager upload **共用** builder |
| 3 | MIME 统一调用 **`FKFileMimeResolver`**（考虑 `public` 或 `package` 级暴露给 Network） |

### 15.3 `FKFileMimeResolver` 增强（可选）

```swift
public enum FKFileMimeResolver {
  public static func mimeType(forFileExtension: String) -> String
  public static func mimeType(forFileURL: URL) -> String
}
```

- 内部保留 `UTType` + `fallbackMap`（已含 `zip`、`mp4` 等）；
- Network Multipart **禁止** 复制完整 mime 表。

---

## 16. iOS 分享与预览

### 16.1 已交付

| API | 说明 |
|-----|------|
| `makeShareController(for:)` | `UIActivityViewController` 单文件 |
| `makePreviewController(for:)` | Quick Look + `FKSingleFilePreviewDataSource` |

**注意：** dataSource 须强引用至预览结束。

### 16.2 与 Tier 3 `FKShareSheet` 边界

| 需求 | 选用 |
|------|------|
| 单文件系统分享 | **已有** `makeShareController` |
| 多文件、自定义排除活动、统一 FK 样式 Sheet | 未来 **FKShareSheet**（FKUIKit）可包装本 API |
| ZIP 导出后分享 | Examples `ShareZippedExport`（§27） |

---

## 17. 与 FKNetwork / FKStorage 分工

| 用户需求 | FKNetwork | FKFileManager |
|----------|-----------|---------------|
| REST JSON API | ✅ `Requestable` | — |
| 小图片 POST | ✅ upload task | 可选 Multipart |
| 大文件下载、断点 | — | ✅ |
| 后台继续下载 | — | ✅ |
| 沙盒读写、日志目录 | — | ✅ |
| ZIP 离线包 | — | ✅（增强后） |
| API 缓存 TTL | ✅ `NetworkCachePolicy` | — |
| Token 401 | ✅ | — |

**Multipart：** 大文件 + 表单 → FileManager `upload`；纯 JSON → Network。

---

## 18. 协议导向设计

| 协议 | 职责 | 默认实现 |
|------|------|----------|
| `FKFileOperating` | 沙盒 + CRUD + 元数据 | `FKFileManager` / `FKFileStorageCore` |
| `FKFileContentStoring` | 序列化读写 | 同上 |
| `FKTransferManaging` | 上传下载控制 | `FKFileManager` + 内部服务 |

- 测试可注入自定义 `FKFileManager(configuration:)`（内部服务当前硬编码 — v2 可注入协议）；
- Pluggable **无** `FKFileOperating` 契约（v2 可选，非 v1）。

---

## 19. 错误模型

### 19.1 现有 `FKFileManagerError`

| Case | 含义 |
|------|------|
| `fileNotFound(path:)` | 路径不存在 |
| `fileAlreadyExists(path:)` | 冲突 |
| `invalidURL(_:)` | URL 无效 |
| `transferFailed(_:)` | 传输失败消息 |
| `invalidResponse` | 响应无效 |
| `insufficientDiskSpace(required:available:)` | 磁盘不足 |
| `zipUnavailable` | ZIP 不可用 |
| `unknown(_:)` | 包装错误 |

- `mappingFileOperation` — Cocoa/POSIX → 结构化 case；
- `LocalizedError` + **FKI18n**（`fkcore.file.error.*`）。

### 19.2 增强扩展（semver minor）

```swift
case zipCorrupted(archivePath: String)
case zipEntryPathUnsafe(entry: String)
case zipOperationFailed(message: String)
```

---

## 20. 配置模型

### 20.1 现有 `FKFileManagerConfiguration`

| 字段 | 默认 | 说明 |
|------|------|------|
| `backgroundSessionIdentifier` | `com.fkkit.filemanager.background` | 后台下载 |
| `minimumRequiredDiskSpace` | 50 × 1024 × 1024 | 传输前检查 |
| `persistenceKey` | `com.fkkit.filemanager.transfers` | 快照 UserDefaults |
| `workingDirectoryName` | `FKFileManager` | Caches 子目录 |

### 20.2 增强扩展

```swift
public extension FKFileManagerConfiguration {
  /// When false, zip APIs throw zipUnavailable even if Archive is available.
  public var isZipEnabled: Bool  // default true
  /// Multiplier for pre-zip disk space heuristic (default 1.1).
  public var zipDiskSpaceSafetyFactor: Double
}
```

---

## 21. 并发与 Swift 6

| 组件 | 现状 | 增强要求 |
|------|------|----------|
| `FKFileManager` | `@MainActor` | 保持门面 MainActor |
| `FKFileStorageCore` | `@MainActor` | ZIP 委托 `nonisolated`/`actor` 服务 offload |
| `FKDownloadService` / Upload | `@MainActor` | URLSession delegate 回调切回 MainActor |
| 进度/完成闭包 | `@Sendable` | 保持 |
| `FKTransferPersistenceStore` | `actor` | 保持 |
| Verify | — | `SWIFT_STRICT_CONCURRENCY=complete` |

**ZIP 大目录：** 禁止在 MainActor 上同步读全目录；Archive API 在后台 `Task` 执行。

---

## 22. 安全注意事项

- **Zip slip** 必须实现（§13.5）；
- 不解压到沙盒外路径；
- 不执行 ZIP 内脚本；
- 日志默认不 dump 归档内文件名列表（debug opt-in）；
- `clearCaches` 破坏性 — 文档警告（§9.2）；
- 分享/预览仅本地已信任路径。

---

## 23. v2 能力展望（非 v1 交付）

| 能力 | 说明 | 优先级 |
|------|------|--------|
| **上传后台 Session** | 大文件后台 upload | 中 |
| **加密 ZIP** | 密码保护归档 | 低 |
| **ZIP 进度回调** | 压缩/解压百分比 | 中 |
| **FKShareSheet** | FKUIKit 统一分享入口 | 中 |
| **文件变更观察** | `NSFilePresenter` / FSEvents 风格 | 低 |
| **iCloud 容器路径辅助** | 仅 URL 解析，无同步策略 | 低 |
| **Pluggable `FKFileOperating`** | 测试注入 | 低 |
| **与 FKLogger 集成** | 传输诊断上传 | 低 |

---

## 24. FKCoreKit 复用要求

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 磁盘检查 | `ensureSufficientDiskSpace` | 跳过 |
| 父目录 | `ensureParentDirectory` 模式 | 重复实现 |
| 错误 | `FKFileManagerError.mappingFileOperation` | 平行 Error enum |
| 遍历 | `enumerateFiles` / `FileManager` enumerator | 手写栈（除非 ZIP 内部） |
| 本地化 | `FKI18n` | 硬编码英文 |
| 日志 | `FKLogger`（增强诊断） | `print` |
| Multipart | 统一 `FKMultipartFormData`（§15） | 第三处 boundary 实现 |
| MIME | `FKFileMimeResolver` | Network 重复 mime 表 |

---

## 25. 公开 API 索引

**入口：** `FKFileManager.shared`、`init(configuration:)`

| 分类 | 方法 |
|------|------|
| 沙盒 | `directoryURL(_:)` |
| CRUD | `createDirectory`, `removeItem`, `moveItem`, `copyItem`, `renameItem`, `exists`, `fileInfo` |
| 内容 | `writeContent`, `writeModel`, `readData`, `readText`, `readModel` |
| 目录 | `directorySize`, `enumerateFiles`, `clearCaches`, `clearTemporaryFiles` |
| ZIP | `zipItem`, `unzipItem`（+ options 重载）；`FKFileManager.isZipAvailable` |
| 工具 | `ensureSufficientDiskSpace`, `isImageFile` |
| 下载 | `download`, `pauseDownload`, `resumeDownload` |
| 上传 | `upload` |
| 控制 | `cancel`, `cancelAll`, `persistedTransfers` |
| 后台（增强） | `registerBackgroundSessionCompletionHandler` |
| iOS | `makeShareController`, `makePreviewController` |

**README 修正：** 统一使用 `download` / `upload`（非 `startDownload` / `startUpload`）。

---

## 26. 建议源码目录结构

```text
Sources/FKCoreKit/Components/FileManager/
├── Service/
│   ├── FKFileStorageCore.swift
│   ├── FKZipService.swift              # 协议
│   ├── FKArchiveZipService.swift       # Archive 实现
│   ├── FKUnavailableZipService.swift
│   ├── FKMultipartFormData.swift       # 与 Network 共享（或上移 Utils）
│   └── FKFileUtilities.swift
├── Model/
│   ├── FKZipOptions.swift
│   └── FKUnzipOptions.swift
├── Background/                         # 可选
│   └── FKBackgroundSessionCoordinator.swift
└── README.md
```

---

## 27. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/FileManager/`

### 27.1 基线能力（已交付 — 补齐演示）

| # | 场景 | 验证点 |
|---|------|--------|
| B1 | `SandboxPaths` | 四沙盒目录 |
| B2 | `WriteReadModel` | Codable 往返 |
| B3 | `DownloadPauseResume` | 断点下载 |
| B4 | `MultipartUpload` | 多文件 + 字段 |
| B5 | `CacheSizeAndClear` | `directorySize` + clear |
| B6 | `DiskSpaceGuard` | `ensureSufficientDiskSpace` |
| B7 | `PersistedTransfers` | 快照列表 UI |
| B8 | `ShareAndPreview` | iOS 分享 + Quick Look |

### 27.2 增量增强（待交付）

| # | 场景 | 验证点 |
|---|------|--------|
| E1 | `ZipFolder` | 目录压缩 |
| E2 | `UnzipAndVerify` | 哈希一致 |
| E3 | `ZipSingleFile` | 单文件归档 |
| E4 | `ZipUnavailableFallback` | 门控 UI |
| E5 | `InsufficientDiskSpace` | 压缩前失败 |
| E6 | `ZipSlipBlocked` | 恶意条目 |
| E7 | `BackgroundDownloadRecovery` | 快照 + 文档式恢复 |
| E8 | `ShareZippedExport` | ZIP 后 `makeShareController` |

---

## 28. 分阶段交付计划

| 阶段 | 交付物 | 主题 |
|------|--------|------|
| **F0** | 基线 Examples B1–B8 + README API 名修正 | 已交付能力可见性 |
| **F1** | ZIP（Archive）+ `isZipAvailable` + 错误扩展 | 核心欠债 |
| **F2** | Background completion API + README Recovery | 后台可靠性 |
| **F3** | `FKMultipartFormData` 共享 + MIME public | 与 Network 对齐 |
| **F4** | Examples E1–E8 + Roadmap 勾选 | 发布卫生 |

每阶段：`xcodebuild` → `CHANGELOG` → Hub 条目。

---

## 29. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | Archive-only vs 纯 Swift ZIP 回退？ | Archive-only + `zipUnavailable` |
| Q2 | `FKFileStorageCore` 去掉 `@MainActor`？ | ZIP 用独立 actor，门面保持 MainActor |
| Q3 | ZIP 进度 callback v1？ | v1.1 |
| Q4 | 加密 ZIP | v2 |
| Q5 | `FKMultipartFormData` 放 FileManager vs Utils？ | `FileManager/Service/` 或 `FKCoreKit/Components/Utils/` |
| Q6 | 后台 completion API v1 必达？ | 是（与 ZIP 同列车或紧接 PR） |
| Q7 | `clearCaches` 仅删 working 子目录？ | v2；v1 文档警告即可 |

---

## 30. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | `FKFileManager_ENHANCEMENT_DESIGN.md` 初版（ZIP + 后台文档） |
| 2026-06-14 | 合并为完整模块设计：已交付详表、传输恢复、Multipart 统一、基线 Examples、v2 展望 |

---

## 31. 相关文档

| 文档 | 内容 |
|------|------|
| [FileManager/README.md](../Sources/FKCoreKit/Components/FileManager/README.md) | 使用指南 |
| [FKFileManager_ENHANCEMENT_DESIGN.md](FKFileManager_ENHANCEMENT_DESIGN.md) | 增量增强索引 |
| [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md) | Multipart / 传输分工 |
| [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md) | 无 File 协议（v2 展望） |
| [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md) | §8.4 ZIP、§10.2 |
| [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) | §2.9、现有模块增强 |
| [FKBackgroundTaskManager_DESIGN.md](FKBackgroundTaskManager_DESIGN.md) | BGTask vs URLSession 后台传输边界 |
