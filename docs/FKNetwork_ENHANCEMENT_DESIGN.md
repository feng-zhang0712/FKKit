# FKNetwork — 增量增强设计索引

> **完整模块设计需求文档（已交付能力 + 增量增强 + Pluggable + 基线 Examples）见：**
> **[FKNetwork_DESIGN.md](FKNetwork_DESIGN.md)**

本文档保留为 **Roadmap 四项增强** 的快速索引；详细规范、API 草案、验收标准已合并入主文档对应章节。

**文档类型：** 索引（指向主设计文档）  
**状态：** 草案  
**主文档：** [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md)  
**模块 README 路线图：** [Network/README.md](../Sources/FKCoreKit/Components/Network/README.md#roadmap)

---

## 增强项与主文档章节映射

| Roadmap 增强项 | 用户价值 | 主文档章节 | 状态 |
|----------------|----------|------------|------|
| **SSL Pinning** | 金融/企业防中间人；现有 `shouldPinSSLHost` 过弱 | §13 | 待交付 |
| **Multipart 辅助** | 图片/文件上传 Boundary 样板重复 | §12 | 待交付 |
| **Retry 预设** | 幂等 GET 退避重试无统一策略 | §14 | 待交付 |
| **Mock URLSession 模板** | 集成测试与 Examples 无标准路径 | §15 | 待交付 |

**原则：** 全部为 **opt-in**；未配置时行为与当前发版 **完全一致**（semver minor）。

---

## 相关增强（主文档已覆盖，原索引未列）

| 能力 | 主文档章节 | 说明 |
|------|------------|------|
| 已交付能力详表 | §6 | 缓存、去重、401、Mock 数据路径等 |
| 请求生命周期 | §7 | 管道顺序与取消 |
| Pluggable 桥接 | §17 | `FKAPIClientProviding`、凭证、拦截器 |
| Reachability 统一 | §16 | `FKNetworkReachabilityProviding` 双符合 |
| 基线 Examples B1–B8 | §26.1 | 已交付能力演示补齐 |
| v2 展望（WebSocket 等） | §22 | 明确非 v1 范围 |

---

## FKKitExamples 场景索引

见主文档 **§26**：

- **基线** B1–B8：GET/POST、缓存、去重、401、离线、上传下载、mockData
- **增强** E1–E9：Pinning、Multipart、Retry、Mock Session、Pluggable Adapter

---

## 修订历史

| 日期 | 变更 |
|------|------|
| 2026-06-12 | 初版独立增强设计文档 |
| 2026-06-14 | 合并入主文档 `FKNetwork_DESIGN.md`；本文改为索引 |

---

## 相关文档

- [FKNetwork_DESIGN.md](FKNetwork_DESIGN.md) — **主设计文档**
- [Network/README.md](../Sources/FKCoreKit/Components/Network/README.md)
- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKPluggable_ENHANCEMENT_DESIGN.md](FKPluggable_ENHANCEMENT_DESIGN.md)
