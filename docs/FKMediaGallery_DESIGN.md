# FKMediaGallery — 设计需求文档

FKKit **`FKMediaGallery`** 的实现指导文档：面向生产的 **全屏媒体预览画廊**（Lightbox），支持 Post / 聊天 / 商品详情等场景下，从缩略图进入后**横向浏览同一组图片与视频**、双指缩放、下滑关闭、Hero 转场与页码指示。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.13  
**命名说明：** [FKCarousel-FKImageBanner_DESIGN.md](FKCarousel-FKImageBanner_DESIGN.md) §2.2 曾以 **`FKImageGallery`** 指代同类能力；本组件正式命名为 **`FKMediaGallery`**，以明确图片 + 视频混合预览范围。

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 产品划分 — FKMediaGallery vs 邻域组件](#4-产品划分--fkmediagallery-vs-邻域组件)
- [5. 架构总览](#5-架构总览)
- [6. 模块边界](#6-模块边界)
- [7. 数据模型与来源](#7-数据模型与来源)
- [8. 呈现与转场](#8-呈现与转场)
- [9. 分页引擎与页面生命周期](#9-分页引擎与页面生命周期)
- [10. 图片页 — 加载与缩放](#10-图片页--加载与缩放)
- [11. 视频页 — 播放与可见性（FKVideoPlayer）](#11-视频页--播放与可见性fkvideoplayer)
- [12. 手势与交互](#12-手势与交互)
- [13. Chrome 与叠加层](#13-chrome-与叠加层)
- [14. 公开 API 与 Delegate](#14-公开-api-与-delegate)
- [15. 配置模型](#15-配置模型)
- [16. 错误分类](#16-错误分类)
- [17. 与邻域组件的协作边界](#17-与邻域组件的协作边界)
- [18. 并发与内存](#18-并发与内存)
- [19. 无障碍、RTL 与本地化](#19-无障碍rtl-与本地化)
- [20. 安全与隐私](#20-安全与隐私)
- [21. 网络、离线与鉴权](#21-网络离线与鉴权)
- [22. 呈现集成与系统冲突](#22-呈现集成与系统冲突)
- [23. SwiftUI 桥接](#23-swiftui-桥接)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [26. 待决问题](#26-待决问题)
- [27. 修订历史](#27-修订历史)

---

## 1. 概述

社交 Feed（微信朋友圈、Twitter/X、Instagram）、IM 聊天记录、电商评价图、工单附件等场景反复实现同一套 **「点缩略图 → 全屏预览整组媒体」** 能力：

- 从被点击缩略图 **Hero 放大** 进入全屏
- **左右滑动** 浏览同一 Post 的全部图片/视频
- 图片 **双指缩放**、**双击** 放大/还原（以触点为中心）
- **下滑关闭**（interactive dismiss）
- 视频页 **自动暂停** 非当前页；当前页经 **`FKVideoPlayer`** 播放
- 页码 **「3 / 9」** 或圆点指示
- 可选 **长按菜单**（保存、分享、复制链接）
- Feed 缩略图与全屏 **共享缓存 Key**，渐进加载高清图

FKKit 已有 **`FKImageView`**（单图加载展示）、**`FKVideoPlayer`**（视频播放）、**`FKCarousel`**（嵌入式横向轮播 Banner），但缺少 **全屏沉浸式、可缩放、混合媒体** 的独立画廊组件。

| 交付物 | 职责 |
|--------|------|
| **`FKMediaGallery`** | 主协调器：`present` / `dismiss`、会话生命周期、配置分发 |
| **`FKMediaGalleryViewController`** | 全屏 `UIViewController` 宿主：分页 Collection、Chrome、手势 |
| **`FKMediaGalleryItem`** | 单页媒体模型：图片 / 视频 / Live Photo 静帧 |
| **`FKMediaGalleryConfiguration`** | Sendable 策略：转场、缩放、视频、Chrome、预取、交互 |
| **`FKMediaGalleryTransitionAnimator`** | Hero / cross-dissolve 转场 |
| **`FKMediaGalleryPageView`** | 内部协议：图片页 / 视频页统一生命周期 |

**模块：** 仅 `FKUIKit`（`Sources/FKUIKit/Components/MediaGallery/`）。

**硬依赖：** **`FKImageView`** + **`FKImageLoader`**（图片页）；**`FKVideoPlayer`** + **`FKVideoPlayerView`**（视频页，精简控制条预设）。

**视频播放原则（强制）：** 画廊内视频 **必须** 使用 **`FKVideoPlayer`** 能力渲染与控制；**禁止** 默认采用系统 `AVPlayerViewController` / `AVKit` 作为画廊内播放 UI。底层 AVFoundation 由 `FKVideoPlayer` 统一封装。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **社交 Feed 级预览** — 单 Post 内 N 张图 + M 个视频混合浏览；`startIndex` 定位到用户点击项。
2. **全来源覆盖** — 本地 `UIImage`、`file://`、Bundle 资源、远程 HTTPS 图、远程 MP4/HLS 视频、`PHAsset` / `FKPhotoPickerResult` 映射；同一 `items` 数组可任意混搭。
3. **Hero 转场** — 从缩略图 frame 动画进入/退出（可关闭为 cross-dissolve）；源 View 回收时 fallback。
4. **渐进式高清加载** — Feed 缩略图 cacheKey 与画廊大图共享；可选 `thumbnailURL` → `fullSizeURL` 两阶段。
5. **图片缩放** — 双指 pinch、以触点为中心双击放大/还原、边界回弹；缩放时与横向分页手势仲裁。
6. **视频页** — **仅** 经 `FKVideoPlayer`；非当前页暂停；离屏 teardown；HLS / 本地文件 / 鉴权 headers。
7. **下滑关闭** — 拖拽 dimming + 位移；与图片缩放 pan、视频 scrub 不冲突。
8. **Chrome 动作** — 关闭、页码、caption、静音切换、可选分享/更多入口（Delegate 驱动）。
9. **长按上下文菜单** — 保存、分享、复制链接（可配置）。
10. **运行时更新** — 展示中 `updateItems` / `scrollToItem`（聊天发送前删图场景）。
11. **复用 FKKit** — `FKImageView`、`FKImageLoader`、`FKVideoPlayer`、`FKProgressBar`、`FKButton`、`FKFileManager`（分享）、`FKPermissions`（PHAsset / 保存相册）、`FKI18n`。
12. **Swift 6** — 配置 `Sendable`；UI `@MainActor`；Delegate 弱引用。
13. **SwiftUI** — `FKMediaGalleryPresenter` / `fkMediaGallery` modifier。
14. **HIG 基线** — 44pt 触点、VoiceOver、RTL、Dynamic Type、「减少动态效果」。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 系统相册 / 相机选取 | **`FKPhotoPicker`** 职责 |
| 嵌入式 Banner 轮播 | **`FKCarousel` / `FKImageBanner`** |
| 画廊内 **`AVPlayerViewController` 默认 UI** | 必须用 **`FKVideoPlayer`**；完整功能面经 Delegate 跳转 **`FKVideoPlayerViewController`** |
| 评论、点赞等业务 Overlay | 宿主经 `FKMediaGalleryChromeProviding` 注入 |
| 多 Post 纵向 Feed 无限刷 | 宿主编排；画廊仅 **单组 items** |
| **内置**图片裁剪 / 标注 / 滤镜编辑器 | 非 v1；经 Delegate 跳转未来 **`FKImageCropper`**（见 §17.3） |
| Live Photo 长按播放 MOV | v1 显示静帧；v1.1 配对 MOV |
| 360° / AR / PDF 多页 | 非 v1 |
| macOS / Catalyst | iOS 15+ UIKit |
| 内置静默写入相册（无用户动作） | 须经 explicit 保存 / 系统分享 |
| OCR / QR | 非 v1 |
| PiP / AirPlay / 字幕 / 离线 HLS 下载 UI | 画廊内隐藏；完整播放器页提供 |

### 2.3 成功标准

- [ ] **本地混合**：`UIImage` + 本地 `file://` 图 + 本地 MOV/MP4 视频同一组预览。
- [ ] **远程混合**：HTTPS 图 + 远程 MP4 + HLS 直播/点播同一组预览。
- [ ] **跨源混合**：同组内本地 + 远程项并存，页码与切页正确。
- [ ] 9 图 + 2 视频：从第 4 项 Hero 进入，左右滑切，页码正确。
- [ ] 缩略图 → 全屏：共享 `cacheKey` 时秒开缓存图，再渐进替换高清。
- [ ] 远程 HTTPS 图：占位 → 加载进度 → 双指缩放；快速滑走取消、无错图。
- [ ] 视频：`FKVideoPlayer` 播放；滑入 autoplay（可配置）；滑出 pause + teardown；仅 1 路活跃解码。
- [ ] 鉴权 URL：带 headers 的远程视频可播放；带 token 的 CDN 图可加载。
- [ ] 下滑关闭 + 关闭按钮；Hero 返回缩略图无闪烁。
- [ ] 长按菜单 → Delegate 分享 / 保存流程可演示。
- [ ] `updateItems` 删除一项后页码与索引正确。
- [ ] `FKPhotoPickerResult` → `[FKMediaGalleryItem]` — Examples 选后预览。
- [ ] VoiceOver + RTL 切页方向正确。
- [ ] README 决策树；Examples 覆盖 §25。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 领域 | 状态 |
|------|------|
| 单图远程/本地加载 | **`FKImageView`** + **`FKImageLoader`** ✅ |
| 视频播放（含 HLS、headers） | **`FKVideoPlayer`** / **`FKMediaSource`** ✅ |
| 嵌入式横向轮播 | **`FKCarousel`** ✅ |
| 媒体选取 | **`FKPhotoPicker`** ✅ |
| iOS 分享 / Quick Look | **`FKFileManager.makeShareController`** ✅ |
| **全屏混合媒体画廊** | **无** |

### 3.2 集成方重复痛点

| 痛点 | 无 FKKit 时 |
|------|-------------|
| ScrollView 嵌套分页 + 缩放 | 手势冲突 |
| 画廊用 AVKit、Feed 用 FKVideoPlayer | 行为不一致、双份维护 |
| 多视频同时解码 | 内存尖峰 |
| Hero dismiss 与缩略图不同步 | 闪烁 |
| 缩略图与大图重复下载 | 无共享 cacheKey |
| 快速滑动错图 | 无 identity 校验 |
| 发送前预览无法删图 | 缺 runtime update API |
| CDN 鉴权 headers 各写一套 | 无统一 item 模型 |

---

## 4. 产品划分 — FKMediaGallery vs 邻域组件

| 维度 | **`FKMediaGallery`** | **`FKPhotoPicker`** | **`FKCarousel`** | **`FKVideoPlayer`** |
|------|----------------------|---------------------|------------------|---------------------|
| **用途** | 浏览已有媒体 | 选取新媒体 | 嵌入式轮播 | 视频播放 |
| **呈现** | 全屏 modal | 系统 Picker | 内嵌 `UIView` | 内嵌 / 全屏 VC |
| **视频引擎** | **`FKVideoPlayer`（精简）** | 无 | 无（v1） | **`FKVideoPlayer`（完整）** |
| **缩放** | 双指 / 双击 | 无 | 无 | 无 |

**决策规则（README 必须文档化）：**

- **选取** → `FKPhotoPicker`
- **内嵌轮播** → `FKCarousel` / `FKImageBanner`
- **全屏浏览一组图/视频** → `FKMediaGallery`
- **PiP、字幕、离线 HLS、完整控制条** → `FKVideoPlayerViewController`（Delegate 跳转）

---

## 5. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 UIViewController                                           │
│  FKMediaGallery.present(from:items:startIndex:source:config:)    │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKMediaGalleryCoordinator（@MainActor）                         │
│  会话门控 · 转场 · items 校验 · Delegate · 运行时更新            │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│ FKMediaGalleryViewController                                    │
│  ├─ UICollectionView（横向分页，RTL 感知）                       │
│  ├─ FKMediaGalleryImagePageCell → ZoomScrollView + FKImageView  │
│  ├─ FKMediaGalleryVideoPageCell → FKVideoPlayerView + 精简条    │
│  ├─ FKMediaGalleryChromeView                                    │
│  ├─ FKMediaGalleryGestureCoordinator                            │
│  └─ FKMediaGalleryVisibilityController                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   FKImageView          FKVideoPlayer       FKMediaGalleryTransitionAnimator
   FKImageLoader        FKVideoItem
```

**状态机：** `idle` → `presenting` → `browsing` ↔ `dismissing` → `completed`  
重复 `present` → `.alreadyPresenting`。

---

## 6. 模块边界

### 6.1 FKCoreKit / FKUIKit 复用（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 图片加载 | **`FKImageView`** / **`FKImageLoader`** | Cell 内裸 `URLSession` |
| 位图处理 | **`UIImage.fk_*`** | 组件内 UIGraphics 重复实现 |
| **视频播放与 UI** | **`FKVideoPlayer`** + **`FKVideoPlayerView`** | **默认 `AVPlayerViewController`** |
| 分享 | **`FKFileManager.makeShareController`**（Delegate 默认实现可选） | 重复 UIActivity 封装 |
| PHAsset 读 | **`FKPermissions`** + **`FKMediaSource.photoAsset`** | 散落 Photos 权限 |
| 本地化 | **`FKI18n`** / **`FKUIKitI18n`** | 硬编码 |

---

## 7. 数据模型与来源

### 7.1 单页模型

```swift
public struct FKMediaGalleryItem: Sendable, Equatable, Identifiable {
  public var id: String
  public var kind: FKMediaGalleryItemKind
  public var caption: String?
  public var accessibilityLabel: String?
  /// Optional link copied by context menu (e.g. original tweet media URL).
  public var shareURL: URL?
}

public enum FKMediaGalleryItemKind: Sendable, Equatable {
  case image(FKMediaGalleryImageSource)
  case video(FKMediaGalleryVideoSource)
}

public struct FKMediaGalleryImageRequestOptions: Sendable, Equatable {
  public var cacheKey: String?
  /// Smaller URL shown first; full-size loaded progressively when set.
  public var thumbnailURL: URL?
  public var thumbnailCacheKey: String?
}

public enum FKMediaGalleryImageSource: Sendable, Equatable {
  case url(URL, options: FKMediaGalleryImageRequestOptions = .init())
  case image(UIImage)
  case bundleResource(name: String, bundle: Bundle = .main)
  case assetLocalIdentifier(String)   // PHAsset.localIdentifier → FKImageLoader / Photos
}

public enum FKMediaGalleryVideoSource: Sendable, Equatable {
  case url(
    URL,
    posterURL: URL? = nil,
    headers: [String: String] = [:],
    fallbackURLs: [URL] = []
  )
  case item(FKVideoItem)
  case bundleResource(name: String, ext: String, bundle: Bundle = .main, posterURL: URL? = nil)
}
```

**规范：**

- `id` 稳定，用于 Diffable、Hero、runtime update。
- `items.isEmpty` → `.emptyItems`。
- `startIndex` 越界 → clamp + Debug 断言。
- `UIImage` / `UIView` 仅经 `@MainActor` API 交付，不强行塞入 `Sendable` 闭包跨线程。

### 7.2 转场源

```swift
/// @MainActor-only presentation context; not stored in Sendable configuration.
public struct FKMediaGalleryTransitionSource {
  public weak var thumbnailView: UIView?
  public var thumbnailFrameInWindow: CGRect?
  public var cornerRadius: CGFloat
  public var placeholderImage: UIImage?
  /// Index in `items` matching the tapped thumbnail (defaults to startIndex).
  public var itemIndex: Int?
}
```

### 7.3 便捷构造

```swift
extension FKMediaGalleryItem {
  public static func from(_ result: FKPhotoPickerResult) -> FKMediaGalleryItem?
  public static func from(_ results: [FKPhotoPickerResult]) -> [FKMediaGalleryItem]
}
```

| `FKPhotoPickerResult.mediaType` | Gallery kind |
|---------------------------------|--------------|
| `.image` | 优先 `.image(result.image!)`；否则 `.url(fileURL)` |
| `.video` | `.video(.url(fileURL, posterURL: nil))`；`result.thumbnail` 作 `FKVideoItem`/poster |
| `.livePhoto` | v1：`.image` 静帧；v1.1：`.livePhoto` |

### 7.4 媒体来源能力矩阵（规范）

| 来源类型 | 图片 | 视频 | 混合同一 `items` | 实现路径 |
|----------|------|------|------------------|----------|
| 内存 `UIImage` | ✅ | — | ✅ | 直接渲染 |
| 本地 `file://` 图片 | ✅ | — | ✅ | `FKImageLoader` 本地读 |
| 本地 `file://` 视频 | — | ✅ | ✅ | `FKVideoPlayer` + `FKMediaSource.url` |
| App Bundle 资源 | ✅ | ✅ | ✅ | `Bundle.url(forResource:)` |
| 远程 HTTPS 图片 | ✅ | — | ✅ | `FKImageView` + Loader |
| 远程 MP4 /  progressive | — | ✅ | ✅ | `FKVideoPlayer` |
| 远程 HLS (`.m3u8`) | — | ✅ | ✅ | `FKVideoPlayer` HLS |
| `PHAsset` localIdentifier | ✅ | ✅ | ✅ | `FKMediaSource.photoAsset` + 权限 |
| `FKPhotoPickerResult` 临时文件 | ✅ | ✅ | ✅ | §7.3 映射 |
| 远程图 + 本地视频 | ✅ | ✅ | ✅ | 每项独立 kind，无同源限制 |
| 鉴权 headers | ✅¹ | ✅ | ✅ | ¹Loader 全局 headers / URL token；视频 `FKMediaSource` headers |

### 7.5 渐进式加载（Feed → 全屏）

**目标：** 点击 Feed 缩略图后，画廊 **立即** 显示已缓存低清图，再后台拉高清。

**规范：**

1. Feed 缩略图与画廊大图使用 **相同 `cacheKey` 前缀或显式相同 key**（Examples 文档化命名约定，如 `post/{id}/image/{index}`）。
2. Item 设 `thumbnailURL` + `url`（fullSize）时：
   - 先显示 thumbnail（或 `transitionSource.placeholderImage` / 内存缓存）。
   - 再加载 fullSize；完成后 cross-fade（时长可配置，默认 0.2s）。
3. 仅 fullSize URL、无 thumbnail 时：使用 `FKImageLoader` 内存/磁盘命中则秒开。
4. Hero 转场使用 **当前可见位图**（缩略图或 placeholder），不等待 fullSize。

```swift
public struct FKMediaGalleryProgressiveLoadingConfiguration: Sendable, Equatable {
  public var enabled: Bool                    // 默认 true
  public var fullSizeCrossfadeDuration: TimeInterval  // 默认 0.2
  public var showsProgressIndicator: Bool     // 默认 true（FKImageView loading）
}
```

### 7.6 鉴权与 CDN

**图片：**

- 优先在 URL 上携带 token（宿主签名）。
- 全局鉴权：注入自定义 `FKImageLoading` 实例（`FKImageLoaderConfiguration.defaultHeaders`）。
- v1 `FKImageLoadRequest` 无 per-request headers；文档说明限制，Gallery **不**重复造 headers 层。

**视频：**

- `FKMediaGalleryVideoSource.url(..., headers:)` → `FKVideoItem(source: .url(url, headers: headers))`。
- 支持 `fallbackURLs`（CDN  failover）。

---

## 8. 呈现与转场

### 8.1 呈现样式

```swift
public enum FKMediaGalleryPresentationStyle: Sendable, Equatable {
  case fullScreen
  case overFullScreen    // Hero 推荐；透明底
}
```

### 8.2 转场

```swift
public enum FKMediaGalleryTransition: Sendable, Equatable {
  case hero(FKMediaGalleryHeroTransitionOptions)
  case crossDissolve
  case system
}

public struct FKMediaGalleryHeroTransitionOptions: Sendable, Equatable {
  public var duration: TimeInterval              // 默认 0.35
  public var backgroundDimmingAlpha: CGFloat     // 默认 0.95
  public var usesSpringAnimation: Bool           // 默认 true
  public var fadeInFullResolutionDuringTransition: Bool  // 默认 false
}
```

**Hero 流程：**

1. 捕获 `thumbnailView` window frame；若无 view 则用 `thumbnailFrameInWindow`。
2. 快照层动画至目标页 layout；背景 dimming。
3. Dismiss 逆向；源不可见 → cross-dissolve。
4. `UIAccessibility.isReduceMotionEnabled` → cross-dissolve，无 spring。

### 8.3 入口 API

```swift
@MainActor
public final class FKMediaGallery: FKMediaGalleryPresenting {
  public var configuration: FKMediaGalleryConfiguration
  public weak var delegate: FKMediaGalleryDelegate?
  public var chromeProvider: (any FKMediaGalleryChromeProviding)?

  public func present(
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    transitionSource: FKMediaGalleryTransitionSource? = nil,
    configuration: FKMediaGalleryConfiguration? = nil
  ) throws

  public func dismiss(animated: Bool, completion: (() -> Void)? = nil)
}
```

---

## 9. 分页引擎与页面生命周期

### 9.1 Collection

- 横向 `UICollectionView`，`isPagingEnabled`，`decelerationRate = .fast`。
- **RTL：** 使用 `effectiveUserInterfaceLayoutDirection` 镜像 scroll 方向与页码语义。
- iPad 分屏 / 尺寸变化：`viewWillTransition` 重算 layout，保持 `currentIndex` 可见。

### 9.2 生命周期

| 事件 | 图片页 | 视频页 |
|------|--------|--------|
| `willDisplay` | 加载 / 渐进 | 创建 `FKVideoPlayer`，bind `FKVideoPlayerView`，可选 preload |
| `didBecomeCurrent` | — | autoplay（策略允许时） |
| `didEndDisplaying` | cancel load | **pause** + teardown（默认） |
| `galleryWillDismiss` | cancel all | **stop** all |

### 9.3 当前页与 Delegate

- `currentIndex: Int` 只读；变化 → `mediaGallery(_:didChangeCurrentIndex:previousIndex:)`。
- `currentItem: FKMediaGalleryItem?`

### 9.4 预取

`prefetchNeighborCount`（默认 `1`）：相邻页图片经 `FKImageLoader` 预取（屏幕像素 targetSize）；**不**预创建视频 player。

### 9.5 运行时更新与编程式导航

```swift
extension FKMediaGalleryViewController {
  /// Replaces items while presented; preserves current id when possible.
  public func updateItems(
    _ items: [FKMediaGalleryItem],
    currentIndex: Int? = nil,
    animated: Bool = false
  ) throws

  /// Scrolls to page; does not change items array.
  public func scrollToItem(at index: Int, animated: Bool)

  /// Scrolls to item with stable id.
  public func scrollToItem(withID id: String, animated: Bool)
}
```

**`updateItems` 规范：**

- 按 `id` 匹配保留当前页；id 消失则 clamp index。
- count → 0 时自动 dismiss 或抛 `.emptyItems`（可配置 `dismissWhenEmpty`）。
- 聊天「发送前删一张」Examples 必测。

---

## 10. 图片页 — 加载与缩放

### 10.1 结构

```text
FKMediaGalleryImagePageCell
  └─ FKMediaGalleryZoomScrollView
       └─ FKImageView
```

### 10.2 缩放

```swift
public struct FKMediaGalleryZoomConfiguration: Sendable, Equatable {
  public var minimumZoomScale: CGFloat       // 默认 1.0
  public var maximumZoomScale: CGFloat       // 默认 4.0
  public var doubleTapZoomScale: CGFloat     // 默认 2.5
  public var allowsDoubleTap: Bool           // 默认 true
  /// When true, double-tap zooms toward the tap point (Instagram-style).
  public var doubleTapZoomsToFocalPoint: Bool  // 默认 true
}
```

- aspect fit 初始缩放；zoom > 1 时禁止 Collection 切页。
- 缩放至 `minimumZoomScale` 以下时 rubber-band 回弹。

### 10.3 加载与失败

- 远程 / 本地 file / Bundle → `FKImageView` + `FKImageLoadRequest`（含 `cacheKey`、targetSize）。
- 失败：重试按钮 + Delegate `didFailToLoad`；**不**导致整个画廊 dismiss。

### 10.4 加载进度 UI

- 默认显示 `FKImageView` 自带 loading（ spinner 或 skeleton，随 ImageView 配置）。
- `showsProgressIndicator = false` 时仅 dimming placeholder。

---

## 11. 视频页 — 播放与可见性（FKVideoPlayer）

### 11.1 强制集成规范

| 规则 | 说明 |
|------|------|
| **必须** | 每页 `FKVideoPlayer` 实例 + `FKVideoPlayerView` 作为渲染表面 |
| **必须** | 通过 `FKVideoItem` / `FKMediaSource` 加载，支持 url / HLS / file / photoAsset |
| **禁止** | 画廊默认路径使用 `AVPlayerViewController` |
| **允许** | Delegate 请求跳转 **`FKVideoPlayerViewController`** 获得 PiP、字幕等 |

**Gallery 内 `FKVideoPlayer` 配置预设：**

```swift
extension FKVideoPlayerConfiguration {
  /// Strip PiP, AirPlay, settings; slim controls; used by FKMediaGallery.
  public static func galleryEmbedded() -> FKVideoPlayerConfiguration
}
```

实现：`FKMediaGalleryVideoPageCell` 持有 player，`bind(to: playerView)`，离屏 `stop()` + unbind。

### 11.2 精简控制 UI

| 控件 | 默认 |
|------|------|
| 中央播放/暂停 | ✅ |
| Slim 进度条 + scrub | ✅（可关） |
| 静音 / 取消静音 | ✅（Chrome 或 overlay） |
| 当前时间 / 总时长 | 可选 |
| 重播（结束后） | ✅ |
| 全屏 / PiP / AirPlay / 设置 | ❌ 隐藏 |

### 11.3 可见性与 autoplay

```swift
public struct FKMediaGalleryVideoConfiguration: Sendable, Equatable {
  public var autoplayCurrentVideo: Bool
  public var loopsCurrentVideo: Bool
  public var mutedByDefault: Bool
  public var showsMuteButton: Bool
  public var pauseWhenScrolling: Bool
  public var teardownPlayerWhenOffscreen: Bool
  public var cellularAutoplayPolicy: FKMediaGalleryAutoplayPolicy
  public var allowsScrubbing: Bool
  public var playerConfiguration: FKVideoPlayerConfiguration  // 默认 .galleryEmbedded()
}

public enum FKMediaGalleryAutoplayPolicy: Sendable, Equatable {
  case always
  case wifiOnly
  case never
}
```

### 11.4 进度拖拽（Scrub）

- Slim 进度条支持拖拽 seek。
- **拖拽中** 禁止横向切页与下滑关闭。
- 使用 `FKVideoPlayer` seek API；缓冲时显示 `FKProgressBar`。

### 11.5 音频会话

```swift
public enum FKMediaGalleryAudioSessionPolicy: Sendable, Equatable {
  case ambient              // 默认：不打断其他 App 音乐（静音 autoplay 场景）
  case soloAmbient          // 播放时独占，停止后恢复
  case duckOthers           // 压低背景音
}
```

- `present` 时激活；`dismiss` 时恢复先前 session category（经 `FKVideoPlayer` / Core 协调，**不**重复 AVAudioSession 散落调用）。
- 物理静音开关 + `mutedByDefault` 交互：README 说明预期行为。

### 11.6 Poster / 缓冲

- `posterURL` 或 `FKPhotoPickerResult.thumbnail` 作首帧占位。
- 缓冲 spinner 覆盖在 poster 上，首帧就绪后隐藏。

### 11.7 跳转完整播放器

```swift
func mediaGallery(
  _ gallery: FKMediaGallery,
  requestFullScreenVideoPlayerFor item: FKMediaGalleryItem,
  at index: Int,
  player: FKVideoPlayer
) -> Bool
```

默认：长按菜单或双击（可配置）→ present `FKVideoPlayerViewController(player:)`。

---

## 12. 手势与交互

### 12.1 手势矩阵

| 手势 | 图片 zoom≤1 | 图片 zoom>1 | 视频（非 scrub） | 视频 scrubbing |
|------|-------------|-------------|------------------|----------------|
| 横向 swipe | 切页 | 平移 | 切页 | ❌ |
| 纵向 swipe | 下滑关闭 | 平移 | 下滑关闭 | ❌ |
| pinch | 缩放 | 缩放 | — | — |
| double tap |  focal zoom | 还原 | 播放/暂停 | — |
| 长按 | 上下文菜单 | 同上 | 同上 | — |

### 12.2 下滑关闭

```swift
public struct FKMediaGalleryDismissGestureConfiguration: Sendable, Equatable {
  public var allowsInteractiveDismiss: Bool
  public var dismissDistanceRatio: CGFloat     // 默认 0.22
  public var dismissVelocityThreshold: CGFloat
  public var allowsDismissFromVideoPage: Bool  // 默认 true
}
```

### 12.3 单击与 Chrome

```swift
public enum FKMediaGallerySingleTapBehavior: Sendable, Equatable {
  case toggleChrome
  case toggleChromeAndVideoControls
  case none
}
```

### 12.4 长按上下文菜单

```swift
public struct FKMediaGalleryContextMenuConfiguration: Sendable, Equatable {
  public var isEnabled: Bool                   // 默认 true
  public var showsSaveToPhotosAction: Bool       // 默认 true（需 Delegate 或内置权限流）
  public var showsShareAction: Bool              // 默认 true
  public var showsCopyLinkAction: Bool           // 默认 true when item.shareURL != nil
  public var showsEditAction: Bool               // 默认 false；true 时走 §17.3
}
```

**内置 Save / Share 默认实现（可关）：**

- **Save：** `UIImageWriteToSavedPhotosAlbum` / 视频存相册 — 经 **`FKPermissions`** `.photoLibraryAddOnly`；失败 Toast。
- **Share：** `FKFileManager.makeShareController(for: fileURL)` 或 UIImage 分享。
- 宿主可在 Delegate 拦截自定义。

---

## 13. Chrome 与叠加层

```swift
public struct FKMediaGalleryChromeConfiguration: Sendable, Equatable {
  public var showsCloseButton: Bool
  public var showsPageIndicator: Bool
  public var pageIndicatorStyle: FKMediaGalleryPageIndicatorStyle
  public var showsMuteButton: Bool
  public var showsShareButton: Bool              // 触发 Delegate / 默认 Share
  public var showsCaption: Bool
  public var chromeAutoHideInterval: TimeInterval?
  public var backgroundStyle: FKMediaGalleryBackgroundStyle
  public var statusBarStyle: UIStatusBarStyle?   // nil = 自动 light content
}

public enum FKMediaGalleryPageIndicatorStyle: Sendable, Equatable {
  case numeric
  case dots       // count ≤ 10；否则自动 numeric
  case none
}

public enum FKMediaGalleryBackgroundStyle: Sendable, Equatable {
  case black
  case blackTranslucent
  case blur(UIBlurEffect.Style)   // 下滑 dismiss 时可渐变为纯黑
}
```

**自定义 Chrome：**

```swift
public protocol FKMediaGalleryChromeProviding: AnyObject {
  func mediaGallery(
    _ gallery: FKMediaGalleryViewController,
    overlayForPageAt index: Int,
    item: FKMediaGalleryItem
  ) -> UIView?
}
```

---

## 14. 公开 API 与 Delegate

### 14.1 Presenting 协议

```swift
@MainActor
public protocol FKMediaGalleryPresenting: AnyObject {
  func present(
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int,
    transitionSource: FKMediaGalleryTransitionSource?,
    configuration: FKMediaGalleryConfiguration
  ) throws
}
```

### 14.2 Delegate

```swift
@MainActor
public protocol FKMediaGalleryDelegate: AnyObject {
  func mediaGallery(_ gallery: FKMediaGallery, willPresentWith itemCount: Int)
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didChangeCurrentIndex: Int,
    previousIndex: Int
  )
  func mediaGallery(_ gallery: FKMediaGallery, didDismissAt finalIndex: Int?)
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didFailToLoad item: FKMediaGalleryItem,
    at index: Int,
    error: FKMediaGalleryError
  )

  // Actions — return true if handled; false uses built-in when available.
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestShare item: FKMediaGalleryItem,
    at index: Int,
    sourceView: UIView
  ) -> Bool

  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestSaveToPhotos item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool

  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestEdit item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool

  func mediaGallery(
    _ gallery: FKMediaGallery,
    requestFullScreenVideoPlayerFor item: FKMediaGalleryItem,
    at index: Int,
    player: FKVideoPlayer
  ) -> Bool
}
```

Optional 默认空 / `false`（Swift extension）。

### 14.3 预设

| 预设 | 特征 |
|------|------|
| `socialFeed()` | Hero、混合媒体、numeric 页码、Wi‑Fi autoplay、渐进加载、上下文菜单 |
| `chatAttachments()` | cross-dissolve、静音默认、精简 Chrome、`updateItems` 友好 |
| `productDetail()` | 高 max zoom、无 autoplay、numeric 页码 |
| `previewOnly()` | 无 share/edit、宿主 dismiss |
| `authenticatedCDN()` | headers 友好默认、无 autoplay on cellular |

---

## 15. 配置模型

```swift
public struct FKMediaGalleryConfiguration: Sendable, Equatable {
  public var presentationStyle: FKMediaGalleryPresentationStyle
  public var transition: FKMediaGalleryTransition
  public var zoom: FKMediaGalleryZoomConfiguration
  public var progressiveLoading: FKMediaGalleryProgressiveLoadingConfiguration
  public var video: FKMediaGalleryVideoConfiguration
  public var audioSession: FKMediaGalleryAudioSessionPolicy
  public var dismissGesture: FKMediaGalleryDismissGestureConfiguration
  public var interaction: FKMediaGalleryInteractionConfiguration
  public var contextMenu: FKMediaGalleryContextMenuConfiguration
  public var chrome: FKMediaGalleryChromeConfiguration
  public var prefetchNeighborCount: Int
  public var dismissWhenItemsBecomeEmpty: Bool
  public var statusBarHidden: Bool
  public var supportedInterfaceOrientations: UIInterfaceOrientationMask
}

public struct FKMediaGalleryInteractionConfiguration: Sendable, Equatable {
  public var singleTapBehavior: FKMediaGallerySingleTapBehavior
  public var videoDoubleTapTogglesPlayback: Bool
}
```

**自定义 ImageLoader：** 通过 `FKMediaGallery(imageLoader: any FKImageLoading)` 初始化注入；**不**放入 `Equatable` configuration。

---

## 16. 错误分类

```swift
public enum FKMediaGalleryError: Error, Sendable, Equatable {
  case emptyItems
  case alreadyPresenting
  case presenterDeallocated
  case transitionSourceUnavailable
  case imageLoadFailed(index: Int, description: String)
  case videoLoadFailed(index: Int, underlying: String)
  case unsupportedItemKind
  case saveToPhotosDenied
  case shareItemUnavailable
  case updateItemsFailed(reason: String)
}
```

单页失败 **不** 关闭画廊；Chrome 可展示错误态 + 重试。

---

## 17. 与邻域组件的协作边界

### 17.1 FKPhotoPicker

| 流程 | 组件 |
|------|------|
| 选取 | `FKPhotoPicker.pick` |
| 选后预览 | `FKMediaGallery.present(items: .from(results))` |
| 已发布 Post | `FKMediaGallery.present(items: post.media)` |

不在 PhotoPicker 内嵌 Gallery。

### 17.2 FKFileManager

- 默认 Share：`FKFileManager.makeShareController(for: url)`（iOS）。
- 单文件非图视频预览：**不**由 Gallery 承担 → Quick Look `makePreviewController`。

### 17.3 编辑（FKImageCropper）

- v1 Gallery **不含**编辑器 UI。
- `showsEditAction = true` 或 Delegate `didRequestEdit` → 宿主 present 未来 **`FKImageCropper`**（[FKPhotoPicker_DESIGN.md](FKPhotoPicker_DESIGN.md) v1.1）。
- 编辑完成后宿主 `updateItems` 替换对应 `id` 的图片源。

### 17.4 FKVideoPlayer 完整能力

- 画廊 = **精简 FKVideoPlayer**。
- PiP、字幕、离线、QoE → **`FKVideoPlayerViewController`**（§11.7 Delegate）。

---

## 18. 并发与内存

- UI：`@MainActor`。
- 图片解码：`FKImageLoader` 后台。
- **最多 1 路** 活跃视频解码；切页 pause → scroll。
- 大图：屏幕像素降采样；内存中 **最多保留当前页 + 邻居** 全分辨率 bitmap（默认 3 页上限，可配置）。
- Hero 快照：转场结束释放。
- `updateItems` / dismiss：取消所有 in-flight 图片 load 与 video seek。

---

## 19. 无障碍、RTL 与本地化

- 关闭：`fkui.media_gallery.close`
- 页码：`"Photo %1$d of %2$d"` / `"Video %1$d of %2$d"`
- 保存/分享/编辑/复制链接：独立 I18n 键
- VoiceOver：页码变化 `UIAccessibility.post(notification: .pageScrolled)`
- RTL：Collection semanticContentAttribute + 手势方向镜像
- Reduce Motion：Hero off、无 cross-fade 渐进
- Dynamic Type：caption 用 `UIFontMetrics`

---

## 20. 安全与隐私

- Release 推荐 HTTPS；`file://` 仅本地/临时文件。
- 日志不记录完整 token URL。
- `FKPhotoPicker` 临时 URL：宿主清理策略见 PhotoPicker README。
- Save to Photos：**必须**经用户明确动作 + 权限。
- `validatesFileURLs`：继承 `FKImageLoader` 防 symlink。

---

## 21. 网络、离线与鉴权

| 场景 | 行为 |
|------|------|
| 离线 + 磁盘缓存命中 | 图片秒开；视频 file/offline 可播 |
| 离线 + 无缓存 | 图片失败 UI + 重试；视频 `didFailToLoad` |
| 加载中切页 | 取消旧 load；无错图 |
| cellular + `wifiOnly` autoplay | 显示 poster + 中央播放钮 |
| 403 / 401 | 失败 Delegate；可 Retry |

可选：`FKNetworkReachabilityProviding` 注入（Pluggable）显示离线 banner — v1 轻量 Toast 即可。

---

## 22. 呈现集成与系统冲突

| 场景 | 规范 |
|------|------|
| Modal vs Navigation | 默认 **modal** `fullScreen` / `overFullScreen`；**不推荐** push |
| 侧滑返回 | `isModalInPresentation = true` 当 `allowsInteractiveDismiss == false` |
| 父 ScrollView | Present 时暂停父 scroll（不强制；Hero 源在 UITableView 中需 Examples 验证） |
| 状态栏 | `statusBarHidden` + `preferredStatusBarStyle` 来自 Chrome |
| iPad 分屏 | 支持；layout 随 size class 重算 zoom |
| iPad popover | v1 仍 fullScreen；v1.1 可选 popover（Q6） |
| 多窗口 | 每窗口独立 session；不跨 window 共享 coordinator |

---

## 23. SwiftUI 桥接

```swift
public struct FKMediaGalleryPresenter: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  var items: [FKMediaGalleryItem]
  var startIndex: Int
  var configuration: FKMediaGalleryConfiguration
}

extension View {
  public func fkMediaGallery(
    isPresented: Binding<Bool>,
    items: [FKMediaGalleryItem],
    startIndex: Int = 0,
    configuration: FKMediaGalleryConfiguration = .socialFeed()
  ) -> some View
}
```

Presenter 解析 presenter VC（与 `FKPhotoPickerButton` 同模式）。

---

## 24. 建议源码目录结构

```text
Sources/FKUIKit/Components/MediaGallery/
├── README.md
├── Public/
│   ├── FKMediaGallery.swift
│   ├── FKMediaGalleryViewController.swift
│   ├── FKMediaGalleryItem.swift
│   ├── FKMediaGalleryConfiguration.swift
│   ├── FKMediaGalleryError.swift
│   ├── FKMediaGalleryDelegate.swift
│   ├── FKMediaGalleryPresets.swift
│   ├── Transition/
│   │   ├── FKMediaGalleryTransitionSource.swift
│   │   └── FKMediaGalleryTransitionAnimator.swift
│   └── Bridge/
│       └── FKMediaGalleryPresenter.swift
├── Internal/
│   ├── FKMediaGalleryCoordinator.swift
│   ├── FKMediaGalleryCollectionViewLayout.swift
│   ├── FKMediaGalleryGestureCoordinator.swift
│   ├── FKMediaGalleryVisibilityController.swift
│   ├── FKMediaGalleryContextMenuBuilder.swift
│   ├── FKMediaGalleryShareSaveCoordinator.swift
│   ├── Pages/
│   │   ├── FKMediaGalleryImagePageCell.swift
│   │   ├── FKMediaGalleryVideoPageCell.swift
│   │   └── FKMediaGalleryZoomScrollView.swift
│   └── Chrome/
│       └── FKMediaGalleryChromeView.swift
└── Extension/
    ├── FKMediaGalleryItem+PhotoPickerResult.swift
    ├── FKVideoPlayerConfiguration+Gallery.swift
    └── FKMediaGallery+Convenience.swift
```

---

## 25. FKKitExamples 场景

路径：`Examples/.../FKUIKit/MediaGallery/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `SocialFeedPost` | 9 图 + 1 视频；Hero；渐进加载 |
| 2 | `LocalMixedGallery` | UIImage + file 图 + file 视频 |
| 3 | `RemoteMixedGallery` | HTTPS 图 + MP4 + HLS |
| 4 | `LocalRemoteMixed` | 同组本地 + 远程 |
| 5 | `RemoteGallery` | 加载进度、失败重试 |
| 6 | `ZoomGestures` | focal double-tap、pinch、切页仲裁 |
| 7 | `SwipeToDismiss` | 下滑 + 关闭 |
| 8 | `VideoAutoplay` | FKVideoPlayer；Wi‑Fi only；scrub |
| 9 | `ChatPreview` | 本地 file；`updateItems` 删图 |
| 10 | `PhotoPickerBridge` | pick → preview |
| 11 | `ThumbnailCacheShared` | 与 Feed 共享 cacheKey |
| 12 | `ContextMenuShareSave` | 长按；FKFileManager 分享 |
| 13 | `AuthenticatedMedia` | 视频 headers |
| 14 | `SingleImage` | 隐藏页码 |
| 15 | `CustomChrome` | ChromeProviding |
| 16 | `SwiftUIPresenter` | modifier |
| 17 | `ReduceMotion` | Hero 降级 |
| 18 | `ProductDetail` | 高倍缩放 + caption |
| 19 | `RTLGallery` | 阿拉伯语 layout |
| 20 | `FullVideoPlayerHandoff` | → FKVideoPlayerViewController |

---

## 26. 待决问题

| ID | 问题 | 决定 |
|----|------|------|
| Q1 | 视频默认静音？ | `socialFeed()` 否；`chatAttachments()` 是 |
| Q2 | FKVideoPlayerPool？ | v1 否；离屏 teardown |
| Q3 | PHAsset v1？ | **是** — `assetLocalIdentifier` + FKPermissions |
| Q4 | 圆点上限？ | >10 → numeric |
| Q5 | 自定义 ImageLoader？ | 初始化器注入 |
| Q6 | iPad popover？ | v1.1 |
| Q7 | 图片 per-request headers？ | v1 靠 URL token / Loader 全局 headers；v1.1 扩展 Request |
| Q8 | GIF 动画？ | 系统解码则自动播；否则静帧 |

---

## 27. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-18 | 初版 |
| 2026-06-18 | 增补：来源矩阵、渐进加载、FKVideoPlayer 强制规范、鉴权、音频会话、runtime API、上下文菜单、Share/Save、RTL、离线、Examples 扩展 |

---

## 相关文档

- [FKPhotoPicker_DESIGN.md](FKPhotoPicker_DESIGN.md)
- [FKCarousel-FKImageBanner_DESIGN.md](FKCarousel-FKImageBanner_DESIGN.md)
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md)
- [FKFileManager_DESIGN.md](FKFileManager_DESIGN.md) — §16 分享 / Quick Look
- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
