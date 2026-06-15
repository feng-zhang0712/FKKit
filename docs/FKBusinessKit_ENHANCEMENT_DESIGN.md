# FKBusinessKit — 增量增强设计索引

> **完整模块设计需求文档（已交付七子系统 + Alert/Pluggable/Examples 增强）见：**
> **[FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md)**

本文档保留为 **BusinessKit 增量增强** 的快速索引；详细规范、API 草案、验收标准已合并入主文档对应章节。

**文档类型：** 索引（指向主设计文档）  
**状态：** 草案  
**主文档：** [FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md)  
**模块 README：** [BusinessKit/README.md](../Sources/FKCoreKit/Components/BusinessKit/README.md)

---

## 增强项与主文档章节映射

| 增强项 | 用户价值 | 主文档章节 | 状态 |
|--------|----------|------------|------|
| **FKBusinessAlertBackend** | 系统 Alert vs FKAlert 统一入口 | §15 | 待交付（v1.1） |
| **Pluggable 桥接** | Lifecycle / Deeplink / Analytics DI 对齐 | §16 | 待交付 |
| **Top VC 公开化** | Toast/Alert/Banner 复用顶层 VC 解析 | §17 | 待交付 |
| **Examples Hub** | 每子系统独立场景 | §26 | 待交付 |
| **Widgets 组合文档** | Chip/Avatar 编排边界 | §18 + 专文 | 已有索引 |

**原则：** 增强均为 **opt-in** 或文档化；默认 `FKBusinessKit.shared` 行为 **不变**（semver minor）。

---

## 相关增强（主文档已覆盖）

| 能力 | 主文档章节 | 说明 |
|------|------------|------|
| 七子系统能力详表 | §6–§14 | Version/Track/I18n/Lifecycle/Deeplink/Info/Utils |
| FKI18n 分工 | §10 | Business facade vs coreManager |
| FKBanner 版本条组合 | §8.4、§18 | 无硬依赖 |
| TabBarFilter 缺口 | §22 | 文档引用但 FKKit 未交付 |
| v2 展望 | §22 | consent、route priority 等 |

---

## FKKitExamples 场景索引

见主文档 **§26**：Hub B1–B9 + 增强 E1–E3 + 现有 All-in-One H0。

---

## 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-14 | 初版索引，指向 `FKBusinessKit_DESIGN.md` |

---

## 相关文档

- [FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md) — **主设计文档**
- [FKBusinessKit-Widgets-Integration_DESIGN.md](FKBusinessKit-Widgets-Integration_DESIGN.md)
- [FKAlert_DESIGN.md](FKAlert_DESIGN.md)
- [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md)
- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
