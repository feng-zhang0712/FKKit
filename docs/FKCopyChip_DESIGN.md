# FKCopyChip — 设计需求文档

FKKit **`FKCopyChip`** 的实现指导文档：展示截断 ID/订单号等文本，一键复制到剪贴板，可选 **`FKToast`** 成功反馈与轻触觉。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.2–2.3  
**所属家族：** [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 能力与特性](#3-能力与特性)
- [4. FKCoreKit 复用要求（强制）](#4-fkcorekit-复用要求强制)
- [5. 配置模型](#5-配置模型)
- [6. 公开 API](#6-公开-api)
- [7. 复制行为](#7-复制行为)
- [8. 视觉与布局](#8-视觉与布局)
- [9. 无障碍与本地化](#9-无障碍与本地化)
- [10. SwiftUI 桥接](#10-swiftui-桥接)
- [11. 建议源码目录结构](#11-建议源码目录结构)
- [12. FKKitExamples 场景](#12-fkkitexamples-场景)
- [13. 待决问题](#13-待决问题)
- [14. 修订历史](#14-修订历史)

---

## 1. 概述

订单详情、物流页、客服工单常见「订单 #A1288… 📋 点击复制」。重复实现时易遗漏：

- `copyText` 与展示文本分离（展示截断、复制全文）
- 复制成功 Toast / 触觉反馈
- 44pt 热区与 VoiceOver「复制」动作

**`FKCopyChip`**（建议 `Sources/FKUIKit/Components/Widgets/CopyChip/`）是 `@MainActor` 的 **`UIControl`**。

| 交付物 | 职责 |
|--------|------|
| **`FKCopyChip`** | 展示 + 复制 |
| **`FKCopyChipConfiguration`** | 截断、图标、Toast、触觉 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **展示与复制分离** — `text` 展示；`copyText` 默认等于 `text`。
2. **UIPasteboard 写入** — 通用 pasteboard，可选 expiration（文档说明 iOS 限制）。
3. **可选 Toast** — 成功时 **`FKToast`**（可关）。
4. **轻触觉** — 对齐 **`FKButton`** 成功反馈。
5. **等宽/截断** — monospace 可选；中间省略号。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| 分享 Sheet | 宿主 `UIActivityViewController` |
| 二维码展示 | 其他组件 |
| 敏感信息遮罩 | 可用 **`String.fk_masked*`** 在宿主预处理展示文本 |

### 2.3 成功标准

- [ ] 复制全文与展示截断分离 Examples。
- [ ] Toast 可配置关闭。
- [ ] VoiceOver 朗读「复制 {摘要}」。

---

## 3. 能力与特性

### 3.1 文本处理

| 能力 | 说明 |
|------|------|
| 中间截断 | `A1288…9F2` |
| 前缀标签 | 配置 `prefix`「订单 #」 |
| Monospace | 配置 `usesMonospacedFont` |
| copyText 覆盖 | 复制完整 ID，展示短格式 |

### 3.2  trailing 图标

- 默认 `doc.on.doc` 或 `square.on.square` SF Symbol。
- 经 **`FKIconView`** 渲染。

### 3.3 反馈

| `FKCopyChipFeedback` | 行为 |
|----------------------|------|
| `.hapticOnly` | 轻触 |
| `.toast` | Toast + 可选 haptic |
| `.none` | 静默 |

---

## 4. FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止自建 |
|------|----------|----------|
| 剪贴板 | **`UIPasteboard.general`**（系统 API）；封装可放 Internal | 重复 pasteboard wrapper 到 Core 除非多组件复用 |
| 字符串截断/遮罩 | **`String.fk_limitedPrefix`**、**`fk_masked*`**（展示侧） | 自写 mask |
| Toast | **`FKToast`** | 自绘 snackbar |
| 触觉 | 与 **`FKButton`** 相同路径 | 散落 generator |
| 图标 | **`FKIconView`** / **`UIImage.fk_tinted`** | — |
| 本地化 | **`FKUIKitI18n`** `fkui.copy_chip.*` | 硬编码 |
| 动画 | **`UIView` Animation Extension**（复制成功 flash） | — |

若需通用「复制到剪贴板 + Toast」编排且多组件复用，**优先在 FKCoreKit Utils 补充**（如 `FKPasteboardService`），CopyChip 调用之 — v1 可 Internal，但禁止与 Toast 模块重复实现提示 UI。

---

## 5. 配置模型

```swift
public struct FKCopyChipConfiguration: Sendable, Equatable {
  public var layout: FKCopyChipLayoutConfiguration
  public var appearance: FKCopyChipAppearanceConfiguration
  public var interaction: FKCopyChipInteractionConfiguration
  public var feedback: FKCopyChipFeedbackConfiguration
  public var accessibility: FKCopyChipAccessibilityConfiguration
}
```

---

## 6. 公开 API

```swift
@MainActor
public final class FKCopyChip: UIControl {
  public var configuration: FKCopyChipConfiguration
  public var text: String
  public var copyText: String?  // nil → text
  public var onCopy: ((String) -> Void)?  // 复制后钩子
}
```

---

## 7. 复制行为

1. `primaryActionTriggered` → 解析 `copyText ?? text`。
2. 写入 `UIPasteboard.general.string`。
3. 触发 feedback 配置。
4. 调用 `onCopy`。
5. 发送可选 Notification（文档：宿主监听若需要）。

---

## 8. 视觉与布局

- 胶囊或圆角矩形底：`secondarySystemFill`。
- 高度 S/M：28–36pt。
- 整控件 44pt 最小热区（含透明扩展）。

---

## 9. 无障碍与本地化

- `accessibilityTraits`: `.button`
- `accessibilityHint`: 「双击复制」（FKI18n）
- 复制成功：`UIAccessibility.post` announcement（可配置）

---

## 10. SwiftUI 桥接

`FKCopyChipRepresentable`。

---

## 11. 建议源码目录结构

```text
Sources/FKUIKit/Components/Widgets/CopyChip/
├── Public/
│   ├── FKCopyChip.swift
│   └── FKCopyChipConfiguration.swift
└── Internal/
    └── FKCopyChipPasteboardWriter.swift
```

---

## 12. FKKitExamples 场景

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `CopyOrderID` | 截断 + 全文复制 |
| 2 | `ToastFeedback` | FKToast |
| 3 | `MonospacedTracking` | 等等宽字体 |
| 4 | `SilentCopy` | feedback none |

---

## 13. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | 复制敏感 ID 是否二次确认？ | v1 否；文档安全提示 |
| Q2 | iOS 16+ UIPasteboard 通知？ | README 说明隐私指示器 |

---

## 14. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-10 | 独立设计文档 |

---

## 相关文档

- [FKIconView_DESIGN.md](FKIconView_DESIGN.md)
- [FKSmallComponents_DESIGN.md](FKSmallComponents_DESIGN.md)
