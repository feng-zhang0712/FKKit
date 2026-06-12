# FKCellKit — 设计需求文档

FKKit **终极 Cell 组件库**的实现指导文档：覆盖 iOS 设置页风格的**展示类 Cell**、**行内交互 Cell**，以及登录/注册/信息提交场景的**表单类 Cell**；提供可独立使用的 `UITableViewCell` / `UICollectionViewCell` 实现，并与 **FKListKit** 预设 Item 对齐。

**文档类型：** 设计需求（对实现者具有规范约束力）  
**状态：** 草案  
**实施方式：** **分阶段交付** — 禁止单次全量实现；Cursor/Agent 按 **[§14 分阶段实现与交付计划](#14-分阶段实现与交付计划)** 逐 Phase 执行（Phase 0→6，一 Phase 一任务）  
**路线图引用：** [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 列表/表单面  
**关联文档：** [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md)、[FKFormControls_DESIGN.zh-CN.md](FKFormControls_DESIGN.zh-CN.md)、[FKIconView_DESIGN.zh-CN.md](FKIconView_DESIGN.zh-CN.md)

> **给 Cursor / 实施者：** 打开本文后 **先读 §14**，确认当前要实现的 **Phase N**；仅实现该 Phase「本阶段交付」范围，**不得**越界做后续 Phase 的 Cell。每 Phase 结束须通过该 Phase 的 **验收 Gate** + `xcodebuild` BUILD SUCCEEDED。

---

## 目录

- [1. 概述](#1-概述)
- [2. 目标、非目标与成功标准](#2-目标非目标与成功标准)
  - [2.4 全局工程要求（强制）](#24-全局工程要求强制)
- [3. 页面参考与 Cell 样式目录](#3-页面参考与-cell-样式目录)
- [3.5 扩展展示类样式目录（通用业务场景）](#35-扩展展示类样式目录通用业务场景)
- [3.6 交互类 Cell 样式目录](#36-交互类-cell-样式目录)
- [4. 组件命名与分类体系](#4-组件命名与分类体系)
- [5. 与 FKListKit / 邻域模块的边界](#5-与-fklistkit--邻域模块的边界)
- [6. 共享基础设施](#6-共享基础设施)
- [7. 展示类 Cell 规格](#7-展示类-cell-规格)
- [8. 交互类 Cell 规格](#8-交互类-cell-规格)
- [9. 语义化表单 Cell 与布局矩阵](#9-语义化表单-cell-与布局矩阵)
- [10. 配置、状态与回调模型](#10-配置状态与回调模型)
- [11. 布局、分隔线与 Inset Grouped 规范](#11-布局分隔线与-inset-grouped-规范)
  - [11.5 Auto Layout 约束规范](#115-auto-layout-约束规范)
- [12. Pluggable 与复用契约](#12-pluggable-与复用契约)
  - [12.4 列表性能与视图层级](#124-列表性能与视图层级)
- [13. 无障碍与 Dynamic Type](#13-无障碍与-dynamic-type)
- [14. 分阶段实现与交付计划](#14-分阶段实现与交付计划)
  - [14.1 为何分阶段](#141-为何分阶段)
  - [14.2 分阶段原则](#142-分阶段原则)
  - [14.3 阶段总览与依赖](#143-阶段总览与依赖)
  - [14.4 Phase 0 — 基础设施](#144-phase-0--基础设施)
  - [14.5 Phase 1 — 设置页 MVP](#145-phase-1--设置页-mvp)
  - [14.6 Phase 2 — 表单 MVP](#146-phase-2--表单-mvp)
  - [14.7 Phase 3 — 表单扩展](#147-phase-3--表单扩展)
  - [14.8 Phase 4 — 通用列表展示](#148-phase-4--通用列表展示)
  - [14.9 Phase 5 — 富内容与扩展交互](#149-phase-5--富内容与扩展交互)
  - [14.10 Phase 6 — 长尾、Collection 与 ListKit](#1410-phase-6--长尾collection-与-listkit)
  - [14.11 Cursor / Agent 实施指引](#1411-cursor--agent-实施指引)
- [15. 建议源码目录结构](#15-建议源码目录结构)
- [16. FKKitExamples 场景](#16-fkkitexamples-场景)
- [17. 待决问题](#17-待决问题)
- [18. 修订历史](#18-修订历史)

---

## 1. 概述

日常 iOS 开发中，列表页与设置页反复出现大量结构相似但细节不同的 **Cell 布局**。FKKit 已有 **FKListKit**（Diffable 列表基础设施 + 少量预设行）与 **FKTextField** / **FKFormControls**（独立控件），但缺少一套**可单独 dequeue、单独嵌入自定义 Table/Collection、且视觉与行为统一**的 Cell 库。

**FKCellKit**（建议路径 `Sources/FKUIKit/Components/CellKit/`）交付：

| 交付物 | 职责 |
|--------|------|
| **展示类 Cell** | 只读或弱交互（导航、链接、复制、展开预览）；§3.2 设置页 + §3.5 通用列表 |
| **交互类 Cell** | 用户输入、手势、控件联动、表单校验反馈；§3.3 设置控件 + §3.6 表单/搜索/复合交互 |
| **结构辅助视图** | Section 头尾、分组圆角容器、行分隔 inset 策略 |
| **统一配置层** | `Sendable`/`Equatable` 配置结构体 + `apply(_:)` |

FKCellKit **不是**列表 ViewController 框架 — 那是 **FKListKit** 的职责。FKCellKit 专注 **Cell 视图本身**；FKListKit 的 `FKListPresetItem` **应当**映射到 FKCellKit 的具体 Cell 类型。

**交付节奏：** 样式 ID 合计 200+，**按 §14 分 7 个 Phase（0–6）交付** — 每 Phase 独立 PR、独立 Examples、独立验收 Gate；完整 CellKit 需 **严格顺序** 完成 Phase 0→6，不可跳步（Collection / ListKit 集成在 Phase 6）。

---

## 2. 目标、非目标与成功标准

### 2.1 目标

1. **覆盖设置页与通用列表 90%+ 常见行型** — §3.2 + §3.5（D-01–D-90）。
2. **覆盖交互类行型** — 设置控件 I-01–I-15、表单 X-01–X-72、语义 F-01–F-20、混合 M-01–M-06。
3. **覆盖典型表单语义** — 文本、密码、验证码、勾选协议、提交按钮等（§9 `F-*`）。
4. **即拿即用** — 每个 Cell 可独立 `apply(_:)` 配置（ListKit 集成时另实现 `configure(with:)`），不依赖 FKListKit。
5. **与 FKListKit 对齐** — 预设 Item → Cell 一对一映射；避免两套布局逻辑。
6. **FKKit 一致性** — Swift 6、`@MainActor` UI、`Sendable` 配置、英文公开 API、HIG（44pt 触控、Dark Mode、Dynamic Type、VoiceOver）。
7. **复用邻域组件** — `FKTextField`、`FKSearchField`、`FKFormControls` 等；**布局在 CellKit、输入逻辑在控件层**。

### 2.2 非目标

| 排除项 | 原因 |
|--------|------|
| Diffable VC、刷新、分页、空态 | **FKListKit** |
| 完整表单校验/提交编排器 | 未来 `FKForm`（路线图 Tier 3）；v1 Cell 级 + 宿主编排 |
| 复制 60+ 搜索栏 UI 变体 | 嵌入 **`FKSearchField`** + 有限 `FKFormSearchCellStyle` |
| 拖拽排序数据层 | v1 仅提供 Reorder 把手 **视觉 + 回调**；排序逻辑由宿主/系统 editing 模式负责 |
| macOS / tvOS | 仅 iOS 15+ UIKit |
| SwiftUI 原生 Cell | v1 可选 Representable；MVP 以 UIKit Cell 为主 |
| 替代 `UITableViewCell` 系统样式 | 不封装 `.subtitle` / `.value1` 等 legacy style；提供 FK 自研布局 |

### 2.3 成功标准

以下为 **全量 CellKit（Phase 6 完成后）** 的最终成功标准。分阶段交付时，**以各 Phase 验收 Gate（§14.4–§14.10）为准**；未完成 Phase 6 前，下列部分项可标记为「待 Phase N」。

- [ ] **Phase 0–2：** Core/Internal 基础设施 + 设置页 MVP + 表单 5 种 Layout（§14.4–§14.6 Gate）
- [ ] **Phase 3–5：** 表单扩展 + 通用展示 + 富内容/扩展交互（§14.7–§14.9 Gate）
- [ ] **Phase 6：** Collection parity、FKListKit 预设映射、长尾样式（§14.10 Gate）
- [ ] §8 **P0 交互 Cell** 实现且 Examples 覆盖 5 种表单布局（Underline / CardStacked / CardInline / InlineLabel / IconUnderline）— **Phase 2**
- [ ] 任意 Cell 可在 plain `UITableViewController` 中 10 行代码内完成注册与展示 — **Phase 0 起**
- [ ] FKListKit `FKListPresetItem` 扩展后复用 FKCellKit 实现（无重复 Auto Layout）— **Phase 6**
- [ ] Inset Grouped 视觉与系统设置页并排对比无明显漂移（边距、圆角、分隔 inset、字阶）— **Phase 1**
- [ ] `xcodebuild` verify 通过；组件 README + 根 README 索引 — **每 Phase**
- [ ] 满足 §2.4 全局工程要求（命名、复用、约束、性能）；Code Review 可对照检查表验收 — **每 Phase**

### 2.4 全局工程要求（强制）

本节为 CellKit **实现层硬约束**，与 §3–§9 功能规格同等效力。面向**全球开源接入方**，须保证 API 可发现、实现可维护、长列表可滚动。

#### 2.4.1 命名规范（全球开发者）

CellKit 全部 **公开** API **必须**遵循 FKKit 与 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)，**仅使用英文**（类型、成员、配置字段、DocComment、README、Examples 文案）。

| 规则 | 要求 | 正例 | 反例 |
|------|------|------|------|
| 前缀 | 模块内类型 `FK` + PascalCase | `FKCellDisclosureCell` | `CellDisclosure`、`FKDisclosureTableCell` |
| Cell 后缀 | UITableViewCell 子类以 `Cell` 结尾 | `FKFormCellTextFieldCell` | `FKFormTextFieldRowView` |
| 配置 | `…Configuration`；Row 模型 `…Row` | `FKCellDisclosureConfiguration` | `FKCellDisclosureConfig`、`DisclosureCellModel` |
| 表单 | 表单语义用 `FKFormCell*`；设置控件用 `FKCell*` | `FKFormCellPhoneCell` | `FKPhoneInputCell`（语义不清） |
| 枚举 Case | lowerCamelCase；语义完整 | `.inlineLabel`、`.cardStacked` | `.style1`、`.typeA` |
| 布尔 | `is` / `shows` / `has` 前缀 | `showsDisclosure` | `disclosure: Bool` |
| 回调 | 动词 + 宾语；避免 `handler` 裸名 | `onValueChanged` | `callback` |
| 禁止 | 匈牙利命名、缩写、中英混用 | — | `FKCellDisclosureCellUI`、`FK表单Cell` |

**文档：** 每个公开类型/成员 **必须**有英文 `///`（摘要 + 非 obvious 时的线程/默认值说明）。组件 README **必须**含目录结构表与最小用法 snippet。

**稳定性：** 公开 API 变更遵循 semver；避免为单一 App 需求暴露 `open` 或过宽 `public` 面。

#### 2.4.2 复用 FKUIKit / FKCoreKit（禁止重复造轮子）

实现任何 Cell **之前** **必须**检索 `Sources/FKCoreKit` 与 `Sources/FKUIKit` 已有能力（见 §5.2、§5.5、§12.3）。**禁止**在 CellKit 内复制已有或应上提的通用逻辑。

| 类别 | 必须复用 | 禁止 |
|------|----------|------|
| 输入/校验 | `FKTextField`、`FKCodeTextField`、`FKCountTextView` | Cell 内裸 `UITextField` + 自写 pipeline |
| 搜索 | `FKSearchField` / `FKSearchBar` | 自写搜索框 60+ 变体 |
| 控件 | `FKToggle`、`FKCheckbox`、`FKRadioGroup`、`FKSlider`、`FKSegmentedControl` | 样式各异的 duplicate Switch |
| 展示 | `FKIconView`、`FKImageView`、`FKAvatar`、`FKButton`、`FKDivider` | 裸 `UIImageView` / 手写 1px 线 |
| 状态/标签 | `FKStatusPill`、`FKBadge`、`FKChip`/`FKChipGroup`、`FKCopyChip` | 每 Cell 自画 Pill |
| 进度/空态 | `FKProgressBar`、`FKEmptyState`、`FKSkeleton` | Cell 内自建进度条 |
| 布局/集合 | `FKCoreKit` `Extension/`（`UIStackView`、`CGRect`、`IndexPath`…） | 复制 layout 辅助函数 |
| 并发/防抖 | `FKDebouncer`、`CancellableWork` | Cell 内裸 `Timer`（SMS 倒计时除外，见 §12.4） |
| 复用契约 | `FKCellReusable` / Pluggable | 自定义 reuse 约定 |

**上提原则：** 若某能力被 **≥2 个 Cell** 或 **CellKit 外模块** 需要，**应**在 `FKCoreKit` / 对应 FKUIKit 组件中扩展，CellKit 仅 **组合**。

#### 2.4.3 子组件拆分（样式多 ≠ Cell 类爆炸）

样式 ID 多（D/I/X/F/M）**不**等于每种一个独立 Cell 文件。允许且 **鼓励** 在 CellKit 或 FKUIKit 中封装 **共享子组件**，供多 Cell 组合：

| 子组件（示例） | 职责 | 复用者 |
|----------------|------|--------|
| `FKCellContentStack`（Internal） | Leading / 标题栈 / Trailing 三区布局 | 多数 Display Cell |
| `FKCellAccessoryHostView` | 统一 chevron、checkmark、badge 槽位 | D-*、I-* |
| `FKFormFieldChromeView` | Label + 底线/卡片 + error 区 | X-01–X-05 |
| `FKFormAccessoryHostView` | Leading/Trailing accessory 懒加载 | Form Cell |
| `FKCellGroupedBackgroundView` | Inset grouped 圆角背景 | S-03 |
| `FKCellStorageProgressView` | 分段进度 + 图例 | D-13 |
| `FKCellLinkTextView` | 富文本链接 tap | D-07、X-52 |

**何时新建独立 Cell 类型：** 仅当 **布局结构** 或 **交互模型** 无法由 `Layout + Accessory + Compose` 表达（§3.5.12、§3.6.12）。

**何时上提到 FKUIKit 新组件：** 子组件具 **独立产品语义** 且非 Cell 专用（如通用 `FKPhoneNumberField`）— 先评估 `FKTextField` 扩展 vs 新 Widget。

#### 2.4.4 Auto Layout 约束（合理、无冲突）

Cell 在 **Dynamic Type 最大档**、**最长文案**、**RTL** 下 **不得**出现约束冲突、压缩异常或内容 clipping（除非配置明确 `numberOfLines`）。

**必须：**

1. **单一布局权威** — 优先 `UIStackView` + `FKCellLayoutMetrics` 常量；避免同一视图既有 frame 又有冲突 Auto Layout。
2. **语义边** — 使用 `leading`/`trailing`；禁止硬编码 left/right（RTL 见 §11.4）。
3. **Compression Resistance / Hugging** — 标题 vs 详情 vs accessory **必须**显式设置；长 detail 截断时 **压缩标题侧**，不挤压 chevron 槽位。
4. **固定槽位** — Icon 列、checkmark 列、chevron 列 **固定宽度**；分隔线 inset 与标题 leading 对齐（§6.3）。
5. **优先级** — 必要时使用 `UILayoutPriority`（如 error label 可换行 `999`，accessory `required`）。
6. **Intrinsic 高度** — 自适应行高依赖 `contentView` 上下约束 **完整闭合**；Form 多行/展开须文档化 `preferredLayoutAttributes` 或 batch update 模式。
7. **Debug** — Debug 构建可对 `FKCellKit` 启用 constraint 冲突日志；PR **不得**引入 Xcode constraint warning。

**禁止：**

- 为「占位」创建零尺寸 invisible 视图撑布局（用 stack spacing / layoutGuide）。
- 在 `layoutSubviews` 里反复 `removeConstraints` + 重建（用 `apply(_:)` 更新常量或 `isHidden`）。
- 嵌套超过 **3 层** 无功能意义的 container（见 §12.4 层级预算）。

详见 §11.5。

#### 2.4.5 列表性能与视图层级（长列表优先）

Cell 主要用于 `UITableView` / `UICollectionView`，单页 **数十～上千** 行是常态。实现 **必须**按滚动性能设计。

**视图层级：**

| 预算 | 目标 |
|------|------|
| 典型单行 Cell `contentView` 子视图 | **≤ 8** 个（含 stack 子项计层） |
| 嵌套 container | **≤ 3** 层（contentView → stack → 叶子） |
| 每个 accessory 类型 | **懒创建**；`apply` 切换类型时 **复用** 或 `isHidden`，非 remove/add  churn |

**懒加载与复用：**

- Trailing chevron / checkmark / badge / 错误 label：**按需** `isHidden = true`，**不**在 init 堆满所有可能 accessory。
- 远程图：**必须** `FKImageView` + `prepareForReuse` 取消加载。
- 表单 field：单一 `FKTextField` 实例；切换 layout **不**重建 field。
- SMS 倒计时 Timer：**invalidate** on reuse；禁止泄漏。

**`apply(_:)` / `configure(with:)`：**

- **同步**、无网络、无阻塞主线程布局。
- 仅更新 **变化** 的子树（diff 配置）；避免 `removeFromSuperview` 风暴。
- 富文本/链接：**复用** `FKCellLinkTextView` 实例。

**禁止：**

- 无功能意义的背景层、shadow 容器、额外 `UIView()` 包裹。
- Cell 内 `draw(_:)` 复杂自绘（应用 `FKDivider`、子组件或 `CALayer` 极简场景）。
- 每行独立 heavy 子树（如全页 `WKWebView`、内嵌完整 `UICollectionView` 除非样式 ID 明确要求如 D-26、X-63）。

**验收：** Examples 中 **500 行** 同类型 Cell 滚动 FPS 可接受（ Instruments Core Animation 无持续掉帧）；内存无 accessory 泄漏。

详见 §12.4。

---

## 3. 页面参考与 Cell 样式目录

以下基于 **iOS 设置 Inset Grouped 典型页面结构**（General、About、Software Update、iOS 详情、iOS Version、WeChat 存储、General 列表、Language & Region、AutoFill、Legal & Regulatory、AirDrop、Dictionary、Transfer or Reset、iPhone Storage，共 14 类场景）与 **§3.6.2 表单布局参考表**（7 类 archetype，**无配图**）归纳。**样式 ID** 供 §7–§9 与 Examples 交叉引用。

### 3.1 页面级结构（非单行，但 CellKit 需支持）

| ID | 名称 | 参考页面 | 描述 |
|----|------|----------|------|
| **S-01** | Section 小标题头 | Language & Region、AirDrop、AutoFill | 小号、全大写或 Title Case、secondary 灰色，位于白色卡片上方 |
| **S-02** | Section 说明尾 | 多处 | 卡片下方多行灰色说明；可含蓝色可点链接 |
| **S-03** | Inset Grouped 卡片容器 | 全部 | 白底圆角（≈10–12pt）块，左右距屏幕 ≈16–20pt，块间垂直间距 |
| **S-04** | 导航栏 | 全部 | 不在 CellKit 范围；Examples 用系统 `UINavigationController` |

### 3.2 展示类行型（Display）

| ID | 名称 | 参考页面 | Leading | 主内容 | Trailing | 分隔 | 交互 |
|----|------|----------|---------|--------|----------|------|------|
| **D-01** | 纯导航 | Legal「Built-in Apps」 | — | 标题 | Chevron | 标准 inset | Push |
| **D-02** | 键值只读 | About「Model Name」 | — | 标题 | 灰色 Detail | 标准 inset | 无 |
| **D-03** | 键值导航 | About「Name」「iOS Version」 | — | 标题 | Detail + Chevron | 标准 inset | Push |
| **D-04** | 图标导航 | General 列表行 | 彩色圆角 Icon | 标题 | Chevron | **Icon 后 inset** | Push |
| **D-05** | 信息头（Icon + 多行元数据） | iOS 详情、WeChat 顶行 | 大 App/OS Icon | 标题 + 1–2 行副标题 | — | 标准 inset | 通常无 |
| **D-06** | 居中 Hero 说明 | General 顶卡 | 居中 Icon | 居中标题 + 居中多行说明 | — | 无/卡片底 | 无 |
| **D-07** | 富文本详情卡 | iOS Version | — | 粗体标题 + 多行正文 | — | 卡内全宽分隔 | 底部蓝色链接 |
| **D-08** | 更新状态卡 | Software Update 中部 | Icon | 标题 + 红色状态 + 正文 + 链接 | — | 卡内分隔 | 链接 |
| **D-09** | 警告行动卡 | Software Update 底部 | — | 粗体标题 + ⚠️ + 正文 | 警告 Icon | 分隔 + 蓝色行动 | 行动按钮 |
| **D-10** | 左对齐行动链接 | Language「Add Language…」 | — | 蓝色标题 | — | 标准 inset | 回调 |
| **D-11** | 居中/左对齐行动按钮 | Shut Down、Offload/Delete | — | 蓝色或红色标题 | — | 独立单格或组内 | 回调 |
| **D-12** | 功能推广卡 | Transfer「Prepare for New iPhone」 | 居中 Icon | 标题 + 说明 | — | 分隔 + 「Get Started」 | CTA |
| **D-13** | 存储摘要卡 | iPhone Storage 顶卡 | — | 标题 + 用量 + 进度条 + 图例 | — | 独立卡片 | 只读 |
| **D-14** | 图标 + 双行 + 值 + 导航 | Storage 应用列表 | App Icon | 标题 + 副标题 | 值 + Chevron | Icon 后 inset | Push |
| **D-15** | 双列法规/复杂信息 | Legal 认证块 | 区域标签 | 多行地址/编号/Logo 网格 | — | 行内多段 | 只读 |
| **D-16** | 键值对（强调值） | iOS「Total Size」 | — | 标题 | 黑色等宽值 | 标准 inset | 无 |

### 3.3 设置行内控件（I-01–I-07，交互类之子集）

| ID | 名称 | 参考页面 | Leading | 主内容 | Trailing | 交互 |
|----|------|----------|---------|--------|----------|------|
| **I-01** | 开关行 | AirDrop、AutoFill | — | 标题 | `UISwitch` / `FKToggle` | 切换 |
| **I-02** | 图标 + 副标题 + 开关 | AutoFill「Passwords」 | App Icon | 标题 + 副标题 | Switch | 切换 |
| **I-03** | 单选 Checkmark | AirDrop、Dictionary | Checkmark 占位 | 标题（+ 可选副标题） | — | 单选/多选 |
| **I-04** | 值 + 导航 | Language「Region」 | — | 标题 | 灰色值 + Chevron | Push / Picker |
| **I-05** | Picker 指示行 | AutoFill「Set Up Codes In」 | — | 标题 | Icon + 值 + ↕︎ | 弹出选择 |
| **I-06** | 可排序双行 | Language 语言列表 | — | 标题 + 副标题 | Reorder 把手 | 排序* |
| **I-07** | 带状态值导航 | Software Update 顶行 | — | 标题 | 「Off」+ Chevron | Push |
| **I-08** | 多选 Checkbox | 批量编辑、表单多选 | optional Icon | 标题 + 副标题 | `FKCheckbox` | 多选切换 |
| **I-09** | 收藏/星标 Toggle | 书签、收藏夹 | optional Icon | 标题 | 星形 Icon（空/实） | 点击切换 |
| **I-10** | 行内 Segment | 设置内模式切换 | — | `FKSegmentedControl` 撑满 | — | 分段切换 |
| **I-11** | 行内 Slider | 音量、亮度、字体大小 | 标题 | `FKSlider` | 当前值 optional | 连续调节 |
| **I-12** | 删除/编辑模式 | 邮件、备忘录列表 | — | 标题 + 副标题 | 系统 Edit 控件 / ✓ | 编辑态 |
| **I-13** | 详情 + Stepper | 购物车设置、配额 | 标题 | 说明 optional | `UIStepper` 或 ± | 数值增减 |
| **I-14** | 权限三级选项 | 通知样式 None/Banners/Alerts | — | 标题 | 同 I-03 Checkmark | 单选 |
| **I-15** | 带预览的 Picker | 铃声、壁纸缩略图 | 标题 | 当前值 | 小预览图 + Chevron | Push/Picker |

\* v1：把手仅 UI + `onReorderRequested`；是否启用系统 `UITableView` editing 由宿主决定。

### 3.4 语义化表单字段（F-01–F-13）

表示 **字段业务语义**（与布局正交，layout 见 §3.6.2 `X-*`）：

| ID | 名称 | 典型场景 | 核心嵌入 |
|----|------|----------|----------|
| **F-01** | 单行文本 | 昵称、邮箱、姓名 | `FKTextField` |
| **F-02** | 密码 | 登录/注册 | `FKTextField` secure + X-08 |
| **F-03** | 验证码 / OTP | 短信登录 | `FKCodeTextField` / X-18 |
| **F-04** | 多行文本 | 备注、反馈 | `FKCountTextView` |
| **F-05** | 协议勾选 | 注册 | `FKCheckbox` + 富文本（X-52） |
| **F-06** | 单选组 | 性别、支付方式 | `FKRadioGroup`（X-37） |
| **F-07** | 分段选择 | 筛选条件 | `FKSegmentedControl`（X-38） |
| **F-08** | 日期/时间 | 生日 | `UIDatePicker` / X-13、X-14 |
| **F-09** | 主提交按钮 | 登录 | `FKButton`（X-49） |
| **F-10** | 次要/文字按钮 | 忘记密码 | 链接（X-51） |
| **F-11** | 头像上传 | 资料编辑 | `FKAvatar` + X-19 |
| **F-12** | 手机号 | 区号 + 号码 | 双 field + X-06 |
| **F-13** | 社交登录 | 第三方 | Icon 按钮行（X-53） |
| **F-14** | 邮箱 | 登录/通知 | `FKTextField` + X-54 域名后缀 optional |
| **F-15** | 金额/货币 | 支付、定价 | `FKTextField` + X-09 货币前缀 |
| **F-16** | 证件/银行卡 | KYC | 格式化 + 掩码 + X-20 |
| **F-17** | URL / 链接 | 配置、分享 | `FKTextField` URL keyboard |
| **F-18** | 整数/数量 | 库存、人数 | Number pad + X-32/33 |
| **F-19** | 地址自动补全 | 收货 | field + X-45 |
| **F-20** | 银行卡号 | 绑卡 | 分组空格 + Luhn 校验 hint |

### 3.5 扩展展示类样式目录（通用业务场景）

§3.2 主要来自 **iOS 设置 Inset Grouped 典型页面**。实际产品开发中，列表/Table 还大量出现下列 **展示类** 行型（只读或弱交互：点击跳转、复制、展开预览）。按业务域分组；**样式 ID** 延续 `D-*` 编号。

> **实现策略：** 标注 **组合（Compose）** 的样式优先用已有 Cell + 邻域组件 trailing/leading 扩展实现，避免重复 Auto Layout；标注 **独立（Standalone）** 的样式在 CellKit 交付专用 Cell 类型。

#### 3.5.1 用户与社交

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-17** | 个人资料头 | 我的、编辑资料入口 | 大 `FKAvatar` | 昵称 + 账号/简介 | Chevron / 「编辑」 | Standalone |
| **D-18** | 联系人/成员 | 通讯录、团队成员 | `FKAvatar` | 姓名 + 职位/公司 | Chevron | Standalone |
| **D-19** | 在线状态 | IM 好友列表 | `FKAvatar` + `FKPresenceIndicator` | 姓名 + 状态文案 | 时间 optional | Standalone |
| **D-20** | 会话预览 | 消息列表 | `FKAvatar` + 未读角标 | 标题 + 最后一条消息 | 时间 + 未读点 | Standalone |
| **D-21** | 通知条目 | 通知中心 | 类别 Icon / App Icon | 标题 + 摘要 | 时间 | Standalone |
| **D-22** | 系统公告 | 站内信、更新日志 | Icon | 标题 + 多行摘要 + 日期 | — | Compose → D-07 变体 |

#### 3.5.2 媒体与内容

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-23** | 缩略图条目 | 相册、视频列表 | 圆角缩略图 | 标题 + 副标题 | 时长角标 / Chevron | Standalone |
| **D-24** | 音频/播客 | 音乐 App、播客 | 封面图 | 曲名 + 艺术家 | 时长 / 序号 | Standalone |
| **D-25** | 资讯/文章 | 新闻 Feed | 配图（optional） | 标题 + 来源 + 时间 | — | Standalone |
| **D-26** | 横向缩略图条 | 最近浏览、附件预览 | — | 内嵌横向 `UICollectionView` | — | Standalone |
| **D-27** | 大图卡片 | 横幅内容、推广位 | — | 全宽图 + 标题 + 摘要 | — | Standalone（类 `FKImageBanner` 行内版） |

#### 3.5.3 电商与交易

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-28** | 商品条目 | 购物车、订单商品 | 商品图 | 名称 + SKU/规格 | 价格 / 数量 | Standalone |
| **D-29** | 订单摘要行 | 结算页 | — | 小计/税费/运费 键值栈 | 金额 | Compose → 多行 D-02 |
| **D-30** | 支付方式 | 钱包、结账 | 卡组织 Icon | 掩码卡号 + 到期 | 默认标签 / Chevron | Standalone |
| **D-31** | 优惠券/促销 | 领券中心 | 券面左色条 | 面额 + 使用条件 + 有效期 | 「去使用」 | Standalone |
| **D-32** | 物流轨迹节点 | 快递详情 | 时间轴圆点/线 | 状态 + 地点 + 时间 | — | Standalone |

#### 3.5.4 状态、进度与指标

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-33** | 状态胶囊 | 订单状态、审核态 | optional Icon | 标题 | `FKStatusPill` | Compose |
| **D-34** | 数字角标 | 未读、待办计数 | Icon / 标题 | 副标题 optional | `FKBadge` | Compose |
| **D-35** | 同步/任务状态 | 云同步、上传队列 | Icon | 标题 + 状态说明 | Spinner / ✓ / ✗ | Standalone |
| **D-36** | 行内进度 | 下载、导入 | Icon | 文件名 + `FKProgressBar` | 百分比 | Standalone |
| **D-37** | KPI 指标卡 | 仪表盘、报表 | — | 大数字 + 标签 + 同比趋势箭头 | — | Standalone |
| **D-38** | 迷你图表行 | 数据概览 | 标题 | 内嵌 sparkline / 柱形 | 数值 | P2 Standalone |

#### 3.5.5 复制、分享与凭证

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-39** | 可复制键值 | 订单号、邀请码、SN | 标签 | 等宽/长字符串 | `FKCopyChip` / 复制 Icon | Standalone |
| **D-40** | 分享目的地 | 系统分享面板行 | App/渠道 Icon | 标题 | — | Compose → D-04 无 chevron |
| **D-41** | 二维码展示 | 收款码、取票码 | — | 居中 QR + 说明文字 | — | Standalone |
| **D-42** | 邀请/Referral | 增长活动 | Icon | 标题 + 奖励说明 | 分享 Chevron | Compose → D-03 |

#### 3.5.6 位置、文件与文档

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-43** | 地址条目 | 收货地址、门店 | Pin Icon | 多行地址 + 联系人电话 | 默认标签 / Chevron | Standalone |
| **D-44** | 地图预览 | 门店详情、签到 | 地图快照缩略图 | 地名 + 距离 | Chevron | Standalone |
| **D-45** | 文件条目 | 文件管理器、附件 | 文件类型 Icon | 文件名 + 大小 + 日期 | Chevron / 云状态 | Standalone |
| **D-46** | 文件夹条目 | 网盘 | 文件夹 Icon | 名称 + 「N 项」 | Chevron | Compose → D-14 无 value |
| **D-47** | 下载状态文件 | 离线下载列表 | 文件 Icon | 名称 + 进度/已下载 | 状态 Icon | Standalone |

#### 3.5.7 时间线、活动与步骤

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-48** | 时间轴事件 | 订单历史、审计日志 | 左列日期/时间块 | 事件标题 + 描述 | — | Standalone |
| **D-49** | 动态/feeds | 社交动态 | `FKAvatar` | 「A 评论了 B」+ 目标预览 | 时间 | Standalone |
| **D-50** | 只读步骤清单 |  onboarding 回顾、流程状态 | 步骤序号/✓圈 | 步骤标题 + 说明 | 状态 Pill | Standalone |
| **D-51** | 日历事件 | 日程、预约 | 日期块（月/日） | 标题 + 时间/地点 | 色条标识 | Standalone |

#### 3.5.8 评分、标签与筛选摘要

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-52** | 评分展示 | 商品详情、App 评价 | — | `FKRatingControl`（只读）+ 分数 + 人数 | Chevron | Standalone |
| **D-53** | 评论摘要 | 评价列表 | `FKAvatar` | 用户名 + 星标 +  excerpt | 时间 | Standalone |
| **D-54** | 标签行 | 技能、话题 | 标题 optional | 横向 `FKChipGroup` | — | Standalone |
| **D-55** | 筛选摘要 | 列表页已选筛选 | — | 「已选：」+ Chips | 清除 | Standalone |

#### 3.5.9 内嵌横幅、提示与空占位

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-56** | 行内通知条 | 列表顶部警告 | — | 内嵌 `FKNoticeBar` / 轻量 Banner | 关闭 optional | Standalone |
| **D-57** | 行内提示 | 表单说明、合规提示 | Info Icon | 多行 secondary 文案 | — | Compose → S-02 行内版 |
| **D-58** | Section 内空态 | 无数据占位 | — | Icon + 标题 + 说明 | CTA optional | Standalone（复用 `FKEmptyState` 紧凑 preset） |
| **D-59** | 跑马灯说明 | 活动规则、Ticker | — | `FKMarqueeLabel` 单行 | — | Compose |

#### 3.5.10 设备、网络与权限

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-60** | 已配对设备 | 蓝牙、Home | 设备 Icon | 名称 + 连接状态 | 信号/电量 optional | Standalone |
| **D-61** | Wi‑Fi / 网络 | 网络列表 | Wi‑Fi Icon | SSID + 安全类型 | 信号条 | Standalone |
| **D-62** | 权限状态 | 隐私说明页 | 权限 Icon | 权限名 + 授权状态文案 | Chevron | Compose → D-03 |
| **D-63** | 订阅方案卡 | 会员中心 | — | 档位名 + 价格 + 权益列表 + 「当前」Badge | CTA | Standalone |

#### 3.5.11 可展开与搜索结果

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-64** | FAQ 折叠 | 帮助中心 | — | 问题标题 | Chevron ▼/▲ | Standalone |
| **D-65** | 展开式详情 | Release Notes 条目 | — | 标题 + 折叠正文 | 展开指示 | Standalone |
| **D-66** | 搜索命中 | 搜索结果列表 | optional Icon | 标题/副标题 **高亮**匹配词 | Chevron | Standalone |
| **D-67** | 最近搜索 | 搜索历史 | 时钟 Icon | 搜索词 | 删除 ✕ | Standalone |

#### 3.5.12 样式组合矩阵（减少重复实现）

下列 **不必**单独新建 Cell 类型，文档要求通过 **配置组合** 或 **轻量 Variant** 覆盖：

| 基础 Cell | + 扩展 | 等效样式 |
|-----------|--------|----------|
| `FKCellKeyValueCell` | `valueEmphasis`、多行 value | D-02、D-16、D-29 单行 |
| `FKCellValueDisclosureCell` | trailing pill 槽位 | D-33、D-62 |
| `FKCellIconDisclosureCell` | 无 chevron | D-40 |
| `FKCellIconValueDisclosureCell` | 去掉 value | D-46 |
| `FKCellRichTextCell` | 紧凑模式 | D-22 |
| `FKCellInfoCell` | 小 avatar 尺寸 | D-18 简化版 |
| `FKCellSectionFooterView` | 嵌入 cell | D-57 |

#### 3.5.13 补充展示类（业务扩展 II）

下列为 §3.5.1–§3.5.11 **尚未覆盖**、但在中大型 App 中 **高频或强复用** 的展示行型。

| ID | 名称 | 典型场景 | Leading | 主内容 | Trailing | 策略 |
|----|------|----------|---------|--------|----------|------|
| **D-68** | 快捷入口宫格 | 首页金刚区、Settings 快捷 | — | 内嵌 3–5 列 Icon+标题 grid | — | Standalone |
| **D-69** | 交易/账单流水 | 钱包、银行 | 商户 Icon | 商户名 + 时间 | 金额（红/绿） | Standalone |
| **D-70** | 待办/任务 | Reminders、Tasks | Checkbox 圈（只读态） | 标题 + 截止日 | 优先级点 | Standalone* |
| **D-71** | 投票结果条 | 问卷结果 | — | 选项名 + **比例条** + 百分比 | — | Standalone |
| **D-72** | 排行榜 | 游戏、活动 | 名次 | Avatar + 昵称 | 分数 | Standalone |
| **D-73** | 播放列表行 | 音乐/视频 | 封面 + ▶︎ 叠层 | 标题 + 作者 | 时长 / 更多 | Standalone |
| **D-74** | 引用块 | 评论引用、邮件 | 左竖线 | 引用正文 + 来源 | — | Standalone |
| **D-75** | 等宽数据块 | API Key 预览、日志 | — | Monospace 多行 + 行数 | 复制 | Standalone |
| **D-76** | 语言/地区 | 语言列表 | 国旗/Icon | 语言名 + 本地化名 | 选中 ✓ | Compose → I-03 |
| **D-77** | 版本更新 | App 关于页 | App Icon | 版本号 + 「可更新」 | Chevron | Standalone |
| **D-78** | 排序/筛选栏 | 列表顶 | — | 「排序 ▼」\|「筛选」文本按钮 | — | Standalone |
| **D-79** | 加载更多脚 | Feed 底 | — | Spinner + 「加载中…」 | — | Standalone |
| **D-80** | 骨架单行 | 首屏占位 | — | `FKSkeleton` 灰条 | — | 与 Skeleton 模块协作 |
| **D-81** | 树形/缩进 | 评论楼中楼、目录 | 缩进层宽 | 标题 + 摘要 | Chevron optional | Standalone |
| **D-82** | 横向操作组 | 滑动替代 | — | `编辑 \| 分享 \| 删除` 文本按钮 | — | Standalone |
| **D-83** | LIVE / 实时 | 直播、赛事 | `LIVE` Pill | 标题 + 观看数 | — | Standalone |
| **D-84** | 学习/课程进度 | 教育 App | 封面 | 课名 + 进度条 + `%` | Chevron | Standalone |
| **D-85** | 提醒/闹钟 | 时钟 App | Icon | 时间 + 重复规则 | Switch optional | Compose |
| **D-86** | Now Playing 迷你 | 音乐底栏入列表 | 封面 | 曲名 + 艺术家 | ⏯ | Standalone |
| **D-87** | 冲突/差异摘要 | 同步、Git | ⚠️ Icon | 冲突说明 + 两行 diff 预览 | 解决 CTA | Standalone |
| **D-88** | 内联零结果 | 搜索无结果 | — | Icon + 「无结果」+ 建议 | 重试 optional | Standalone |
| **D-89** | 环境/账户切换 | Dev/Staging、多账号 | 环境色点 | 环境名 + 当前用户 | Chevron | Standalone |
| **D-90** | 横向对比列 | 套餐功能对比 | 功能名 | ✓/✗/文案 多列 | — | P2 Standalone |

\* **D-70** 若需点击完成，使用 **I-08** 多选 Checkbox 变体（交互类）。

#### 3.5.14 补充展示 Compose 矩阵

| 基础 | 扩展 | 等效 |
|------|------|------|
| `FKCellIconDisclosureCell` | + 金额着色 | D-69 |
| `FKCellMediaThumbnailCell` | + play overlay | D-73 |
| `FKCellProgressCell` | + 百分比 trailing | D-84 |
| `FKCellSelectionCell` | + 国旗 leading | D-76 |
| `FKCellInlineEmptyCell` | + query 文案 | D-88 |

### 3.6 交互类 Cell 样式目录

**交互类 Cell** 指用户可编辑、可触发控件、或与键盘/手势/其他字段联动的行。与 **展示类**（§3.2、§3.5）相对。

**编号体系：**

| 前缀 | 含义 | 章节 |
|------|------|------|
| **I-*** | 设置页行内控件（Switch、Checkmark、Reorder…） | §3.3 |
| **X-*** | 表单/搜索/复合交互 **布局与行为模式**（§3.6.2 布局参考 + 业务扩展） | 本节 |
| **F-*** | 语义化表单字段类型（文本、密码、OTP…） | §3.4、§9 |

**核心设计原则（强制）：**

1. **布局 × 语义 解耦** — 同一 `F-01` 文本输入可套用 `X-01` 下划线或 `X-02` 卡片布局（见 §9 矩阵）。
2. **输入能力不重复** — 格式化、校验、键盘类型由 **`FKTextField`** / **`FKSearchField`** 等负责；Cell 管 **标签、边距、Accessory 槽位、错误展示、联动**。
3. **Accessory 槽位标准化** — Leading / Trailing 使用统一 `FKFormAccessory`（§6.8），避免每种 Cell 各自实现 eye icon、倒计时按钮。

#### 3.6.1 设置行内控件（I-01–I-07，§3.3 摘要）

iOS 设置风格、**非文本输入**的行内交互：Switch、Checkmark 单选、Picker 指示、Reorder 把手等。详见 §8.1。

#### 3.6.2 表单输入布局风格（Material / Card / Inline）

来自注册/资料/登录类表单的 **布局 archetype**（忽略具体配色/字号，只约束结构）。**无配图**；下列 **布局参考 ID** 供表格与 Examples 交叉引用：

| 参考 ID | 名称 | 结构摘要 |
|---------|------|----------|
| **R-01** | Material 下划线登录/注册 | 顶置小 Label + 大字号输入 + **全宽底边线**；常见邮箱、密码、手机（分栏）行 |
| **R-02** | 卡片单行资料 | **白圆角卡片**内单行 placeholder/value；适合姓名、日期等紧凑字段 |
| **R-03** | 行内搜索变体 | Capsule 药丸搜索框、右侧主色按钮、分类前缀 `All ▼`、语音 Mic Icon 等组合 |
| **R-04** | 卡片堆叠注册 | **浅底圆角卡片**；Label 上、输入下；含 Account Type Drop-down、手机竖切分栏 |
| **R-05** | Icon 下划线联系方式 | 左 gray Icon + 输入 + 底边线；含 **表单 Section 头**（Bold 标题 + 灰说明）、Skype/Facebook 平台分栏 |
| **R-06** | 校验态与金额 | 底线 **红/绿** + Error Text；金额行内 **$ / ¥ / %** 前缀 |
| **R-07** | 企业 Inline Label 表单 | 左固定宽 Label（含必填 `*`）+ 右输入/placeholder；Drop-down、Push 选择、图形验证码、短信码行 |

| ID | 名称 | 布局参考 | 结构描述 | Leading | 主输入区 | Trailing | 底部分隔 |
|----|------|----------|----------|---------|----------|----------|----------|
| **X-01** | 下划线 + 顶置 Label | R-01、R-06 | Label 小字在上；输入大字在下；**全宽底边线** | — | `FKTextField` | optional | **状态色底线**（黑/红/绿） |
| **X-02** | 卡片 + 堆叠 Label | R-04 | 圆角浅底卡片；Label 上、Placeholder/Value 下 | — | 内嵌 field | optional | 无（卡片边界） |
| **X-03** | 卡片单行填充 | R-02 | 白圆角卡片；**仅一行** value/placeholder | — | 单行 field | optional | 无 |
| **X-04** | 左 Label + 右输入 | R-07 | 左固定宽 Label（+ 必填 `*`）；右输入/placeholder | Label | field 撑满 | Accessory | 行底 hairline |
| **X-05** | Icon + 下划线输入 | R-05 | 左 gray Icon；右输入；共用底边线 | Icon | field | optional | 底边线 |
| **X-06** | 前缀选择 + 输入（竖切） | R-01/R-02/R-04 手机行 | **左：** 国旗+区号+▼；**右：** 号码 field；可同卡片或同 underline | Prefix picker | phone field | — | 分区竖线 + 底边线 |
| **X-07** | 平台选择 + 用户名（横切） | R-05（Skype/FB 行） | **左：** 品牌 Icon+平台名+▼；**右：** @username field；各自底边线 | Platform | username | — | 双 field 独立底线 |
| **X-08** | 密码 + 可见性切换 | R-01、R-02、R-06 | 任一种 layout + trailing **eye** toggle | — | secure field | 眼睛 Icon | 随 layout |
| **X-09** | 前缀文字/符号 | R-06（金额行） | Label 在上；输入行内 **$ / ¥ / %** 前缀 | Prefix text | amount field | — | 底边线 |
| **X-10** | 表单 Section 头 | R-05 | **非输入**；Bold 标题 + 灰色说明（分组引导） | — | 文案 stack | — | 无 |

#### 3.6.3 选择与弹出类（仍属交互，但非键盘输入）

| ID | 名称 | 布局参考 | 结构描述 | 交互 |
|----|------|----------|----------|------|
| **X-11** | 表单 Drop-down | R-04（Account Type）、R-07（证件类型） | Label + placeholder/值 + **Chevron Down** | 弹 ActionSheet / Picker |
| **X-12** | 表单 Push 选择 | R-07（归属组织 Push 行） | Label + placeholder/值 + **Chevron Right** | Push 子页选择 |
| **X-13** | 日期选择行 | R-02 | 左 value 或 placeholder；右 **Calendar** Icon | `UIDatePicker` / 日历弹层 |
| **X-14** | 时间选择行 | — | 同 X-13；Clock Icon | Time picker |
| **X-15** | 级联选择 | 省市区 | 多行 X-11 或单行组合展示 | 级联 Picker |

#### 3.6.4 验证码、倒计时与图片附件

| ID | 名称 | 布局参考 | 结构描述 | 交互 |
|----|------|----------|----------|------|
| **X-16** | 图形验证码 | R-07 | 输入 field + trailing **Captcha 图片**（可点刷新） | 键盘 + 点击图片刷新 |
| **X-17** | 短信码 + 发送按钮 | R-07 | field + trailing **文字按钮**「获取验证码」 | 点击发送 + **倒计时**禁用 |
| **X-18** | OTP 分格 | — | 整行 `FKCodeTextField`；非单 field | 分格输入 + 联动下格 |
| **X-19** | 图片/文件选取 | 头像、附件 | Label + 「上传」/ 缩略图 preview + Chevron | 相册/文档 Picker |
| **X-20** | 扫码输入 | 快递单号 | field + trailing **Scan** Icon | 打开相机扫码回填 |

#### 3.6.5 校验、必填与字段状态

| ID | 名称 | 布局参考 | 说明 |
|----|------|----------|------|
| **X-21** | 必填星号 | R-07 | Label 后红色 `*`；`isRequired` 驱动 |
| **X-22** | 错误态 | R-06（错误列） | 底线 **红** + 下方 **Error Text** |
| **X-23** | 成功/有效态 | R-06 | 底线 **绿**（optional ✓） |
| **X-24** | Helper 说明 | — | 底线/卡片下 footnote 灰字 |
| **X-25** | 实时校验联动 | 密码强度 | 输入框下 **强度条** / 规则 checklist |

#### 3.6.6 搜索与筛选输入（行内搜索布局参考）

> **边界：** 搜索 **控件本体** 由 **`FKSearchBar` / `FKSearchField`** 实现；CellKit 提供 **嵌入列表的行级壳**（`FKFormCellSearch`），不复制 60+ 搜索 UI 变体。

| ID | 名称 | 布局参考 | 结构描述 |
|----|------|----------|----------|
| **X-26** | 行内搜索（Capsule） | R-03（Capsule） | 整行嵌入 `FKSearchField`；圆角 capsule |
| **X-27** | 搜索 + 右侧按钮 | R-03（右侧按钮） | field + trailing Search/Go 按钮 |
| **X-28** | 搜索 + 分类前缀 | R-03（分类前缀） | `[Category ▼] \| field \| icons` |
| **X-29** | 搜索 + 语音 | R-03（语音 Icon） | field + Mic Icon |
| **X-30** | 筛选条 Cell | — | 横向 `FKChipGroup` 或 Segment 可点筛选 |

#### 3.6.7 数值、评分与连续调节

| ID | 名称 | 典型场景 | 结构描述 |
|----|------|----------|----------|
| **X-31** | Slider 行 | 音量、价格区间 | Label + `FKSlider` + optional 当前值 |
| **X-32** | Stepper 行 | 数量、天数 | Label + `UIStepper` / 自定义 ± |
| **X-33** | 数量选择行 | 购物车 | Label + − **[N]** + + |
| **X-34** | 可编辑评分 | 评价提交 | Label + 可点 `FKRatingControl` |
| **X-35** | 范围双 Slider | 价格筛选 | Label + min/max 双滑块 |

#### 3.6.8 选择与 Toggle 组（表单语境）

与 **I-03** 不同：出现在 **表单分组** 内，常带 Label 说明或竖向排列。

| ID | 名称 | 典型场景 | 结构描述 |
|----|------|----------|----------|
| **X-36** | Checkbox 组 | 多选兴趣 | 多行 `FKCheckbox` + 标题 |
| **X-37** | Radio 组行 | 性别 | 单行或多行 `FKRadioGroup` |
| **X-38** | Segment 行 | 切换输入模式 | Label + `FKSegmentedControl` |
| **X-39** | Switch 说明行 | 接收营销邮件 | 标题 + 副标题 + Switch（同 I-01 但 form 卡片包） |
| **X-40** | Tag 多选输入 | 技能标签 | `FKChipGroup` 可选 + 添加 |

#### 3.6.9 联动、复合与动态表单

| ID | 名称 | 典型场景 | 行为 |
|----|------|----------|------|
| **X-41** | 条件显隐 | 「有公司？」→ 公司名 field | Toggle/Select 控制其他 Cell 插入 |
| **X-42** | 字段联动校验 | 密码 + 确认密码 | 失焦/实时比对；不匹配 X-22 |
| **X-43** | 表单步骤条 | 注册 Step 1/3 | Section 顶 progress（非单行时可配合 Header） |
| **X-44** | 地址复合 | 收货 | 单行摘要；点进 multi-field 子表单 |
| **X-45** | 自动补全 | 城市搜索 | field + dropdown 建议列表 overlay |
| **X-46** | 地图选点 | 门店位置 | 地图 preview + 「选择位置」 |
| **X-47** | 签名板 | 合同 | 行内 `PKCanvasView` 或 push 全屏 |
| **X-48** | 富文本编辑 | 公告 | 简化 toolbar + `FKCountTextView` |

#### 3.6.10 提交与操作行

| ID | 名称 | 典型场景 | 结构描述 |
|----|------|----------|----------|
| **X-49** | 主按钮 | 登录/注册 | 满宽 `FKButton` |
| **X-50** | 双按钮 | Cancel + Save | 左右或上下双 CTA |
| **X-51** | 文字链操作 | 忘记密码 | 居中/右对齐链接 |
| **X-52** | 协议勾选 | 注册 | `FKCheckbox` + 富文本链接（= F-05） |
| **X-53** | 社交登录 | OAuth | 品牌 Icon 按钮行（= F-13） |

#### 3.6.11 布局风格 × 语义字段 速查

|  | X-01 下划线 | X-02 卡片堆叠 | X-03 卡片单行 | X-04 左 Label | X-05 Icon+线 |
|--|------------|--------------|--------------|--------------|-------------|
| **F-01 文本** | ✓ 默认 Material | ✓ 注册表单 | ✓ 简洁列表 | ✓ 政务/企业 | ✓ 联系方式 |
| **F-02 密码** | ✓ | ✓ | ✓ | ✓ | — |
| **F-12 手机** | ✓ + X-06 | ✓ + X-06 分格 | ✓ | ✓ | — |
| **F-08 日期** | — | ✓ X-13 | ✓ X-13 | ✓ X-13 | — |
| **X-11 Picker** | ✓ | ✓ | ✓ | ✓ | — |

#### 3.6.12 实现策略（Compose vs Standalone）

| 策略 | 适用 | 说明 |
|------|------|------|
| **Layout 配置** | X-01–X-05、X-08–X-10 | 单一 `FKFormCellTextField` + `FKFormCellLayout` enum |
| **Accessory 配置** | X-08、X-16–X-20、X-17 | `FKFormAccessory` trailing/leading |
| **Standalone Cell** | X-06、X-07、X-18、X-26–X-30、X-45–X-48 | 布局差异大或内嵌多控件 |
| **Delegate 联动** | X-41–X-42、X-15 倒计时 | Cell 只暴露 callback；编排由宿主或未来 `FKForm` |

#### 3.6.13 补充设置/列表交互（I-08–I-15）

§3.3 已列 ID；此处补充 **与展示类边界** 及典型用法：

| ID | 与 I-03 / D 类区别 | 关键点 |
|----|-------------------|--------|
| I-08 | I-03 为 **Checkmark 单选**；I-08 为 **Checkbox 多选** | `selectionStyle = .none`；trailing 或 leading checkbox |
| I-09 | 非 Switch；**瞬时 toggle** 无 on/off 文案 | 星标动画；可配合收藏 API |
| I-10 | 非 X-38（表单 Segment） | 整行仅 Segment；Settings grouped 卡片内 |
| I-11 | 非 X-31（表单 Slider） | 标题左、Slider 右撑满；可选实时数值 |
| I-12 | 系统 `UITableView` editing 或自定义 | 左圆删/右选；与 I-06 Reorder 可并存 |
| I-13 | 非 X-33 购物车式 | Settings 配额；min/max 约束 |
| I-14 | 同 I-03 布局 | 选项固定 2–4 个；Radio 语义 |
| I-15 | 同 I-05 + 预览 | trailing 28–40pt 预览图 |

#### 3.6.14 补充表单交互（X-54–X-72）

| ID | 名称 | 典型场景 | 结构 / 交互 |
|----|------|----------|-------------|
| **X-54** | 邮箱域名后缀 | 快速邮箱输入 | field + `@domain ▼` 或后缀 Chip |
| **X-55** | 双字段横排 | 名/姓、起止日期 | 单 Cell 内 `50% \| 50%` 两 field + 中缝分隔 |
| **X-56** | 金额区间 | 价格筛选表单 | 「最低」field — 「最高」field |
| **X-57** | 颜色选择 | 主题、标注 | 色块 Well + Hex field / 系统 ColorPicker |
| **X-58** | 富文本工具条 | 公告、帖子 | Cell 顶 B/I/U/Link toolbar + 下方 TextView |
| **X-59** | 语音输入 | 搜索、备注 | field + Mic；按住说话或 tap 转文字 |
| **X-60** | 生物识别门控 | 敏感操作确认 | Icon + 说明 + 「使用 Face ID」按钮 |
| **X-61** | PIN 圆点 | 支付 PIN、家长锁 | 4–6 圆点指示；配合隐藏 numpad |
| **X-62** | 拖拽上传区 | Web 风表单 | 虚线框 + 「拖入或点击上传」 |
| **X-63** | 多图 Grid 上传 | 商品图、用户反馈配图 | 3 列 grid + 「+」；删单张 × |
| **X-64** | 内联展开子字段 | 发票抬头 | Switch/Select 下 **同 Cell** 展开 field |
| **X-65** | NPS / 量表 | 满意度 | 0–10 或 1–5 横排可选按钮 |
| **X-66** | Emoji 选择 | 反馈、Reaction | 横向 emoji scroll + 选中放大 |
| **X-67** | 内嵌 Wheel Picker | 身高体重 | Cell 内 `UIPickerView`；行高自适应 |
| **X-68** | 计算/格式化预览 | 汇率、税费 | field 下实时显示计算结果行 |
| **X-69** | 字符计数 Footer | 简介、推文 | field 下 `128/280` 右对齐 |
| **X-70** | 系统 Picker 入口 | 选联系人、选照片 | 只读摘要 + 「选择…」→ 系统 Picker |
| **X-71** | 跳转系统设置 | 权限引导 | 说明 + 「前往设置」链接 |
| **X-72** | 地图 + 半径 | 配送范围 | 小地图 + Slider 调半径 |

#### 3.6.15 补充语义字段（F-14–F-20）

| ID | 默认 Layout | 默认 Accessory | 备注 |
|----|-------------|----------------|------|
| F-14 邮箱 | X-01 / X-03 | X-54 optional | 域名后缀列表可配置 |
| F-15 金额 | X-01 / X-04 | X-09 货币符号 | 小数位 locale |
| F-16 证件 | X-04 | 掩码显示 | 身份证/护照 formatter |
| F-17 URL | X-03 | clear | URL 校验 |
| F-18 数量 | X-04 | I-13 / X-33 | 整数 Stepper |
| F-19 地址 | X-02 | X-45 补全 | 与地图 X-46 组合 |
| F-20 银行卡 | X-01 | 分组 4-4-4-4 | PCI 显示掩码 |

#### 3.6.16 跨类混合行（Display + Interactive）

同一行 **既有展示又有轻交互**；实现用 Compose，**不**强制独立类名：

| ID | 名称 | 结构 | 组合 |
|----|------|------|------|
| **M-01** | 通知预览 + Switch | 标题/副标题 + Switch | I-02 |
| **M-02** | 商品 + Stepper | 商品信息 + 数量 | D-28 + I-13 |
| **M-03** | 文件 + 更多菜单 | 文件信息 + `…` | D-45 + Menu |
| **M-04** | 联系人多选 | 头像姓名 + Checkbox | D-18 + I-08 |
| **M-05** | 排序筛选条 | Sort + Filter + Chips | D-78 + D-55 |
| **M-06** | 播放 + 下载进度 | 媒体行 + 进度 | D-73 + D-36 |

**M-*** 仅作 **Examples 验收 ID**。

---

## 4. 组件命名与分类体系

### 4.1 模块与类型前缀

| 层级 | 命名 | 示例 |
|------|------|------|
| 模块目录 | `CellKit/` | `Sources/FKUIKit/Components/CellKit/` |
| 配置 | `FKCell*` / `FKFormCell*` + `Configuration` | `FKFormCellTextFieldConfiguration` |
| Table Cell | `FKCell*` / `FKFormCell*` | `FKFormCellTextFieldCell` |
| 行模型 | `FKCell*Row` / `FKForm*Row` | `FKFormTextFieldRow` |
| 布局枚举 | `FKFormCellLayout` | `.underline`、`.card`、`.inlineLabel`… |

**命名约定：**

- **`FKCell*`** — 展示类 + **设置行内控件**（`I-*`）
- **`FKFormCell*`** — 表单/输入/搜索/复合交互（`X-*`、`F-*`）
- **不**为每种 `X-*` 单独建类；优先 **`FKFormCell` + Layout + Accessory**（§3.6.12）

**与 §2.4.1 对齐：** 命名评审为 PR **必查项**；新增公开类型须更新组件 README 目录表。

### 4.1.1 类型命名与文件组织

| 公开类型 | 文件命名 |
|----------|----------|
| `FKCellDisclosureCell` | `FKCellDisclosureCell.swift` |
| `FKCellDisclosureConfiguration` | 同文件或 `FKCellDisclosureConfiguration.swift` |
| `FKCellDisclosureRow` | `Rows/FKCellDisclosureRow.swift`（ListKit 用时） |
| Internal 布局引擎 | `Internal/FKCellContentStack.swift` — **不** export |

Collection 变体：`FKCellDisclosureCollectionCell` — 与 Table **共享** Internal 布局 core，**禁止**复制约束代码。

### 4.2 样式 ID → 公开类型映射

> **Phase 归属：** 各 ID 的交付阶段见 **§14.4–§14.10**；下表「优先级」列（P0/P1/P2）表示产品重要度，**不等同于** Phase 序号。

| 样式 ID | 公开 Cell 类型 | 优先级 |
|---------|----------------|--------|
| S-01 | `FKCellSectionHeaderView` | P0 |
| S-02 | `FKCellSectionFooterView` | P0 |
| S-03 | `FKCellGroupConfiguration` + Table/Collection 背景装饰 | P0 |
| D-01 | `FKCellDisclosureCell` | P0 |
| D-02 | `FKCellKeyValueCell` | P0 |
| D-03 | `FKCellValueDisclosureCell` | P0 |
| D-04 | `FKCellIconDisclosureCell` | P0 |
| D-05 | `FKCellInfoCell` | P0 |
| D-06 | `FKCellHeroCell` | P1 |
| D-07 | `FKCellRichTextCell` | P1 |
| D-08 | `FKCellStatusDetailCell` | P1 |
| D-09 | `FKCellAlertActionCell` | P1 |
| D-10 | `FKCellLinkCell` | P0 |
| D-11 | `FKCellActionCell` | P0 |
| D-12 | `FKCellFeatureCardCell` | P1 |
| D-13 | `FKCellStorageSummaryCell` | P2 |
| D-14 | `FKCellIconValueDisclosureCell` | P0 |
| D-15 | `FKCellRegulatoryCell` | P2 |
| D-16 | `FKCellKeyValueCell`（`valueEmphasis: .primary`） | P0 |
| **I-01** | `FKCellSwitchCell` | P0 |
| **I-02** | `FKCellIconSwitchCell` | P0 |
| **I-03** | `FKCellSelectionCell` | P0 |
| **I-04** | `FKCellValueDisclosureCell` | P0 |
| **I-05** | `FKCellPickerCell` | P1 |
| **I-06** | `FKCellReorderCell` | P2 |
| **I-07** | `FKCellValueDisclosureCell` | P0 |
| **I-08** | `FKCellCheckboxCell` | P1 |
| **I-09–I-15** | 见 §4.2.2 | P1–P2 |
| **F-01–F-20** | `FKFormCell*` 系列 | P0–P2 |

### 4.2.2 交互类映射（§3.3、§3.6）

| 样式 ID | 公开类型 | 优先级 | 实现策略 |
|---------|----------|--------|----------|
| I-01 | `FKCellSwitchCell` | P0 | Standalone |
| I-02 | `FKCellIconSwitchCell` | P0 | Standalone |
| I-03 | `FKCellSelectionCell` | P0 | Standalone |
| I-04 / I-07 | `FKCellValueDisclosureCell` | P0 | 展示+Push；表单 Push 选 X-12 复用布局 |
| I-05 | `FKCellPickerCell` | P1 | Standalone |
| I-06 | `FKCellReorderCell` | P2 | Standalone |
| X-01–X-05 | `FKFormCellTextFieldCell` + `FKFormCellLayout` | P0 | Layout 配置 |
| X-06 | `FKFormCellPhoneCell` | P0 | Standalone |
| X-07 | `FKFormCellSocialAccountCell` | P1 | Standalone |
| X-08 | `FKFormAccessory.visibilityToggle` | P0 | Accessory |
| X-09 | `FKFormAccessory.prefixText` | P1 | Accessory |
| X-10 | `FKFormSectionHeaderView` | P0 | Structure |
| X-11 | `FKFormCellPickerCell`（`.dropdown`） | P0 | Standalone |
| X-12 | `FKFormCellPickerCell`（`.navigation`） | P0 | Standalone |
| X-13 / X-14 | `FKFormCellDateCell` / `FKFormCellTimeCell` | P1 | Standalone |
| X-15 | `FKFormCellCascadePickerCell` | P2 | Standalone |
| X-16 | `FKFormCellCaptchaCell` | P1 | Standalone |
| X-17 | `FKFormCellSMSCodeCell` | P0 | Standalone + 倒计时 |
| X-18 | `FKFormCellOTPCell` | P0 | Standalone |
| X-19 | `FKFormCellMediaPickerCell` | P1 | Standalone |
| X-20 | `FKFormCellScanInputCell` | P2 | Standalone |
| X-21–X-25 | `FKFormFieldValidationPresentation` | P0 | 共享配置 |
| X-26–X-29 | `FKFormCellSearchCell` | P1 | 嵌入 `FKSearchField` |
| X-30 | `FKFormCellFilterChipsCell` | P2 | `FKChipGroup` |
| X-31–X-35 | `FKFormCellSliderCell` 等 | P2 | 嵌入 FormControls |
| X-36–X-40 | `FKFormCellCheckboxGroupCell` 等 | P1 | FormControls |
| X-41–X-48 | 联动由宿主编排；Cell 暴露 hook | P2 | 文档 + 可选 Helper |
| X-49–X-53 | `FKFormCellButtonCell` 等 | P0 | Standalone / F-09–13 |
| I-08 | `FKCellCheckboxCell` | P1 | Standalone |
| I-09 | `FKCellFavoriteCell` | P1 | Standalone |
| I-10 | `FKCellSegmentCell` | P2 | Settings 语境 |
| I-11 | `FKCellSliderCell` | P2 | Settings 语境 |
| I-12 | `FKCellEditingCell` | P2 | 配合 table editing |
| I-13 | `FKCellStepperCell` | P1 | Standalone |
| I-14 | `FKCellSelectionCell` | P2 | 同 I-03 |
| I-15 | `FKCellPreviewPickerCell` | P2 | I-05 + preview |
| X-54–X-55 | `FKFormAccessory` / `FKFormCellSplitFieldCell` | P1/P2 | Accessory / Standalone |
| X-56–X-72 | 见 §3.6.14 | P2–P3 | 多数 Standalone |
| F-14–F-20 | `FKFormCellTextFieldCell` 语义 preset | P1–P2 | Layout + Formatter |

### 4.2.3 扩展展示类映射（§3.5）

| 样式 ID | 公开 Cell 类型 | 优先级 | 备注 |
|---------|----------------|--------|------|
| D-17 | `FKCellProfileCell` | P1 | |
| D-18 | `FKCellContactCell` | P1 | 可视为 Profile 紧凑变体 |
| D-19 | `FKCellPresenceCell` | P2 | 依赖 `FKPresenceIndicator` |
| D-20 | `FKCellConversationCell` | P1 | 消息列表高频 |
| D-21 | `FKCellNotificationCell` | P1 | |
| D-22 | `FKCellRichTextCell`（`.compact`） | P2 | Compose |
| D-23 | `FKCellMediaThumbnailCell` | P1 | |
| D-24 | `FKCellAudioTrackCell` | P2 | |
| D-25 | `FKCellArticleCell` | P1 | |
| D-26 | `FKCellThumbnailStripCell` | P2 | 内嵌横向列表 |
| D-27 | `FKCellImageCardCell` | P2 | |
| D-28 | `FKCellProductCell` | P1 | 电商高频 |
| D-29 | `FKCellKeyValueCell`（stacked） | P1 | Compose |
| D-30 | `FKCellPaymentMethodCell` | P1 | |
| D-31 | `FKCellCouponCell` | P2 | |
| D-32 | `FKCellTimelineNodeCell` | P2 | 物流/步骤轴 |
| D-33 | `FKCellStatusCell` | P1 | trailing `FKStatusPill` |
| D-34 | `FKCellBadgeCell` | P1 | trailing `FKBadge` |
| D-35 | `FKCellSyncStatusCell` | P1 | |
| D-36 | `FKCellProgressCell` | P1 | |
| D-37 | `FKCellMetricCardCell` | P2 | |
| D-38 | `FKCellSparklineCell` | P3 | |
| D-39 | `FKCellCopyableValueCell` | P1 | `FKCopyChip` |
| D-40 | `FKCellIconDisclosureCell`（无 chevron） | P2 | Compose |
| D-41 | `FKCellQRDisplayCell` | P2 | 依赖 `FKQRCode` |
| D-42 | `FKCellValueDisclosureCell` | P1 | Compose |
| D-43 | `FKCellAddressCell` | P1 | |
| D-44 | `FKCellMapPreviewCell` | P2 | |
| D-45 | `FKCellFileCell` | P1 | |
| D-46 | `FKCellIconDisclosureCell` | P2 | Compose |
| D-47 | `FKCellFileProgressCell` | P2 | D-45 + D-36 |
| D-48 | `FKCellTimelineEventCell` | P2 | |
| D-49 | `FKCellActivityCell` | P2 | |
| D-50 | `FKCellStepListCell` | P2 | |
| D-51 | `FKCellEventCell` | P2 | 日历 |
| D-52 | `FKCellRatingCell` | P1 | 只读 `FKRatingControl` |
| D-53 | `FKCellReviewCell` | P2 | |
| D-54 | `FKCellTagCell` | P1 | `FKChipGroup` |
| D-55 | `FKCellFilterSummaryCell` | P2 | |
| D-56 | `FKCellInlineNoticeCell` | P1 | `FKNoticeBar` |
| D-57 | `FKCellTipCell` | P1 | |
| D-58 | `FKCellInlineEmptyCell` | P2 | `FKEmptyState` compact |
| D-59 | `FKCellMarqueeCell` | P3 | |
| D-60 | `FKCellDeviceCell` | P2 | |
| D-61 | `FKCellNetworkCell` | P2 | |
| D-62 | `FKCellValueDisclosureCell` | P2 | Compose |
| D-63 | `FKCellSubscriptionPlanCell` | P2 | |
| D-64 | `FKCellExpandableCell` | P1 | FAQ 折叠 |
| D-65 | `FKCellExpandableCell`（`.detailBody`） | P1 | 同类型 variant |
| D-66 | `FKCellSearchResultCell` | P1 | 高亮匹配 |
| D-67 | `FKCellRecentSearchCell` | P1 | |
| D-68 | `FKCellShortcutGridCell` | P2 | 宫格快捷入口 |
| D-69 | `FKCellTransactionCell` | P1 | 账单流水 |
| D-70 | `FKCellTaskCell` | P2 | 待办展示 |
| D-71 | `FKCellPollResultCell` | P2 | 投票结果条 |
| D-72 | `FKCellLeaderboardCell` | P2 | 排行榜 |
| D-73 | `FKCellPlayableMediaCell` | P1 | 播放列表 |
| D-74 | `FKCellQuoteCell` | P2 | 引用块 |
| D-75 | `FKCellMonospaceBlockCell` | P2 | 等宽数据 |
| D-76 | `FKCellLanguageCell` | P1 | Compose → I-03 |
| D-77 | `FKCellAppUpdateCell` | P2 | 版本更新 |
| D-78 | `FKCellSortFilterBarCell` | P1 | 排序筛选栏 |
| D-79 | `FKCellLoadMoreCell` | P1 | 加载更多脚 |
| D-80 | `FKCellSkeletonRowCell` | P1 | Skeleton 协作 |
| D-81 | `FKCellIndentedCell` | P2 | 树形缩进 |
| D-82 | `FKCellInlineActionsCell` | P2 | 横向操作组 |
| D-83 | `FKCellLiveBadgeCell` | P2 | LIVE 标记 |
| D-84 | `FKCellCourseProgressCell` | P2 | 课程进度 |
| D-85 | `FKCellReminderCell` | P2 | 提醒/闹钟 |
| D-86 | `FKCellNowPlayingCell` | P2 | 迷你播放 |
| D-87 | `FKCellConflictCell` | P3 | 冲突摘要 |
| D-88 | `FKCellZeroResultsCell` | P1 | 内联零结果 |
| D-89 | `FKCellEnvironmentCell` | P2 | 环境切换 |
| D-90 | `FKCellComparisonCell` | P3 | 套餐对比 |

### 4.3 组合关系（示意）

```text
FKCellKit
├── Structure/          S-01, S-02, S-03
├── Display/
│   ├── Settings/       D-01 … D-16（§3.2 设置页参考）
│   └── General/        D-17 … D-90（§3.5 业务扩展）
├── Interactive/
│   ├── Settings/         I-01 … I-15
│   ├── Form/             X-01 … X-72 / F-01 … F-20
│   └── Search/           X-26 … X-30
│   └── Mixed/            M-01 … M-06（Compose 验收）
└── Core/               共享配置、Accessory、Separator、Appearance、Compose 扩展
```

---

## 5. 与 FKListKit / 邻域模块的边界

### 5.1 FKCellKit vs FKListKit

| 维度 | FKCellKit | FKListKit |
|------|-----------|-----------|
| 职责 | Cell **视图** + 行级配置 | Diffable **VC**、快照、刷新、空态 |
| 使用方式 | 任意 Table/Collection | 继承 `FKDiffableTableViewController` |
| 预设 | 具体 `UITableViewCell` 子类 | `FKListPresetItem` 枚举 |
| 关系 | **被消费** | `FKListPresetItem` → 映射 FKCellKit Cell |

**规范：** FKListKit §16 预设 Cell 的 **布局与 Auto Layout 仅维护一份**，位于 FKCellKit；List 层做薄包装与 Item 绑定。

### 5.2 邻域依赖

| 模块 | FKCellKit 用法 |
|------|----------------|
| **FKIconView** | D-04、D-05、I-02、D-40、D-60/61 leading 图标 |
| **FKImageView** | D-05、D-14、D-23–D-27、D-28、D-44 远程图/缩略图 |
| **FKAvatar** / **FKAvatarGroup** / **FKPresenceIndicator** | D-17–D-20、D-49、D-53、F-11 |
| **FKDivider** | 行分隔、D-07/08/09/12 卡内分隔 |
| **FKTextField** / **FKCodeTextField** / **FKCountTextView** | F-01–F-04、F-12 |
| **FKFormControls** | I-01/02；F-05/06/07 |
| **FKButton** | F-09、D-11、D-12 CTA |
| **FKProgressBar** | D-13、D-36、D-47 |
| **FKStatusPill** | D-33 |
| **FKBadge** | D-20、D-34、D-63 |
| **FKChip** / **FKChipGroup** | D-54、D-55 |
| **FKCopyChip** | D-39 |
| **FKRatingControl** | D-52（只读模式） |
| **FKNoticeBar** / **FKBanner** | D-56 行内通知 |
| **FKEmptyState** | D-58 紧凑空占位 |
| **FKMarqueeLabel** | D-59 |
| **FKQRCode** | D-41 |
| **FKSearchBar** / **FKSearchField** | X-26–X-29 行内搜索 Cell 嵌入 |
| **Pluggable `FKCellReusable`** | 所有 Cell 注册/出队契约 |
| **FKBiometricAuth**（若可用） | X-60 生物识别门控 |
| **FKAnchoredDropdownController** | X-45 自动补全 overlay 集成 |

### 5.5 FKCoreKit / FKUIKit 检索清单（实现前必读）

实现者 **必须**在写代码前 grep / 浏览下列路径；缺失能力按 §2.4.2 **上提**，而非 Cell 内私有实现：

```text
Sources/FKCoreKit/Components/Extension/     # UIKit/Foundation 便捷 API
Sources/FKCoreKit/Components/Utils/
Sources/FKCoreKit/Components/Pluggable/
Sources/FKUIKit/Components/TextField/
Sources/FKUIKit/Components/FormControls/      # 路线图组件；过渡期对照 ActionSheet
Sources/FKUIKit/Components/Divider/
Sources/FKUIKit/Components/Button/
Sources/FKUIKit/Components/ImageView/
Sources/FKUIKit/Components/SearchBar/
Sources/FKUIKit/Components/Widgets/           # Avatar, IconView, Badge, Chip…
```

**CellKit Internal 仅允许：** Cell 专用布局组合、Accessory 宿主、Grouped 背景 — **不得**复制上述目录已有逻辑。

### 5.6 子组件上提与 CellKit Internal 边界

| 落点 | 条件 |
|------|------|
| **CellKit `Internal/`** | 仅 CellKit 使用；纯布局/宿主；无独立产品语义 |
| **FKUIKit 新 Widget** | 其他模块也会用（如通用 PhoneNumber 输入条） |
| **FKCoreKit Extension** | 纯 Foundation/UIKit 无 UI 品牌 |

新增 Internal 类型 **必须**在 CellKit README 目录表注明；若后续被 2+ 模块引用，**应**开 issue 上提。

### 5.3 与 FKSearchBar 的边界

| 场景 | 选用 |
|------|------|
| `navigationItem.titleView`、页面顶搜索 | **`FKSearchBar`** |
| 列表 Section 内嵌搜索行 | **`FKFormCellSearchCell`**（包装 `FKSearchField`） |
| 60+ 搜索 UI 变体（R-03 行内搜索） | **`FKSearchField` + `FKFormSearchCellStyle`** 枚举；**不**在 CellKit 复制 |

### 5.4 非重复项

- **ActionSheet 内部 Cell**（`FKActionSheetToggleCell` 等）保持私有；若需统一视觉，v2 再评估是否迁到 FKCellKit 并 deprecate 副本。
- **FKSkeletonTableViewCell** 不变；CellKit 可提供 `showsSkeleton` 配置钩子与 Skeleton 模块协作。

---

## 6. 共享基础设施

### 6.1 FKCellAppearanceConfiguration

全局默认字阶、色板、间距、圆角 — 类似 `FKListAppearanceConfiguration`，但 **Cell 层独立**，便于非 List 场景复用。

```swift
public struct FKCellAppearanceConfiguration: Sendable, Equatable {
  public var titleTextStyle: FKCellTextStyle
  public var subtitleTextStyle: FKCellTextStyle
  public var detailTextStyle: FKCellTextStyle
  public var linkColor: UIColor
  public var destructiveColor: UIColor
  public var secondaryLabelColor: UIColor
  public var groupedBackgroundColor: UIColor
  public var cellBackgroundColor: UIColor
  public var cornerRadius: CGFloat          // default 10–12
  public var horizontalMargin: CGFloat      // inset grouped 外边距
  public var contentInsets: UIEdgeInsets    // cell 内边距，default 16h
  public var minimumRowHeight: CGFloat      // 44
}
```

### 6.2 FKCellAccessory

统一 trailing/leading 附件枚举：

```swift
public enum FKCellAccessory: Sendable, Equatable {
  case none
  case disclosureIndicator
  case checkmark(isSelected: Bool)
  case switchControl(isOn: Bool)
  case value(String)
  case statusPill(FKStatusPillConfiguration)   // D-33
  case badge(FKBadgeConfiguration)             // D-34, D-20
  case copy(FKCopyChipConfiguration)           // D-39
  case custom(id: String)
}
```

### 6.3 FKCellSeparatorPolicy

| 策略 | 行为 | 适用 |
|------|------|------|
| `.automatic` | 非末行显示；inset 随 leading 内容 | 大多数 |
| `.insetFromLeadingContent` | 分隔线起点 = 标题 leading | D-04、D-14 |
| `.fullWidth` | 卡内全宽（D-07/08/09/12） | 富文本/Feature 卡 |
| `.none` | 无分隔 | Hero、单格 Action |

实现 **必须**使用 `FKDivider` list preset，禁止硬编码 1px 视图散落。

### 6.4 FKCellSectionHeaderView / FKCellSectionFooterView

**S-01 Header：**

- 字体：footnote / caption，secondary 色
- 支持 `.automaticUppercase` 与 `.preserved` 原文
- 可选 `accessibilityTraits: .header`

**S-02 Footer：**

- 多行 `UILabel`；链接范围用 `FKCellLinkRange` + 点击回调
- 与卡片左边缘对齐（非屏幕边距）

### 6.5 FKCellGroupConfiguration

描述 **Inset Grouped** 下单个 Section 卡片外观：

- `cornerRadius`、`backgroundColor`
- `positionInSection`: `.single` | `.first` | `.middle` | `.last` — 驱动圆角遮罩与分隔
- Table：通过 `UITableView` section 背景配置或 Cell 背景合并实现
- Collection：配合 `FKListCollectionLayoutPreset.insetGroupedList` 或独立 compositional section

### 6.6 FKCellUnreadPresentation（共享）

消息、通知、会话类 Cell（D-20、D-21）共享未读 presentation，避免各 Cell 重复实现：

```swift
public struct FKCellUnreadPresentation: Sendable, Equatable {
  public var isUnread: Bool
  public var usesBoldTitle: Bool          // default true when unread
  public var showsBadge: Bool
  public var badgeCount: Int
  public var backgroundTint: UIColor?     // subtle highlight
}
```

### 6.7 FKFormCellLayout（布局枚举）

**所有**文本类 Form Cell 共用的视觉布局；对应 §3.6.2 `X-01`–`X-05`：

```swift
public enum FKFormCellLayout: Sendable, Equatable {
  case underline              // X-01 Material 顶 Label + 底边线
  case cardStacked            // X-02 卡片内 Label 上、输入下
  case cardInline             // X-03 卡片单行
  case inlineLabel            // X-04 左 Label 右输入
  case iconUnderline          // X-05 左 Icon + 底边线
  case groupedInset           // iOS Inset Grouped 表单（白卡片内 X-04）
}
```

每种 layout **必须**支持：`normal` / `focused` / `disabled` / `error` / `success`（X-22、X-23）底线或边框色。

### 6.8 FKFormAccessory（Leading / Trailing 槽位）

统一表单 Cell 左右附件，避免 X-08、X-16–X-20 各写一套：

```swift
public enum FKFormLeadingAccessory: Sendable, Equatable {
  case none
  case icon(FKIconViewConfiguration)
  case countryPicker(FKFormCountryPickerConfiguration)   // X-06 左半
  case platformPicker(FKFormPlatformPickerConfiguration) // X-07 左半
  case prefixText(String)                                // X-09
}

public enum FKFormTrailingAccessory: Sendable, Equatable {
  case none
  case visibilityToggle                                    // X-08
  case chevronDown                                         // X-11
  case chevronForward                                      // X-12
  case calendar                                            // X-13
  case clock                                               // X-14
  case captchaImage(url: URL?)                             // X-16
  case smsCodeButton(FKFormSMSCodeButtonConfiguration)     // X-17
  case scan                                                // X-20
  case clearButton
  case custom(id: String)
}
```

**Hit testing：** Trailing 按钮（SMS、Scan、Copy）**独立**于 row selection；`selectionStyle = .none` 于纯输入行。

### 6.9 FKFormFieldValidationPresentation（X-21–X-25）

```swift
public struct FKFormFieldValidationPresentation: Sendable, Equatable {
  public var isRequired: Bool
  public var helperText: String?
  public var errorText: String?
  public var successText: String?
  public var showsRequiredIndicator: Bool     // red *
  public var passwordStrength: FKPasswordStrength?  // X-25 optional
}

public enum FKFormFieldFocusState: Sendable, Equatable {
  case unfocused
  case focused
  case disabled
}
```

错误/成功文案位于 **底线下方**（X-01）或 **卡片下方**（X-02）；Dynamic Type 下撑高 Cell。

### 6.10 FKFormCellLinkage（X-41、X-42）

Cell 级 **不**实现业务联动；暴露供宿主或 `FKTextFieldLinkageCoordinator` 使用的标识：

```swift
public struct FKFormCellLinkageID: Hashable, Sendable {
  public let rawValue: String
}

// 例：password + confirmPassword 共用 validation group
public var linkageID: FKFormCellLinkageID?
public var linkageRole: FKFormCellLinkageRole?  // .password, .confirmPassword, ...
```

---

## 7. 展示类 Cell 规格

以下每类 **必须**：独立 `Configuration` + `Row`/`Content` 模型、`apply(_:)`、`prepareForReuse` 清理异步状态、遵循 `FKCellReusable`（或 List Pluggable 别名）。

### 7.1 FKCellDisclosureCell（D-01）

| 字段 | 说明 |
|------|------|
| `title` | 主标题，单行优先，支持多行 |
| `isEnabled` | 禁用时灰显 |
| `accessory` | 固定 disclosure |

布局：标题 leading 16；chevron trailing；垂直居中；最小高 44pt。

### 7.2 FKCellKeyValueCell（D-02, D-16）

| 字段 | 说明 |
|------|------|
| `title` | 左标签 |
| `value` | 右值 |
| `valueEmphasis` | `.secondary`（灰）\| `.primary`（黑，D-16） |
| `isSelectable` | 默认 false |

布局：左右撑开；值 `numberOfLines` 可配置；长值压缩标题（horizontal hugging）。

### 7.3 FKCellValueDisclosureCell（D-03, I-04, I-07）

在 KeyValue 基础上增加 chevron；detail 与 chevron 间距固定（≈6pt）。detail 过长时 trailing 截断。

### 7.4 FKCellIconDisclosureCell（D-04）

| 字段 | 说明 |
|------|------|
| `icon` | `FKIconViewConfiguration` 或 App 图标 `UIImage` |
| `title` | 单行标题 |
| `showsDisclosure` | 默认 true |

分隔：**inset 从标题 leading 开始**，不穿过 icon 列。Icon 列宽固定（28–32pt）。

### 7.5 FKCellInfoCell（D-05）

| 字段 | 说明 |
|------|------|
| `icon` | 大图标（≈60pt 圆角，App Store 风格） |
| `title` | Bold |
| `subtitles` | `[String]` 1–2 行 secondary |
| `accessory` | 通常 none |

行高：自适应；icon 与 text stack 间距 ≈12–16pt。

### 7.6 FKCellHeroCell（D-06）

| 字段 | 说明 |
|------|------|
| `icon` | 居中，较大（≈64pt 灰底圆角） |
| `title` | 居中 bold |
| `description` | 居中多行 body |
| `textAlignment` | 默认 center |

通常独占一个 section；无 trailing accessory。

### 7.7 FKCellRichTextCell（D-07）

| 字段 | 说明 |
|------|------|
| `title` | Bold headline |
| `body` | 多行正文；可选 `NSAttributedString` |
| `footerAction` | 可选 `FKCellActionLink`（「Learn More」） |
| `separatorBeforeFooter` | 默认 true |

卡内 `fullWidth` 分隔；footer 蓝色可点。

### 7.8 FKCellStatusDetailCell（D-08）

扩展 RichText：`statusText` + `statusColor`（如红色错误）；leading 可选 OS 更新 icon；body 可含链接 URL。

### 7.9 FKCellAlertActionCell（D-09）

| 字段 | 说明 |
|------|------|
| `title` | Bold |
| `warningIcon` | 可选 SF Symbol trailing |
| `body` | 多行 |
| `primaryAction` | 蓝色行动标题 + handler |

标题行：title leading，warning trailing；body 在上/下布局可配置（默认 title 上）。

### 7.10 FKCellLinkCell（D-10）

左对齐蓝色单行；无 chevron；highlight 态。用于组内「Add Language…」类。

### 7.11 FKCellActionCell（D-11）

| 字段 | 说明 |
|------|------|
| `title` | 行动文案 |
| `style` | `.default`（蓝）\| `.destructive`（红） |
| `alignment` | `.leading`（Transfer 组内）\| `.center`（Shut Down） |

### 7.12 FKCellFeatureCardCell（D-12）

Hero + 分隔 + 居中/leading CTA；与 D-06 + Action 组合，但 **单一 Cell** 便于单卡 section。

### 7.13 FKCellStorageSummaryCell（D-13）

| 字段 | 说明 |
|------|------|
| `title` | 如「iPhone」 |
| `usageText` | 「118.17 GB of 128 GB used」 |
| `segments` | `[FKCellStorageSegment]` 名称+颜色+比例 |
| `progress` | 0...1 或分段数组 |

独立圆角卡片；内部自定义 `FKCellStorageProgressView`（可复用 FKProgressBar 若语义匹配）。

### 7.14 FKCellIconValueDisclosureCell（D-14）

| 字段 | 说明 |
|------|------|
| `icon` | App 图标 |
| `title` / `subtitle` | 双行 optional |
| `value` | 右对齐灰字 |
| `showsDisclosure` | 默认 true |

### 7.15 FKCellRegulatoryCell（D-15）

| 字段 | 说明 |
|------|------|
| `regionTitle` | 左列固定宽 |
| `contentBlocks` | 右列：`text` / `image` / `spacer` 块数组 |
| `footerMetadata` | 可选地址、日期 |

P2；布局用嵌套 stack；支持 Dynamic Type 多行。

### 7.16 扩展展示类 Cell 规格（§3.5）

以下补充 **§3.2 设置页参考之外** 的高频业务行型。标注 **Compose** 的优先通过 §3.5.12 组合实现；仅 **Standalone** 在此给出独立规格。

#### 7.16.1 FKCellProfileCell（D-17）

| 字段 | 说明 |
|------|------|
| `avatar` | `FKAvatarConfiguration` |
| `title` | 昵称/姓名 |
| `subtitle` | 账号、邮箱或简介 |
| `accessory` | `.disclosure` \| `.text("Edit")` \| none |
| `layout` | `.horizontal`（默认）\| `.centered`（小型卡片） |

行高自适应；头像默认 56–64pt。

#### 7.16.2 FKCellConversationCell（D-20）

| 字段 | 说明 |
|------|------|
| `avatar` | 单聊头像或群聊 `FKAvatarGroup` |
| `title` | 会话名 |
| `preview` | 最后消息预览；支持 `[草稿]`、`[图片]` 前缀 |
| `timestamp` | 右上相对时间 |
| `unreadCount` | 0 隐藏；>0 显示 `FKBadge` 或圆点 |
| `isPinned` / `isMuted` | 可选 leading 标识 |

#### 7.16.3 FKCellNotificationCell（D-21）

| 字段 | 说明 |
|------|------|
| `icon` | 类别色底 Symbol 或 App Icon |
| `title` | 通知标题 |
| `body` | 1–2 行摘要 |
| `timestamp` | trailing 或 subtitle 行 |
| `isRead` | 未读加粗标题 / 背景 subtle highlight |

#### 7.16.4 FKCellMediaThumbnailCell（D-23）

| 字段 | 说明 |
|------|------|
| `thumbnail` | 本地/远程；固定 56×56 或 16:9 小图 |
| `title` / `subtitle` | |
| `durationBadge` | 可选右下角时长 |
| `accessory` | chevron 或 none |

`prepareForReuse` 取消 `FKImageView` 请求。

#### 7.16.5 FKCellProductCell（D-28）

| 字段 | 说明 |
|------|------|
| `image` | 商品图 |
| `title` | 商品名，最多 2 行 |
| `specText` | SKU、规格、属性 |
| `price` | 现价；可选划线价 |
| `quantity` | 「×2」或 trailing stepper **仅展示**数量 |

#### 7.16.6 FKCellPaymentMethodCell（D-30）

| 字段 | 说明 |
|------|------|
| `brandIcon` | Visa/Master/Apple Pay 等 |
| `maskedNumber` | 「•••• 4242」 |
| `expiry` | optional |
| `badges` | 「默认」`FKStatusPill` |
| `showsDisclosure` | 管理支付方式时为 true |

#### 7.16.7 FKCellStatusCell / FKCellBadgeCell（D-33, D-34）

基于 `FKCellDisclosureCell` 或 `FKCellKeyValueCell` 的 **trailing 槽位**扩展：

```swift
public enum FKCellTrailingContent: Sendable, Equatable {
  case none
  case disclosure
  case value(String)
  case statusPill(FKStatusPillConfiguration)
  case badge(FKBadgeConfiguration)
  case custom(id: String)
}
```

避免为每种 trailing 新建 Cell 类。

#### 7.16.8 FKCellProgressCell / FKCellSyncStatusCell（D-35, D-36）

**Progress：** leading icon + 标题 + `FKProgressBar` + optional 百分比。  
**Sync：** 标题 + 状态文案 + trailing `UIActivityIndicatorView` / 静态 icon（success/failure）。

#### 7.16.9 FKCellCopyableValueCell（D-39）

| 字段 | 说明 |
|------|------|
| `label` | 左标签 |
| `value` | 可复制文本；长串 monospace 可选 |
| `copyControl` | `FKCopyChip` 或 icon button |
| `onCopied` | 复制成功回调（供 Toast） |

点击复制 **不**触发 row selection；VoiceOver 提供「Copy」action。

#### 7.16.10 FKCellFileCell / FKCellFileProgressCell（D-45, D-47）

| 字段 | 说明 |
|------|------|
| `fileType` | pdf/doc/image/video… 映射 SF Symbol 或 asset |
| `fileName` | |
| `meta` | 大小 · 修改日期 |
| `cloudState` | 仅本地 / 已同步 / 上传中（与 D-36 合并为 FileProgress） |

#### 7.16.11 FKCellAddressCell（D-43）

多行地址 + 可选联系人/电话；支持「默认地址」`FKStatusPill`；trailing chevron 进入编辑。

#### 7.16.12 FKCellExpandableCell（D-64, D-65）

| 字段 | 说明 |
|------|------|
| `title` | 折叠标题 |
| `body` | 展开正文；折叠时高度 0 |
| `isExpanded` | 驱动 chevron 方向与 body 可见性 |
| `animation` | 宿主 table 更新行高或 cell 内 animated layout |

**注意：** 展开时推荐配合 `UITableView.performBatchUpdates`；Cell 暴露 `preferredHeight` 辅助。

#### 7.16.13 FKCellSearchResultCell / FKCellRecentSearchCell（D-66, D-67）

**SearchResult：** `attributedTitle` / `attributedSubtitle` 高亮 `query` 范围；optional leading icon。  
**RecentSearch：** 时钟 icon + 查询词 + trailing 删除按钮（独立 hit area，不触发 row select）。

#### 7.16.14 FKCellRatingCell / FKCellTagCell（D-52, D-54）

**Rating：** 只读 `FKRatingControl` + 数值 + 「(128)」评论数。  
**Tag：** optional 左标题 + 换行友好的 `FKChipGroup`（横向 scroll 或 wrap，配置切换）。

#### 7.16.15 FKCellInlineNoticeCell / FKCellTipCell（D-56, D-57）

**Notice：** 行内嵌入 `FKNoticeBar` 或 slim banner；可选关闭按钮。  
**Tip：** leading info glyph + footnote 色多行说明；无 chevron。

#### 7.16.16 其他 Standalone 类型（摘要）

| 类型 | ID | 要点 |
|------|-----|------|
| `FKCellContactCell` | D-18 | Profile 紧凑版：40pt avatar + 双行 |
| `FKCellPresenceCell` | D-19 | Avatar + presence + status text |
| `FKCellArticleCell` | D-25 | 左图右文或右图左文；三行标题 |
| `FKCellThumbnailStripCell` | D-26 | 固定行高 + 内嵌 horizontal collection |
| `FKCellImageCardCell` | D-27 | 全宽 16:9 图 + 渐变叠字 |
| `FKCellAudioTrackCell` | D-24 | 封面 48pt + 曲名/艺人 + 时长 |
| `FKCellCouponCell` | D-31 | 左色条 + 面额 + 规则 |
| `FKCellTimelineNodeCell` | D-32 | 竖轴 + 节点状态 |
| `FKCellTimelineEventCell` | D-48 | 左时间列 + 右内容 |
| `FKCellActivityCell` | D-49 | 动态文案 + 引用块 |
| `FKCellStepListCell` | D-50 | 序号/完成态 + 步骤说明 |
| `FKCellEventCell` | D-51 | 日历 date block + 事件信息 |
| `FKCellMetricCardCell` | D-37 | 指标卡；可独占 section |
| `FKCellMapPreviewCell` | D-44 | 56pt 地图快照 + 距离 |
| `FKCellReviewCell` | D-53 | 用户 + 星 + 摘要 |
| `FKCellFilterSummaryCell` | D-55 | Chips + 清除 |
| `FKCellInlineEmptyCell` | D-58 | 紧凑空态 |
| `FKCellDeviceCell` / `FKCellNetworkCell` | D-60/61 | 连接态 + 信号 graphic |
| `FKCellSubscriptionPlanCell` | D-63 | 档位卡 + 权益 bullet |
| `FKCellQRDisplayCell` | D-41 | 居中 QR + caption |

#### 7.17 补充展示类 Cell 规格（§3.5.13，D-68–D-90）

| 类型 | ID | 要点 |
|------|-----|------|
| `FKCellShortcutGridCell` | D-68 | 3–5 列等分；Icon 24–32pt + caption2 标题 |
| `FKCellTransactionCell` | D-69 | 金额 `.credit` 绿 / `.debit` 红；右对齐 tabular nums |
| `FKCellTaskCell` | D-70 | 完成态 strikethrough；逾期日期 secondary→destructive |
| `FKCellPollResultCell` | D-71 | 比例条 `FKProgressBar` + 百分比；不可点 |
| `FKCellLeaderboardCell` | D-72 | 名次 1–3 可选 medal tint |
| `FKCellPlayableMediaCell` | D-73 | 封面 48pt + 居中 play 28pt；Now Playing 高亮 |
| `FKCellQuoteCell` | D-74 | leading 3pt accent bar + body italic optional |
| `FKCellMonospaceBlockCell` | D-75 | `UIFont.monospaced`；最大行数 + Expand |
| `FKCellSortFilterBarCell` | D-78 | 非 scroll 区；Sort/Filter 独立 button hit area |
| `FKCellLoadMoreCell` | D-79 | `UIActivityIndicator` + 文案；触发 load more |
| `FKCellSkeletonRowCell` | D-80 | 复用 `FKSkeleton` line preset；与 List 首载协作 |
| `FKCellIndentedCell` | D-81 | `indentLevel × 16pt`；用于评论树 |
| `FKCellInlineActionsCell` | D-82 | 等宽 text button；destructive 最右 |
| `FKCellNowPlayingCell` | D-86 | 与 D-73 共享封面；trailing play/pause |
| `FKCellZeroResultsCell` | D-88 | 紧凑空态；可配置 illustration |
| `FKCellEnvironmentCell` | D-89 | 环境色点 8pt；prod/staging/dev token |

其余 D-76、D-77、D-83–D-85、D-87、D-90 见 §3.5.13 表格；优先 Compose。

---

## 8. 交互类 Cell 规格

交互类 Cell 分 **四类**，规格必须完整、可独立 dequeue：

| 类别 | ID 范围 | § |
|------|---------|---|
| 设置/列表行内控件 | I-01–I-15 | §8.1 |
| 表单布局与 Accessory | X-01–X-72 | §8.2–§8.9 |
| 语义字段（绑定控件） | F-01–F-20 | §9 |
| 跨类混合（Compose） | M-01–M-06 | §3.6.16 |

**通用要求（全部交互 Cell）：**

- `selectionStyle`：纯输入行 `.none`；Push 选择行 `.default`
- 键盘：遵守 `FKTextField`/`FKSearchField` first responder 链；Cell 不拦截 field 以外的 touch 除非 Accessory
- `prepareForReuse`：取消倒计时、Captcha 请求、Scan 回调
- 回调不放入 `Equatable` Row；用 `FKFormCellDelegate` 或 typed closure 属性

### 8.1 设置行内控件（I-01–I-07）

#### 8.1.1 FKCellSwitchCell（I-01）

| 字段 | 说明 |
|------|------|
| `title` | 可多行 |
| `isOn` | 绑定开关 |
| `isEnabled` | |
| `onValueChanged` | `(Bool) -> Void`，Cell 外注册 |

**必须**使用 `FKToggle`（FKFormControls 就绪后）；过渡期允许 styled `UISwitch`，API 不变。  
`selectionStyle = .none`；VoiceOver：switch trait + value。

#### 8.1.2 FKCellIconSwitchCell（I-02）

Icon + title + optional subtitle + switch；分隔 inset 从标题 leading。

#### 8.1.3 FKCellSelectionCell（I-03）

| 字段 | 说明 |
|------|------|
| `title` / `subtitle` | |
| `isSelected` | 显示蓝色 checkmark |
| `selectionMode` | `.single` \| `.multiple` |
| `leadingCheckmarkSlot` | 未选保留空白，保证文字对齐 |

#### 8.1.4 FKCellValueDisclosureCell / FKCellPickerCell（I-04、I-05、I-07）

设置语境下的 Push/Picker 行 — 布局见 §7.3；交互为 `onTap` → Push 或弹出 Picker。  
**与 X-11/X-12 区别：** I-* 用于 **设置 Inset Grouped**；X-* 用于 **表单**（左 Label、必填、校验）。

#### 8.1.5 FKCellReorderCell（I-06）

双行 + Reorder 把手；v1 不实现数据重排。

#### 8.1.6 FKCellCheckboxCell（I-08）

| 字段 | 说明 |
|------|------|
| `title` / `subtitle` | |
| `isChecked` | `FKCheckbox` 或系统 checkbox 样式 |
| `placement` | `.leading` \| `.trailing` |

`selectionStyle = .none`；点击 checkbox 或整行（可配置）切换。

#### 8.1.7 FKCellFavoriteCell（I-09）

trailing 星形按钮；`isFavorite` 驱动 fill；tap 回调；**不**用 Switch。

#### 8.1.8 FKCellSegmentCell / FKCellSliderCell / FKCellStepperCell（I-10、I-11、I-13）

- **Segment：** 整行仅 `FKSegmentedControl`；高度 ≈44–52pt
- **Slider：** 标题 + `FKSlider`；Settings 卡片内；optional 数值 label
- **Stepper：** 标题 + `UIStepper`；`value` + min/max 约束

#### 8.1.9 FKCellPreviewPickerCell（I-15）

同 I-05 + trailing 28–40pt 预览（铃声波形、壁纸缩略图）。

---

### 8.2 文本输入 Cell（X-01–X-05 + F-01/F-02）

#### 8.2.1 FKFormCellTextFieldCell

**核心类型** — 通过 `FKFormCellLayout` + `FKFormAccessory` 覆盖 §3.6.2 多种布局 archetype。

```swift
public struct FKFormCellTextFieldConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout
  public var label: String?
  public var placeholder: String?
  public var textFieldConfiguration: FKTextFieldConfiguration
  public var leadingAccessory: FKFormLeadingAccessory
  public var trailingAccessory: FKFormTrailingAccessory
  public var validation: FKFormFieldValidationPresentation
  public var linkageID: FKFormCellLinkageID?
}
```

| Layout | 最小高度 | 分隔 | Label 位置 |
|--------|----------|------|------------|
| `.underline` | 56–72pt | 底边线 1–2pt | 顶部 footnote |
| `.cardStacked` | 64–80pt | 卡片 fill | 卡片内顶部 |
| `.cardInline` | 48–52pt | 卡片 fill | 无或 placeholder |
| `.inlineLabel` | 48–52pt | 行底 hairline | 左列固定宽 ≈28–35% |
| `.iconUnderline` | 52–56pt | 底边线 | 无单独 label 或 icon 替代 |

**Focused（X-01/X-05）：** 底线加粗/变色；与 `FKTextField` focus 同步。  
**Error（X-22）：** 底线红色 + `validation.errorText`。  
**Success（X-23）：** 底线绿色 optional。

#### 8.2.2 FKFormCellSecureFieldCell（F-02 + X-08）

`FKFormCellTextFieldCell` + `trailingAccessory: .visibilityToggle`；secure `FKTextField`；toggle 不提交表单。

#### 8.2.3 FKFormCellMultilineCell（F-04）

`FKCountTextView` + layout `.cardStacked` 或 `.underline`；最小/最大高度可配置；行数增长时通知 table `beginUpdates/endUpdates`。

---

### 8.3 复合与分栏输入（X-06、X-07、F-12）

#### 8.3.1 FKFormCellPhoneCell（X-06、F-12）

| 区域 | 内容 | 交互 |
|------|------|------|
| Leading（≈30–40%） | 国旗 + 区号 + ▼ | `onCountryTap` → 国家列表 |
| Divider | 竖线 1px | — |
| Trailing | 号码 `FKTextField` | 数字键盘 |

支持 layout：`.underline`（R-01）、`.cardSplit`（R-04 双卡片手机行）、`.groupedInset`。

#### 8.3.2 FKFormCellSocialAccountCell（X-07）

| 区域 | 内容 | 交互 |
|------|------|------|
| Leading | 品牌 Icon + 平台名 + ▼ | 切换平台（Skype/FB/…） |
| Trailing | `@username` field | 文本；focus 时 **仅右区** 底线高亮（R-05 平台行） |

---

### 8.4 选择与日期（X-11–X-15、F-08）

#### 8.4.1 FKFormCellPickerCell

```swift
public enum FKFormPickerPresentation: Sendable, Equatable {
  case dropdown      // X-11 Chevron Down → ActionSheet / Picker
  case navigation    // X-12 Chevron Forward → Push
}
```

| 字段 | 说明 |
|------|------|
| `label` | 左或上 |
| `placeholder` | 未选时灰字 |
| `value` | 当前选中 |
| `isEnabled` | |
| `presentation` | dropdown / navigation |
| `onTap` | 宿主弹出 UI |

Layout：`.inlineLabel`（R-07）、`.cardStacked`（R-04 Account Type 行）。

#### 8.4.2 FKFormCellDateCell / FKFormCellTimeCell（X-13、X-14）

| Layout 变体 | 描述 |
|-------------|------|
| `.cardInline` | R-02：白卡片 + 日期 + 右 Calendar Icon |
| `.inlineLabel` | 左 Label + 值 + Icon |
| `.underline` | Label 上 + 值 + Icon + 底线 |

`UIDatePicker` 使用 `.compact` 或 popover；Icon 与整行 tap 均触发。

#### 8.4.3 FKFormCellCascadePickerCell（X-15）

只读展示「省 / 市 / 区」组合值；tap → 多级 Picker；P2。

---

### 8.5 验证码、OTP 与媒体（X-16–X-20、F-03、F-11）

#### 8.5.1 FKFormCellCaptchaCell（X-16）

- Leading/middle：`FKTextField`
- Trailing：Captcha `UIImage` / `FKImageView`（≈80×32pt）
- `onCaptchaRefresh`：点击图片换图
- 与 X-17 可组合为同一注册 Section

#### 8.5.2 FKFormCellSMSCodeCell（X-17）

| 字段 | 说明 |
|------|------|
| `label` | 「短信码」 |
| `textField` | 数字 limited length |
| `sendButtonTitle` | 「获取验证码」 |
| `countdownSeconds` | 60；发送后按钮 **倒计时** 禁用 |
| `onSendSMS` | async；成功启动 countdown |

**必须**在 `prepareForReuse` invalidate Timer。

#### 8.5.3 FKFormCellOTPCell（X-18、F-03）

整行嵌入 `FKCodeTextField`；slot 数可配置； linkage 自动跳格。

#### 8.5.4 FKFormCellMediaPickerCell（X-19、F-11）

| 变体 | 布局 |
|------|------|
| `.avatar` | 左 `FKAvatar` + 右「Change Photo」 |
| `.thumbnail` | 左缩略图 + 文件名 + Chevron |
| `.file` | Icon + 标题 + 大小 |

`onPick` / `onRemove` 回调；相册用系统 Picker。

#### 8.5.5 FKFormCellScanInputCell（X-20）

Text field + trailing Scan Icon；扫描结果 **回填** field；P2。

---

### 8.6 搜索与筛选（X-26–X-30）

#### 8.6.1 FKFormCellSearchCell

嵌入 **`FKSearchField`**（非重新实现搜索 UI）：

```swift
public enum FKFormSearchCellStyle: Sendable, Equatable {
  case capsule                    // X-26
  case roundedWithButton          // X-27
  case prefixCategory             // X-28
  case withVoiceIcon              // X-29
}
```

| 要求 | 说明 |
|------|------|
| 行高 | 44–52pt + vertical padding |
| 背景 | 与列表 grouped/plain 协调 |
| 回调 | `onTextChange`、`onSubmit`、`onClear` 转发 SearchField |

#### 8.6.2 FKFormCellFilterChipsCell（X-30）

横向 scroll `FKChipGroup`；单选/多选；`onSelectionChange`；常用于列表顶 Section。

---

### 8.7 数值、Toggle 组与提交（X-31–X-53）

#### 8.7.1 嵌入 FormControls 的行

| Cell | ID | 嵌入 |
|------|-----|------|
| `FKFormCellSliderCell` | X-31、X-35 | `FKSlider` |
| `FKFormCellStepperCell` | X-32、X-33 | Stepper / ± 按钮 |
| `FKFormCellRatingInputCell` | X-34 | 可编辑 `FKRatingControl` |
| `FKFormCellCheckboxGroupCell` | X-36 | 多 `FKCheckbox` |
| `FKFormCellRadioGroupCell` | X-37、F-06 | `FKRadioGroup` |
| `FKFormCellSegmentCell` | X-38、F-07 | `FKSegmentedControl` |
| `FKFormCellSwitchCaptionCell` | X-39 | 标题+副标题+Switch |
| `FKFormCellTagInputCell` | X-40 | `FKChipGroup` + 添加 |

#### 8.7.2 FKFormSectionHeaderView（X-10）

| 字段 | 说明 |
|------|------|
| `title` | Bold |
| `subtitle` | secondary 说明 |

用于表单 Section 顶；**非** UITableView 默认 section header API 的替代，而是 **首行 Cell** 或 supplementary view 皆可配置。

#### 8.7.3 提交与协议（X-49–X-53、F-05、F-09、F-10、F-13）

| Cell | 说明 |
|------|------|
| `FKFormCellPrimaryButtonCell` | 满宽 `FKButton`；loading/disabled |
| `FKFormCellDualButtonCell` | 双 CTA 水平或垂直 |
| `FKFormCellLinkButtonCell` | 文字链 |
| `FKFormCellAgreementCell` | Checkbox + 富文本协议链接 |
| `FKFormCellSocialAuthCell` | 第三方 Icon 按钮行 |

---

### 8.8 联动与动态表单（X-41–X-48）

CellKit **v1 不**内置表单状态机；**必须**文档化推荐模式：

1. **条件显隐（X-41）：** Diffable snapshot 增删 `FKForm*Row`；Switch `onValueChanged` → 宿主 `applyMutation`
2. **交叉校验（X-42）：** `FKTextFieldLinkageCoordinator` + 两个 field 的 `linkageID`
3. **自动补全（X-45）：** `FKFormCellTextFieldCell` + 宿主 overlay `UITableView` / `FKAnchoredDropdown`
4. **地图/签名（X-46、X-47）：** Push 全屏；Cell 仅展示 summary + Chevron

可选 **Phase 6** 交付 `FKFormCellConditionalVisibility` 配置 helper（仍不含网络；与 §14.10 一致）。

---

### 8.9 补充表单与特殊交互（X-54–X-72）

#### 8.9.1 FKFormCellSplitFieldCell（X-55）

单 Cell 内两 field 50/50；中缝 `FKDivider` vertical；独立 focus 底线（underline layout）。

#### 8.9.2 FKFormCellRangeCell（X-56）

「最低」「最高」双 amount field；共享 `F-15` formatter。

#### 8.9.3 FKFormCellColorCell（X-57）

`UIColorWell`（iOS 15+）+ optional hex `FKTextField`；layout `.inlineLabel`。

#### 8.9.4 FKFormCellRichTextCell（X-58）

顶部 compact toolbar（Bold/Italic/Link）；下方 `FKCountTextView`；行高随内容。

#### 8.9.5 FKFormCellBiometricCell（X-60）

非输入；`FKButton` 触发 `LAContext`；失败展示 inline error（X-22）。

#### 8.9.6 FKFormCellPINIndicatorCell（X-61）

4–6 圆点；配合隐藏 numpad 或 `FKCodeTextField` secure slots；**不**明文显示 PIN。

#### 8.9.7 FKFormCellMediaGridCell（X-63）

3 列 flow；`maxCount`；add tile + delete badge；相册 multi-select。

#### 8.9.8 FKFormCellNPSScaleCell（X-65）

0–10 等宽 button；选中态 fill；`onScoreSelected`。

#### 8.9.9 FKFormCellInlineWheelCell（X-67）

内嵌 `UIPickerView`；expanded 行高 ≈216pt；collapse 可选。

#### 8.9.10 FKFormCellCharacterCountFooter（X-69）

与 multiline 组合；`remaining = max - count`；超限 X-22。

#### 8.9.11 FKFormCellSystemPickerCell（X-70）

摘要 label + 「Choose…」；`UIImagePicker` / `CNContactPicker` 由宿主 present。

#### 8.9.12 FKFormCellMapRadiusCell（X-72）

静态 map snapshot + `FKSlider`；半径 label 实时更新。

**X-54、X-59、X-62、X-64、X-66、X-68、X-71** 见 §3.6.14；实现优先级 P2–P3。

---

## 9. 语义化表单 Cell 与布局矩阵

§3.4 **F-*** 表示字段 **语义**；实现时选用 §8 中具体 Cell + Layout。

### 9.1 F-01 单行文本

| 推荐 Layout | 场景 |
|-------------|------|
| X-01 `.underline` | Material 登录/注册 |
| X-02 `.cardStacked` | 多字段注册（R-04） |
| X-03 `.cardInline` | 简洁资料（R-02） |
| X-04 `.inlineLabel` | 企业表单（R-07） |
| X-05 `.iconUnderline` | 联系方式（R-05） |

### 9.2 F-02 密码

任意 F-01 layout + `X-08` visibility toggle；配合 `X-25` 强度指示 optional。

### 9.3 F-03 / F-12 验证码与手机

| 语义 | 实现 |
|------|------|
| F-03 OTP | `FKFormCellOTPCell`（X-18） |
| F-03 短信六位 | `FKFormCellSMSCodeCell`（X-17）或 OTP |
| F-12 手机 | `FKFormCellPhoneCell`（X-06） |

### 9.4 F-04 多行

`FKFormCellMultilineCell`；layout `.cardStacked` 为主。

### 9.5 F-05–F-07 选择控件

见 §8.7.1；layout 通常 `.groupedInset` 或独立 card section。

### 9.6 F-08 日期时间

`FKFormCellDateCell` / `FKFormCellTimeCell`（§8.4.2）。

### 9.7 F-09–F-13 行动与社交

见 §8.7.3；不占输入 layout。

### 9.8 F-14–F-20 扩展语义字段

| 语义 | 推荐 Cell | 关键 Formatter / Accessory |
|------|-----------|---------------------------|
| F-14 邮箱 | `FKFormCellTextFieldCell` | `.email` keyboard；X-54 后缀 optional |
| F-15 金额 | `FKFormCellTextFieldCell` | decimal pad；X-09；X-68 预览 optional |
| F-16 证件 | `FKFormCellTextFieldCell` | 掩码；`.inlineLabel` |
| F-17 URL | `FKFormCellTextFieldCell` | `.URL` keyboard；link preview optional |
| F-18 数量 | `FKCellStepperCell` / X-33 | integer；min/max |
| F-19 地址 | + X-45 / X-46 | autocomplete + map |
| F-20 银行卡 | `FKFormCellTextFieldCell` | 4-4-4-4 分组；Luhn 校验 |

### 9.9 完整矩阵（实现验收用）

|  | underline | cardStacked | cardInline | inlineLabel | iconUnderline |
|--|-----------|-------------|------------|-------------|---------------|
| F-01 Text | ✓ P0 | ✓ P0 | ✓ P0 | ✓ P0 | ✓ P1 |
| F-02 Password | ✓ P0 | ✓ P0 | ✓ P1 | ✓ P1 | — |
| F-04 Multiline | ✓ P1 | ✓ P0 | — | — | — |
| F-08 Date | — | ✓ P1 | ✓ P1 | ✓ P1 | — |
| X-11 Picker | ✓ P1 | ✓ P0 | ✓ P1 | ✓ P0 | — |
| X-12 Nav Pick | ✓ P1 | ✓ P1 | — | ✓ P0 | — |
| F-15 Amount | ✓ P1 | ✓ P1 | — | ✓ P1 | — |
| F-20 Card | ✓ P1 | — | — | — | — |

### 9.10 与 FKTextField 的职责分界

| 职责 | FKTextField | FKFormCell |
|------|-------------|------------|
| 格式化/校验 pipeline | ✓ | 透传 configuration |
| Label / 必填 * | — | ✓ |
| Layout / 卡片 / 底线 | — | ✓ |
| Accessory 槽位 | 部分 | ✓ 编排 |
| Error 文案位置 | 可选 | ✓ 标准位置 |
| Table 行高 / 分隔 | — | ✓ |

---

## 10. 配置、状态与回调模型

### 10.1 模式

每个 Cell：

```swift
public struct FKCellDisclosureConfiguration: Sendable, Equatable { ... }

@MainActor
public final class FKCellDisclosureCell: UITableViewCell, FKCellReusable {
  public func apply(_ configuration: FKCellDisclosureConfiguration)
  public func apply(_ row: FKCellDisclosureRow, appearance: FKCellAppearanceConfiguration)
}
```

- **Configuration** — 纯数据 + 样式 token
- **Row** — 业务字段 + `id`（供 FKListKit Hashable）
- 回调（`onTap`、`onSwitch`）**不**放入 `Equatable` Row；经 Cell 属性或 delegate 注册

### 10.2 状态

| 状态 | 支持 Cell |
|------|-----------|
| `normal` / `disabled` | 全部 |
| `highlighted` | 可点行 |
| `selected` | Selection、ValueDisclosure |
| `focused` | Form 输入行（X-01 底线） |
| `loading` | Form Submit、Avatar、SMS 发送 |
| `error` / `success` | Form 系列（X-22、X-23） |
| `countdown` | X-17 SMS 按钮 |

### 10.3 内容更新策略

- 开关/选中：**原地更新** accessory，避免整行 flash
- 远程图标 / Captcha：`FKImageView` 取消前次请求（`prepareForReuse`）
- SMS 倒计时：invalidate Timer on reuse
- 富文本链接：复用 `FKCellLinkTextView`（Internal）统一 tap 处理
- 表单校验：优先 **原地** 更新底线色与 error label，避免整表 reload

### 10.4 FKFormCellDelegate（推荐）

```swift
@MainActor
public protocol FKFormCellDelegate: AnyObject {
  func formCell(_ cell: UITableViewCell, didTap accessory: FKFormTrailingAccessory, at indexPath: IndexPath)
  func formCell(_ cell: UITableViewCell, didChange text: String, at indexPath: IndexPath)
  func formCell(_ cell: UITableViewCell, didSendSMSCodeAt indexPath: IndexPath)
  func formCell(_ cell: UITableViewCell, didPickValue: Any, at indexPath: IndexPath)
}
```

协议扩展提供默认空实现；高频场景亦支持 per-cell 闭包。

---

## 11. 布局、分隔线与 Inset Grouped 规范

### 11.1 尺寸常量（默认值，可 appearance 覆盖）

| 常量 | 值 | 备注 |
|------|-----|------|
| 最小行高 | 44pt | HIG |
| 双行行高 | 56–60pt | 含副标题 |
| 水平内边距 | 16pt | |
| Inset grouped 外边距 | 16–20pt | |
| 卡片圆角 | 10–12pt | |
| Icon 小 | 28–32pt | D-04 |
| Icon 大 | 60pt | D-05 |
| Title–Subtitle 间距 | 2–4pt | |
| Chevron 宽 | 13pt 系统 accessory | |
| Form 卡片圆角 | 8–12pt | X-02、X-03 |
| Form 底边线高 | 1pt normal / 2pt focused | X-01、X-05 |
| Inline Label 列宽比 | ≈ 0.28–0.35 leading | X-04、R-07 |
| Captcha 图宽 | ≈ 80–96pt | X-16 |
| SMS 按钮最小宽 | 88pt | X-17 倒计时 |

### 11.2 字阶（Dynamic Type）

| 角色 | Text Style |
|------|------------|
| 标题 | `body` |
| 副标题 / Detail | `subheadline` secondary |
| Section Header | `footnote` uppercase |
| Section Footer | `footnote` |
| Hero 标题 | `title2` bold |
| 行动链接 | `body` tint |

使用 `UIFontMetrics` 缩放；不硬编码 point size。

### 11.3 Dark Mode

- `groupedBackgroundColor`：`systemGroupedBackground`
- `cellBackgroundColor`：`secondarySystemGroupedBackground`
- 分隔线：`separator` / FKDivider semantic color

### 11.4 RTL

Leading/trailing 语义约束；checkmark 镜像；chevron 系统镜像。

### 11.5 Auto Layout 约束规范

本节细化 §2.4.4，为 Code Review **约束检查表**。

#### 11.5.1 标准三区模型（Display / Settings 行）

```text
contentView
└── FKCellContentStack (horizontal UIStackView)
    ├── leadingSlot   (icon / checkmark / 固定宽)
    ├── textStack     (title + subtitle vertical stack, fill)
    └── trailingSlot  (detail + accessory, hugging)
```

- `leadingSlot`：`widthAnchor` 固定或 `== 0`（hidden 时 width 0，**非** remove）。
- `textStack`：`leading` 接 leadingSlot；`trailing ≤ trailingSlot.leading - spacing`。
- `trailingSlot`：`trailing` 接 contentView layout margin；chevron **required** 水平 hugging。

#### 11.5.2 Form Field 区（Underline / Card）

```text
contentView
└── verticalStack
    ├── label (optional)
    ├── fieldRow (horizontal: prefix | field | accessory)
    ├── underline (FKDivider, height 1–2)
    └── errorLabel (optional, hidden when nil)
```

- Focus/Error **仅**更新 underline 颜色与 errorLabel `isHidden`；**不**重建 stack。
- Card layout：underline 换为 `backgroundContainer` 四边约束；field 内边距用 `layoutMargins`。

#### 11.5.3 冲突预防清单

| 场景 | 做法 |
|------|------|
| 长 detail 与 chevron | detail `lineBreakMode = byTruncatingTail`；detail compression priority < title |
| Dynamic Type 撑高 | 多行 label `numberOfLines = 0`；bottom 约束接 `contentView` |
| Hidden accessory | `isHidden = true` + width constraint constant 0 |
| 可选 subtitle | subtitle hidden 时 textStack 仍闭合；无 orphan 约束 |
| 编辑态 Switch | Switch 在 trailingSlot；**不**与 `accessoryView` 混用系统 API |

#### 11.5.4 验收

- iPhone SE + iPhone 16 Pro Max、Light/Dark、LTR + RTL、AX5 字体档 **无** constraint warning。
- `UITableView` 估算高度：`estimatedRowHeight` + 自适应；Form 固定高 Cell 文档化 height。

---

## 12. Pluggable 与复用契约

### 12.1 协议

所有公开 Cell **应当**实现：

```swift
@MainActor
public protocol FKCellConfigurable: FKCellReusable {
  associatedtype Item: Sendable
  func configure(with item: Item)
}
```

FKListKit 扩展：

```swift
extension FKCellDisclosureCell: FKListTableCellConfigurable {
  public typealias Item = FKCellDisclosureRow
}
```

### 12.2 注册便利 API

```swift
extension UITableView {
  public func fk_registerCellKitCells(_ types: FKCellRegistration...)
}
```

### 12.3 FKCoreKit 复用（强制）

| 能力 | 必须使用 | 禁止 |
|------|----------|------|
| Cell 复用 | `FKCellReusable` | 自定义 reuse 约定 |
| 分隔线 | `FKDivider` | 手写 1px |
| 图标 | `FKIconView` | 裸 `UIImageView` 尺寸不一 |
| 远程图 | `FKImageView` | Cell 内 URLSession |
| 布局 | `UIStackView` + CoreKit Extensions | 重复 layout 辅助 |

### 12.4 列表性能与视图层级

本节细化 §2.4.5。

#### 12.4.1 `prepareForReuse` 必做项

| 资源 | 动作 |
|------|------|
| `FKImageView` | 取消加载、清 placeholder |
| 文本 | 清 label / field；reset `accessibilityLabel` |
| 选中/开关 | 重置为 configure 前默认，防错态闪烁 |
| Timer（SMS 倒计时） | `invalidate()` |
| 链接 handler | 置 nil |
| 展开态 | 重置 `isExpanded` 默认 |

#### 12.4.2 Accessory 懒加载模式

```swift
// 推荐：单一 trailing host，按配置显示子视图
private lazy var disclosureView = UIImageView(image: chevronImage)
private lazy var checkmarkView = UIImageView(image: checkmarkImage)

func apply(_ configuration: FKCellDisclosureConfiguration) {
  disclosureView.isHidden = !configuration.showsDisclosure
  checkmarkView.isHidden = true
  // 不 removeFromSuperview
}
```

**禁止**在 `apply` 内 `subviews.forEach { $0.removeFromSuperview() }`。

#### 12.4.3 层级与离屏优化

- `contentView.clipsToBounds = true` 仅当圆角/分组需要；避免多余 mask。
- 不在 Cell 内启动 `CADisplayLink` 或持续动画；LIVE、倒计时等 **可见行** 才运行。
- 复杂 Cell（D-26 横滑、X-63 网格）：**降低**默认子视图数；离屏 cell 不 prefetch 内嵌 collection 数据。

#### 12.4.4 PR 性能检查表

- [ ] 典型 Cell 子视图数 ≤ §2.4.5 预算
- [ ] 无 duplicate 功能视图（两个 chevron、双 divider）
- [ ] `prepareForReuse` 覆盖异步/Timer/图片
- [ ] `apply` 主线程、无 IO
- [ ] 500 行 Demo 场景可流畅滚动（§16 Examples 可选 `StressScroll`）

---

## 13. 无障碍与 Dynamic Type

**必须：**

- 标题 + 副标题 + detail 合并朗读策略可配置（默认合并）
- Switch/Checkbox：正确 traits 与 value
- Selection：「Selected」状态播报
- 行动 Cell：`.button` trait
- Section Header：`.header`
- 链接：可单独聚焦或使用 `accessibilityCustomActions`

**应当：**

- 减少动态效果下关闭非必要动画
- 表单错误：`accessibilityLabel` 含 error text
- 必填：`accessibilityLabel` 含「required」或使用 `accessibilityAttributedLabel`
- SMS 倒计时：按钮 `accessibilityValue` 播报剩余秒数
- 密码可见性 toggle：「Show password」/「Hide password」
- Picker 行：hint「Double tap to change」

---

## 14. 分阶段实现与交付计划

FKCellKit 样式 ID 合计 **200+**（D/I/X/F/M），**禁止**单次 PR/会话「全量实现」。本文 §14 为 **分阶段交付的规范**：每一 Phase 独立可合并、可验证、可交给 Cursor/Agent **按序执行**。

> **给实施者：** 开始 Phase *N* 前，确认 Phase *N−1* 验收 Gate 已通过；**仅实现该 Phase 范围**，勿提前做后续 Phase 的 Cell。

### 14.1 为何分阶段

| 原因 | 说明 |
|------|------|
| 规模 | 90+ 展示、15+ 设置交互、72+ 表单布局模式、20 语义字段；全量无法实现可 review 的 diff |
| 依赖 | Form Cell 依赖 Phase 0 的 `FKCellContentStack` + **Phase 2** 的 `FKFormFieldChromeView`；General Display 依赖 Phase 0 的 `FKCellContentStack` |
| 质量 | §2.4 约束/性能需在 Phase 0 建立模式，后续 Phase **复制**而非各自为政 |
| 集成 | FKListKit、Collection parity 放在最后，避免 API 未稳定时双重维护 |
| Cursor | 单次上下文有限；**一个 Phase = 一次 Agent 任务** 成功率最高 |

### 14.2 分阶段原则

1. **TableViewCell 优先** — Phase 0–5 仅 `UITableViewCell`；`UICollectionViewCell` parity 在 **Phase 6**。
2. **Internal 先行** — 新 Phase 先复用/扩展 Internal 子组件，再增 Public Cell。
3. **Examples 跟 Phase 走** — 每 Phase **必须**新增/更新对应 Hub 场景（§14.4–§14.10 表）；无 Demo 不算交付完成。
4. **编译 Gate** — 每 Phase 结束 `xcodebuild` **BUILD SUCCEEDED**（见 FKKit skill § Verify）。
5. **不越界** — 每 Phase 列出 **「本阶段不做」**；Agent **不得**实现后续 Phase 类型。
6. **Compose 优先** — 新样式先查 §3.5.12、§3.6.12；能配置扩展则不新建 Cell 类。

### 14.3 阶段总览与依赖

```text
Phase 0  基础设施（Core + Internal 布局引擎 + Structure）
    │
    ├──► Phase 1  设置页 MVP（Display + Settings 交互 P0）
    │
    ├──► Phase 2  表单 MVP（5 种 Layout + 登录注册）
    │         │
    │         └──► Phase 3  表单扩展（手机/OTP/Picker/日期）
    │
    └──► Phase 4  通用列表展示（消息/电商/搜索展示…）
              │
              └──► Phase 5  富内容 + 扩展设置/表单交互
                        │
                        └──► Phase 6  长尾 + Collection + ListKit
```

| Phase | 名称 | 核心产出 | 样式量级 | 前置 |
|-------|------|----------|----------|------|
| **0** | 基础设施 | Core、Internal 引擎、Section 头尾 | — | — |
| **1** | 设置页 MVP | Settings Display + I-01–04/07 | ~20 ID | 0 |
| **2** | 表单 MVP | `FKFormCellTextField` 全 Layout + 登录流 | ~25 ID | 0 |
| **3** | 表单扩展 | 手机、SMS、OTP、Picker、日期 | ~20 ID | 2 |
| **4** | 通用列表展示 | 消息、商品、状态、搜索命中… | ~35 ID | 0, 1 |
| **5** | 富内容与扩展交互 | Hero/富文本、I-05–15、Form 控件行 | ~40 ID | 1–4 |
| **6** | 长尾与集成 | D-68–90、X-54–72、Collection、ListKit | 剩余 | 0–5 |

---

### 14.4 Phase 0 — 基础设施

**目标：** 建立 **所有后续 Cell 共用的 Core + Internal**，并用 **1 个参考 Cell** 验证布局引擎与 §2.4 规范。

**前置依赖：** 无（FKCellKit 目录首次创建）。

**本阶段交付（源码）：**

| 路径 | 内容 |
|------|------|
| `CellKit/README.md` | 目录表、Phase 路线图引用、最小 register 示例 |
| `Public/Core/` | `FKCellAppearanceConfiguration`、`FKCellAccessory`、`FKCellSeparatorPolicy`、`FKCellGroupConfiguration`、`FKCellRegistration` |
| `Extension/` | `UITableView+FKCellKit.swift` |
| `Internal/` | `FKCellLayoutMetrics`、`FKCellContentStack`、`FKCellAccessoryHostView`、`FKCellGroupedBackgroundView` |
| `Public/Structure/` | `FKCellSectionHeaderView`、`FKCellSectionFooterView` |
| `Public/Display/` | **`FKCellDisclosureCell` + Configuration + Row**（参考实现） |
| `Package.swift` | `exclude:` CellKit README |

**样式 ID：** `S-01`、`S-02`、`S-03`；参考 `D-01`。

**本阶段不做：**

- 任何其他 Display/Form/Interactive Cell
- `FKFormCell*`、`FKListKit` 集成
- Collection Cell

**Examples（必须）：** #12 `CellKitStandaloneTable`（单类型 disclosure + section 头尾；验证独立 dequeue，不依赖 FKListKit）。

**验收 Gate：**

- [ ] `FKCellContentStack` 三区模型符合 §11.5.1
- [ ] `FKCellDisclosureCell` 通过 Dynamic Type / RTL 无 constraint warning
- [ ] `prepareForReuse` + `FKCellReusable` 注册可用
- [ ] README 英文、目录表含 Phase checklist（§14.11）
- [ ] Example #12 `CellKitStandaloneTable` 可运行
- [ ] `xcodebuild` BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 0 — core infrastructure and disclosure reference cell`

---

### 14.5 Phase 1 — 设置页 MVP

**目标：** 覆盖 **iOS 设置 Inset Grouped** 最高频只读/导航行 + **核心行内控件**（Switch、单选、值+导航）。

**前置依赖：** **Phase 0** 完成。

**本阶段交付：**

| 类型 | 样式 ID | 公开类型（代表） |
|------|---------|------------------|
| Display | D-02–D-05, D-10, D-11, D-14, D-16 | `FKCellKeyValueCell`、`FKCellValueDisclosureCell`、`FKCellIconDisclosureCell`、`FKCellLinkCell`、`FKCellActionCell`、`FKCellIconValueDisclosureCell` |
| Interactive | I-01–I-04, I-07 | `FKCellSwitchCell`、`FKCellIconSwitchCell`、`FKCellSelectionCell`（I-03/07 复用 ValueDisclosure + Selection） |

**Internal 扩展：** 按需完善 `FKCellAccessoryHostView`（disclosure、checkmark）。

**本阶段不做：**

- D-06–D-09、D-12、D-13、D-15 富文本/Hero/Storage/Legal（→ Phase 5）
- I-05、I-06、I-08–I-15（→ Phase 5/6）
- 全部 `FKFormCell*`（→ Phase 2+）
- D-17+ 通用业务展示（→ Phase 4）

**Examples：** #1 `SettingsGeneral`（MVP：D-04/D-11，无 D-06）、#2 `SettingsAbout`、#4 `SettingsAirDrop`（I-01/03）。

**验收 Gate：**

- [ ] Inset Grouped 分组圆角 + 分隔 inset 与系统设置并排无明显漂移
- [ ] Switch/Selection 无 retain cycle；VoiceOver 基本正确
- [ ] 每 Cell 独立 register + `apply(_:)`；Row 模型 `Sendable`
- [ ] Examples 三场景可运行
- [ ] BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 1 — settings display and inline controls MVP`

---

### 14.6 Phase 2 — 表单 MVP

**目标：** 交付 **表单布局引擎** + **5 种 Layout** + **登录/注册最小闭环**（文本、密码、协议、提交）。

**前置依赖：** **Phase 0**（可与 Phase 1 并行开发，但 **合并前** Phase 0 须已 main；**推荐顺序 0→1→2**）。

**本阶段交付：**

| 类型 | 样式 ID | 公开类型 |
|------|---------|----------|
| Form Core | X-01–X-05, X-08–X-10, X-21–X-24, X-49, X-52 | `FKFormCellLayout`、`FKFormFieldValidationPresentation`、`FKFormCellTextFieldCell`、`FKFormSectionHeaderView`、`FKFormCellPrimaryButtonCell`、`FKFormCellAgreementCell`；**Internal：** `FKFormFieldChromeView`、`FKFormAccessoryHostView`（含 X-09 prefix accessory） |
| Semantic | F-01, F-02, F-05, F-09 | 透传上述 Cell |

**Layout 必须全部可用：** `.underline`、`.cardStacked`、`.cardInline`、`.inlineLabel`、`.iconUnderline`。

**本阶段不做：**

- X-06 手机、X-17 SMS、X-18 OTP（→ Phase 3）
- X-11/12 Picker、X-13/14 日期（→ Phase 3）
- F-12 及 F-03/04/06–08/10–20（→ Phase 3/6）
- 搜索 Cell X-26–29（→ Phase 5）

**Examples：** #10 `FormLoginRegister`、#13 `FormMaterialUnderline`（5 layout 分 section 展示）。

**验收 Gate：**

- [ ] 5 种 Layout 视觉与 §3.6.2（R-01–R-07）结构描述一致
- [ ] Error/Success/Required（X-21–24）在 underline + card 下均正确
- [ ] 密码 X-08 visibility toggle；协议 X-52 链接可点
- [ ] `FKTextField` pipeline 透传；Cell 内无裸 `UITextField`
- [ ] 表单 Cell `selectionStyle = .none`；层级 ≤ §2.4.5 预算
- [ ] BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 2 — form layout engine and login/register MVP`

---

### 14.7 Phase 3 — 表单扩展

**目标：** 注册/企业表单 **高频复杂 field**：手机、验证码、Picker、日期。

**前置依赖：** **Phase 2** 完成。

**本阶段交付：**

| 类型 | 样式 ID | 公开类型 |
|------|---------|----------|
| Form | X-06, X-11, X-12, X-17, X-18 | `FKFormCellPhoneCell`、`FKFormCellPickerCell`、`FKFormCellSMSCodeCell`、`FKFormCellOTPCell` |
| Form | X-13, X-14 | `FKFormCellDateCell`、`FKFormCellTimeCell` |
| Semantic | F-03, F-12, F-08 | 绑定上述 Cell |

**本阶段不做：**

- X-16 Captcha、X-19 媒体、X-07 社交账号（→ Phase 5）
- F-04 多行、F-06/07 控件组（→ Phase 5）
- X-26+ 搜索（→ Phase 5）

**Examples：** #14 `FormCardStacked`、#15 `FormCardInline`、#17 `FormEnterpriseInline`（X-04 inlineLabel + X-11/12 Picker + X-17 SMS；**不含** X-16 Captcha，留 Phase 5）。

**验收 Gate：**

- [ ] 手机 X-06 国家区与号码分栏；竖线分隔
- [ ] SMS X-17 倒计时 `prepareForReuse` invalidate Timer
- [ ] OTP X-18 分格 + linkage
- [ ] Picker dropdown vs navigation 两种 presentation
- [ ] BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 3 — phone, OTP, picker, and date form cells`

---

### 14.8 Phase 4 — 通用列表展示

**目标：** 设置页以外的 **P1 通用 Feed 展示行**（消息、通知、商品、文件、搜索…）。

**前置依赖：** **Phase 0**；**建议 Phase 1 已完成**（复用 Selection/Disclosure 模式）。

**本阶段交付（样式 ID）：**

`D-17`–`D-21`、`D-23`–`D-25`、`D-28`–`D-30`、`D-33`–`D-36`、`D-39`、`D-43`、`D-45`、`D-52`、`D-54`–`D-55`、`D-56`、`D-57`、`D-64`–`D-67`、`D-78`、`D-79`、`D-88`

**代表类型：** `FKCellProfileCell`、`FKCellConversationCell`、`FKCellNotificationCell`、`FKCellProductCell`、`FKCellTransactionCell`（若时间紧可部分 Compose 推迟 Phase 6）、`FKCellFileCell`、`FKCellSearchResultCell`、`FKCellExpandableCell`、`FKCellSortFilterBarCell`…

**本阶段不做：**

- D-06–D-15 设置风富文本（→ Phase 5）
- D-68–D-90 长尾（→ Phase 6）
- 全部 Form Interactive 扩展

**Examples：** #19 `MessagesInbox`、#20 `CommerceCheckout`、#21 `FAQExpandable`、#24 `ListSortFilter`。

**验收 Gate：**

- [ ] 远程图一律 `FKImageView` + reuse 取消
- [ ] `FKCellUnreadPresentation`（§6.6）用于 D-20/21
- [ ] 搜索高亮 D-66 attributed string
- [ ] BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 4 — general-purpose display cells (feed, commerce, search)`

---

### 14.9 Phase 5 — 富内容与扩展交互

**目标：** 设置风 **复杂卡片**、剩余 **Settings 交互**、**表单控件行**与 **行内搜索**。

**前置依赖：** Phase 1–4。

**本阶段交付：**

| 类型 | 样式 ID |
|------|---------|
| Display 富内容 | D-06–D-09, D-12, D-13, D-15, D-22, D-26, D-27, D-31, D-32 |
| Settings 交互 | I-02（若 Phase 1 未做 icon switch）、I-05, I-06 |
| Form 控件/搜索 | X-07, X-16, X-19, X-26–X-30, X-36–X-39, X-50, X-51 |
| Semantic | F-04, F-06, F-07, F-10, F-11 | F-08 日期由 Phase 3 交付，本 Phase Examples 复用 |

**Examples：** #3 `SettingsSoftwareUpdate`、#5–#9 Settings 系列、#11 `FormProfileEdit`、#16 `FormContactSocial`、#18 `FormInlineSearch`。

**验收 Gate：**

- [ ] 富文本 D-07/08 `FKCellLinkTextView` 链接
- [ ] 搜索 Cell 嵌入 `FKSearchField`，非自研搜索 UI
- [ ] Form 控件行嵌入 `FKFormControls`（或过渡期 UISwitch 文档说明）
- [ ] BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 5 — rich settings cards, form controls, and inline search`

---

### 14.10 Phase 6 — 长尾、Collection 与 ListKit

**目标：** 收尾 **P2/P3 长尾样式**、**UICollectionViewCell parity**、**FKListKit 预设映射**。

**前置依赖：** Phase 0–5。

**本阶段交付：**

| 类型 | 范围 |
|------|------|
| Display 长尾 | D-68–D-90（§3.5.13 剩余） |
| Interactive 长尾 | I-08–I-15 |
| Form 长尾 | X-54–X-72、F-14–F-20 |
| 混合验收 | M-01–M-06 Compose Examples |
| 集成 | `*CollectionCell` 与 Table **共享 Internal**；`FKListPresetItem` → CellKit Row 薄映射 |
| 可选 | `FKFormCellConditionalVisibility` helper（X-41） |

**Examples：** #22–#27 全部；可选 `CellKitStressScroll`（500 行）。

**验收 Gate：**

- [ ] Collection 与 Table 同 Configuration 视觉一致
- [ ] ListKit 预设无 duplicate Auto Layout
- [ ] §12.4.4 性能检查表 spot check
- [ ] 根 README 索引 CellKit；CHANGELOG 条目
- [ ] BUILD SUCCEEDED

**建议 PR：** `feat(cellkit): Phase 6 — long-tail cells, collection parity, and ListKit integration`

---

### 14.11 Cursor / Agent 实施指引

**单次 Agent 任务模板（复制到 Cursor）：**

```markdown
Implement FKCellKit **Phase N** only, per docs/FKCellKit_DESIGN.zh-CN.md §14.(4+N).
  (Phase 0 → §14.4, Phase 1 → §14.5, … Phase 6 → §14.10)

Constraints:
- Follow §2.4 global engineering requirements (English API, reuse FKUIKit/FKCoreKit, layout, performance).
- Do NOT implement styles listed in "本阶段不做" for this phase.
- Run xcodebuild verify (FKKit skill) until BUILD SUCCEEDED.
- Update CellKit README + FKKitExamples scenarios listed for this phase.

Deliver: list of new files, public types, and Example screen names.
```

**阶段选择建议：**

| 用户需求 | 从哪 Phase 开始 |
|----------|----------------|
| 只做设置页 | Phase 0 → 1 |
| 登录注册表单 | Phase 0 → 2（+3 若要 OTP/手机） |
| 消息/商品列表 | Phase 0 → 1 → 4 |
| 完整 CellKit | Phase 0 → 1 → 2 → 3 → 4 → 5 → 6 **严格顺序** |

**并行规则：**

- **不可并行：** 0 是第一；2 依赖 0；3 依赖 2；6 依赖 0–5。
- **可并行（人力充足时）：** Phase 1 与 Phase 2 在 Phase 0 合并后由不同人做，但 **避免改同一 Internal 文件**。

**完成度追踪：** 在 CellKit `README.md` 维护 **Phase checklist**（与 §14.4–§14.10 Gate 同步），每合并一 Phase 勾选。

---

## 15. 建议源码目录结构

> 目录为建议起点；实际以组件 `README.md` 为准。**按 §14 分 Phase 增量创建** — Phase 0 仅 Core/Internal/Structure/Disclosure；Form Internal（`FKFormFieldChromeView` 等）自 Phase 2 起；Collection Extension 自 Phase 6 起。

```text
Sources/FKUIKit/Components/CellKit/
├── README.md
├── Public/
│   ├── Core/
│   │   ├── FKCellAppearanceConfiguration.swift
│   │   ├── FKCellAccessory.swift
│   │   ├── FKCellSeparatorPolicy.swift
│   │   ├── FKCellGroupConfiguration.swift
│   │   └── FKCellRegistration.swift
│   ├── Structure/
│   │   ├── FKCellSectionHeaderView.swift
│   │   └── FKCellSectionFooterView.swift
│   ├── Display/
│   │   ├── Settings/               # D-01 … D-16
│   │   ├── General/                # D-17 … D-90
│   │   ├── FKCellDisclosureCell.swift
│   │   ├── …
│   │   └── Rows/
│   ├── Interactive/
│   │   ├── Settings/               # I-01 … I-07
│   │   ├── Form/
│   │   │   ├── Core/               # FKFormCellLayout, Accessory, Validation
│   │   │   ├── Text/               # FKFormCellTextFieldCell …
│   │   │   ├── Pickers/            # Phone, Picker, Date …
│   │   │   ├── Verification/       # Captcha, SMS, OTP
│   │   │   └── Actions/            # Button, Agreement, Social
│   │   └── Search/                 # FKFormCellSearchCell
├── Internal/
│   ├── FKCellLayoutMetrics.swift
│   ├── FKCellContentStack.swift      # 三区布局引擎
│   ├── FKCellAccessoryHostView.swift
│   ├── FKFormFieldChromeView.swift
│   ├── FKCellLinkTextView.swift
│   ├── FKCellGroupedBackgroundView.swift
│   └── FKCellStorageProgressView.swift
└── Extension/
    ├── UITableView+FKCellKit.swift
    └── UICollectionView+FKCellKit.swift
```

`Package.swift` `exclude:` 增加 `Components/CellKit` README。

---

## 16. FKKitExamples 场景

路径建议：`Examples/.../FKUIKit/CellKit/`

| # | 场景 | 覆盖样式 | 交付 Phase |
|---|------|----------|------------|
| 1 | `SettingsGeneral` | D-04, D-11, S-01/02（**Phase 5** 补 D-06 Hero） | 1（MVP）/ 5（完整） |
| 2 | `SettingsAbout` | D-02, D-03, D-05, D-16 | 1 |
| 3 | `SettingsSoftwareUpdate` | D-07, D-08, D-09, I-07 | 5 |
| 4 | `SettingsAirDrop` | I-01, I-03, S-01/02 | 1 |
| 5 | `SettingsLanguageRegion` | I-04, I-06, D-10 | 5 |
| 6 | `SettingsAutoFill` | I-02, I-05 | 5 |
| 7 | `SettingsStorage` | D-13, D-14, D-05, D-11 | 5 |
| 8 | `SettingsLegal` | D-15, D-01 | 5 |
| 9 | `SettingsTransferReset` | D-12, D-11 | 5 |
| 10 | `FormLoginRegister` | X-01/02, F-01/02/05/09, X-49/52 | 2 |
| 11 | `FormProfileEdit` | X-02/03, F-04/08/11, X-13 | 5 |
| 12 | `CellKitStandaloneTable` | D-01, S-01/02/03；不依赖 FKListKit | 0 |
| 13 | `FormMaterialUnderline` | X-01, X-08, X-22/23（R-01、R-06） | 2 |
| 14 | `FormCardStacked` | X-02, X-11, X-06 split（R-04） | 3 |
| 15 | `FormCardInline` | X-03, X-13, X-08（R-02） | 3 |
| 16 | `FormContactSocial` | X-05, X-07, X-10（R-05） | 5 |
| 17 | `FormEnterpriseInline` | X-04, X-11/12, X-17（R-07；不含 X-16） | 3 |
| 18 | `FormInlineSearch` | X-26–X-29（R-03） | 5 |
| 19 | `MessagesInbox` | D-20 | 4 |
| 20 | `CommerceCheckout` | D-28, D-30 | 4 |
| 21 | `FAQExpandable` | D-64, D-65 | 4 |
| 22 | `WalletTransactions` | D-69, D-30 | 6 |
| 23 | `MediaPlaylist` | D-73, D-86, M-06 | 6 |
| 24 | `ListSortFilter` | D-78, D-55, M-05 | 4 |
| 25 | `TaskAndCheckbox` | D-70, I-08, M-04 | 6 |
| 26 | `FormExtendedFields` | F-14–F-20, X-54–X-56 | 6 |
| 27 | `SurveyNPS` | X-65, D-71 | 6 |

Hub 按 **Settings / Form Layouts / Form Flows / General Display / Mixed** 分组。

**与 Phase 对应关系（Examples 随 Phase 交付，勿一次全做）：**

| Phase | 必须交付的 Examples # |
|-------|------------------------|
| 0 | 12 |
| 1 | 1, 2, 4 |
| 2 | 10, 13 |
| 3 | 14, 15, 17 |
| 4 | 19, 20, 21, 24 |
| 5 | 3, 5, 6, 7, 8, 9, 11, 16, 18 |
| 6 | 22, 23, 25, 26, 27 + 可选 StressScroll |

---

## 17. 待决问题

| ID | 问题 | 建议默认 |
|----|------|----------|
| Q1 | 模块名 `CellKit` vs `ListCells`？ | **`CellKit`** — 强调可独立使用 |
| Q2 | Collection Cell 是否与 Table 同步首发？ | **Phase 6**；Phase 0–5 仅 Table（§14.2） |
| Q3 | Inset grouped 圆角：Cell 背景 vs Section 背景？ | iOS 15+ 优先 **section 级** `UITableView` grouped + Cell 透明；plain 模拟时用 `FKCellGroupedBackgroundView` |
| Q4 | FKListKit 预设 enum 是否迁到 CellKit Row 类型？ | Row 类型定义在 **CellKit**；ListKit `FKListPresetItem` 引用 |
| Q5 | 表单校验：Cell 内还是宿主？ | v1 **宿主**；Cell 仅展示 `errorText` |
| Q6 | Hero/Feature 卡是否支持 Dark Mode 插图？ | 支持 asset + SF Symbol；无插图时仅 Symbol |
| Q7 | Regulatory Cell 是否 worth P2？ | 是；低频但 About/Legal 类 App 需要 |
| Q8 | D-17–D-90 是否全部独立 Cell 类？ | **否**；§3.5.12 / §3.5.14 Compose 优先 |
| Q9 | 展开 Cell 是否在 Cell 内改高？ | 默认 **通知 table 批量更新**；Cell 提供 `onExpandedHeightChange` |
| Q10 | 消息/通知未读态是否统一？ | `FKCellUnreadPresentation` 共享配置 |
| Q11 | X-* 是否每种独立 Cell 类？ | **否**；`FKFormCellLayout` + `FKFormAccessory` 优先（§3.6.12） |
| Q12 | Material 下划线 vs iOS grouped 表单？ | 两种 **layout** 均一等支持；Examples 分场景 |
| Q13 | SMS 倒计时放 Cell 还是 Helper？ | Cell 内 **轻量 Timer** + `prepareForReuse` 清理 |
| Q14 | 搜索 60+ 变体是否全做？ | **否**；`FKFormSearchCellStyle` 4 种 + SearchField 配置扩展 |
| Q15 | 每种样式 ID 是否一个 Swift 文件？ | **否**；Compose + Internal 子组件；见 §2.4.3 |
| Q16 | Cell 内能否写私有 `formatDate()`？ | **否**；用 FKCoreKit Extension 或上游 Utils |
| Q17 | 性能验收标准？ | §12.4.4 检查表 + Phase 6 可选 StressScroll |
| Q18 | 能否一次实现全部 Cell？ | **禁止**；必须按 §14 Phase 0→6 顺序交付 |
| Q19 | Agent 如何知道当前做哪一阶段？ | 用户指定 Phase N + §14.11 任务模板 |

---

## 18. 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版：基于 iOS 设置典型页面与 7 类表单布局 archetype 归纳 Display/Interactive/Form taxonomy，定义 FKCellKit 命名与 FKListKit 边界 |
| 2026-06-12 | 增补 §3.5 扩展展示类（D-17–D-67）、§7.16、Compose 策略 |
| 2026-06-12 | 增补 §3.6 交互类完整目录（I/X/F 体系）、§6.7–§6.10、§8–§9 表单布局规格；7 类表单/搜索布局 archetype |
| 2026-06-12 | 增补 §2.4 全局工程要求（命名、复用、子组件、约束、性能）；§4.1.1、§5.5–§5.6、§11.5、§12.4 |
| 2026-06-12 | 增补 **§14 分阶段实现与交付计划**（Phase 0–6、依赖图、每 Phase 交付/不做/Gate/PR 标题、§14.11 Cursor 任务模板）；§16 Examples 与 Phase 映射；§17 Q18–Q19 |
| 2026-06-12 | 文档一致性审查：修正 Phase 1「本阶段不做」与交付 ID 冲突、Phase 0/2/3 Examples 与 Internal 公开边界、§14.1 依赖表述、§16 Phase 列、§4.2 Phase 说明 |
| 2026-06-12 | 移除「截图 N」依赖：§3 改为页面/布局文字参考；新增 §3.6.2 **R-01–R-07** 布局参考表 |

---

## 相关文档

- [FKListKit_DESIGN.zh-CN.md](FKListKit_DESIGN.zh-CN.md) — 列表 VC；预设 Item 消费 FKCellKit
- [FKFormControls_DESIGN.zh-CN.md](FKFormControls_DESIGN.zh-CN.md) — Switch/Checkbox/Radio 控件
- [FKIconView_DESIGN.zh-CN.md](FKIconView_DESIGN.zh-CN.md) — 设置行 leading 图标
- [COMPONENT_ROADMAP.zh-CN.md](COMPONENT_ROADMAP.zh-CN.md) — 总路线图；**勿重复造轮子**表与 §2.4.2 一并遵守
- [FKSearchBar-FKSearchField_DESIGN.zh-CN.md](FKSearchBar-FKSearchField_DESIGN.zh-CN.md) — 行内搜索 Cell（X-26–X-29）
- [FKTextField README](../Sources/FKUIKit/Components/TextField/README.md) — 输入 pipeline
- [FKCellReusable](../Sources/FKCoreKit/Components/Pluggable/UIKit/FKCellReusable.swift) — 复用契约
