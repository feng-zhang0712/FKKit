# FKBusinessKit × FKUIKit Widgets — 组合用法设计片段

> **BusinessKit 完整模块设计（七子系统 + 增强 + Widgets 边界 §18）：** [FKBusinessKit_DESIGN.md](FKBusinessKit_DESIGN.md)

FKBusinessKit 如何**组合** FKUIKit Widgets（小组件库）的指导片段。**完整正文见 FKBusinessKit 仓库：**

[`FKBusinessKit/docs/FKWidgets-Integration_DESIGN.md`](https://github.com/feng-zhang0712/FKBusinessKit/blob/main/docs/FKWidgets-Integration_DESIGN.md)

本地 side-by-side 开发时路径：`../FKBusinessKit/docs/FKWidgets-Integration_DESIGN.md`

---

## 摘要

| 项 | 结论 |
|----|------|
| Widgets 源码归属 | **仅** `FKKit/Sources/FKUIKit/Components/Widgets/` |
| BusinessKit 角色 | **组合 + 可选薄封装**（`Base`、`TabBarFilter` 与 Widgets 同屏编排） |
| 禁止 | 在 BusinessKit 复制 Chip/Avatar/Tag 渲染或自建图片管线 |
| v1 交付 | Examples 演示组合；`ListWidgets/` 薄封装待重复模式出现后再提取 |

### 与 TabBarFilter / ChipGroup 分工

- **TabBarFilter** — Tab + 锚点 Sheet **复杂面板**
- **FKChipGroup** — 行内 **快速标签**筛选
- 同一列表页可**上下并存**；面板 VC 内也可再嵌 `FKChipGroup`

### 可选薄封装（非 v1 强制）

- `FKUserListLeadingView` — Avatar + 双行标题
- `FKInlineFilterBar` — ChipGroup + 刷新胶水
- 业务枚举 → `FKStatusPillStyle` / `FKTagVariant` 映射（纯 Swift，无 UI 复制）

---

**文档类型：** 索引（指向 FKBusinessKit 侧完整设计片段）  
**状态：** 草案  
**修订：** 2026-06-10 初版
