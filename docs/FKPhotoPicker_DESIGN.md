# FKPhotoPicker — 设计需求文档

FKKit **`FKPhotoPicker`** 的实现指导文档：面向生产的 **`PHPickerViewController`** 与 **`UIImagePickerController`** 封装，集成 **`FKPermissions`** 预检、选择数量限制、后处理（压缩、缩放）及类型化结果（`UIImage`、`Data`、文件 URL）。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.6  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 选择器后端与选型策略](#6-选择器后端与选型策略)
- [7. 来源与展示模式](#7-来源与展示模式)
- [8. 权限预检](#8-权限预检)
- [9. 选择限制与媒体类型](#9-选择限制与媒体类型)
- [10. 选取流程与生命周期](#10-选取流程与生命周期)
- [11. 结果模型与交付](#11-结果模型与交付)
- [12. 图像处理流水线](#12-图像处理流水线)
- [13. 视频处理](#13-视频处理)
- [14. 公开 API](#14-公开-api)
- [15. 错误分类](#15-错误分类)
- [16. 配置模型](#16-配置模型)
- [17. 展示集成](#17-展示集成)
- [18. 安全与隐私](#18-安全与隐私)
- [19. 并发与内存](#19-并发与内存)
- [20. 无障碍与本地化](#20-无障碍与本地化)
- [21. SwiftUI 桥接](#21-swiftui-桥接)
- [22. 建议源码目录结构](#22-建议源码目录结构)
- [23. FKKitExamples 场景](#23-fkkitexamples-场景)
- [25. 待决问题](#25-待决问题)
- [26. 修订历史](#26-修订历史)

---

## 1. 概述

头像上传、KYC 证件拍摄、聊天发图、商品上架图等场景都需要**相机拍摄**和/或**相册选取**。直接集成 `PHPickerViewController` 与 `UIImagePickerController` 时，团队反复处理：

- 与 Info.plist 文案一致的权限检查
- PHPicker 与旧版选择器、`selectionLimit` 选型
- 多选上限与混合媒体策略
- 主线程展示与 delegate 接线
- 图像缩小、JPEG 压缩、临时文件导出
- 拒绝 / 受限相册 UX

**`FKPhotoPicker`**（`Sources/FKUIKit/Components/PhotoPicker/`）是 **`@MainActor`** 协调器：从宿主 `UIViewController` 弹出系统选择器，执行 **`FKPermissions`** 预检，在后台执行处理，通过 `async` 或回调返回 **`[FKPhotoPickerResult]`**。

| 交付物 | 职责 |
|--------|------|
| **`FKPhotoPicker`** | 主协调器（`pick` / `presentCamera` / `presentLibrary`） |
| **`FKPhotoPickerConfiguration`** | Sendable 策略：来源、限制、媒体类型、处理 |
| **`FKPhotoPickerResult`** | 单资源：image、data、fileURL、元数据 |
| **`FKPhotoPickerError`** | 类型化失败（权限、取消、处理、不可用） |
| **`FKPhotoPicking`** | 依赖注入协议 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **统一入口** — 一个配置结构驱动相册、相机或来源选择（Action Sheet）。
2. **FKPermissions 集成** — 系统弹窗前可选 `FKPermissionPrePrompt`。
3. **PHPicker 优先** — iOS 15+ 相册用 `PHPickerViewController`；相机用 `UIImagePickerController`。
4. **选择限制** — 单选（头像）与多选（最多 N 张）。
5. **处理流水线** — 最大边长、JPEG/HEIC 质量、剥离 GPS EXIF、临时文件 URL。
6. **类型化结果** — 内存 `UIImage`；上传用 `URL`；可选原始 `Data`。
7. **受限相册** — 处理 `FKPermissionStatus.limited` 及管理入口。
8. **Swift 6** — 配置与结果 `Sendable`；处理在后台执行。
9. **取消语义** — 用户关闭映射为 `FKPhotoPickerError.cancelled`。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 自定义相册网格 UI | 仅系统选择器 |
| 除相机 `allowsEditing` 外的内置裁剪 | v1.1 `FKImageCropper` |
| 以 SwiftUI `PhotosPicker` 为主入口 | 可选薄桥接；UIKit 协调器为准 |
| 超出选择器交代的 iCloud 大视频下载编排 | 宿主负责上传 |
| RAW / ProRAW | 不在范围 |
| Live Photo 播放 UI | 按配置导出静帧或 MOV |
| macOS / Catalyst 相机 | 仅 iOS 15+ UIKit |
| `PHPhotoLibrary` 变更监听 | 宿主职责 |

### 2.3 成功标准

- [ ] 相册单选 + 压缩 + 最大边长生效。
- [ ] 多选（如 9 张）顺序正确。
- [ ] 相机在 `FKPermissions` 授权后可用。
- [ ] 拒绝权限返回类型化错误；Examples 展示降级 UI。
- [ ] 临时 URL 清理策略在 README 说明。
- [ ] README 含 Info.plist 与 PHPicker / UIImagePicker 对照表。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 领域 | 状态 |
|------|------|
| `PHPicker` / `UIImagePicker` | **无** |
| **`FKPermissions`** | 相机、`.photoLibraryRead`、`.photoLibraryAddOnly` |
| **`FKSheetPresentationController`** | Sheet 展示 |
| **`FKImageLoader` / `FKImageView`** | 展示远端/本地图（路线图 §1.1） |
| **`FKFileManager`** | 路径与分享 — 配合导出 URL |

### 3.2 重复痛点

| 痛点 | 影响 |
|------|------|
| 遗漏 `NSPhotoLibraryUsageDescription` | 审核拒收 |
| iOS 14+ 仍用 UIImagePicker 读全库 | 隐私审查风险 |
| 多张全分辨率进内存 | Jetsam |
| 上传前无统一压缩 | 慢网、成本高 |
| 未处理 `limited` | 多选体验损坏 |
| Delegate 循环引用 | 泄漏 |

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 UIViewController                                           │
│  FKPhotoPicker.pick(from:configuration:)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKPhotoPickerCoordinator（@MainActor）                          │
│  1. FKPermissions 预检                                          │
│  2. 展示 PHPicker / UIImagePicker / 来源选择                    │
│  3. 接收 NSItemProvider / UIImage / URL                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKPhotoProcessingPipeline（后台）                               │
│  解码 → 方向校正 → 缩放 → 压缩 → 写临时文件                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ 完成：[FKPhotoPickerResult] 或 FKPhotoPickerError               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 模块边界

| 关注点 | FKUIKit PhotoPicker | FKCoreKit |
|--------|---------------------|-----------|
| 系统选择器展示 | **是** | 否 |
| 权限请求 | 编排 | **`FKPermissions`** |
| 图像解码/缩放 | **是** | 否 |
| 网络上传统 | 否 | **`FKNetwork`**（宿主） |
| 持久化 | 仅临时导出 | **`FKFileManager`** / Storage |

依赖：`FKUIKit` → `FKCoreKit`；`import Photos`、`PhotosUI`、`UniformTypeIdentifiers`。

### 5.1 FKCoreKit 复用要求（强制）

PhotoPicker **必须**通过 FKCoreKit 完成权限、文件与位图预处理编排，**禁止**重复实现：

| 能力 | 必须使用（FKCoreKit） | 禁止 |
|------|----------------------|------|
| 权限 | **`FKPermissions`**、**`FKPermissionPrePrompt`** | 直接 `AVCaptureDevice` 散落检查 |
| 临时文件路径 | **`FKFileManager`** | 硬编码 `/tmp` 路径 |
| 图像缩放/压缩/JPEG | **`UIImage.fk_*`** Extension | 组件内 UIGraphics 工具 |
| 本地化 | **`FKI18n`** | 硬编码 |
| 后台工作 | **`FKAsync`** / 结构化并发 | 无取消的 GCD 链 |

图像解码流水线可留在 FKUIKit Internal，但**位图操作必须走 Core Extension**。

---

## 6. 选择器后端与选型策略

### 6.1 后端矩阵（规范）

| 流程 | iOS 15+ | 回退 |
|------|---------|------|
| 相册读取 | **`PHPickerViewController`** | `UIImagePickerController` 相册（文档标注弃用） |
| 相机拍摄 | **`UIImagePickerController`**（`.camera`） | 无相机 → `.cameraUnavailable` |
| 相册视频 | PHPicker + `UTType.movie` | 同左 |
| 相机视频 | UIImagePicker + movie | 由配置控制 |

**说明：** PHPicker 读取不必申请完整相册权限（Apple 隐私模型）。配置要求时仍可通过 **`FKPermissions`** 做 UX 预检；回退旧版时必须检查权限。

### 6.2 PHPicker 字段映射

| 配置字段 | `PHPickerConfiguration` |
|----------|----------------------|
| `selectionLimit` | `selectionLimit`（0 表示系统默认 → 内部设上限） |
| `mediaTypes` | `filter`（`.images` / `.videos` / `.livePhotos`） |
| 表示偏好 | `.current` / `.compatible` |

### 6.3 UIImagePicker 用途

相机及可选旧版相册：

- `sourceType`、 `mediaTypes`、`allowsEditing`、`cameraDevice`、`videoMaximumDuration` 均由配置映射。

---

## 7. 来源与展示模式

### 7.1 来源枚举

```swift
public enum FKPhotoPickerSource: Sendable, Equatable {
  case photoLibrary
  case camera
  case cameraFront
  case cameraBack
  case libraryOrCamera    // Action Sheet：相册 / 相机
  case custom(FKPhotoPickerSource)
}
```

### 7.2 来源选择器

`libraryOrCamera` 时优先 **`FKActionSheet`**，否则 `UIAlertController`；文案走 `FKI18n` 键 `fkui.photo_picker.source.*`；iPad 使用 `barButtonItem` / `sourceView` 作 popover 锚点。

### 7.3 展示样式

| `FKPhotoPickerPresentation` | 行为 |
|-----------------------------|------|
| `.automatic` | 相机全屏；相册按设备 sheet |
| `.fullScreen` | 相机默认 |
| `.pageSheet` | iPhone 相册 |
| `.popover(anchor:)` | iPad |

可选用 **`FKSheetPresentationController`** 辅助（非强制）。

---

## 8. 权限预检

### 8.1 策略结构

```swift
public struct FKPhotoPickerPermissionPolicy: Sendable, Equatable {
  public var checksPhotoLibrary: Bool      // 纯 PHPicker 默认 false
  public var checksCamera: Bool            // 相机默认 true
  public var photoLibraryPrePrompt: FKPermissionPrePrompt?
  public var cameraPrePrompt: FKPermissionPrePrompt?
  public var opensSettingsOnDenied: Bool // 默认 false
}
```

### 8.2 流程（规范）

**相册（PHPicker）：**

1. `checksPhotoLibrary == false` → 直接展示 PHPicker（**推荐默认**）。
2. `true` → `await FKPermissions.shared.request(.photoLibraryRead)`；拒绝 → `.permissionDenied`，不展示选择器。

**相机：**

1. `await FKPermissions.shared.request(.camera)`（可选预提示）。
2. 拒绝 → `.permissionDenied(.camera)`；授权 → 展示 UIImagePicker。

### 8.3 受限相册

状态为 `.limited` 时 PHPicker 仍可用；提供：

```swift
public func presentLimitedLibraryManagement(from viewController: UIViewController)
```

调用 `PHPhotoLibrary.shared().presentLimitedLibraryPicker(from:)`。

### 8.4 仅添加权限

选取流程不需要；**写回相册**时宿主使用 `.photoLibraryAddOnly`（README 分述）。

---

## 9. 选择限制与媒体类型

### 9.1 选择策略

```swift
public struct FKPhotoPickerSelectionPolicy: Sendable, Equatable {
  public var limit: Int   // 1=单选；>1=多选；内部限制 1...50
  public var overflowBehavior: FKPhotoPickerOverflowBehavior
}
```

默认多选上限 **9**（聊天附件惯例）；超出时默认 **失败** 而非静默截断。

### 9.2 媒体类型

```swift
public struct FKPhotoPickerMediaTypes: OptionSet, Sendable {
  public static let images
  public static let videos
  public static let livePhotos
}
```

### 9.3 Live Photo

| `FKLivePhotoExportPolicy` | 输出 |
|---------------------------|------|
| `.stillImageOnly` | 静图 JPEG/HEIC |
| `.pairedMovieAndStill` | 静图 + MOV URL |
| `.skip` | 多选时跳过 Live Photo |

---

## 10. 选取流程与生命周期

### 10.1 状态机

```text
idle → presenting → processing → completed
                 ↘ cancelled / failed
```

同一 `FKPhotoPicker` 实例仅允许**一次**活跃会话；重复 `present` → `.alreadyPresenting`。

### 10.2 入口

```swift
@MainActor
public final class FKPhotoPicker {
  public func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration = .init()
  ) async throws -> [FKPhotoPickerResult]
}
```

便捷静态方法：`pickAvatar`、`pickImages(limit:)`。

### 10.3 取消

- PHPicker 空选择完成 → `.cancelled`
- UIImagePicker 取消 → `.cancelled`
- 宿主 dismiss → 取消进行中的 continuation

### 10.4 持有关系

`presentingViewController` 弱引用；完成前 coordinator 强持有自身（README 说明防循环引用）。

---

## 11. 结果模型与交付

### 11.1 单资源结果

```swift
public struct FKPhotoPickerResult: Sendable, Equatable {
  public var id: String
  public var mediaType: FKPhotoPickerMediaType
  public var image: UIImage?
  public var data: Data?
  public var fileURL: URL?
  public var thumbnail: UIImage?
  public var pixelSize: CGSize
  public var byteCount: Int?
  public var uniformTypeIdentifier: String?
  public var assetIdentifier: String?
  public var exifProperties: [String: Any]?  // 剥离后为 nil
}
```

**规范：** `async` 在 **`@MainActor`** 完成并携带 UIKit 类型；上传前应把 `Data`/`URL` 拷到后台任务。`UIImage` 非 `Sendable` — 结果类型可用 `@unchecked Sendable` 或仅主线程交付。

### 11.2 交付模式

```swift
public enum FKPhotoPickerDelivery: Sendable, Equatable {
  case image
  case compressedData
  case fileURL
  case imageAndFileURL      // 上传默认
  case imageAndData
}
```

### 11.3 顺序与空选择

- 数组顺序与用户选择一致。
- 零张且未开 `allowsEmptySelection`（默认 false）→ `.cancelled`。

---

## 12. 图像处理流水线

### 12.1 压缩选项

```swift
public struct FKPhotoCompressionOptions: Sendable, Equatable {
  public var maxPixelDimension: CGFloat?   // 如 2048
  public var jpegQuality: CGFloat         // 默认 0.85
  public var outputFormat: FKPhotoOutputFormat
  public var stripLocationEXIF: Bool      // 默认 true
  public var stripAllEXIF: Bool
  public var preserveAlpha: Bool
}
```

### 12.2 后台步骤

1. 从 `NSItemProvider` / UIImagePicker 加载  
2. `CGImageSource` 降采样（与路线图 `FKImageLoader` 模式一致）  
3. 方向校正  
4. 按 `maxPixelDimension` 等比缩放  
5. 编码  
6. 写入 `temporaryDirectory/FKPhotoPicker/` 唯一文件名  
7. 回主线程组装 `FKPhotoPickerResult`

### 12.3 临时文件

| 策略 | 行为 |
|------|------|
| `.hostResponsible` | 宿主删除（**默认**） |
| `.deleteOnDeinit` | 协调器析构时删 |
| `.deleteAfterCompletion(seconds:)` | 延迟删除 |

### 12.4 进度

多图处理可选 `(processed, total)` 回调，**主线程**触发。

---

## 13. 视频处理

### 13.1 v1 范围

- 相册：复制到临时 MOV/MP4（v1 **不转码**）
- 相机：`videoMaximumDuration` 限制时长
- 可选 `maxVideoBytes` → 超出 `.fileTooLarge`

### 13.2 缩略图

`AVAssetImageGenerator` 首帧作为 `thumbnail`。

### 13.3 交付

`mediaType == .video` 时 **`fileURL` 必填**；`image` 仅为缩略图。

---

## 14. 公开 API

### 14.1 协议

```swift
@MainActor
public protocol FKPhotoPicking: AnyObject {
  func pick(
    from viewController: UIViewController,
    configuration: FKPhotoPickerConfiguration
  ) async throws -> [FKPhotoPickerResult]
}
```

### 14.2 根配置

```swift
public struct FKPhotoPickerConfiguration: Sendable, Equatable {
  public var source: FKPhotoPickerSource
  public var mediaTypes: FKPhotoPickerMediaTypes
  public var selection: FKPhotoPickerSelectionPolicy
  public var delivery: FKPhotoPickerDelivery
  public var compression: FKPhotoCompressionOptions
  public var permission: FKPhotoPickerPermissionPolicy
  public var presentation: FKPhotoPickerPresentationConfiguration
  public var camera: FKPhotoPickerCameraOptions
  public var video: FKPhotoPickerVideoOptions
  public var livePhoto: FKLivePhotoExportPolicy
  public var tempFilePolicy: FKPhotoPickerTempFilePolicy
  public var allowsEmptySelection: Bool
}
```

### 14.3 预设

| 预设 | 特征 |
|------|------|
| `avatar()` | 单选、相册或相机、1024px、JPEG 0.9 |
| `chatAttachments(max:)` | 多图、压缩 fileURL |
| `documentScan()` | 相机、剥离 GPS |
| `highQualitySingle()` | 相册、弱压缩 |

---

## 15. 错误分类

```swift
public enum FKPhotoPickerError: Error, Sendable, Equatable {
  case cancelled
  case permissionDenied(FKPermissionKind)
  case permissionError(FKPermissionError)
  case cameraUnavailable
  case sourceUnavailable(FKPhotoPickerSource)
  case alreadyPresenting
  case selectionLimitExceeded(selected: Int, limit: Int)
  case processingFailed(underlyingDescription: String)
  case fileTooLarge(bytes: Int, max: Int)
  case unsupportedMediaType
  case emptySelection
  case underlying(code: Int, domain: String)
}
```

`LocalizedError` 使用 `FKI18n` / `FKUIKitI18n`。

---

## 16. 配置模型

### 16.1 相机选项

`allowsEditing`、`cameraDevice`（默认后置）、`flashMode`、`showsCameraControls`。

### 16.2 展示配置

`style`、`barButtonItem`（popover 锚点）、`sourceView`。

---

## 17. 展示集成

- 相机：`modalPresentationStyle = .fullScreen`
- PHPicker：iPhone `.pageSheet`；iPad 提供锚点时用 popover
- v1 不做选后预览 Sheet（非目标）

---

## 18. 安全与隐私

### 18.1 Info.plist

| 键 | 场景 |
|----|------|
| `NSPhotoLibraryUsageDescription` | 旧版相册 / 受限管理 |
| `NSCameraUsageDescription` | 相机 |
| `NSMicrophoneUsageDescription` | 带音轨视频 |

### 18.2 EXIF

上传导向导出默认 `stripLocationEXIF = true`。

### 18.3 日志

Release **禁止**记录含用户内容的路径全文或图像字节。

### 18.4 目录

默认仅 `temporaryDirectory`；未经宿主同意不写 Documents。

---

## 19. 并发与内存

- 展示与 delegate：`@MainActor`
- 解码/压缩：后台队列；多图默认**最多 2 路并行**
- 仅要 `fileURL` 时先降采样再构建全尺寸 `UIImage`，控制峰值内存

---

## 20. 无障碍与本地化

- 系统选择器继承 Apple 无障碍
- 来源 Action Sheet：FKI18n VoiceOver 标签
- 错误提示本地化

---

## 21. SwiftUI 桥接

```swift
public struct FKPhotoPickerButton<Label: View>: View { ... }
```

通过 `UIViewControllerRepresentable` 解析 presenter；**不**复制完整 `PhotosPicker` API。

---

## 22. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.md — 组件源码目录规范](COMPONENT_ROADMAP.md#组件源码目录规范)。

```text
Sources/FKUIKit/Components/PhotoPicker/
├── README.md
├── Public/
│   ├── FKPhotoPicker.swift
│   ├── FKPhotoPickerConfiguration.swift
│   ├── FKPhotoPickerResult.swift
│   ├── FKPhotoPickerError.swift
│   ├── FKPhotoCompressionOptions.swift
│   ├── FKPhotoPickerPresets.swift
│   └── Bridge/FKPhotoPickerButton.swift
├── Internal/
│   ├── FKPhotoPickerCoordinator.swift
│   ├── FKPHPickerDelegateAdapter.swift
│   ├── FKImagePickerDelegateAdapter.swift
│   ├── FKPhotoProcessingPipeline.swift
│   ├── FKPhotoTempFileStore.swift
│   └── FKPhotoEXIFStripper.swift
└── Extension/FKPhotoPicker+Convenience.swift
```

---

## 23. FKKitExamples 场景

路径：`Examples/.../FKUIKit/PhotoPicker/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `SingleAvatar` | 单图 + 压缩 |
| 2 | `MultiChatImages` | 9 张顺序 |
| 3 | `CameraOnly` | 权限 + 拍摄 |
| 4 | `PermissionDenied` | 拒绝 UX |
| 5 | `LimitedLibrary` | 受限管理 |
| 6 | `FileURLOutput` | 上传 URL |
| 7 | `StripGPS` | GPS 剥离 |
| 8 | `VideoPick` | 视频 + 缩略图 |
| 9 | `CancelFlow` | cancelled |
| 10 | `SwiftUIPickerButton` | 桥接 |
| 11 | `iPadPopover` | popover |
| 12 | `LargeImageDownscale` | 大图降采样 |

---

## 25. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | PHPicker 是否默认不检查相册权限？ | 是 |
| Q2 | 结果含 `UIImage` 的 Sendable？ | 仅 @MainActor 交付 |
| Q3 | 并行处理数？ | 2 |
| Q4 | 默认 HEIC 还是 JPEG？ | JPEG 兼容性 |
| Q5 | 来源选择用 FKActionSheet？ | 是 |

---

## 26. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §2.6 |

---

## 相关文档

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKPermissions README](../Sources/FKCoreKit/Components/Permissions/README.md)
- [FKMediaGallery_DESIGN.md](FKMediaGallery_DESIGN.md) — 选后/Post 内全屏预览（浏览，非选取；由宿主显式调用）
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md)
