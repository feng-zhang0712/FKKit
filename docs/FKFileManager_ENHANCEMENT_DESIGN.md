# FKFileManager — 增量增强设计索引

> **完整模块设计需求文档（已交付能力 + ZIP/后台/Multipart 增强 + 基线 Examples）见：**
> **[FKFileManager_DESIGN.md](FKFileManager_DESIGN.md)**

本文档保留为 **ZIP 与后台传输** 相关 Roadmap 的快速索引；详细规范、API 草案、验收标准已合并入主文档对应章节。

**文档类型：** 索引（指向主设计文档）  
**状态：** 草案  
**主文档：** [FKFileManager_DESIGN.md](FKFileManager_DESIGN.md)  
**模块 README：** [FileManager/README.md](../Sources/FKCoreKit/Components/FileManager/README.md)

---

## 增强项与主文档章节映射

| 增强项 | 用户价值 | 主文档章节 | 状态 |
|--------|----------|------------|------|
| **ZIP 压缩/解压** | 离线包、日志打包；API 已公开但 `zipUnavailable` | §13 | 待交付 |
| **后台传输恢复文档** | `handleEventsForBackgroundURLSession` 逐步清单 | §12、§14 | 待交付 |
| **后台 completion API** | 系统 completionHandler 接线 | §14 | 待交付 |
| **Multipart / MIME 统一** | 与 FKNetwork `FKMultipartFormData` 共用 | §15 | 待交付 |

**原则：** ZIP 与后台增强均为 **opt-in** 或能力门控；未启用时现有沙盒/传输行为 **不变**。

---

## 相关增强（主文档已覆盖，原索引未列）

| 能力 | 主文档章节 | 说明 |
|------|------------|------|
| 已交付能力详表 | §6 | 沙盒、CRUD、断点下载、Multipart 上传等 |
| 断点下载与后台 Session | §10 | `allowsBackground`、resumeData |
| 传输持久化 | §12 | `FKPersistedTransfer`、`reconnectBackgroundTasks` |
| 上传仅前台 Session | §11、§23 | v2 后台上传 |
| iOS 分享/预览 | §16 | vs Tier 3 FKShareSheet |
| 与 FKNetwork 分工 | §17 | 大文件 vs REST |
| 基线 Examples B1–B8 | §27.1 | 已交付路径演示 |
| v2 展望 | §23 | 加密 ZIP、上传后台等 |

---

## FKKitExamples 场景索引

见主文档 **§27**：

- **基线** B1–B8：沙盒、Codable、断点下载、上传、缓存、磁盘、快照、分享预览
- **增强** E1–E8：ZIP、Zip slip、后台恢复、ZIP 分享

---

## 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版独立增强设计文档 |
| 2026-06-14 | 合并入主文档 `FKFileManager_DESIGN.md`；本文改为索引 |

---

## 相关文档

- [FKFileManager_DESIGN.md](FKFileManager_DESIGN.md) — **主设计文档**
- [FileManager/README.md](../Sources/FKCoreKit/Components/FileManager/README.md)
- [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md) — Multipart 分工
- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [COMPONENT_GAP_ANALYSIS.md](COMPONENT_GAP_ANALYSIS.md)
