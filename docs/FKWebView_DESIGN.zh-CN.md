# FKWebView — 设计需求文档

FKKit **`FKWebView`** 的实现指导文档：面向生产的 `WKWebView` 封装，含加载进度、错误恢复、导航 chrome、JavaScript Bridge 与策略化链接处理。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §1.6  
**English version:** [FKWebView_DESIGN.md](FKWebView_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 背景与问题陈述](#3-背景与问题陈述)
- [4. 架构总览](#4-架构总览)
- [5. 模块边界](#5-模块边界)
- [6. 加载生命周期与状态机](#6-加载生命周期与状态机)
- [7. 导航 API](#7-导航-api)
- [8. 进度展示](#8-进度展示)
- [9. 错误与离线恢复](#9-错误与离线恢复)
- [10. 导航 Chrome 与工具栏](#10-导航-chrome-与工具栏)
- [11. WKWebView 配置](#11-wkwebview-配置)
- [12. 导航策略与链接处理](#12-导航策略与链接处理)
- [13. JavaScript Bridge](#13-javascript-bridge)
- [14. Cookie、请求头与认证](#14-cookie请求头与认证)
- [15. OAuth 与自定义 URL Scheme](#15-oauth-与自定义-url-scheme)
- [16. WKUIDelegate 与系统对话框](#16-wkuidelegate-与系统对话框)
- [17. 安全与隐私](#17-安全与隐私)
- [18. 配置模型](#18-配置模型)
- [19. Delegate 与回调 API](#19-delegate-与回调-api)
- [20. FKWebViewController（可选宿主）](#20-fkwebviewcontroller可选宿主)
- [21. SwiftUI 桥接](#21-swiftui-桥接)
- [22. 性能与内存](#22-性能与内存)
- [23. 无障碍](#23-无障碍)
- [24. 建议源码目录结构](#24-建议源码目录结构)
- [25. FKKitExamples 场景](#25-fkkitexamples-场景)
- [27. 待决问题](#27-待决问题)
- [28. 修订历史](#28-修订历史)

---

## 1. 概述

混合 Web 内容——用户协议、帮助中心、营销活动、支付页、OAuth 登录、应用内 FAQ——几乎存在于每个消费级 iOS App。直接使用 **`WKWebView`** 时，团队反复实现：

- 顶部加载进度与失败叠加层
- 后退/前进/关闭工具栏
- `decidePolicyFor` 路由与 `target=_blank` 行为
- 临时命名的 JS 消息处理器
- 安全的日志与 Cookie/请求头注入说明

**`FKWebView`**（`Sources/FKUIKit/Components/WebView/`）是持有内部 `WKWebView` 的 **`UIView`** 组合，协调 UI 状态，并集成 **`FKProgressBar`**、**`FKEmptyState`**、**`FKButton`** 与 **`FKNetwork`** 可达性提示。

| 交付物 | 职责 |
|--------|------|
| **`FKWebView`** | 可嵌入自定义布局的 Web 容器 |
| **`FKWebViewController`**（推荐） | 带可选导航 chrome 的 VC 宿主 |
| **`FKWebViewConfiguration`** | Sendable 策略 + 展示 + WK 配置钩子 |
| **`FKJavaScriptBridge`** | 类型化 `WKScriptMessageHandler` 注册表 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **80% 混合页**开箱即用 — 加载 URL、进度、错误恢复。
2. **FKKit 原生 UX** — 复用叠加层、进度条、按钮样式。
3. **明确安全默认** — HTTPS 优先、JS Handler  opt-in、不记录密钥。
4. **OAuth 友好** — 重定向拦截钩子，不绑定特定 SDK。
5. **可注入 `WKWebViewConfiguration`** — Cookie、DataStore、UA、内容拦截（宿主提供）。
6. **Swift 6 / `@MainActor`** UI；WebKit 回调派发到主线程。

### 2.2 非目标（v1）

| 排除 | 说明 |
|------|------|
| 完整浏览器（多 Tab、书签、历史 UI） | 不在范围 |
| 内容拦截规则编译 | 宿主提供 `WKContentRuleList` |
| Service Worker / 离线包管理 | 宿主负责 |
| `SFSafariViewController` 封装 | 文档说明何时用系统 VC |
| 文件上传面板深度定制 | v1.1 转发 `runOpenPanel` |
| tvOS / Mac Catalyst | 仅 iOS 15+ UIKit |

### 2.3 成功标准

- [ ] HTTPS 页面 + 线性进度 + 重试可用。
- [ ] OAuth 示例拦截自定义 scheme 且日志不泄露 token。
- [ ] JS Bridge 往返在 Examples 演示。
- [ ] 外链按策略在 Safari 打开。
- [ ] README 含安全章节；API 不打印 Cookie/头。

---

## 3. 背景与问题陈述

### 3.1 FKKit 现状

- `Sources/` **无** WebKit 代码。
- **`FKEmptyState`**、**`FKProgressBar`**、**`FKNetworkReachability`** 可集成。

### 3.2 痛点

| 痛点 | 影响 |
|------|------|
| `estimatedProgress` KVO 接进度条 | 每 VC 样板代码 |
| 网络/SSL 错误 | 重试 UX 不一致 |
| `target=_blank` | 空白页/导航 Bug |
| JS 桥命名冲突 | 线上事故 |
| OAuth 被 WebView 吞掉 | 登录失败 |
| URL 带 token 打日志 | 安全泄露 |

---

## 4. 架构总览

```text
┌─────────────────────────────────────────────────────────────────┐
│ FKWebView（UIView，@MainActor）                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ FKWebChromeView（可选：后退/前进/刷新/关闭）              │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ FKWebProgressView（FKProgressBar 细条）                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ WKWebView（内部，v1 不公开）                              │  │
│  └───────────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ FKEmptyState 叠加（错误/离线）                            │  │
│  └───────────────────────────────────────────────────────────┘  │
│         FKWebNavigationCoordinator                              │
└─────────────────────────────────────────────────────────────────┘
```

可选 **`FKWebViewController`** 全屏嵌入并配置导航栏关闭按钮。

---

## 5. 模块边界

| 关注点 | FKUIKit WebView | FKCoreKit |
|--------|-----------------|-----------|
| `WKWebView` 持有 | 是 | 否 |
| UI Chrome | 是 | 否 |
| 可达性提示 | 集成 | `FKNetworkReachability` |
| API 鉴权 HTTP | 否 | `FKNetwork` 独立 |

仅 `import WebKit`；无第三方 Web SDK。

---

## 6. 加载生命周期与状态机

### 6.1 状态

```swift
public enum FKWebViewLoadingState: Equatable, Sendable {
  case idle
  case loading(progress: Double?)
  case loaded
  case failed(FKWebViewError)
}
```

### 6.2 转移

| 自 | 事件 | 至 |
|----|------|-----|
| idle | `load` | loading |
| loading | `didFinish` | loaded |
| loading | 失败 | failed |
| failed | 重试 | loading |

### 6.3 公开 API

```swift
public func load(_ request: URLRequest)
public func load(_ url: URL)
public func loadHTMLString(_ string: String, baseURL: URL?)
public func reload()
public func stopLoading()
public func goBack() -> Bool
public func goForward() -> Bool

public var canGoBack: Bool { get }
public var canGoForward: Bool { get }
public var url: URL? { get }
public var title: String? { get }
```

加载中再次 `load` 行为与 WebKit 一致；文档说明替换导航。

---

## 7. 导航 API

### 7.1 请求选项

```swift
public struct FKWebViewRequestOptions: Sendable, Equatable {
  public var additionalHeaders: [String: String]
  public var cachePolicy: URLRequest.CachePolicy
  public var timeoutInterval: TimeInterval
}
```

**安全：** 实现层**禁止**记录 `additionalHeaders`。

### 7.2 历史导航

- `goBack` / `goForward` 返回是否执行成功。
- 根据 `canGoBack` / `canGoForward` 更新工具栏。

### 7.3 下拉刷新

`configuration.interaction.pullToRefreshEnabled` 为 true 时可在内部 `scrollView` 挂 `UIRefreshControl`（v1 默认 false）。

---

## 8. 进度展示

### 8.1 模式

| 模式 | UI |
|------|-----|
| `.none` | 隐藏 |
| `.linearBar` | 细条 `FKProgressBar`（**默认**） |
| `.linearBarTopSafeArea` | 贴顶安全区 |
| `.indeterminateUntilFirstPaint` | 有进度前不确定 |

### 8.2 绑定

- `estimatedProgress` → `FKProgressBar`
- 完成且 `didFinish` 后延迟隐藏（默认 0.15s）
- 失败立即隐藏

### 8.3 配置

```swift
public enum FKWebProgressPresentation: Sendable, Equatable {
  case none
  case linearBar
  case linearBarTopSafeArea
  case indeterminateUntilFirstPaint
}

public struct FKWebProgressConfiguration: Sendable, Equatable {
  public var presentation: FKWebProgressPresentation
  public var progressBar: FKProgressBarConfiguration?  // nil = FKProgressBar 默认
  public var hidesWhenComplete: Bool
  public var completeHideDelay: TimeInterval
}
```

进度条位于 Chrome 下方或贴顶安全区；与 `FKWebViewController` 导航栏共存时不遮挡系统返回手势。

---

## 9. 错误与离线恢复

### 9.1 错误类型

```swift
public enum FKWebViewError: Equatable, Sendable {
  case notConnectedToInternet
  case timedOut
  case secureConnectionFailed
  case serverError(statusCode: Int)
  case cancelled
  case webKit(code: Int, domain: String)
  case unreachableHost
  case custom(message: String)
}
```

README 提供 `NSError` 映射表。

### 9.2 空态叠加

当 `configuration.error.showsEmptyStateOverlay == true`（默认 **true**）且进入 `failed`：

- 使用 **`FKEmptyStateConfiguration`**，phase 为 `.error`
- 标题/文案按 `FKWebViewError` 种类映射（模板放在 `FKUIKitI18n`）
- 主操作 **重试** → `reload()` 或重发上次 `URLRequest`（保留 `additionalHeaders`）
- 次操作 **在 Safari 中打开** — 仅当 URL 为 `http(s)` 且 `configuration.error.showsOpenInSafariAction == true`

空态叠加盖在 `WKWebView` 之上，不销毁 WebView 实例，便于重试时复用会话状态。

### 9.3 离线预检

当 `configuration.reachability.showsOfflineEmptyStateBeforeLoad == true` 且 `FKNetworkReachability.isReachable == false`：

- **跳过** `load`，立即展示离线空态（phase 可区分 `.offline` 与 `.error`）
- 可选注册可达性观察者：网络恢复后自动隐藏空态或提示用户点重试
- 与 §9.2 错误空态共用 `FKWebEmptyStatePresenter`，避免两套叠加逻辑

### 9.4 SSL

- 默认显示错误，**不**自动接受无效证书（v1 无公开绕过 API）。
- 企业 Pinning 可走 `FKWebViewDelegate` 认证挑战（文档警示风险）。

---

## 10. 导航 Chrome 与工具栏

### 10.1 模式

| 模式 | UI |
|------|-----|
| `.none` | 仅 Web 内容 |
| `.compactToolbar` | 后退/前进/刷新/关闭（`FKWebViewController` 默认） |
| `.custom(providerID:)` | 宿主自定义工具栏 |

### 10.2 默认项

| 项 | 行为 |
|----|------|
| 后退 | `goBack()` |
| 前进 | `goForward()` |
| 刷新/停止 | 随加载态切换 |
| 关闭 | 触发 `onClose`（不自动 dismiss VC） |

优先 **`FKButton`** 风格；v1 可用 `UIBarButtonItem` + FK 外观令牌。

### 10.3 标题

`FKWebViewController` 可在 `didFinish` 用 `webView.title` 更新 `navigationItem.title`（可配置）。

---

## 11. WKWebView 配置

### 11.1 分层配置 + Builder

```swift
public struct FKWebViewConfiguration: Sendable, Equatable {
  public var presentation: FKWebPresentationConfiguration   // chrome、进度
  public var interaction: FKWebInteractionConfiguration
  public var navigation: FKWebNavigationConfiguration       // 策略、域名列表
  public var javascript: FKWebJavaScriptConfiguration       // bridge、user scripts
  public var security: FKWebSecurityConfiguration
  public var reachability: FKWebReachabilityConfiguration
  public var error: FKWebErrorConfiguration
  public var accessibility: FKWebAccessibilityConfiguration
  /// 非 Equatable 的 WK 工厂逃逸可放在 FKWebViewConfigurationContext（若需要）
}
```

`WKWebViewConfiguration` 为引用类型，通过：

```swift
public struct FKWebViewWKConfigurationBuilder: Sendable {
  public var apply: @Sendable (WKWebViewConfiguration) -> Void
}
```

在内部 WebView **创建时**应用一次；之后修改需重建（文档说明）。

### 11.2 常见 WK 项

| 设置 | 建议默认 |
|------|----------|
| 内联播放 | 视媒体页 true |
| 需用户手势播放 | 按产品 |
| JavaScript | 默认允许 |
| DataStore | `.default()`；登录可用 `.nonPersistent()` |
| User-Agent | 可追加应用后缀 |

### 11.3 Data Store 与 Cookie

| 场景 | 推荐做法 |
|------|----------|
| 持久登录 | `WKWebsiteDataStore.default()` |
| 临时授权（OAuth） | `WKWebsiteDataStore.nonPersistent()` |
| 预置 Cookie | 在 Builder 中于**首次 load 前**调用 `WKHTTPCookieStore.setCookie` |
| 登出清理 | `WKWebsiteDataStore.default().removeData(ofTypes:…)` |

**禁止**在 Debug/Release 日志中输出 Cookie 值或 `Set-Cookie` 原文。

---

## 12. 导航策略与链接处理

### 12.1 处置枚举

```swift
public enum FKWebNavigationActionDisposition: Sendable, Equatable {
  case allow
  case cancel
  case openExternally(URL)
  case download(URL)
}
```

### 12.2 策略结构

```swift
public struct FKWebNavigationPolicy: Sendable, Equatable {
  public var httpHTTPS: FKWebHTTPPolicy
  public var customSchemes: [String: FKWebCustomSchemePolicy]
  public var targetBlank: FKWebTargetBlankPolicy
  public var mailtoTel: FKWebSystemURLPolicy
}

public enum FKWebTargetBlankPolicy: Sendable, Equatable {
  case loadInPlace      // 在同一 WKWebView 加载 target=_blank
  case openExternally   // UIApplication.shared.open
  case cancel           // 忽略新窗口请求
}
```

### 12.3 决策流程（规范）

在 `decidePolicyFor navigationAction` 中**必须**按序执行：

1. 离线快速失败 → cancel + 离线 UI  
2. http(s) → 域名白/黑名单/外链列表  
3. `targetFrame == nil` → `targetBlank` 策略  
4. 自定义 scheme（如 `myapp://oauth`）→ `onCustomScheme`；默认 cancel 导航  
5. `mailto:` / `tel:` → `UIApplication.shared.open`

### 12.4 域名策略

```swift
public struct FKWebDomainListPolicy: Sendable, Equatable {
  public var allowedHosts: [String]?   // nil = 允许所有 https（仍受 ATS 约束）
  public var deniedHosts: [String]     // 命中则 cancel 并可选错误 UI
  public var externalHosts: [String]   // 命中则在 Safari 打开，不在应用内导航
}
```

`deniedHosts` 与 `externalHosts` 匹配规则：主机名完全匹配或后缀匹配（实现需在 README 说明，如 `endsWith` 子域规则）。

---

## 13. JavaScript Bridge

### 13.1 注册

```swift
public struct FKJavaScriptBridge: Sendable {
  public var handlers: [FKJavaScriptHandlerRegistration]
}

public struct FKJavaScriptHandlerRegistration: Sendable, Equatable {
  public var name: String
  public var handlerID: String   // 映射到宿主闭包表，避免在配置中持有 AnyObject
}
```

内部 `WKUserContentController` 在初始化时 `add(_:name:)`；**`deinit` 必须** `removeScriptMessageHandler(forName:)`，防止 WebKit 强引用泄漏。

### 13.2 收消息

```swift
public protocol FKWebViewJavaScriptHandling: AnyObject {
  func webView(_ webView: FKWebView, didReceive message: FKJavaScriptMessage)
}

public struct FKJavaScriptMessage: Sendable {
  public var name: String
  public var body: FKJavaScriptMessageBody  // JSON 安全、类型擦除
}
```

**必须**校验 `message.name` 仅投递给已注册 handler；未知 name 丢弃并可选 Debug 断言。

### 13.3 注入脚本

`FKUserScriptRegistration`：`source`、`injectionTime`、`forMainFrameOnly`。

### 13.4 从 Native 调用 JavaScript

```swift
public func evaluateJavaScript(
  _ script: String,
  completion: (@MainActor (Result<Any?, Error>) -> Void)? = nil
)
```

在 `loading` 与 `loaded` 状态均可调用；`failed` 时是否允许由文档说明（默认允许对仍存活的 document 执行）。

---

## 14. Cookie、请求头与认证

- 单次加载头：`FKWebViewRequestOptions`
- 全局：通过 Builder 改 DataStore / UA，**不**重复 `FKNetwork` 拦截器职责
- HTTP Basic：默认系统处理；可 delegate 自定义
- README：生产仅用 HTTPS；会话优先 Cookie；登出清非持久数据

---

## 15. OAuth 与自定义 URL Scheme

匹配已注册 scheme 时：

1. **取消** Web 内导航  
2. 回调 `onOAuthRedirect(URL)`  
3. 宿主用 `FKNetwork` 换 token  

Universal Links 由 App 层处理；文档说明分工。

Examples：模拟 `fkkit-examples://oauth/callback?code=demo`。

---

## 16. WKUIDelegate 与系统对话框

默认转发：

| 回调 | 默认 |
|------|------|
| `createWebViewWith` | 按 `targetBlank` 原地或外链 |
| JS alert/confirm/prompt | `UIAlertController` |
| `runOpenPanelWith` | v1.1 或取消 |

可用 `FKWebViewUIDelegate` 覆盖（未来可换 `FKAlert`）。

---

## 17. 安全与隐私

### 17.1 禁止日志

- `Authorization`、Cookie、OAuth code/token、Basic 凭证

URL Debug 默认 `redactsQueryInLogs == true`（仅路径）。

### 17.2 JavaScript

- 仅注册名暴露给 `messageHandlers`
- `javaScriptCanOpenWindowsAutomatically` 默认 false

### 17.3 文件

- `loadFileURL` 仅沙盒/Bundle 合法路径  
- 远程页跳转 `file://` 默认 **拦截**

### 17.4 ATS

尊重 App Transport Security；**无**内置 ATS 例外或降级 API。

### 17.5 混合内容

遵循 WebKit 默认混合内容策略；v1 不提供覆盖 HTTP 子资源加载的公开 API。

---

## 18. 配置模型

见 §11。交互相关标志：

```swift
public struct FKWebInteractionConfiguration: Sendable, Equatable {
  public var allowsBackForwardGestures: Bool  // 默认 true
  public var pullToRefreshEnabled: Bool       // 默认 false
  public var scrollBounces: Bool?
  public var zoomEnabled: Bool                // 避免 legacy scalesPageToFit；依赖 viewport meta
  public var previewingEnabled: Bool          // 3D Touch peek（可用设备）
}
```

```swift
public enum FKWebViewDefaults {
  public static var defaultConfiguration: FKWebViewConfiguration
  public static func inAppBrowser() -> FKWebViewConfiguration
  public static func ephemeralAuth() -> FKWebViewConfiguration
}
```

| 预设 | 行为摘要 |
|------|----------|
| **`inAppBrowser()`** | 紧凑工具栏 + 线性进度 + 未知域名外链走 Safari |
| **`ephemeralAuth()`** | `nonPersistent` DataStore + 自定义 scheme OAuth 钩子 + 关闭时可选清数据 |

---

## 19. Delegate 与回调 API

```swift
@MainActor
public protocol FKWebViewDelegate: AnyObject {
  func webView(_ webView: FKWebView, didChangeState: FKWebViewLoadingState)
  func webView(_ webView: FKWebView, didCommit url: URL?)
  func webView(_ webView: FKWebView, didFinish url: URL?)
  func webView(_ webView: FKWebView, didFail error: FKWebViewError)
  func webView(
    _ webView: FKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    defaultDisposition: FKWebNavigationActionDisposition
  ) -> FKWebNavigationActionDisposition
  func webView(_ webView: FKWebView, didReceiveOAuthRedirect url: URL)
}
```

未实现的方法通过 **protocol extension** 提供默认空实现或透传 `defaultDisposition`。

**`FKWebViewCallbacks`**：`Sendable` 闭包结构体，字段与 delegate 方法一一对应，便于 SwiftUI / 无子类场景。

**`FKWebViewUIDelegate`**：覆盖 WKUIDelegate 弹窗、`createWebViewWith`、文件选择（v1.1）等。

---

## 20. FKWebViewController（可选宿主）

```swift
@MainActor
open class FKWebViewController: UIViewController {
  public let webView: FKWebView
  public init(url: URL, configuration: FKWebViewConfiguration = .init())
}
```

- 全屏嵌入 `FKWebView`，进度条尊重 safe area
- 可选导航栏关闭 `UIBarButtonItem`（不自动 `dismiss`）
- `preferredStatusBarStyle` 来自 `configuration.presentation.statusBarStyle`
- 纯嵌入场景可不使用本 VC，仅将 `FKWebView` 加入任意层级

---

## 21. SwiftUI 桥接

```swift
public struct FKWebViewRepresentable: UIViewRepresentable {
  public var url: URL?
  public var configuration: FKWebViewConfiguration
  public var callbacks: FKWebViewCallbacks
}
```

**必须**在 `updateUIView` 中比较 URL，仅在 binding 变化时 `load`，避免与 `didFinish` 形成重载环路。

可选 **`FKWebViewControllerRepresentable`**：需要完整 Chrome 的全屏场景。

---

## 22. 性能与内存

- 每个 `FKWebView` 实例对应**一个** `WKWebView`（不池化 View 本身）
- `deinit`：移除 `estimatedProgress` KVO、script message handlers、可达性观察者
- 多实例共享 **`WKProcessPool`**：通过 Builder 注入，README 说明内存/进程权衡
- 登出/清缓存便捷 API：

```swift
public static func clearWebsiteData(
  types: Set<String>,
  since: Date,
  completion: (@MainActor () -> Void)?
)
```

---

## 23. 无障碍

- Web 内容由 WebKit 提供 a11y
- Chrome 按钮本地化标签
- 错误叠加继承 `FKEmptyState`
- 容器可选 `accessibilityLabel`："Web content"

---

## 24. 建议源码目录结构

```text
Sources/FKUIKit/Components/WebView/
├── README.md
├── Public/
│   ├── FKWebView.swift
│   ├── FKWebViewController.swift
│   ├── FKWebViewState.swift
│   ├── FKWebViewError.swift
│   ├── Configuration/
│   ├── Navigation/
│   │   ├── FKWebNavigationPolicy.swift
│   │   └── FKWebNavigationActionDisposition.swift
│   ├── JavaScript/
│   │   ├── FKJavaScriptBridge.swift
│   │   └── FKJavaScriptMessage.swift
│   ├── Protocols/
│   │   ├── FKWebViewDelegate.swift
│   │   └── FKWebViewUIDelegate.swift
│   └── Bridge/
│       └── FKWebViewRepresentable.swift
├── Internal/
│   ├── FKWebNavigationCoordinator.swift
│   ├── FKWebChromeView.swift
│   ├── FKWebProgressPresenter.swift
│   ├── FKWebEmptyStatePresenter.swift
│   └── FKWebView+WKDelegates.swift
└── Extension/
    └── FKWebView+Convenience.swift
```

---

## 25. FKKitExamples 场景

路径：`Examples/.../FKUIKit/WebView/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `BasicRemoteLoad` | HTTPS + 进度 |
| 2 | `ErrorRetrySafari` | 404 + 重试 + Safari |
| 3 | `OfflinePreflight` | 离线空态 |
| 4 | `OAuthRedirect` | 自定义 scheme |
| 5 | `JavaScriptBridge` | 消息往返 |
| 6 | `ExternalLinks` | `_blank` → Safari |
| 7 | `ToolbarNavigation` | 历史后退前进 |
| 8 | `EphemeralDataStore` | 非持久 Cookie |
| 9 | `EmbeddedInSheet` | `FKSheetPresentationController` 承载 |
| 10 | `SwiftUIRepresentable` | Binding URL |
| 11 | `LocalHTML` | 本地 HTML |
| 12 | `DomainAllowlist` | 域名策略 |

---

## 27. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | 公开 `wkWebView`？ | v1 否 |
| Q2 | 下拉刷新默认？ | false |
| Q3 | JS 弹窗用 FKAlert？ | v1 UIAlertController |
| Q4 | 共享 ProcessPool？ | Builder 可选 |
| Q5 | 下载 v1？ | 仅回调 |

---

## 28. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-08 | 初版，源自 COMPONENT_ROADMAP §1.6 |

---

## 相关文档

- [FKWebView_DESIGN.md](FKWebView_DESIGN.md) — 英文版
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md)
- [FKEmptyState README](../Sources/FKUIKit/Components/EmptyState/README.md)
- [FKProgressBar README](../Sources/FKUIKit/Components/ProgressBar/README.md)
- [FKNetwork README](../Sources/FKCoreKit/Components/Network/README.md)
