# FKStatusPill — 设计需求文档

FKKit **`FKStatusPill`** 的实现指导文档：短**流程状态**文案胶囊（如「进行中」「待审核」「已发货」），映射工作流语义色，可选状态点前导圆点。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) §2.2–2.3  
**所属家族：** [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md)

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
- [3. 能力与特性](#3-能力与特性)
- [4. FKCoreKit 复用要求（强制）](#4-fkcorekit-复用要求强制)
- [5. 与 FKTag 的区别](#5-与-fktag-的区别)
- [6. 配置模型](#6-配置模型)
- [7. 公开 API](#7-公开-api)
- [8. 可选交互与帮助](#8-可选交互与帮助)
- [9. 无障碍与本地化](#9-无障碍与本地化)
- [10. SwiftUI 桥接](#10-swiftui-桥接)
- [11. 建议源码目录结构](#11-建议源码目录结构)
- [12. FKKitExamples 场景](#12-fkkitexamples-场景)
- [13. 待决问题](#13-待决问题)
- [14. 修订历史](#14-修订历史)

---

## 1. 概述

订单列表、工单系统、物流详情需要**统一语义的流程状态**展示。用 `FKTag.success` 表示「已发货」会与卡片促销 Tag 混淆；用 `UILabel` + 背景色则各页面色板不一致。

**`FKStatusPill`**（建议 `Sources/FKUIKit/Components/Widgets/StatusPill/`）是 `@MainActor` 的 **`UIView`**（可选弱交互 v1.1）。

| 交付物 | 职责 |
|--------|------|
| **`FKStatusPill`** | 状态文案 + 语义样式 |
| **`FKStatusPillStyle`** | success / warning / error / info / neutral / custom |
| **`FKStatusPillConfiguration`** | 点、字号、密度 |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **工作流语义色** — 与 Tag 营销色区分文档化。
2. **可选前导点** — `showsDot` 8pt 圆点，与 **`FKPresenceIndicator`** 视觉协调但语义不同。
3. **S 档密度** — 高度 28–32pt，列表 trailing。
4. **custom 样式** — 后端驱动未知状态时 fallback。
5. **ListKit 组合** — trailing 与 **`FKTag`** 并存示例。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| 在线/忙碌状态 | **`FKPresenceIndicator`** |
| 可切换筛选 | **`FKChip`** |
| 内置 Tooltip 实现 | v1 宿主接 **`FKCallout`** |

### 2.3 成功标准

- [ ] 五种预设 style + custom Examples。
- [ ] README 含 StatusPill vs Tag 对照表。
- [ ] 深色模式对比度达标。

---

## 3. 能力与特性

### 3.1 样式枚举

| `FKStatusPillStyle` | 语义 | 典型文案 |
|---------------------|------|----------|
| `.success` | 完成/通过 | 已完成、已发货 |
| `.warning` | 待处理/风险 | 待审核、即将超时 |
| `.error` | 失败/拒绝 | 支付失败 |
| `.info` | 进行中/中性信息 | 处理中 |
| `.neutral` | 草稿/未知 | 草稿 |
| `.custom(...)` | 后端枚举 | 宿主映射 |

### 3.2 前导点

- `showsDot: Bool` — 与文案间距 6pt。
- 点颜色跟随 style 前景或独立配置。

### 3.3 密度与字号

- 默认 S：28–32pt 高；文字 `caption` / `footnote` 档。
- Dynamic Type：2 档后截断。

---

## 4. FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止自建 |
|------|----------|----------|
| 胶囊布局 | **`FKCapsuleLayoutEngine`**（Widgets/Core） | 独立 pill 测量 |
| 语义色表 | **`Widgets/Core` 共享 status 色 token**（与 Tag 分表） | Pill 内硬编码 hex |
| 文字 | **`String.fk_limitedPrefix`** | — |
| 本地化 | **`FKI18n`** 状态文案键 `fkui.status.*` | 硬编码中文在库内 |
| 动画（点脉冲） | 与 **`FKPresenceIndicator`** 共享 Internal 脉冲层（若启用） | 重复 CA 脉冲 |

---

## 5. 与 FKTag 的区别

| 维度 | FKStatusPill | FKTag |
|------|--------------|-------|
| 语义 | 工作流/订单状态 | 分类/促销/角色 |
| 色板 | status 专用 | brand/marketing |
| 前导点 | 常见（流程态） | 少见 |
| 场景 | 列表 trailing 状态 | 卡片角标 |

**规范：** 同一行可同时有 Tag（「VIP」）+ StatusPill（「配送中」）。

---

## 6. 配置模型

```swift
public struct FKStatusPillConfiguration: Sendable, Equatable {
  public var layout: FKStatusPillLayoutConfiguration
  public var appearance: FKStatusPillAppearanceConfiguration
  public var accessibility: FKStatusPillAccessibilityConfiguration
}
```

---

## 7. 公开 API

```swift
public enum FKStatusPillStyle: Sendable, Equatable {
  case success, warning, error, info, neutral
  case custom(FKStatusPillCustomAppearance)
}

@MainActor
public final class FKStatusPill: UIView {
  public var configuration: FKStatusPillConfiguration
  public var title: String
  public var style: FKStatusPillStyle
  public var showsDot: Bool
}
```

---

## 8. 可选交互与帮助

- v1：默认不可点。
- v1.1：可配置 `isHelpAvailable` + 宿主 present **`FKCallout`** 解释状态含义。

---

## 9. 无障碍与本地化

- `accessibilityTraits`: `.staticText`
- Label：`"{title}，状态"` 或完整句子（FKI18n）。
- 颜色不作为唯一信息载体（配合文案 + 点）。

---

## 10. SwiftUI 桥接

`FKStatusPillView` 原生 SwiftUI 或轻量 Representable。

---

## 11. 建议源码目录结构

```text
Sources/FKUIKit/Components/Widgets/StatusPill/
├── README.md
├── Public/
│   ├── FKStatusPill.swift
│   ├── FKStatusPillStyle.swift
│   └── Bridge/FKStatusPillView.swift
└── Internal/
    └── FKStatusPillRenderer.swift
```

---

## 12. FKKitExamples 场景

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `OrderStatusPills` | 五种 style |
| 2 | `WithDot` | showsDot |
| 3 | `CustomBackendEnum` | custom 映射 |
| 4 | `ListRowWithTag` | Tag + Pill 并存 |

---

## 13. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | 与 Tag 合并类型？ | 保持独立（Q4 FKSmallComponents） |
| Q2 | 脉冲点默认？ | 否；仅 info 可选 |

---

## 14. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-10 | 独立设计文档 |

---

## 相关文档

- [FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md](FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md)
- [FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md](FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md)
- [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md)
