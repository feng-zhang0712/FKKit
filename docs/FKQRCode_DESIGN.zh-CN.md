# FKQRCode — 设计需求文档

FKKit **`FKQRCode`** 的实现指导文档：基于系统框架的 **QR 码生成**（`CoreImage`）与 **扫描 UI**（`AVFoundation`），相机权限走 **`FKPermissions`**，零第三方依赖。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) Tier 3 `FKQRCode`  
**缺口分析引用：** [COMPONENT_GAP_ANALYSIS.zh-CN.md](COMPONENT_GAP_ANALYSIS.zh-CN.md) §9  

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. FKCoreKit — 生成与解析](#6-fkcorekit--生成与解析)
- [7. FKUIKit — 扫描 UI](#7-fkuikit--扫描-ui)
- [8. 内容模型与载荷类型](#8-内容模型与载荷类型)
- [9. 公开 API](#9-公开-api)
- [10. 配置模型](#10-配置模型)
- [11. 权限与错误处理](#11-权限与错误处理)
- [12. 性能与线程](#12-性能与线程)
- [13. 安全与隐私](#13-安全与隐私)
- [14. 无障碍](#14-无障碍)
- [15. SwiftUI 桥接](#15-swiftui-桥接)
- [16. 建议源码目录结构](#16-建议源码目录结构)
- [17. FKKitExamples 场景](#17-fkkitexamples-场景)
- [18. 待决问题](#18-待决问题)
- [19. 修订历史](#19-修订历史)

---

## 1. 概述

支付、登录、分享、设备配对等场景需要 **QR 码生成与扫描**。各 App 重复集成 `CIFilter`、`AVCaptureSession`、权限与预览层，且对弱光、重复回调、外链校验处理不一致。

**FKQRCode** 拆分为两层：

| 模块 | 路径（建议） | 职责 |
|------|--------------|------|
| **FKQRCodeGenerator** / **FKQRCodeParser** | `FKCoreKit/Components/QRCode/` | 纯 Swift/Image 生成、字符串规范化、可选校验 |
| **FKQRCodeScannerViewController** / **FKQRCodeScannerView** | `FKUIKit/Components/QRCode/` | 相机预览、扫描框、手电筒、权限 UI |

| 交付物 | 职责 |
|--------|------|
| **`FKQRCodeGenerator`** | `String` / `URL` / 结构化载荷 → `UIImage` / `CIImage` |
| **`FKQRCodeGenerationOptions`** | 尺寸、纠错级别、前景/背景色、Logo 嵌入（可选） |
| **`FKQRCodeParser`** | 扫描字符串 → 类型化 `FKQRCodePayload` |
| **`FKQRCodeScannerViewController`** | 全屏/嵌入扫描 VC |
| **`FKQRCodeScannerConfiguration`** | 扫描框、振动、连续扫描、外链策略 |
| **`FKQRCodeScannerDelegate`** | 识别回调、错误、权限态 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **零第三方** — 仅 `CoreImage`、`AVFoundation`、`UIKit`。
2. **权限统一** — 相机权限 **必须** 经 `FKPermissions`（`.camera`），支持预提示。
3. **纠错与缩放** — 支持 QR 纠错级别 L/M/Q/H；输出按目标 `CGSize` 缩放清晰。
4. **扫描防抖** — 同一 payload 在可配置窗口内不重复回调。
5. **弱光辅助** — 可选手电筒按钮（设备支持时）。
6. **类型化载荷** — URL、纯文本、Wi-Fi（可选 v1.1）、自定义 scheme。
7. **Swift 6** — 配置 `Sendable`；扫描 UI `@MainActor`；Session 配置在专用 queue。
8. **SwiftUI** — `FKQRCodeScannerRepresentable`、`FKQRCodeImageView`。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 条形码（EAN/Code128） | v2 扩展 `FKBarcode` |
| 相册图片识别 | v1.1 可选 `CIDetector` 静态图 |
| 自定义 ML 检测 | 不在范围 |
| 服务端验签 | 宿主职责 |
| macOS / 模拟器无相机 | 扫描 UI 显示占位 + Mock；生成可用 |
| 动态彩色艺术 QR | v1 仅单色 + 可选中心 Logo |

### 2.3 成功标准

- [ ] 生成 256×256 QR 可扫且纠错级别可配置。
- [ ] 真机扫描 URL 回调一次（防抖生效）。
- [ ] 相机拒绝权限时展示 `FKEmptyState` 风格引导（跳转设置）。
- [ ] 模拟器 Examples 使用 Mock Provider 演示回调。
- [ ] README 含安全章节（外链打开策略）。
- [ ] `xcodebuild` 通过，`SWIFT_STRICT_CONCURRENCY=complete`。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

| 能力 | 状态 |
|------|------|
| `FKPermissions` | ✅ 含 `.camera` |
| `FKEmptyState` | ✅ 可用于无权限/无相机占位 |
| `FKToast` | ✅ 扫描成功轻提示（宿主可选） |
| QR 生成/扫描 | ❌ 无 |

### 3.2 常见集成痛点

| 痛点 | FKQRCode 对策 |
|------|---------------|
| `AVCaptureSession` 阻塞主线程 | 专用 serial queue 启停 |
| 旋转后预览拉伸 | 预览层 `videoGravity` + 方向更新 |
| 连续扫同一码弹多次 | `FKDebouncer` 或 cooldown 窗口 |
| 任意 URL 直接 `open` | `FKQRCodeNavigationPolicy` opt-in |
| Info.plist 遗漏相机用途 | README + Examples plist 注释 |

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ 宿主 App                                                        │
│  present(FKQRCodeScannerViewController)                         │
│  或 UIImageView.image = FKQRCodeGenerator.make(...)             │
└───────────────┬─────────────────────────────┬───────────────────┘
                │                             │
┌───────────────▼──────────────┐   ┌──────────▼──────────────────┐
│ FKUIKit / QRCode             │   │ FKCoreKit / QRCode          │
│  Scanner VC + Preview        │   │  Generator + Parser         │
│  Overlay + Torch             │   │  CIFilter CIQRCodeGenerator │
└───────────────┬──────────────┘   └──────────┬──────────────────┘
                │                             │
                └─────────────┬───────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────────┐
│ AVFoundation / CoreImage                                        │
│  AVCaptureSession + AVCaptureMetadataOutput                     │
│  CIFilter QR generation                                         │
└─────────────────────────────────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────────────────┐
│ FKPermissions (.camera)                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 模块边界

| 关注点 | FKCoreKit QRCode | FKUIKit QRCode | FKPermissions |
|--------|------------------|----------------|---------------|
| 生成 `UIImage` | **是** | 可封装 `UIImageView` | 否 |
| 相机预览 | 否 | **是** | 否 |
| 权限请求 | 调用方或 UI 层调用 | **编排** | **实现** |
| 打开外链 | 否 | 策略回调 | 否 |

### 5.1 FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 相机权限 | **`FKPermissions.shared.request(.camera)`** | 直接 `AVCaptureDevice.requestAccess` |
| 防抖 | **`FKDebouncer`**（扫描重复） | 自写 Timer |
| 图像缩放 | **`UIImage` / `CGSize` Extension**（`fk_*`） | 重复降采样逻辑 |
| 日志 | **`FKLogger`**（调试，不含 payload 全文） | `print` 生产路径 |
| 本地化 | **`FKI18n`** | 硬编码权限文案 |

### 5.2 FKUIKit 复用要求（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| 无权限 UI | **`FKEmptyStateConfiguration`** | 自建空白页 |
| 按钮 | **`FKButton`**（手电筒、关闭） | 裸 `UIButton` 除非内部 Cell |
| 触觉 | 可选 **`UIImpactFeedbackGenerator`**（扫描成功） | — |

---

## 6. FKCoreKit — 生成与解析

### 6.1 FKQRCodeGenerator

```swift
public enum FKQRCodeGenerator {
  public static func makeImage(
    from string: String,
    options: FKQRCodeGenerationOptions = .default
  ) throws -> UIImage

  public static func makeCIImage(
    from string: String,
    options: FKQRCodeGenerationOptions = .default
  ) throws -> CIImage
}
```

**实现要点：**

- Filter：`CIQRCodeGenerator`；`inputMessage` 为 UTF-8 `Data`；
- `inputCorrectionLevel`：`L/M/Q/H`；
- 缩放：使用 `CGAffineTransform` 或 `UIImage.fk_*` 扩展 **禁止** 插值模糊 — 最近邻放大保持模块清晰；
- 可选 Logo：中心嵌入 `UIImage`，自动提高纠错至 **H**；Logo 面积 ≤ 22%（文档约定）。

### 6.2 FKQRCodeParser

```swift
public enum FKQRCodeParser {
  public static func parse(_ rawValue: String) -> FKQRCodePayload
}
```

**FKQRCodePayload：**

```swift
public enum FKQRCodePayload: Sendable, Equatable {
  case url(URL)
  case text(String)
  case unknown(String)
}
```

Wi-Fi `WIFI:S:...` 等可作为 v1.1 扩展 case。

### 6.3 错误

```swift
public enum FKQRCodeError: Error, Sendable {
  case emptyContent
  case contentTooLong(maxBytes: Int)
  case filterFailed
  case imageConversionFailed
}
```

---

## 7. FKUIKit — 扫描 UI

### 7.1 FKQRCodeScannerViewController

**职责：**

- 嵌入 `AVCaptureVideoPreviewLayer`；
- `AVCaptureMetadataOutput` 限定 `.qr`；
- 扫描框 overlay（角标 + 可选动画线）；
- 生命周期：`viewWillAppear` 启 session，`viewWillDisappear` 停 session；
- 权限流：`.notDetermined` → 预提示 → `FKPermissions`；`.denied` → EmptyState。

### 7.2 扫描策略

| 配置 | 行为 |
|------|------|
| `scanMode: .once` | 首次成功后暂停 session，回调 delegate |
| `scanMode: .continuous` | 持续扫描 + cooldown |
| `allowsMultipleCallbacks` | 默认 `false` |
| `cooldownInterval` | 默认 2.0s |

### 7.3 手电筒

- 右下或 overlay 上 `FKButton`；
- `AVCaptureDevice.hasTorch` 检测；
- 关闭 VC 时强制 `torchMode = .off`。

---

## 8. 内容模型与载荷类型

### 8.1 生成输入

- 原始字符串（支付链接、DeepLink、JSON 串）；
- `URL` — `absoluteString` 规范化；
- 长度上限：文档注明 QR 版本与字节上限（二进制模式约 2953 bytes @ L）；超出抛 `contentTooLong`。

### 8.2 扫描输出

Delegate：

```swift
public protocol FKQRCodeScannerDelegate: AnyObject {
  func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didScan payload: FKQRCodePayload)
  func qrCodeScannerDidCancel(_ scanner: FKQRCodeScannerViewController)
  optional func qrCodeScanner(_ scanner: FKQRCodeScannerViewController, didFail error: FKQRCodeScannerError)
}
```

---

## 9. 公开 API

```swift
// 生成
let image = try FKQRCodeGenerator.makeImage(from: "https://example.com/pay?id=1")

// 扫描
let scanner = FKQRCodeScannerViewController(configuration: .default)
scanner.delegate = self
present(scanner, animated: true)
```

**async 包装（可选）：**

```swift
public extension FKQRCodeScannerViewController {
  static func scan(from presenter: UIViewController) async throws -> FKQRCodePayload
}
```

使用 `withCheckedThrowingContinuation` + delegate；取消映射为 `CancellationError`。

---

## 10. 配置模型

### 10.1 FKQRCodeGenerationOptions

```swift
public struct FKQRCodeGenerationOptions: Sendable, Equatable {
  public var size: CGSize
  public var correctionLevel: FKQRCodeCorrectionLevel
  public var foregroundColor: UIColor
  public var backgroundColor: UIColor
  public var logo: FKQRCodeLogoEmbedding?
}
```

### 10.2 FKQRCodeScannerConfiguration

```swift
public struct FKQRCodeScannerConfiguration: Sendable, Equatable {
  public var scanMode: FKQRCodeScanMode
  public var cooldownInterval: TimeInterval
  public var showsTorchButton: Bool
  public var overlayStyle: FKQRCodeOverlayStyle
  public var permissionPrePrompt: FKPermissionPrePromptConfiguration?
  public var navigationPolicy: FKQRCodeNavigationPolicy
  public var hapticsOnSuccess: Bool
}
```

**FKQRCodeNavigationPolicy：**

- `.callbackOnly`（默认）— 不自动 `open` URL；
- `.openHTTPInApp` — 仅 `http/https` 且宿主确认；
- `.openExternally` — 调 `UIApplication.shared.open`（需文档警示）。

---

## 11. 权限与错误处理

### 11.1 权限流

1. `await FKPermissions.shared.status(for: .camera)`；
2. `.notDetermined` → 展示 `permissionPrePrompt`（若配置）→ `request`；
3. `.denied` / `.restricted` → `FKEmptyState` + 跳转设置按钮（`FKPermissions` 已有模式）；
4. `.authorized` → 启动 session。

### 11.2 FKQRCodeScannerError

```swift
public enum FKQRCodeScannerError: Error, Sendable {
  case cameraUnavailable
  case permissionDenied
  case sessionConfigurationFailed
  case interrupted
}
```

---

## 12. 性能与线程

- `AVCaptureSession` `startRunning` / `stopRunning` 在 **serial queue**（非 main）；
- Metadata 回调在 delegate queue，解析后 **`MainActor`** 回调 UI；
- 生成 QR 可在后台 `Task` 执行，结果回主线程设 `image`；
- 避免每帧 CIContext 重建 — 复用 static context。

---

## 13. 安全与隐私

- **禁止** 在日志中记录完整支付类 payload；
- URL 打开必须经 `navigationPolicy` 或宿主 delegate 显式确认；
- 自定义 scheme DeepLink 交 `FKBusinessKit` 路由（文档示例，不硬依赖）；
- Info.plist **`NSCameraUsageDescription`** 由宿主提供；Examples 含英文样例文案。

---

## 14. 无障碍

- 扫描框：VoiceOver 焦点顺序 — 关闭按钮 → 手电筒 → 说明文本；
- 扫描成功：可选 `UIAccessibility.post(notification: .announcement, ...)`；
- Reduce Motion：overlay 扫描线动画禁用。

---

## 15. SwiftUI 桥接

```swift
public struct FKQRCodeScannerRepresentable: UIViewControllerRepresentable { ... }
public struct FKQRCodeImageView: View {
  public init(content: String, options: FKQRCodeGenerationOptions = .default)
}
```

---

## 16. 建议源码目录结构

```text
Sources/FKCoreKit/Components/QRCode/
├── Public/
│   ├── FKQRCodeGenerator.swift
│   ├── FKQRCodeParser.swift
│   ├── FKQRCodePayload.swift
│   ├── FKQRCodeGenerationOptions.swift
│   └── FKQRCodeError.swift
└── README.md

Sources/FKUIKit/Components/QRCode/
├── Public/
│   ├── FKQRCodeScannerViewController.swift
│   ├── FKQRCodeScannerConfiguration.swift
│   ├── FKQRCodeScannerDelegate.swift
│   ├── FKQRCodeScannerError.swift
│   └── Bridge/
│       ├── FKQRCodeScannerRepresentable.swift
│       └── FKQRCodeImageView.swift
├── Internal/
│   ├── FKQRCodeCaptureSessionController.swift
│   ├── FKQRCodeOverlayView.swift
│   └── FKQRCodeMockScanner.swift
└── README.md
```

---

## 17. FKKitExamples 场景

路径：`Examples/.../FKCoreKit/QRCode/` 与 `Examples/.../FKUIKit/QRCode/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `GenerateBasics` | 字符串 → 图片展示 |
| 2 | `CorrectionLevels` | L/H 对比 |
| 3 | `LogoEmbedding` | 中心 Logo + 可扫 |
| 4 | `ScanURL` | 真机扫链接 |
| 5 | `ScanDebounce` | 连续扫只回调一次 |
| 6 | `PermissionDenied` | EmptyState + 设置 |
| 7 | `TorchToggle` | 手电筒 |
| 8 | `MockScanner` | 模拟器 Mock payload |
| 9 | `SwiftUIScanner` | Representable |
| 10 | `NavigationPolicy` | 不自动 open |

---

## 18. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 相册识码 v1 还是 v1.1？ | v1.1 |
| Q2 | 嵌入 `FKWebView` 扫 H5 码？ | 不；独立扫描 |
| Q3 | 振动默认开？ | 开，可配置关 |
| Q4 | Mock 放 Core 还是 UIKit？ | UIKit Internal |

---

## 19. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版，源自 COMPONENT_ROADMAP Tier 3 |

---

## 相关文档

- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKPermissions README](../Sources/FKCoreKit/Components/Permissions/README.md)
- [FKEmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md)
