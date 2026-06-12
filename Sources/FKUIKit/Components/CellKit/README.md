# FKCellKit

Reusable **UITableViewCell** and **UICollectionViewCell** library for iOS settings-style display rows, inline controls, and form field rows. Includes thin **FKListPresetItem** mapping for future FKListKit integration.

**Module:** `FKUIKit` · **Path:** `Sources/FKUIKit/Components/CellKit/`  
**Design:** [FKCellKit_DESIGN.zh-CN.md](../../../docs/FKCellKit_DESIGN.zh-CN.md) · **Phased delivery:** Phase 0→6 (see design §14)

## Module layout

| Path | Role |
|------|------|
| `Public/Core/` | Shared configuration: appearance, accessories, separators, grouping, registration |
| `Public/Structure/` | Section header/footer views (S-01, S-02) |
| `Public/Display/` | Display and settings cells; `General/` feed/commerce; `LongTail/` Phase-6 rows; `Rows/` |
| `Public/Collection/` | Collection parity cells sharing Internal layout renderers with table variants |
| `Public/Integration/` | `FKListPresetItem` + `FKListPresetCellConfigurator` ListKit thin mapping |
| `Public/Interactive/Settings/` | Settings inline controls (switch, checkbox, segment, …); `Rows/` |
| `Public/Interactive/Form/` | Form layout engine, text field, pickers, verification, agreement, submit; `Extended/` long-tail form cells |
| `Internal/` | Layout engine, collection content host, shared layout renderers — not public API |
| `Extension/` | `UITableView` + `UICollectionView` registration helpers |

## Phase checklist

| Phase | Scope | Status |
|-------|--------|--------|
| **0** | Core, Internal engine, Structure, `FKCellDisclosureCell` (D-01) | Done |
| **1** | Settings display D-02–D-05, D-10, D-11, D-14, D-16 + I-01–I-04, I-07 | Done |
| **2** | Form layout engine + 5 layouts + login/register cells (F-01/02/05/09) | Done |
| **3** | Phone, OTP, picker, date form cells | Done |
| **4** | General-purpose feed/commerce display cells | Done |
| **5** | Rich settings cards, form controls, inline search | Done |
| **6** | Long-tail styles, Collection parity, FKListKit presets | Done |

## Phase 2 public types

| Style | Type |
|-------|------|
| X-01–X-05 | `FKFormCellLayout`, `FKFormCellTextFieldCell` |
| X-08 | Password + `FKFormTrailingAccessory.visibilityToggle` |
| X-09 | `FKFormLeadingAccessory.prefixText` |
| X-10 | `FKFormSectionHeaderView` |
| X-21–X-24 | `FKFormFieldValidationPresentation` |
| X-49 | `FKFormCellPrimaryButtonCell` |
| X-52 | `FKFormCellAgreementCell` |
| F-01 | `FKFormTextFieldRow` / `.textField(...)` preset |
| F-02 | `FKFormPasswordRow` / `.password(...)` preset |
| F-05 | `FKFormAgreementRow` |
| F-09 | `FKFormPrimaryButtonRow` |

Supported layouts: `.underline`, `.cardStacked`, `.cardInline`, `.inlineLabel`, `.iconUnderline`, `.groupedInset`, `.cardSplit` (phone).

## Phase 3 public types

| Style | Type |
|-------|------|
| X-06 | `FKFormCellPhoneCell`, `FKFormCountryPickerConfiguration` |
| X-11, X-12 | `FKFormCellPickerCell`, `FKFormPickerPresentation` |
| X-13, X-14 | `FKFormCellDateCell`, `FKFormCellTimeCell` |
| X-17 | `FKFormCellSMSCodeCell`, `FKFormSMSCodeButtonConfiguration` |
| X-18 | `FKFormCellOTPCell` |
| F-03 | `FKFormOTPRow` / `.otp(...)`, `FKFormSMSCodeRow` / `.smsCode(...)` |
| F-08 | `FKFormDateRow` / `.date(...)`, `FKFormTimeRow` / `.time(...)` |
| F-12 | `FKFormPhoneRow` / `.phone(...)` |

## Phase 4 public types

