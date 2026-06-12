# FKCarousel / FKImageBanner — 设计需求文档

FKKit **横向分页轮播**控件实现指南：**`FKCarousel`**（通用页面宿主）与 **`FKImageBanner`**（基于同一引擎的图片优先营销/信息流 Hero 预设）。

**文档类型：** 设计需求（对实现者的规范性说明）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.4  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 产品划分 — FKCarousel vs FKImageBanner](#4-产品划分--fkcarousel-vs-fkimagebanner)
- [5. 架构总览](#5-架构总览)
- [6. 模块边界](#6-模块边界)
- [7. FKCarousel — 数据模型](#7-fkcarousel--数据模型)
- [8. FKCarousel — 布局与分页引擎](#8-fkcarousel--布局与分页引擎)
- [9. FKCarousel — 页码指示器](#9-fkcarousel--页码指示器)
- [10. FKCarousel — 自动滚动](#10-fkcarousel--自动滚动)
- [11. FKCarousel — 无限循环](#11-fkcarousel--无限循环)
- [12. FKCarousel — 交互与手势](#12-fkcarousel--交互与手势)
- [13. FKCarousel — 自定义页面内容](#13-fkcarousel--自定义页面内容)
- [14. FKImageBanner — 页面模型与语义](#14-fkimagebanner--页面模型与语义)
- [15. FKImageBanner — 视觉布局与叠加层](#15-fkimagebanner--视觉布局与叠加层)
- [16. FKImageBanner — 加载、占位与 FKImageView](#16-fkimagebanner--加载占位与-fkimageview)
- [17. FKImageBanner — 点击、Deep Link 与 CTA](#17-fkimagebanner--点击deep-link-与-cta)
- [18. 配置模型](#18-配置模型)
- [19. Delegate、Data Source 与回调 API](#19-delegatedata-source-与回调-api)
- [20. 生命周期、可见性与定时器策略](#20-生命周期可见性与定时器策略)
- [21. 预取、复用与性能](#21-预取复用与性能)
- [22. 无障碍](#22-无障碍)
- [23. RTL、Dynamic Type 与深色模式](#23-rtldynamic-type-与深色模式)
- [24. 动效、触觉与「减少动态效果」](#24-动效触觉与减少动态效果)
- [25. 组件边界](#25-组件边界)
- [26. SwiftUI 桥接](#26-swiftui-桥接)
- [27. 建议源码目录结构](#27-建议源码目录结构)
- [28. FKKitExamples 场景](#28-fkkitexamples-场景)
- [29. 待决问题](#29-待决问题)
- [30. 修订历史](#30-修订历史)

---

## 1. 概述

首页信息流、电商 storefront、引导页与活动页反复实现同一套 **横向分页 Banner**：左右滑动换页、圆点或分数指示器、可选自动轮播、营销无限循环、远程图占位、标题/CTA 叠加层、点击跳转 Deep Link。

FKKit 已有 **`FKPagingController`**（全屏 Tab + 子 ViewController 分页）与 **`FKTabBar`**（Tab 条视觉），但缺少可嵌入 Table Header、Collection 补充视图或 Hero 区域的轻量 **`UIView`** 轮播。

| 交付物 | 职责 |
|--------|------|
| **`FKCarousel`** | 通用 `@MainActor` 横向分页器：`UICollectionView` 驱动页面、指示器、自动滚动、无限循环、自定义页面托管。 |
| **`FKImageBanner`** | 基于 `FKCarousel` 的图片轮播预设：远程/本地图、`FKImageView`、叠加层、骨架屏、链接处理。 |
| **`FKCarouselConfiguration`** | 分层 `Sendable` 策略：布局、分页、指示器、自动滚动、动效、无障碍。 |
| **`FKImageBannerConfiguration`** | 图片专用默认：宽高比、叠加层字阶、Loader 注入、预取半径。 |
| **`FKCarouselItem` / `FKImageBannerSlide`** | 带稳定 ID 的可哈希页面模型，支持 Diffable 式更新。 |

**模块：** 仅 `FKUIKit`（`Sources/FKUIKit/Components/Carousel/`）。

**硬依赖（FKImageBanner）：** **`FKImageView`** + **`FKImageLoader`**（路线图 §1.1）。发版时 `FKImageBanner` 须基于 `FKImageView` 编译；若与 ImageView 同列车发版，可文档化临时 `UIImageView` 回退。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **随处嵌入** — 单个 `UIView`，可配置/固有高度；适用于 `UITableView` header、`UICollectionView` supplementary、Stack 与 SwiftUI Representable。
2. **生产级分页** — 按页吸附、速度感知 settling、编程式 `scrollToPage`、当前页回调、RTL 镜像。
3. **页码指示器** — 圆点、拉伸条、数字分数、进度条、自定义 Provider；内外叠加 placement；`pageCount <= 1` 时隐藏。
4. **自动滚动** — 定时间隔；交互暂停、离屏暂停、后台暂停；尊重「减少动态效果」。
5. **无限循环** — 营销场景可选无缝首尾衔接（≥2 项）；有界内容（引导步骤）可关闭。
6. **图片 Banner 预设** — URL/本地资源页、占位/骨架/失败态、可选标题/副标题/CTA、点击 + 链接 URL。
7. **复用 FKKit** — `FKImageView`、`FKSkeleton`、`FKButton`、`FKCornerShadow`、`FKProgressBar`（可选细进度）、`FKDebouncer`、Extension 布局辅助。
8. **HIG 基线** — 可交互叠加层 44pt 扩展点击区域；VoiceOver 页码播报；叠加文字 Dynamic Type。
9. **Swift 6** — `Sendable` 配置；`@MainActor` UI；Delegate 弱引用；Timer/闭包无循环引用。
10. **SwiftUI** — `FKCarouselRepresentable`、`FKImageBannerRepresentable`，`Binding` 绑定当前页索引。

### 2.2 非目标（v1）

| 排除项 | 说明 |
|--------|------|
| 全屏缩放画廊 / 双指放大 Lightbox | 未来 `FKImageGallery`；Banner 点击仅 `openURL` 或宿主回调 |
| 纵向轮播 / 3D Cover Flow | v1 仅横向 |
| 视频页（内嵌 `AVPlayer`） | v1 静态图 Banner；宿主可用自定义 `FKCarousel` 页嵌入 Player |
| `UIPageViewController` 子 VC 分页 | 请用 `FKPagingController` |
| 视差、立方体、自定义转场 Shader | v1 仅标准横向平移 |
| Banner 内 GIF/APNG 自动播放 | 静态 `UIImage`；除非系统解码器原生支持 |
| macOS / tvOS | iOS 15+ UIKit |
| 内置曝光埋点 | 宿主通过 Delegate 观察；可选钩子 |
| 拖拽排序页面 | 宿主替换 items 数组 |
| 多页同时可见的网格 | 请用 Compositional Layout 单独实现 |

### 2.3 成功标准

- [ ] 5 张远程图 Banner：圆点、自动滚动（3s）、无限循环、点击打开 URL — Examples 演示。
- [ ] Peek 布局（露出下一页边缘）+ `FKCornerShadow` 圆角卡片。
- [ ] 用户拖拽时暂停自动滚动；`window == nil` 时暂停。
- [ ] 「减少动态效果」关闭自动滚动；按配置交叉淡入或瞬时换页。
- [ ] VoiceOver：「第 2 张，共 5 张」+ 可选标题；滑动后播报页码。
- [ ] 列表 Header 嵌入：宽高比高度稳定；快速滚动不泄漏 Timer。
- [ ] README 提供与 `FKPagingController`、`FKTabBar`、`FKMarqueeLabel` 的决策树。
- [ ] 组件 README 含目录说明；公开 API 发版时更新根 README 索引。

---

## 3. 背景与问题陈述

### 3.1 当前 FKKit 状态

| 领域 | 状态 |
|------|------|
| 子 VC 横向分页 | **`FKPagingController`** + **`FKTabBar`** |
| 视图内远程图 | **`FKImageView`**（路线图 §1.1） |
| 闪烁占位预设 | **`FKSkeleton`** 含 banner 高度预设 |
| 单行滚动公告 | **`FKMarqueeLabel`**（SmallComponents / Widgets） |
| **`FKCarousel` / `FKImageBanner`** | **无** |

### 3.2 集成方重复痛点

| 痛点 | 无 FKKit 时 |
|------|-------------|
| `UICollectionView` 分页 + 循环索引 | 边界 off-by-one、跳转闪烁 |
| 可复用 Header 中 Timer 泄漏 | Cell 复用后 Timer 仍跑 |
| 拖拽 scrub 时指示器不同步 | 圆点动画错位 |
| 横向 Banner vs 纵向列表手势冲突 | Banner 抢走 Table 纵向滚动 |
| 滑走未取消图片加载 | 错图闪现、内存尖峰 |
| 促销叠加层字阶不统一 | 每屏一套 |

### 3.3 与路线图关系

路线图 §2.4：横向分页、页码指示器、自动滚动策略、无限循环、页面使用 `FKImageView`。依赖图：**`FKImageView` → `FKCarousel` / `FKAvatar`**。Phase **G** 批次含轮播与富媒体 UI。

---

## 4. 产品划分 — FKCarousel vs FKImageBanner

| 维度 | **`FKCarousel`** | **`FKImageBanner`** |
|------|------------------|---------------------|
| **用途** | 任意 `UIView` 内容的通用页面宿主 | 营销 / 信息流 Hero 图片轮播 |
| **页面内容** | Data Source 提供 `UIView` 或配置闭包 | `FKImageBannerSlide` 模型（URL、图片、叠加层） |
| **默认布局** | 全出血单页 | 固定宽高比（如 16:9）+ 可选卡片 inset |
| **加载** | 宿主自行管理 | 内置 `FKImageView` 流水线 |
| **叠加层** | 宿主可选 accessory | 标题、副标题、渐变遮罩、CTA `FKButton` |
| **典型嵌入** | 自定义引导卡片、混合媒体 | 首页 Banner、品类促销条 |

**实现策略：** `FKImageBanner` 为 **`final` 封装**（或薄子类），内部持有 `FKCarousel`，将 `FKImageBannerConfiguration` 映射为 `FKCarouselConfiguration`，并注册内置图片 Cell/渲染器。公开 API 提供 Banner 便捷方法（`setSlides(_:)`、`reloadSlides()`）；高级场景可直接使用 `FKCarousel`。

---

## 5. 架构总览

```text
┌─────────────────────────────────────────────────────────────┐
│ FKImageBanner（公开门面，可选）                                │
│  ├─ slides → carousel items 映射                             │
│  └─ 配置图片 Cell + 叠加层                                     │
└───────────────────────────┬─────────────────────────────────┘
                            │ 持有
┌───────────────────────────▼─────────────────────────────────┐
│ FKCarousel（UIView）                                           │
│  ├─ UICollectionView + FKCarouselFlowLayout                    │
│  ├─ FKCarouselPageIndicatorView（圆点 / 条 / 分数）             │
│  ├─ FKCarouselAutoScrollController（Timer + 暂停规则）          │
│  ├─ FKCarouselInfiniteLoopAdapter（索引映射）                   │
│  └─ FKCarouselGestureCoordinator（嵌套滚动仲裁）                │
└───────────────────────────┬─────────────────────────────────┘
                            │ 使用
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   FKImageView         FKSkeleton          FKButton / CornerShadow
   （图片页）           （初次加载）         （CTA、卡片外观）
```

**状态机（Carousel）：**

| 阶段 | 说明 |
|------|------|
| `idle` | 已稳定在页索引 `i` |
| `dragging` | 用户拖拽；指示器可插值 |
| `decelerating` | 吸附目标页 |
| `programmatic` | `scrollToPage` 动画过渡 |
| `autoAdvancing` | Timer 触发；Delegate 带独立 reason |

对外提供只读 `FKCarouselStateSnapshot`，供调试与 SwiftUI 绑定。

---

## 6. 模块边界

| 范围内（`FKUIKit/Components/Carousel/`） | 范围外 |
|------------------------------------------|--------|
| 横向 Collection 分页 | 纵向分页 |
| 页码指示器渲染 | Tab 文案（`FKTabBar`） |
| 自动滚动 Timer 编排 | 后台拉取 Slide JSON |
| 无限循环索引适配 | CMS / 广告 SDK |
| 带叠加层的图片页 Cell | 全屏画廊缩放 |
| SwiftUI Representable | WidgetKit 时间线 |

**FKCoreKit：** 无需新类型。图片加载经 **`FKImageLoader`** → **`FKImageView`**。

### 6.1 FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 图片 | **`FKImageLoader`** + **`FKImageView`** | Carousel 内 URLSession |
| 防抖/Timer 生命周期 | **`FKDebouncer`**、`CancellableWork` | Cell 复用 Timer 泄漏 |
| 位图 | **`UIImage.fk_*`**（经 ImageView/Loader） | 重复预处理 |
| 布局 | **`FKCoreKit` CGRect/CGSize Extension** | — |

---

## 7. FKCarousel — 数据模型

### 7.1 `FKCarouselItem`

```swift
public struct FKCarouselItem: Hashable, Sendable {
  public let id: String
  public let accessibilityLabel: String?
  public let isInteractive: Bool
}
```

- **`id`** — 跨 reload 稳定，用于图片身份与埋点关联（宿主定义）。
- **`accessibilityLabel`** — 与页码一并播报；默认 nil → 通用「幻灯片」。
- **`isInteractive`** — 为 `false` 时抑制点击回调；可按配置降低不透明度。

### 7.2 条目更新

- **`setItems(_:animated:)`** — 替换全部页；重置到索引 `0`，或 ID 匹配时钳制保留索引。
- **`applyDifference(_:)`** — 可选辅助：ID 不变时避免全量 reload。
- **空条目** — 按 `emptyStatePolicy` 显示 `FKEmptyState` 或高度 collapse 为 0。

### 7.3 索引空间

| 索引空间 | 用途 |
|----------|------|
| **逻辑** | 暴露给宿主：`0 ..< pageCount` |
| **物理** | 无限循环时在首尾含 duplicate Cell |

公开 API **始终**报告逻辑 `currentPageIndex`；内部 Adapter 做物理 ↔ 逻辑映射。

---

## 8. FKCarousel — 布局与分页引擎

### 8.1 CollectionView 基础

**必须**使用 `UICollectionView` + 自定义 **`FKCarouselFlowLayout`**，原因：

- 大列表必须 Cell 复用。
- 交互式指示器进度可映射 `contentOffset / pageWidth`。
- 图片页与宿主自定义页可共用 Collection 架构。

**滚动配置：**

- `layoutMode == .fullPage` 且页宽等于 bounds 宽时，`isPagingEnabled = true`。
- Peek/卡片模式：`itemSize` + `sectionInset` 使吸附步长为 `pageWidth + interPageSpacing`。

### 8.2 布局模式

| 模式 | 行为 |
|------|------|
| **`.fullPage`** | 每视口宽度一页；贴边 |
| **`.cardPeek(interPageSpacing:peekWidth:)`** | 页宽 = bounds − peek − inset；邻居页露出 |
| **`.fixedPageWidth(_:)`** | 固定页宽，在更宽容器中居中 |
| **`.insetCard(cornerRadius:horizontalInset:)`** | 圆角卡片（`FKCornerShadow` 或 layer） |

**高度策略：**

| 策略 | 行为 |
|------|------|
| **`.fixed(_:)`** | 固定点高度 |
| **`.aspectRatio(_:)`** | `height = width / ratio`（如 16/9） |
| **`.intrinsicFromCurrentPage`** | 由内容驱动；图片 Banner 可在加载后更新 |

### 8.3 分页行为

**必须：**

- 拖拽结束按速度与阈值吸附最近页（阈值可配置，默认贴近 UIScrollView 减速）。
- **`scrollToPage(_:animated:)`** — 编程导航；越界 no-op；合并连续调用。
- **`currentPageIndex`** — 可 KVO；稳定后触发 Delegate。
- **`pageCount`** — 来自 items 数组。
- 支持 **`interPageSpacing`**（全出血默认 0）。
- 可配置 **`decelerationRate`**（`.normal` / `.fast`）。

**应当：**

- 暴露 **`scrollProgress`**（0…1 页间分数位置）供宿主自绘视差（v1 无内置视差）。
- **`isScrollEnabled`** — 仅自动滚动、不可手滑的模式。

### 8.4 裁剪与安全区

- 卡片模式默认 **`clipsToBounds = true`**，可配置。
- 可选 **`contentInsets`** 适配安全区。
- **`respectsSafeAreaForIndicator`** — 底部指示器避开 Home Indicator。

---

## 9. FKCarousel — 页码指示器

### 9.1 样式

| 样式 | 说明 |
|------|------|
| **`.dots`** | 经典圆点；当前点强调（尺寸/颜色/宽度动画） |
| **`.bar`** | 水平胶囊条表示 `(index+1)/count` |
| **`.fraction`** | 文本 `"2 / 5"`，`FKUIKitI18n` 数字格式 |
| **`.line`** | 每页下划线段（借鉴 `FKTabBar` 细线） |
| **`.custom(...)`** | 宿主回调自绘 |
| **`.none`** | 隐藏 |

### 9.2 位置

| 位置 | 说明 |
|------|------|
| **`.overlayBottom(inset:)`** | 叠在内容上；文档建议渐变遮罩 |
| **`.overlayTop(inset:)`** | 较少用 |
| **`.below(spacing:)`** | 在 Collection 外；增加固有高度 |
| **`.above(spacing:)`** | 在 Collection 上方 |

### 9.3 指示器行为

**必须：**

- `pageCount <= 1` 时隐藏，除非 `showsIndicatorForSinglePage == true`。
- 稳定后更新；可选拖拽时 **`indicatorFollowsScrollProgress`**。
- 可配置 **圆点直径**、**间距**、**当前/非当前色**（语义色 `.label`、`.tertiaryLabel`）。
- **减少动态效果：** 关闭圆点缩放动画；仅交叉淡入当前索引。

**无障碍：**

- 页码已在 Carousel 容器播报时，指示器容器设 **`accessibilityElementsHidden = true`**（可配置，避免重复）。

---

## 10. FKCarousel — 自动滚动

### 10.1 配置

```swift
public struct FKCarouselAutoScrollConfiguration: Equatable, Sendable {
  public var isEnabled: Bool
  public var interval: TimeInterval          // 默认 3.0
  public var repeats: Bool                   // 默认 true
  public var direction: FKCarouselScrollDirection // .forward / .reverse
  public var pausesOnUserInteraction: Bool   // 默认 true
  public var pausesWhenOffscreen: Bool       // 默认 true
  public var pausesWhenAppInactive: Bool     // 默认 true
  public var respectsReducedMotion: Bool     // 默认 true → RM 开启时禁用
}
```

### 10.2 Timer 实现

**必须：**

- `Timer` 挂在 **`RunLoop.main`**，模式 **`.common`**，避免父 ScrollView 饿死触发。
- **`FKCarouselAutoScrollController`** 由 Carousel 持有；`deinit` 与 `didMoveToWindow(nil)` 时失效。
- 触发：前进下一页；末页在无限循环时回 0，或 `repeats == false` 时停止。
- 用户手动换页后重置间隔（防抖连续自动翻页）。

**必须暂停当：**

- 用户 `touchDown` 在 Carousel ScrollView 上。
- `window == nil` / `isHidden` / 父视图 alpha 近 0。
- `UIApplication.willResignActiveNotification`。
- `UIAccessibility.isReduceMotionEnabled` 且 `respectsReducedMotion`。

**Delegate：** `carouselWillAutoAdvance(from:to:)` 宿主返回 `false` 可取消。

---

## 11. FKCarousel — 无限循环

### 11.1 开关

- **`isInfiniteLoopEnabled`** — 引导默认 `false`；`FKImageBanner` 营销预设建议 `true`。
- 需要 **`pageCount >= 2`**；单项自动禁用。

### 11.2 实现要求

**必须**采用首尾 duplicate 策略：

- 物理数据源在 index 0 插入末项克隆、末尾插入首项克隆（或等价三窗技术）。
- 停在 duplicate 上时 **无动画跳转** 到真实对应项。
- **`scrollToPage`** 仅接受逻辑索引；Adapter 翻译。

**禁止：**

- 无界 Cell 数量。
- 破坏 VoiceOver 逻辑页码播报。

### 11.3 循环 + 自动滚动

- 末页向前自动滚动无缝回第一页。
- 配置支持反向。

---

## 12. FKCarousel — 交互与手势

### 12.1 点击

- 页 **`isInteractive`** 时 **`FKCarouselDelegate.carousel(_:didSelectPageAt:)`**。
- 指示器在外部 hit 区域时，文档说明 z-order，避免与叠加控件冲突。

### 12.2 嵌套滚动仲裁

**问题：** Banner 在纵向 `UITableView` / `UICollectionView` 内与纵向 pan 竞争。

**必须**支持策略（概念对齐 `FKPagingNestedHorizontalScrollPolicy`）：

| 策略 | 行为 |
|------|------|
| **`.standard`** | UIKit 默认 |
| **`.failParentUntilCarouselAtEdge`** | 非首末页时 Carousel 优先 |
| **`.simultaneous`** | 轴向锁定前允许纵向 |

暴露 **`carousel.panGestureRecognizer`** 供高级宿主接线。

### 12.3 导航返回手势

- 可选 **`requiresNavigationPopGestureToFail`** — 首页横向 Carousel 在首页时允许边缘返回（`require(toFail:)`，与 PagingController 文档一致）。

---

## 13. FKCarousel — 自定义页面内容

### 13.1 Data Source 协议

```swift
@MainActor
public protocol FKCarouselDataSource: AnyObject {
  func numberOfPages(in carousel: FKCarousel) -> Int
  func carousel(_ carousel: FKCarousel, viewForPageAt index: Int, reusing view: UIView?) -> UIView
}
```

**必须：**

- 复用传入 `view`（同类型）；宿主 reconfigure 前清空子状态。
- 可选 **`registerPageView(_:identifier:)`** 注册复用 ID。

### 13.2 条目驱动托管

简单场景：**`FKCarouselHostPageView`** + `(FKCarouselItem, CGRect) -> UIView` 闭包，无需完整 Data Source。

### 13.3 ViewController 页面

**v1 非目标。** 全屏 VC 分页请用 **`FKPagingController`**。若未来需要，仅对可见页做 child  containment。

---

## 14. FKImageBanner — 页面模型与语义

### 14.1 `FKImageBannerSlide`

```swift
public struct FKImageBannerSlide: Hashable, Sendable {
  public let id: String
  public let imageSource: FKImageBannerImageSource
  public let title: String?
  public let subtitle: String?
  public let accessibilityLabel: String?
  public let linkURL: URL?
  public let linkOpenPolicy: FKImageBannerLinkOpenPolicy
  public let isInteractive: Bool
  public let overlayStyle: FKImageBannerOverlayStyle?
}

public enum FKImageBannerImageSource: Hashable, Sendable {
  case url(URL, cacheKey: String?)
  case image(UIImage)
  case named(String, bundle: Bundle?)
}
```

**说明：**

- 优先 **`case asset(String)`** 保证 Sendable；`UIImage` case 文档化为仅宿主内存促销。
- **`linkOpenPolicy`** — `.inAppSafari`、`.openSystem`、`.callbackOnly`。
- **`overlayStyle`** — 单页覆盖全局叠加层配置。

### 14.2 批量 API

```swift
public final class FKImageBanner: UIView {
  public func setSlides(_ slides: [FKImageBannerSlide], preservingIndex: Bool)
  public func reloadSlide(id: String)
  public var slides: [FKImageBannerSlide] { get }
}
```

---

## 15. FKImageBanner — 视觉布局与叠加层

### 15.1 图片 contentMode

| 模式 | 用途 |
|------|------|
| **`.scaleAspectFill`** | 默认营销裁剪 |
| **`.scaleAspectFit`** | 留边促销 |
| **`.scaleToFill`** | 少用；文档说明变形 |

### 15.2 叠加层栈（每页）

自下而上：

1. **`FKImageView`**（或下方骨架）
2. **渐变遮罩** — `CAGradientLayer`，可配置色/停点（底部加重保文字可读）
3. **标题** — `UILabel`，Dynamic Type（默认 `.headline`）
4. **副标题** — `.subheadline`，次要色
5. **CTA** — 可选 **`FKButton`**（紧凑预设）

**必须：**

- **`maximumTextLines`**（默认标题 2 / 副标题 1）。
- 尾部截断；v1 不要求展开。
- **叠加可见性** — `.always`、`.accessibilityOnly`、`.never`。
- **RTL** — 文字与 CTA 用 leading/trailing 约束。

### 15.3 卡片 / 圆角

- 复用 **`FKCornerShadowConfiguration`** 或 **`FKImageBannerConfiguration.cardStyle`**。
- 静态工厂：**`FKImageBannerPresets.homeHero()`**、**`.compactPromo()`**、**`.edgeToEdge()`**。

---

## 16. FKImageBanner — 加载、占位与 FKImageView

### 16.1 图片加载

**必须：**

- 每个可见/复用 Cell 一个 **`FKImageView`**。
- **`targetSize`** = Cell bounds（点）× 屏幕 scale，用于降采样。
- 可注入 **`imageLoader`**（默认 `FKImageLoader.shared`）。
- 复用时取消进行中的加载（`prepareForReuse`）。

### 16.2 占位状态

| 状态 | UI |
|------|-----|
| 加载中 | 可选 **`FKSkeleton`** 或 `FKImageView` 占位色 |
| 成功 | 交叉淡入（可配置时长；RM 时为 0） |
| 失败 | 单页 fallback 图；Banner 级 **`failurePolicy`**（隐藏该页 vs 错误块） |

### 16.3 预取

- **`prefetchRadius`**（默认 1）：稳定后对逻辑索引 ± radius 请求图片。
- 有 **`FKImageLoader`** 预取 API 时使用；否则文档化低优先级 `loadImage`。

### 16.4 单页 / 空

- 0 张 → 可选空占位或零高度。
- 1 张 → 隐藏指示器；无论配置如何禁用自动滚动。

---

## 17. FKImageBanner — 点击、Deep Link 与 CTA

### 17.1 点击图片区域

**必须：**

- 可交互时触发 **`FKImageBannerDelegate.imageBanner(_:didSelectSlideAt:)`**。
- 有 **`linkURL`** 且策略允许时，Delegate **`shouldOpenLink(for:)`** 确认后打开。

### 17.2 CTA 按钮

- 独立回调 **`didTapCTA(forSlideAt:)`**；默认不自动打开 `linkURL`，除非 **`ctaUsesLinkURL`**。
- CTA 支持 **`FKButton`** 加载/禁用态。

### 17.3 安全

- 默认仅 **`http`/`https`/`tel`**；自定义 scheme 白名单可配置。
- 禁止记录含 Token 的完整 URL。

---

## 18. 配置模型

### 18.1 分层（两种类型）

对齐 **`FKButton`** / **`FKProgressBar`**：

```swift
public struct FKCarouselConfiguration: Equatable, Sendable {
  public var layout: FKCarouselLayoutConfiguration
  public var paging: FKCarouselPagingConfiguration
  public var indicator: FKCarouselIndicatorConfiguration
  public var autoScroll: FKCarouselAutoScrollConfiguration
  public var interaction: FKCarouselInteractionConfiguration
  public var motion: FKCarouselMotionConfiguration
  public var accessibility: FKCarouselAccessibilityConfiguration
  public var emptyState: FKCarouselEmptyStatePolicy
}
```

**应用：**

```swift
carousel.apply(configuration: config) // 尽量保留当前索引
```

### 18.2 全局默认

```swift
public enum FKCarouselDefaults {
  public static var configuration: FKCarouselConfiguration
  public static var imageBannerConfiguration: FKImageBannerConfiguration
}
```

### 18.3 预设

| 预设 | 说明 |
|------|------|
| **`FKCarouselPresets.fullWidth()`** | 全出血，底部圆点叠加 |
| **`FKCarouselPresets.cardPeek()`** | 电商 Peek |
| **`FKImageBannerPresets.homeHero()`** | 16:9、无限循环、4s 自动滚动 |
| **`FKImageBannerPresets.onboarding()`** | 无循环、无自动滚动、分数指示器 |

---

## 19. Delegate、Data Source 与回调 API

### 19.1 `FKCarouselDelegate`

```swift
@MainActor
public protocol FKCarouselDelegate: AnyObject {
  func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason)
  func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int)
  func carousel(_ carousel: FKCarousel, willAutoAdvanceFrom from: Int, to: Int) -> Bool
  func carouselDidEndDragging(_ carousel: FKCarousel, willDecelerate: Bool)
}
```

**`FKCarouselPageChangeReason`：** `.userSwipe`、`.programmatic`、`.autoScroll`、`.loopCorrection`、`.reload`。

### 19.2 闭包式 API

**`FKCarouselCallbacks`** — 可选 `@MainActor` 闭包，便于 SwiftUI（对齐 `FKSearchBarCallbacks`）。

### 19.3 `FKImageBannerDelegate`

扩展或包装 Carousel Delegate，增加 `didSelectSlide`、`shouldOpenLink`、`didTapCTA`。

---

## 20. 生命周期、可见性与定时器策略

**必须监听：**

| 事件 | 动作 |
|------|------|
| `didMoveToWindow` | 按可见性启停自动滚动 |
| `willMove(toSuperview:)` | 取消待定动画 |
| `deinit` | 失效 Timer |
| `UIApplication.didEnterBackground` | 暂停自动滚动 |
| `UIApplication.didBecomeActive` | 可见且配置允许时恢复 |
| `traitCollectionDidChange` | 更新颜色；重评 Reduce Motion |

**列表复用：** Banner 离窗但未 dealloc 时 Timer **必须停止**。文档说明宿主在 `prepareForReuse` 中释放强引用。

---

## 21. 预取、复用与性能

### 21.1 Cell 复用

- **`FKImageBannerPageCell`** 固定 reuse identifier。
- **`prepareForReuse`** 取消加载、重置文案、移除 CTA 动作。

### 21.2 内存

- 保持 **当前 ± prefetchRadius** 页 bitmap 热数据；全局淘汰依赖 `FKImageLoader` 缓存。
- 可选 **`evictOffscreenPagesFromMemory`** 清空远处 Cell 图片（换 CPU）。

### 21.3 主线程

- UIKit 变更均在 `@MainActor`。
- 解码经 `FKImageLoader` 离开主线程。

### 21.4 预算目标

| 指标 | 目标 |
|------|------|
| 吸附动画 | A15+ 五页 Banner 60 fps |
| Timer 漂移 | 60s 间隔误差 < 100ms |
| 复用错图 | URL 身份校验下为 0 |
| Header 嵌入滚动 | 无主线程同步大图解码 |

---

## 22. 无障碍

**必须：**

- 容器 **`accessibilityTraits`** 在可滑动时含 `.allowsDirectInteraction`。
- 播报 **`accessibilityLabel`**：幻灯片文案 +「第 X 张，共 Y 张」，`UIAccessibility.post(notification: .pageScrolled, ...)`。
- 可选 **`accessibilityScroll(_:)`** — VoiceOver 三指滚动换页（可配置）。
- CTA 为独立元素，标签可读（非泛化「按钮」）。
- 减少动态效果关闭自动滚动（§10）。
- 可点击幻灯片与 CTA 最小 44pt 点击区域。

**应当：**

- 叠加文字成组时用 **`accessibilityContainerType`**。

---

## 23. RTL、Dynamic Type 与深色模式

- **RTL：** 横向滚动方向反转；指示器顺序镜像；叠加层 leading/trailing 翻转。
- **Dynamic Type：** 标题/副标题用语义字阶；高度可增 — **`overlayExpansionPolicy`**（`.fixedBannerHeight` 裁剪 vs `.growBanner`）。
- **深色模式：** 指示器语义色；预设可加深遮罩。

---

## 24. 动效、触觉与「减少动态效果」

| 特性 | 默认 |
|------|------|
| 换页动画 | UIScrollView 减速 |
| 指示器圆点缩放 | 允许动效时轻微 spring |
| 图片成功交叉淡入 | 0.25s |
| 自动滚动 | RM 开启时禁用 |
| 换页触觉 | 关（可配置轻 impact，默认关） |

---

## 25. 组件边界

| 场景 | 组件 |
|------|------|
| Tab 条 + 全屏子 VC | **`FKPagingController`** |
| 仅筛选 Tab、无完整分页 | **`FKTabBar`** |
| 单行滚动公告 | **`FKMarqueeLabel`**（Widgets） |
| 持久离线通知条 | **`FKBanner`**（路线图 §2.1）— 非滑动多页 |
| 短暂 Toast | **`FKToast`** |
| 标量进度 | **`FKProgressBar`** |
| 信息流 Hero 图轮播 | **`FKImageBanner`** |
| 自定义混合页类型 | **`FKCarousel`** |

README 中提供决策树。

---

## 26. SwiftUI 桥接

### 26.1 `FKCarouselRepresentable`

```swift
public struct FKCarouselRepresentable: UIViewRepresentable {
  public init(
    items: [FKCarouselItem],
    currentPage: Binding<Int>,
    configuration: FKCarouselConfiguration = FKCarouselDefaults.configuration,
    @ViewBuilder content: @escaping (FKCarouselItem) -> AnyView
  )
}
```

- **`Coordinator`** 实现 Delegate；换页更新 Binding。
- 避免 SwiftUI `.onChange` 与 Binding 回写形成反馈环。

### 26.2 `FKImageBannerRepresentable`

- 接受 `[FKImageBannerSlide]` + `currentPage` Binding。
- 可选 **`onSlideTap`**、**`onCTATap`** 闭包。

---

## 27. 建议源码目录结构

> **目录结构说明（非强制）：** 下列目录树仅为**建议起点**，并非必须严格遵守的模板。实际封装时可按组件复杂度与邻近 FKKit 组件**灵活调整**，但必须保持**可发现性**、在组件 `README.md` 中**文档化**，并符合 FKKit 规范（公开/内部边界清晰、英文 `///`、Swift 6 并发）。详见 [COMPONENT_ROADMAP.zh-CN.md — 组件源码目录规范](COMPONENT_ROADMAP.zh-CN.md#组件源码目录规范)。

```text
Sources/FKUIKit/Components/Carousel/
├── README.md
├── Public/
│   ├── FKCarousel.swift
│   ├── FKImageBanner.swift
│   ├── Models/
│   │   ├── FKCarouselItem.swift
│   │   ├── FKCarouselState.swift
│   │   ├── FKImageBannerSlide.swift
│   │   └── FKImageBannerImageSource.swift
│   ├── Configuration/
│   │   ├── FKCarouselConfiguration.swift
│   │   ├── FKCarouselLayoutConfiguration.swift
│   │   ├── FKCarouselIndicatorConfiguration.swift
│   │   ├── FKCarouselAutoScrollConfiguration.swift
│   │   ├── FKImageBannerConfiguration.swift
│   │   ├── FKCarouselPresets.swift
│   │   └── FKImageBannerPresets.swift
│   ├── Protocols/
│   │   ├── FKCarouselDataSource.swift
│   │   ├── FKCarouselDelegate.swift
│   │   ├── FKImageBannerDelegate.swift
│   │   └── FKCarouselCallbacks.swift
│   └── SwiftUI/
│       ├── FKCarouselRepresentable.swift
│       └── FKImageBannerRepresentable.swift
└── Internal/
    ├── Layout/
    │   ├── FKCarouselFlowLayout.swift
    │   └── FKCarouselLayoutEngine.swift
    ├── FKCarouselPageIndicatorView.swift
    ├── FKCarouselAutoScrollController.swift
    ├── FKCarouselInfiniteLoopAdapter.swift
    ├── FKCarouselGestureCoordinator.swift
    ├── FKCarouselCollectionCoordinator.swift
    ├── Cells/
    │   ├── FKCarouselHostCell.swift
    │   └── FKImageBannerPageCell.swift
    └── FKImageBannerOverlayView.swift
```

**Examples 路径：** `Examples/FKKitExamples/.../FKUIKit/Carousel/`

---

## 28. FKKitExamples 场景

| # | 场景 | 要点 |
|---|------|------|
| 1 | **HomeHeroBanner** | 5 张远程 URL、无限循环、自动滚动、点击打开 URL |
| 2 | **CardPeekPromo** | Peek 布局 + 圆角 |
| 3 | **OnboardingCards** | 自定义 `FKCarousel` 页（UIView）、无循环、分数指示器 |
| 4 | **SingleSlide** | 隐藏指示器；关闭自动滚动 |
| 5 | **MixedOverlay** | 标题/副标题/CTA 变体 |
| 6 | **FailureFallback** | 坏 URL → fallback 图 |
| 7 | **ReduceMotion** | 系统设置关闭自动滚动 |
| 8 | **TableHeaderEmbed** | `UITableView` tableHeaderView 嵌入；滚动 + Timer 生命周期 |
| 9 | **RTL** | 阿拉伯语镜像 |
| 10 | **SwiftUIBanner** | `FKImageBannerRepresentable` + `$currentPage` |
| 11 | **DynamicType** | 大字号叠加层扩展策略 |
| 12 | **ManualControl** | 外部上/下页按钮调用 `scrollToPage` |

---

## 29. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | `FKImageBanner` 单类型还是子类？ | 组合：Banner 内部持有 `FKCarousel` |
| Q2 | CompositionalLayout vs FlowLayout？ | v1 FlowLayout，分页数学更可预期 |
| Q3 | 内置 Safari 打开链接？ | 默认回调；Examples 可选 Helper |
| Q4 | 暴露 scrollProgress 同步外部 `FKTabBar`？ | v1.1；文档化 Delegate offset 手动绑定 |
| Q5 | 视频页一等公民？ | v2 仅自定义 Carousel 页 |
| Q6 | 目录名 `Carousel/` vs `ImageBanner/`？ | `Carousel/` 含两者 |

---

## 30. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | FKCarousel / FKImageBanner 初版设计需求 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 中文版路线图
- [FKImageLoader-FKImageView_DESIGN.zh-CN.md](FKImageLoader-FKImageView_DESIGN.zh-CN.md) — 图片加载依赖
- [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md) — 相关原子组件（Badge、Marquee）
- [FKPagingController README](../Sources/FKUIKit/Components/PagingController/README.md) — 全屏分页边界说明
