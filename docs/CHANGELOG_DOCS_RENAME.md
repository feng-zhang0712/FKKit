# docs 目录重命名变更记录

**修改时间：** 2026-06-14

## 变更说明

移除 `docs/` 目录下所有文件名与文件内容中的 `.zh-CN` 后缀，统一为 `*_DESIGN.md` / `COMPONENT_*.md` 命名。

## 重命名文件（33 个）

| 原文件名 | 新文件名 |
|---------|---------|
| `COMPONENT_GAP_ANALYSIS.zh-CN.md` | `COMPONENT_GAP_ANALYSIS.md` |
| `COMPONENT_ROADMAP.zh-CN.md` | `COMPONENT_ROADMAP.md` |
| `FKBanner-FKNoticeBar_DESIGN.zh-CN.md` | `FKBanner-FKNoticeBar_DESIGN.md` |
| `FKAlert_DESIGN.zh-CN.md` | `FKAlert_DESIGN.md` |
| `FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.zh-CN.md` | `FKAvatar-FKAvatarGroup-FKPresenceIndicator_DESIGN.md` |
| `FKBackgroundTaskManager_DESIGN.zh-CN.md` | `FKBackgroundTaskManager_DESIGN.md` |
| `FKBiometricAuth_DESIGN.zh-CN.md` | `FKBiometricAuth_DESIGN.md` |
| `FKBusinessKit-Widgets-Integration_DESIGN.zh-CN.md` | `FKBusinessKit-Widgets-Integration_DESIGN.md` |
| `FKBusinessKit_DESIGN.zh-CN.md` | `FKBusinessKit_DESIGN.md` |
| `FKBusinessKit_ENHANCEMENT_DESIGN.zh-CN.md` | `FKBusinessKit_ENHANCEMENT_DESIGN.md` |
| `FKCarousel-FKImageBanner_DESIGN.zh-CN.md` | `FKCarousel-FKImageBanner_DESIGN.md` |
| `FKChip-FKTag-FKChipGroup_DESIGN.zh-CN.md` | `FKChip-FKTag-FKChipGroup_DESIGN.md` |
| `FKCopyChip_DESIGN.zh-CN.md` | `FKCopyChip_DESIGN.md` |
| `FKFileManager_DESIGN.zh-CN.md` | `FKFileManager_DESIGN.md` |
| `FKFileManager_ENHANCEMENT_DESIGN.zh-CN.md` | `FKFileManager_ENHANCEMENT_DESIGN.md` |
| `FKFormControls_DESIGN.zh-CN.md` | `FKFormControls_DESIGN.md` |
| `FKIconView_DESIGN.zh-CN.md` | `FKIconView_DESIGN.md` |
| `FKImageLoader-FKImageView_DESIGN.zh-CN.md` | `FKImageLoader-FKImageView_DESIGN.md` |
| `FKListKit_DESIGN.zh-CN.md` | `FKListKit_DESIGN.md` |
| `FKLocalNotificationManager_DESIGN.zh-CN.md` | `FKLocalNotificationManager_DESIGN.md` |
| `FKMarqueeLabel_DESIGN.zh-CN.md` | `FKMarqueeLabel_DESIGN.md` |
| `FKNetwork_DESIGN.zh-CN.md` | `FKNetwork_DESIGN.md` |
| `FKNetwork_ENHANCEMENT_DESIGN.zh-CN.md` | `FKNetwork_ENHANCEMENT_DESIGN.md` |
| `FKPhotoPicker_DESIGN.zh-CN.md` | `FKPhotoPicker_DESIGN.md` |
| `FKPluggable_ENHANCEMENT_DESIGN.zh-CN.md` | `FKPluggable_ENHANCEMENT_DESIGN.md` |
| `FKQRCode_DESIGN.zh-CN.md` | `FKQRCode_DESIGN.md` |
| `FKSearchBar-FKSearchField_DESIGN.zh-CN.md` | `FKSearchBar-FKSearchField_DESIGN.md` |
| `FKSearchViewController_DESIGN.zh-CN.md` | `FKSearchViewController_DESIGN.md` |
| `FKStatusPill_DESIGN.zh-CN.md` | `FKStatusPill_DESIGN.md` |
| `FKStepIndicator-FKTimeline_DESIGN.zh-CN.md` | `FKStepIndicator-FKTimeline_DESIGN.md` |
| `FKTheme_DESIGN.zh-CN.md` | `FKTheme_DESIGN.md` |
| `FKWebView_DESIGN.zh-CN.md` | `FKWebView_DESIGN.md` |

## 内容更新

- `docs/` 内所有 Markdown 交叉引用链接已同步更新（移除 `.zh-CN`）。
- 以下组件 `README.md` 中的设计文档链接已同步更新：
  - `Sources/FKCoreKit/Components/BusinessKit/README.md`
  - `Sources/FKCoreKit/Components/FileManager/README.md`
  - `Sources/FKCoreKit/Components/Network/README.md`
  - `Sources/FKCoreKit/Components/Pluggable/README.md`
  - `Sources/FKUIKit/Components/Alert/README.md`
  - `Sources/FKUIKit/Components/ListKit/README.md`
  - `Sources/FKUIKit/Components/SearchBar/README.md`

## 验证

全仓库检索 `.zh-CN`：无匹配项。
