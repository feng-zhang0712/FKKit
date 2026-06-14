# FKAvatar / FKAvatarGroup / FKPresenceIndicator — 设计需求文档

FKKit **头像与在线状态模块**的实现指导文档：三个公开类型 **`FKAvatar`**（单头像）、**`FKAvatarGroup`**（重叠堆叠 +N）、**`FKPresenceIndicator`**（在线/忙碌/离线状态点），统一封装于 `Sources/FKUIKit/Components/Widgets/Avatar/`。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.3  
**所属家族：** [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 模块架构与类型边界](#3-模块架构与类型边界)
- [4. FKCoreKit 复用要求（强制）](#4-fkcorekit-复用要求强制)
- [5. 共享设计语言](#5-共享设计语言)
- [6. FKAvatar](#6-fkavatar)
- [7. FKAvatarGroup](#7-fkavatargroup)
- [8. FKPresenceIndicator](#8-fkpresenceindicator)
- [9. 附件与跨模块组合](#9-附件与跨模块组合)
- [10. SwiftUI 桥接](#10-swiftui-桥接)
- [11. 建议源码目录结构](#11-建议源码目录结构)
- [12. FKKitExamples 场景](#12-fkkitexamples-场景)
- [13. 待决问题](#13-待决问题)
- [14. 修订历史](#14-修订历史)

---

## 1. 概述

导航栏、评论行、资料页、协作者列表、IM 会话等场景需要**一致的用户头像**与**在线状态**呈现。直接手写 `UIImageView` + 圆角 + 小圆点时，团队反复处理：

- 首字母兜底与 CJK 姓名规则
- URL 加载、Cell 复用错图、失败重试
- 故事环、描边、角标、Presence 叠加布局
- Presence 与流程状态 Pill 圆点混淆
- 44pt 点击热区与 VoiceOver

本模块交付 **三个独立公开类型**，Presence 主要附着于 Avatar，Group 组合多个 Avatar；角标仍用 **`FKBadge`**，不在本模块重做。

| 交付物 | 基类 | 职责 |
|--------|------|------|
| **`FKAvatar`** | `UIControl` | 单头像：形状、内容、交互、Presence 槽位 |
| **`FKAvatarGroup`** | `UIView` | 重叠头像 + 溢出「+N」 |
| **`FKPresenceIndicator`** | `UIView` | 8–12pt 状态点；可独立或附着 Avatar |
| **`FKAvatarContent`** | struct | Group 用 Sendable 头像描述 |

**建议路径：** `Sources/FKUIKit/Components/Widgets/Avatar/`

---

## 2. 目标、非目标与成功标准

### 2.1 模块目标

1. **三类型 API 独立** — Presence 为独立类型，但 Avatar 配置可一键附着。
2. **Group 只组合 Avatar** — 禁止 Group 内独立 UIImageView 管线。
3. **FKImageView 集成** — URL 加载经 **`FKImageLoader`** + **`FKImageView`**。
4. **HIG** — 可点时 44×44pt；Dynamic Type；RTL；Reduce Motion。
5. **列表友好** — `resetForReuse()` 取消加载，无错图。

### 2.2 非目标

| 排除 | 改用 |
|------|------|
| 角标数字渲染 | **`FKBadge`** / **`FKBadgeController`** |
| 订单/流程状态点 | **`FKStatusPill`** |
| 图片裁剪编辑器 | **`FKPhotoPicker`** / 宿主 |
| 实时 presence 协议 | 宿主 WebSocket 驱动 `state` |
| macOS / Catalyst 专用 | iOS 15+ UIKit |

### 2.3 成功标准

- [ ] XS–XL 头像尺寸 + Group 堆叠 + Presence 五态 Examples 通过。
- [ ] URL 加载与 Cell 复用压测无错图。
- [ ] Presence 脉冲在 Reduce Motion 下停止。
- [ ] README 含与 StatusPill 点、FKBadge 边界说明。

---

## 3. 模块架构与类型边界

```text
┌──────────────────────────────────────────────────────────┐
│ FKAvatarGroup                                            │
│  [Avatar][Avatar][Avatar][+N]  ← 子视图均为 FKAvatar     │
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│ FKAvatar（UIControl）                                    │
│  ┌─────────────┐                                         │
│  │  图片/首字母  │  + FKPresenceIndicator（右下附着）    │
│  └─────────────┘  + FKBadge（外部 Controller，非本模块）│
└────────────────────────────┬─────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────┐
│ FKImageView / FKImageLoader · UIImage.fk_* · FKSkeleton  │
└──────────────────────────────────────────────────────────┘
```

| 维度 | FKAvatar | FKAvatarGroup | FKPresenceIndicator |
|------|----------|---------------|---------------------|
| 主要职责 | 单用户头像 | 多用户堆叠 | 在线/忙碌/离线点 |
| 与 Pill 点 | — | — | **用户 presence**，非订单状态 |
| 脉冲动画 | — | — | `.online` 可选 |

---

## 4. FKCoreKit 复用要求（强制）

实现前**必须先检索** `Sources/FKCoreKit`；**禁止**在 `Widgets/Avatar/` 内重复实现同等逻辑。

| 能力 | 必须使用 | 禁止自建 |
|------|----------|----------|
| 远端/本地图片 | **`FKImageView`** + **`FKImageLoader`** | URLSession 图片管线 |
| 位图圆角/缩放/着色 | **`UIImage.fk_roundingCorners`**、**`fk_resized`**、**`fk_tinted`** | UIGraphics 工具 |
| 字符串预处理 | **`String.fk_trimmed`**、**`fk_substring`**、**`fk_limitedPrefix`** | 自写 trim/截取 |
| CJK / 拼音 | **`String.fk_pinyin`**、**`fk_pinyinFirstLetter`** | CFStringTransform 复制 |
| 描边 | **`FKLayerBorderStyle`** + **`CALayer` Extension** | 自写 border |
| 加载占位 | **`FKSkeleton`** | 自写 shimmer |
| 角标 | **`FKBadge`** | Avatar 内角标绘制 |
| 脉冲动画 | **`UIView` Animation** + **`UIAccessibility.isReduceMotionEnabled`** | 无限制 repeat |
| 布局锚点 | **`FKWidgetLayoutMetrics`**（Widgets/Core） | Avatar/Group 各算 offset |
| 本地化 | **`FKI18n`** / **`FKUIKitI18n`** | 硬编码 |

**依赖规则：** import `FKCoreKit`、`FKUIKit`；无第三方运行时库。

---

## 5. 共享设计语言

### 5.1 配置分层

```swift
public struct FKAvatarConfiguration: Sendable, Equatable {
  public var layout: FKAvatarLayoutConfiguration
  public var appearance: FKAvatarAppearanceConfiguration
  public var interaction: FKAvatarInteractionConfiguration
  public var accessibility: FKAvatarAccessibilityConfiguration
  // presence 附着：presenceState + presenceConfiguration
}

public struct FKAvatarGroupConfiguration: Sendable, Equatable { ... }
public struct FKPresenceIndicatorConfiguration: Sendable, Equatable { ... }
```

### 5.2 全局默认

```swift
public enum FKAvatarDefaults {
  @MainActor public static var configuration: FKAvatarConfiguration
}
```

### 5.3 尺寸档位（Avatar / Group 统一）

| `FKAvatarSize` | 直径 (pt) | 场景 |
|----------------|-----------|------|
| `.xs(24)` | 24 | 密集列表 |
| `.s(32)` | 32 | 导航栏、Group 默认 |
| `.m(40)` | 40 | 标准行内 |
| `.l(48)` | 48 | 资料页 |
| `.xl(72)` | 72 | 资料头图 |
| `.custom(diameter:)` | 自定义 | — |

---

## 6. FKAvatar

### 6.1 形状（`FKAvatarShape`）

| 值 | 说明 |
|----|------|
| `.circle` | 默认 |
| `.squircle(cornerRadius:)` | 连续曲率 |
| `.roundedRectangle(cornerRadius:)` | 固定圆角 |

### 6.2 内容模式

| 模式 | 触发 | 视觉 |
|------|------|------|
| **Image** | `image` / `imageURL` | 裁剪填充 |
| **Initials** | 无图 + `displayName` | 背景色 + 1–2 字符 |
| **Placeholder** | 无图无有效名 | `person.fill` |
| **Loading** | URL 加载中 | `FKSkeleton` / spinner |
| **Failed** | 加载失败 | 占位 + 可选重试 |

### 6.3 首字母规则

- 拉丁：词首最多 2 字母，大写。
- CJK：第一个扩展字素簇。
- 预处理：`String.fk_trimmed`、`fk_removingSpecialCharacters`。
- 背景色：displayName 稳定哈希（Internal；可用 `String.fk_utf8Data`）。

### 6.4 描边与 Story 环

- 描边：`FKLayerBorderStyle`。
- **Story** 预设：外圈渐变环（性能文档化；Reduce Motion 静态环）。

### 6.5 交互

- 热区扩展 **44×44pt**（`point(inside:with:)`）。
- Highlighted：scale ≤0.2s，尊重 Reduce Motion。

### 6.6 公开 API

```swift
@MainActor
public final class FKAvatar: UIControl {
  public var configuration: FKAvatarConfiguration
  public var displayName: String?
  public var imageURL: URL?
  public var image: UIImage?

  public func setImageURL(_ url: URL?, placeholder: UIImage?)
  public func setDisplayName(_ name: String?)
  public func resetForReuse()
}
```

### 6.7 状态机

```text
empty → loading → loaded
              ↘ failed → (tap?) → loading
empty → initials / placeholder
```

`interaction.retriesOnFailure` 控制失败态点击重试。

### 6.8 无障碍

- VoiceOver：`"{displayName} 的头像"` 或 `fkui.avatar.default_label`。
- 可点击：`.button` trait。
- 加载/失败：`UIAccessibility.post` 状态变化。

---

## 7. FKAvatarGroup

### 7.1 职责

「+3 位协作者」式重叠头像；内部 **必须** 使用 **`FKAvatar`** 或共享 renderer 调用同一路径。

### 7.2 布局参数

| 参数 | 默认 | 说明 |
|------|------|------|
| `maxVisible` | 4 | 可见上限 |
| `overlap` | −8pt | 水平重叠 |
| `showsOverflowCount` | true | 「+N」 |
| `direction` | `.leadingToTrailing` | RTL 镜像 |
| `avatarSize` | `.s(32)` | 组内统一 |
| `borderStyle` | none | 白边分隔重叠 |

### 7.3 溢出「+N」

- 文本：`+{total - maxVisible}`。
- 样式：**`FKTag` neutral** 变体（Chip 模块）；44pt 热区。
- `onOverflowTap` 回调。

### 7.4 内容模型

```swift
public struct FKAvatarContent: Sendable, Equatable, Identifiable {
  public var id: String
  public var displayName: String?
  public var imageURL: URL?
  public var image: UIImage?
}
```

### 7.5 公开 API

```swift
@MainActor
public final class FKAvatarGroup: UIView {
  public var configuration: FKAvatarGroupConfiguration
  public var avatars: [FKAvatarContent] { didSet { reloadAvatars() } }
  public var onOverflowTap: (() -> Void)?
  public var onAvatarTap: ((Int) -> Void)?
}
```

### 7.6 布局与 z 序

```text
[LTR] avatar[0] → avatar[1] → avatar[2] → [+N]  （右侧 z 更高，待决 Q2）
```

intrinsic 宽度：`visibleCount * (diameter + overlap) + overflowWidth`。

### 7.7 无障碍

- 容器：`accessibilityElement = false`；子 Avatar 各自聚焦。
- 溢出：「还有 N 位成员」（FKI18n）。

---

## 8. FKPresenceIndicator

### 8.1 职责

8–12pt **用户 presence** 圆点；附着 Avatar 右下角或独立使用。

### 8.2 状态（`FKPresenceState`）

| 状态 | 默认色 | 脉冲 |
|------|--------|------|
| `.online` | 绿 | 可选 |
| `.offline` | 灰 | 否 |
| `.busy` | 红 | 否 |
| `.away` | 黄/橙 | 否 |
| `.custom(...)` | 宿主 | 可配 |

### 8.3 尺寸

| 档位 | 直径 | 场景 |
|------|------|------|
| S | 8pt | XS 头像 |
| M | 10pt | 默认 |
| L | 12pt | L/XL 头像 |

### 8.4 边框与对比度

- `showsBorder`：默认 true（叠在照片上）。
- 2pt 白或 `systemBackground` 描边。

### 8.5 Avatar 集成

`FKAvatarConfiguration` 含：

- `presence: FKPresenceState?`
- `presenceConfiguration: FKPresenceIndicatorConfiguration?`
- `showsPresenceIndicator: Bool`

附着 offset 进 **`FKWidgetLayoutMetrics`**（约 +2,+2 pt 右下；RTL 镜像）。

### 8.6 公开 API

```swift
@MainActor
public final class FKPresenceIndicator: UIView {
  public var configuration: FKPresenceIndicatorConfiguration
  public var state: FKPresenceState { didSet { updateAppearance() } }
}
```

### 8.7 动效与 Reduce Motion

- `.online` + pulse：周期 ≥1.5s。
- Reduce Motion：**静态实心圆**，无脉冲。
- 脉冲层：`Avatar/Internal/FKPresencePulseLayer.swift`（StatusPill 若需脉冲点可复用，禁止复制）。

### 8.8 与 FKStatusPill 前导点

| 维度 | FKPresenceIndicator | StatusPill dot |
|------|---------------------|----------------|
| 语义 | 用户在线 | 订单/流程状态 |
| 附着 | Avatar 角 | Pill 内联 |

### 8.9 无障碍

- 独立使用时：`accessibilityLabel`「在线/离线/忙碌/离开」。
- 附着 Avatar 时：合并进 Avatar AX 树（不单独聚焦，待决 Q1 默认）。

---

## 9. 附件与跨模块组合

| 能力 | 集成 |
|------|------|
| 未读角标 | **`FKBadgeController.attach(to: avatar, ...)`** |
| 认证标识 | `showsVerifiedBadge` + 小图标 overlay |
| 溢出 +N 标签 | **`FKTag`** neutral（Chip 模块） |
| ListKit 行 | leading：`FKAvatar` + 标题栈 |
| 导航栏 | `.s` 头像，`leftBarButtonItem` |

---

## 10. SwiftUI 桥接

| 类型 | 桥接 |
|------|------|
| `FKAvatar` | `FKAvatarRepresentable` |
| `FKAvatarGroup` | `FKAvatarGroupRepresentable` + `[FKAvatarContent]` |
| `FKPresenceIndicator` | `FKPresenceIndicatorView`（原生 Circle） |

---

## 11. 建议源码目录结构

```text
Sources/FKUIKit/Components/Widgets/Avatar/
├── README.md
├── Public/
│   ├── FKAvatar.swift
│   ├── FKAvatarConfiguration.swift
│   ├── FKAvatarSize.swift
│   ├── FKAvatarShape.swift
│   ├── FKAvatarGroup.swift
│   ├── FKAvatarContent.swift
│   ├── FKAvatarGroupConfiguration.swift
│   ├── FKPresenceIndicator.swift
│   ├── FKPresenceState.swift
│   └── Bridge/
│       ├── FKAvatarRepresentable.swift
│       ├── FKAvatarGroupRepresentable.swift
│       └── FKPresenceIndicatorView.swift
└── Internal/
    ├── FKAvatarContentRenderer.swift
    ├── FKAvatarInitialsGenerator.swift
    ├── FKAvatarStoryRingLayer.swift
    ├── FKAvatarGroupLayoutEngine.swift
    └── FKPresencePulseLayer.swift
```

共享度量：`Widgets/Core/Internal/FKWidgetLayoutMetrics.swift`

---

## 12. FKKitExamples 场景

路径：`Examples/.../FKUIKit/Widgets/Avatar/`

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `ProfileHeader` | L/XL + Story + 描边 |
| 2 | `NavigationBarAvatar` | S + 44pt 热区 |
| 3 | `InitialsFallback` | 拉丁 / CJK / 空名 |
| 4 | `RemoteURL` | FKImageView + 失败重试 |
| 5 | `WithPresenceAndBadge` | Presence + FKBadge |
| 6 | `AvatarGroupRow` | 堆叠 +N + 点击 |
| 7 | `PresenceAllStates` | 五态 + 脉冲 + Reduce Motion |
| 8 | `ListReuseStress` | 快速滚动无错图 |
| 9 | `DarkModeRTL` | 镜像 |
| 10 | `SwiftUIRepresentables` | 桥接 |

---

## 13. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | Presence 附着时单独 AX 聚焦？ | 合并进 Avatar |
| Q2 | Group z 序 | 右侧在上 |
| Q3 | 首字母背景色算法上提 Core？ | v1 Internal |
| Q4 | Story 环默认？ | opt-in |
| Q5 | `FKImageView` 未发布前 URL？ | API 保留，UIImage 先行 |
| Q6 | 溢出 +N 用 Tag neutral？ | 是 |

---

## 14. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-10 | FKAvatar、FKAvatarGroup、FKPresenceIndicator 独立文档初版 |
| 2026-06-10 | 合并为单一模块设计文档 |

---

## 相关文档

- [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)
- [FKChip-FKTag-FKChipGroup_DESIGN.md](FKChip-FKTag-FKChipGroup_DESIGN.md)
- [FKStatusPill_DESIGN.md](FKStatusPill_DESIGN.md)
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md)
- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
