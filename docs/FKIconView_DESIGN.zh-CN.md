# FKIconView — 设计需求文档

FKKit **`FKIconView`** 的实现指导文档：固定尺寸 **SF Symbol / UIImage** 模板图标容器，可选圆形或圆角底，供列表行、Chip 前导图标等场景统一尺寸与着色。

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
- [5. 配置模型](#5-配置模型)
- [6. 公开 API](#6-公开-api)
- [7. 与 FKBadge 组合](#7-与-fkbadge-组合)
- [8. 无障碍](#8-无障碍)
- [9. SwiftUI 桥接](#9-swiftui-桥接)
- [10. 建议源码目录结构](#10-建议源码目录结构)
- [11. FKKitExamples 场景](#11-fkkitexamples-场景)
- [12. 待决问题](#12-待决问题)
- [13. 修订历史](#13-修订历史)

---

## 1. 概述

列表 leading icon、Chip 前导符号、设置行图标需要**一致的 24/28/32pt 盒模型**与 template 着色。各处直接用 `UIImageView` 会导致：

- Symbol 配置（weight/scale）不一致
- 圆形底尺寸不统一
- 角标附着方式各异

**`FKIconView`**（建议 `Sources/FKUIKit/Components/Widgets/IconView/`）是 `@MainActor` 的 **`UIView`**，支持 **`FKBadge`** 扩展附着。

| 交付物 | 职责 |
|--------|------|
| **`FKIconView`** | 图标 + 可选背景 |
| **`FKIconViewConfiguration`** | 尺寸、背景、symbol 配置 |
| **`FKIconViewSize`** | .s(24) / .m(28) / .l(32) |

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **固定尺寸档位** — 24 / 28 / 32pt 正方形容器。
2. **双内容源** — `symbolName`（SF Symbol）或 `image`（模板/原图）。
3. **可选背景** — 无 / 圆形 fill / 圆角矩形 fill。
4. **着色** — `tintColor` + template rendering。
5. **Badge 附着** — 复用 **`FKBadgeController`** 模式。

### 2.2 非目标

| 排除 | 说明 |
|------|------|
| 任意尺寸 UIImage 展示 | **`FKImageView`** |
| 用户头像 | **`FKAvatar`** |
| 动画 Symbol | v1.1 |

### 2.3 成功标准

- [ ] 三档尺寸 Examples。
- [ ] Chip/Tag 内部复用同一 renderer（文档化）。
- [ ] Badge 角标位置与 TabBar accessory 对齐原则。

---

## 3. 能力与特性

### 3.1 尺寸

| `FKIconViewSize` | 边长 | 典型 symbol point |
|------------------|------|-------------------|
| `.s` | 24pt | 12–14 |
| `.m` | 28pt | 14–16 |
| `.l` | 32pt | 16–18 |

### 3.2 背景样式

| `FKIconViewBackgroundStyle` | 说明 |
|-------------------------------|------|
| `.none` | 透明 |
| `.circle(fill:)` | 圆形底，常用于 tinted icon |
| `.roundedRect(cornerRadius:fill:)` | 设置行风格 |

### 3.3 Symbol 配置

- `symbolConfiguration: UIImage.SymbolConfiguration?` — weight、scale。
- 优先 `UIImage(systemName:)` + template。

### 3.4 内容优先级

`image` 非 nil 时优先于 `symbolName`；二者皆 nil 时隐藏或占位（配置）。

---

## 4. FKCoreKit 复用要求（强制）

| 能力 | 必须使用 | 禁止自建 |
|------|----------|----------|
| 模板着色 | **`UIImage.fk_tinted(with:)`** | 重复 UIGraphics tint |
| 缩放 | **`UIImage.fk_resized(to:)`** | 手写 draw |
| 布局 | **`FKWidgetLayoutMetrics`** | 魔法 inset |
| 角标 | **`FKBadge`** / **`FKBadgeController`** | IconView 内自绘数字 |
| 无障碍 | **`FKI18n`** | — |

Widgets/Core 可选 **`FKWidgetIcon`** Sendable 描述 struct，供 Chip/Tag/IconView 共用 — **禁止**三处各定义 icon DTO。

---

## 5. 配置模型

```swift
public struct FKIconViewConfiguration: Sendable, Equatable {
  public var layout: FKIconViewLayoutConfiguration
  public var appearance: FKIconViewAppearanceConfiguration
  public var accessibility: FKIconViewAccessibilityConfiguration
}
```

---

## 6. 公开 API

```swift
@MainActor
public final class FKIconView: UIView {
  public var configuration: FKIconViewConfiguration
  public var symbolName: String?
  public var image: UIImage?
  public var tintColor: UIColor?
}
```

---

## 7. 与 FKBadge 组合

- Extension：`FKIconView+fkbadge.swift` 或统一 `FKBadgeController.attach(to:iconView, ...)`
- 角：默认 top-trailing；RTL 镜像。

---

## 8. 无障碍

- 装饰性图标：`accessibilityElementsHidden = true`（默认）。
- 语义图标：宿主设置 `accessibilityLabel`。
- 不单独占 44pt（除非作为唯一可点 leading）；列表行由 cell 统一聚焦。

---

## 9. SwiftUI 桥接

`FKIconViewRepresentable` 或 `Image(systemName:)` 包装层（保持尺寸 token 一致）。

---

## 10. 建议源码目录结构

```text
Sources/FKUIKit/Components/Widgets/IconView/
├── Public/
│   ├── FKIconView.swift
│   └── FKIconViewConfiguration.swift
└── Internal/
    └── FKIconViewRenderer.swift
```

共享：`Widgets/Core/Public/FKWidgetIcon.swift`

---

## 11. FKKitExamples 场景

| # | 场景 | 验证点 |
|---|------|--------|
| 1 | `ThreeSizes` | s/m/l |
| 2 | `CircleBackground` | tinted + fill |
| 3 | `WithBadge` | 角标 |
| 4 | `InChipLeading` | 与 FKChip 组合 |

---

## 12. 待决问题

| ID | 问题 | 建议 |
|----|------|------|
| Q1 | FKWidgetIcon 放 Core Public？ | 是，Widgets/Core/Public |
| Q2 | 原图非 template 如何渲染？ | aspect fit，不强制 tint |

---

## 13. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-10 | 独立设计文档 |

---

## 相关文档

- [FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md](FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md)
- [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md)
