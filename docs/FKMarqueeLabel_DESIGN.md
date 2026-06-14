# FKMarqueeLabel — 设计需求文档

FKKit **`FKMarqueeLabel`** 的实现指导文档：单行**横向滚动公告**文字（ticker），支持拖拽暂停；**Reduce Motion** 时停止滚动，改为静态截断并暴露完整无障碍文本。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) Tier 3 `FKMarquee`  
**所属家族：** [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 能力与特性](#3-能力与特性)
- [4. FKCoreKit 复用要求（强制）](#4-fkcorekit-复用要求强制)
- [5. 配置模型](#5-配置模型)
- [6. 公开 API](#6-公开-api)
- [7. 滚动逻辑与生命周期](#7-滚动逻辑与生命周期)
- [8. Reduce Motion 与无障碍](#8-reduce-motion-与无障碍)
- [9. 性能与内存](#9-性能与内存)
- [10. SwiftUI 桥接](#10-swiftui-桥接)
- [11. 建议源码目录结构](#11-建议源码目录结构)
- [12. FKKitExamples 场景](#12-fkkitexamples-场景)
- [13. 待决问题](#13-待决问题)
- [14. 修订历史](#14-修订历史)

---

## 1. 概述

首页公告条、股票 ticker、活动横幅需要**超长单行文案**在固定宽度内滚动展示。第三方 Marquee 库常：

- 未处理 Reduce Motion（审核与 AX 风险）
- 与 Dynamic Type 冲突
- 离屏仍跑 CADisplayLink

**`FKMarqueeLabel`**（建议 `Sources/FKUIKit/Components/Widgets/Marquee/`）是 `@MainActor` 的 **`UIView`**。

| 交付物 | 职责 |
|--------|------|
| **`FKMarqueeLabel`** | 滚动文本视图 |
| **`FKMarqueeLabelConfiguration`** | 速度、间距、暂停、渐变遮罩 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **仅文本超宽时滚动** — 短文本静态居中/左对齐。
2. **无缝循环** — 双 label 或 duplicate 文本；可配置间隔。
3. **拖拽暂停** — 用户按住暂停滚动，松开恢复。
4. **Reduce Motion** — 不滚动；`accessibilityLabel` 全文。
5. **前后渐变遮罩** — 可选 fade edge（CALayer mask）。
6. **App 生命周期** — 后台/离屏暂停 timer。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| 多行展开 | **`FKExpandableText`** |
| 富文本/HTML | v1 纯 `String` / `NSAttributedString` 可选 |
| 垂直滚动 | 不在范围 |

### 2.3 成功标准

- [ ] 长文案循环滚动流畅（60fps 目标）。
- [ ] Reduce Motion 下零动画。
- [ ] `didMoveToWindow` 离屏停止。
- [ ] Examples：`MarqueeAnnouncement`。

---

## 3. 能力与特性

### 3.1 滚动参数

| 参数 | 说明 |
|------|------|
| `speed` | pt/s，默认适中（如 30–40） |
| `loopGap` | 循环间距 |
| `delay` | 循环开始前停顿 |
| `direction` | `.left` / `.right`；RTL 默认镜像 |
| `fadeWidth` | 左右渐变遮罩宽度 |

### 3.2 对齐

| `FKMarqueeLabelAlignment` | 行为 |
|---------------------------|------|
| `.leading` | 短文本左对齐 |
| `.center` | 短文本居中 |

### 3.3 交互

- Pan 手势按住：`isPausedByUser = true`
- 松开：恢复滚动（若允许 motion）

### 3.4 文本

- `text: String` 主 API。
- 可选 `attributedText` v1.1；v1 单一样式经 configuration 字体/色。

---

## 4. FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止自建 |
|------|----------|----------|
| 文本测量 | **`UILabel.fk_numberOfLinesThatFit`**、**`String` bounding 辅助** | 重复 CoreText 测量 |
| 字体 | **`UIFont` Extension** / Dynamic Type | 固定字号 |
| 主线程/定时 | **`FKAsync`** / **`CancellableWork`**（FKCoreKit Async） | 裸 Timer 泄漏 |
| Reduce Motion | **`UIAccessibility.isReduceMotionEnabled`** | 忽略 AX |
| 本地化 | **`FKI18n`** | — |
| 动画 | **`UIView` Animation Extension**；CADisplayLink 仅 Internal 封装 | 多处 display link |

离屏检测：复用 **`UIView`** 窗口/ superview 惯例；暂停逻辑放 Internal coordinator。

---

## 5. 配置模型

```swift
public struct FKMarqueeLabelConfiguration: Sendable, Equatable {
  public var layout: FKMarqueeLabelLayoutConfiguration
  public var appearance: FKMarqueeLabelAppearanceConfiguration
  public var animation: FKMarqueeLabelAnimationConfiguration
  public var interaction: FKMarqueeLabelInteractionConfiguration
  public var accessibility: FKMarqueeLabelAccessibilityConfiguration
}
```

---

## 6. 公开 API

```swift
@MainActor
public final class FKMarqueeLabel: UIView {
  public var configuration: FKMarqueeLabelConfiguration
  public var text: String { didSet { reloadMarquee() } }
  public var isPaused: Bool { get set }  // 编程暂停
}
```

---

## 7. 滚动逻辑与生命周期

```text
layout → 测量 textWidth vs boundsWidth
  若 textWidth <= bounds → 静态 label
  否则 → 启动 scroll driver（DisplayLink / CADisplayLink）
window == nil 或 reduceMotion → stop driver
```

- `traitCollectionDidChange`：Dynamic Type 变化 → remeasure。
- deinit：invalidate driver。

---

## 8. Reduce Motion 与无障碍

- Reduce Motion：**静态**单行，`lineBreakMode = .byTruncatingTail`，`accessibilityLabel = text` 全文。
- 滚动时：装饰性；VoiceOver 仍读完整 `text`（不读两次滚动副本）。
- 可选：`accessibilityTraits` `.updatesFrequently` 当滚动且非 reduce motion（文档说明谨慎使用）。

---

## 9. 性能与内存

- 双 label 复用，避免每帧创建 attributed string。
- 长文本（>500 字符）文档建议宿主截断或分段。
- CPU：离屏必须 stop。

---

## 10. SwiftUI 桥接

`FKMarqueeLabelRepresentable` — 绑定 `text`、`isPaused`。

---

## 11. 建议源码目录结构

```text
Sources/FKUIKit/Components/Widgets/Marquee/
├── Public/
│   ├── FKMarqueeLabel.swift
│   └── FKMarqueeLabelConfiguration.swift
└── Internal/
    ├── FKMarqueeScrollDriver.swift
    └── FKMarqueeFadeMaskLayer.swift
```

---

## 12. FKKitExamples 场景

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `LongAnnouncement` | 循环滚动 |
| 2 | `ShortTextNoScroll` | 不滚动 |
| 3 | `DragToPause` | 手势 |
| 4 | `ReduceMotion` | 设置项切换 |
| 5 | `RTLDirection` | 镜像 |
| 6 | `BackgroundPause` | 切后台 |

---

## 13. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | DisplayLink vs UIView.animate 重复？ | DisplayLink 平滑滚动 |
| Q2 | attributedText v1？ | v1.1 |
| Q3 | 与 Banner 组合？ | 文档示例仅 Marquee 条 |

---

## 14. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-10 | 独立设计文档 |

---

## 相关文档

- [FKExpandableText README](../Sources/FKUIKit/Components/ExpandableText/README.md)
- [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)
- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
