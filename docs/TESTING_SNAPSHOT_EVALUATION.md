# FKKit Snapshot 测试评估

**状态：** 结论文档 — Phase 4 产出；**当前不引入** Snapshot 测试。  
**关联：** [`TESTING_GUIDE.md`](TESTING_GUIDE.md)  
**最后更新：** 2026-06-16

---

## 1. 评估背景

Phase 1–3 已建立：

- FKCoreKit / FKUIKit **逻辑层**单元测试（83 cases）
- CI `xcodebuild test` 门禁
- FKKitExamples **人工视觉与交互**验收

Phase 4 需决定是否在库内引入 **Snapshot / 视觉回归** 测试。

---

## 2. 候选方案

| 方案 | 说明 | 与 FKKit 约束 |
|------|------|----------------|
| **A. 暂不引入** | 维持逻辑测试 + Examples | 零新依赖；与现有策略一致 |
| **B. 自建 `UIGraphicsImageRenderer` 对比** | 手写 golden image | 无第三方，但 fragile、难维护 Dark Mode / Dynamic Type |
| **C. pointfreeco/swift-snapshot-testing** | 社区常用 SPM 测试依赖 | 仅 test target，仍增加维护与 CI 体积 |
| **D. Xcode `XCTAssertTrue(view.draw...) + 自建 fixture** | 半手工 | 成本高，收益接近 B |

---

## 3. 结论：**方案 A — 暂不引入**

**理由：**

1. **库约束**：运行时零第三方依赖；测试依赖虽可单独添加，但会增加贡献者与 CI 复杂度，与当前「轻量 CI、快反馈」目标冲突。
2. **UI 变化面大**：Dark Mode、Dynamic Type、RTL、iOS 版本字体差异会导致 snapshot 频繁失效，维护成本高于逻辑测试。
3. **已有分工**：FKKitExamples 强制覆盖 public API；自动化测试已覆盖 ListKit snapshot **模型**、Button **状态** 等可断言逻辑，而非像素。
4. **ROI**：Phase 3 试点表明，FKUIKit 首批高 ROI 用例均为 configuration / state / hit test，非截图。

**不在 CI 中启用 Snapshot；不在 `Package.swift` 增加 snapshot 测试依赖。**

---

## 4. 何时重新评估（触发条件）

满足 **任意两条** 时可 reopen 本评估：

- [ ] Button / ListKit 等核心 UI 的 public 外观 API 冻结一个大版本（例如 1.0 UI contract）
- [ ] 同一 UI 组件在多个 PR 中出现 **视觉回归**（非逻辑 bug）
- [ ] 贡献者 repeatedly 依赖 Examples 手工对比，漏测明显
- [ ] 团队愿意维护 **固定设备 + 固定外观**（light, default content size）的 golden 基线

---

## 5. 若未来引入时的建议（预案）

1. **范围**：仅 1–2 个稳定组件（如 `FKButton` 固定 configuration preset），不全覆盖。
2. **依赖**：优先评估 `swift-snapshot-testing` 仅挂在 `FKUIKitTests`；记录于 CHANGELOG。
3. **策略**：
   - 固定 `traitCollection`（light, LTR, `.large`）
   - 记录 **尺寸** 而非全屏
   - 与逻辑测试并存，不替代
4. **CI**：可选单独 job；**不设** merge 覆盖率 / snapshot 百分比硬门槛，失败由人工 review diff。

---

## 6. 当前推荐做法

| 需求 | 手段 |
|------|------|
| 逻辑 / 契约回归 | `Tests/` + CI |
| API 演示与人工看 UI | FKKitExamples |
| 覆盖率趋势 | `bash scripts/run-tests-with-coverage.sh`（本地） |
| Bug 复现 | PR 附带 regression unit test（见 PR 模板） |

---

## 7. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-06-16 | Phase 4：评估完成，决定暂不引入 Snapshot |