| Style | Type |
|-------|------|
| D-17–D-21 | `FKCellProfileCell`, `FKCellContactCell`, `FKCellPresenceCell`, `FKCellConversationCell`, `FKCellNotificationCell` |
| D-23–D-25 | `FKCellMediaThumbnailCell`, `FKCellAudioTrackCell`, `FKCellArticleCell` |
| D-28–D-30 | `FKCellProductCell`, `FKCellStackedKeyValueCell`, `FKCellPaymentMethodCell` |
| D-33–D-36 | `FKCellStatusCell`, `FKCellBadgeCell`, `FKCellProgressCell`, `FKCellSyncStatusCell` |
| D-39, D-43, D-45 | `FKCellCopyableValueCell`, `FKCellAddressCell`, `FKCellFileCell` |
| D-52, D-54–D-55 | `FKCellRatingCell`, `FKCellTagCell`, `FKCellFilterSummaryCell` |
| D-56, D-57 | `FKCellInlineNoticeCell`, `FKCellTipCell` |
| D-64–D-67 | `FKCellExpandableCell`, `FKCellSearchResultCell`, `FKCellRecentSearchCell` |
| D-78, D-79, D-88 | `FKCellSortFilterBarCell`, `FKCellLoadMoreCell`, `FKCellZeroResultsCell` |
| Shared | `FKCellUnreadPresentation`, `FKCellTrailingContent`, `FKCellImageContent`, `FKCellSearchHighlight` |

## Phase 5 public types

| Style | Type |
|-------|------|
| D-06–D-09, D-12 | `FKCellHeroCell`, `FKCellRichTextCell`, `FKCellStatusDetailCell`, `FKCellAlertActionCell`, `FKCellFeatureCardCell` |
| D-13 | `FKCellStorageSegment`, `FKCellStorageSummaryCell` |
| D-15 | `FKCellRegulatoryBlock`, `FKCellRegulatoryCell` |
| D-26–D-27, D-31–D-32 | `FKCellThumbnailStripCell`, `FKCellImageCardCell`, `FKCellCouponCell`, `FKCellTimelineNodeCell` |
| I-05, I-06 | `FKCellPickerCell`, `FKCellReorderCell` |
| X-07 | `FKFormPlatformPickerConfiguration`, `FKFormCellSocialAccountCell` |
| X-16, X-19 | `FKFormCellCaptchaCell`, `FKFormCellMediaPickerCell` |
| X-26–X-30 | `FKFormSearchCellStyle`, `FKFormCellSearchCell`, `FKFormCellFilterChipsCell` |
| X-36–X-39 | `FKFormCellCheckboxGroupCell`, `FKFormCellRadioGroupCell`, `FKFormCellSegmentCell`, `FKFormCellSwitchCaptionCell` |
| X-50–X-51 | `FKFormCellDualButtonCell`, `FKFormCellLinkButtonCell` |
| F-04, F-06, F-07, F-10, F-11 | `FKFormMultilineRow`, `FKFormRadioGroupRow`, `FKFormSegmentRow`, `FKFormLinkButtonRow`, `FKFormMediaPickerRow` |

## Phase 6 public types

| Area | Types |
|------|-------|
| Display long-tail | `FKCellActivityCell`, `FKCellStepListCell`, `FKCellEventCell`, `FKCellReviewCell`, `FKCellInlineEmptyCell`, `FKCellMarqueeCell`, `FKCellDeviceCell`, `FKCellNetworkCell`, `FKCellSubscriptionPlanCell`, `FKCellShortcutGridCell`, `FKCellTransactionCell`, `FKCellTaskCell`, `FKCellPollResultCell`, `FKCellLeaderboardCell`, `FKCellPlayableMediaCell`, `FKCellQuoteCell`, `FKCellMonospaceBlockCell`, `FKCellLanguageCell`, `FKCellAppUpdateCell`, `FKCellSkeletonRowCell`, `FKCellIndentedCell`, `FKCellInlineActionsCell`, `FKCellLiveBadgeCell`, `FKCellCourseProgressCell`, `FKCellReminderCell`, `FKCellNowPlayingCell`, `FKCellConflictCell`, `FKCellEnvironmentCell`, `FKCellComparisonCell` |
| Interactive long-tail | `FKCellCheckboxCell` (I-08), `FKCellFavoriteCell` (I-09), `FKCellSegmentCell` (I-10), `FKCellSliderCell` (I-11), `FKCellEditingCell` (I-12), `FKCellStepperCell` (I-13), `FKCellPreviewPickerCell` (I-15); I-14 → `FKCellSelectionCell` |
| Form long-tail | `FKFormCellEmailSuffixCell` (X-54), `FKFormCellSplitFieldCell` (X-55), `FKFormCellRangeCell`–`FKFormCellMapRadiusCell` (X-56–X-72), `FKFormCellConditionalVisibility` (X-41) |
| F-14–F-20 | `FKFormEmailRow`, `FKFormAmountRow`, `FKFormIDDocumentRow`, `FKFormURLRow`, `FKFormQuantityRow`, `FKFormAddressRow`, `FKFormBankCardRow` |
| Collection | `FKCellDisclosureCollectionCell`, `FKCellValueDisclosureCollectionCell`, `FKCellSwitchCollectionCell`, `FKCellProfileCollectionCell`, `FKCellConversationCollectionCell` |
| Integration | `FKListPresetItem`, `FKListPresetCellConfigurator` |
| Core | `FKCellCollectionReusable`, `FKCellCollectionRegistration` |

### Collection parity

Table and collection variants share Internal layout renderers (`FKCellDisclosureLayoutRenderer`, `FKCellConversationContentView`, …). Register with `fk_registerCellKitCollectionCells(.collection(FKCellDisclosureCollectionCell.self), …)` and dequeue via `collectionView.dequeue(FKCellDisclosureCollectionCell.self, for:)`.

### ListKit preset mapping

```swift
let item: FKListPresetItem = .disclosure(FKCellDisclosureRow(id: "settings", configuration: .init(title: "General")))
FKListPresetCellConfigurator.configure(cell: cell, with: item)
```

## Quick start (login form)

```swift
import FKUIKit

tableView.fk_registerCellKitCells(
  .table(FKFormCellTextFieldCell.self),
  .table(FKFormCellAgreementCell.self),
  .table(FKFormCellPrimaryButtonCell.self)
)
tableView.fk_registerFormSectionHeaderView()

// Email (F-01, X-01)
let emailCell = tableView.dequeue(FKFormCellTextFieldCell.self, for: indexPath)
emailCell.apply(.textField(layout: .underline, label: "Email", placeholder: "you@example.com", isRequired: true))

// Password (F-02, X-08)
let passwordCell = tableView.dequeue(FKFormCellTextFieldCell.self, for: indexPath)
passwordCell.apply(.password(layout: .underline, label: "Password"))

// Agreement (F-05, X-52)
let agreementCell = tableView.dequeue(FKFormCellAgreementCell.self, for: indexPath)
agreementCell.apply(FKFormCellAgreementConfiguration(text: "I agree to the Terms of Service", linkRanges: [...]))
agreementCell.onCheckedChanged = { isChecked in /* update model */ }

// Submit (F-09, X-49)
let submitCell = tableView.dequeue(FKFormCellPrimaryButtonCell.self, for: indexPath)
submitCell.apply(FKFormCellPrimaryButtonConfiguration(title: "Sign In"))
submitCell.onTap = { /* submit */ }
```

## Requirements

- iOS 15+
- Swift 6
- Depends on `FKCoreKit` (`FKCellReusable`), `FKTextField`, `FKButton`, `FKDivider`, `FKIconView`

## FKKitExamples

Entry: **FKUIKit → CellKit** in the demo app (`FKCellKitExamplesHubViewController`).

| Hub section | Scenarios |
|-------------|-----------|
| Getting Started | Standalone table, ListKit presets, Collection parity |
| Composed Flows | Settings (#1–9), Forms (#10–18), Display (#19–24), Phase 6 (#22–27) |
| Full Coverage | Cell type galleries (Settings / Display / Form), Stress scroll |

Path: `Examples/FKKitExamples/FKKitExamples/Examples/FKUIKit/CellKit/`

## License

Same as FKKit (see repository root).
