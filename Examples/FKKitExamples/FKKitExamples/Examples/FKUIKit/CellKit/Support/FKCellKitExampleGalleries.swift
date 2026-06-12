import FKUIKit
import UIKit

/// Full cell-type galleries grouped by CellKit domain.
@MainActor
enum FKCellKitExampleGalleries {
  static func settingsControlsGallery() -> FKCellKitExampleTableViewController {
    FKCellKitExampleTableViewController(
      title: "Settings Controls",
      sections: [
        FKCellKitExampleSection(title: "Controls", rows: [
          FKCellKitExampleSampleData.sampleCellCheckboxCell(),
          FKCellKitExampleSampleData.sampleCellEditingCell(),
          FKCellKitExampleSampleData.sampleCellFavoriteCell(),
          FKCellKitExampleSampleData.sampleCellIconSwitchCell(),
          FKCellKitExampleSampleData.sampleCellPickerCell(),
          FKCellKitExampleSampleData.sampleCellPreviewPickerCell(),
          FKCellKitExampleSampleData.sampleCellReorderCell(),
          FKCellKitExampleSampleData.sampleCellSegmentCell(),
          FKCellKitExampleSampleData.sampleCellSelectionCell(),
          FKCellKitExampleSampleData.sampleCellSliderCell(),
          FKCellKitExampleSampleData.sampleCellStepperCell(),
          FKCellKitExampleSampleData.sampleCellSwitchCell(),
        ]),
      ]
    )
  }

  static func generalDisplayGallery() -> FKCellKitExampleTableViewController {
    FKCellKitExampleTableViewController(
      title: "General Display",
      sections: [
        FKCellKitExampleSection(title: "Rows", rows: [
          FKCellKitExampleSampleData.sampleCellActionCell(),
          FKCellKitExampleSampleData.sampleCellAddressCell(),
          FKCellKitExampleSampleData.sampleCellArticleCell(),
          FKCellKitExampleSampleData.sampleCellAudioTrackCell(),
          FKCellKitExampleSampleData.sampleCellBadgeCell(),
          FKCellKitExampleSampleData.sampleCellContactCell(),
          FKCellKitExampleSampleData.sampleCellConversationCell(),
          FKCellKitExampleSampleData.sampleCellCopyableValueCell(),
          FKCellKitExampleSampleData.sampleCellDisclosureCell(),
          FKCellKitExampleSampleData.sampleCellExpandableCell(),
          FKCellKitExampleSampleData.sampleCellFileCell(),
          FKCellKitExampleSampleData.sampleCellFilterSummaryCell(),
          FKCellKitExampleSampleData.sampleCellIconDisclosureCell(),
          FKCellKitExampleSampleData.sampleCellIconValueDisclosureCell(),
          FKCellKitExampleSampleData.sampleCellInfoCell(),
          FKCellKitExampleSampleData.sampleCellInlineNoticeCell(),
          FKCellKitExampleSampleData.sampleCellKeyValueCell(),
          FKCellKitExampleSampleData.sampleCellLinkCell(),
          FKCellKitExampleSampleData.sampleCellLoadMoreCell(),
          FKCellKitExampleSampleData.sampleCellMediaThumbnailCell(),
          FKCellKitExampleSampleData.sampleCellNotificationCell(),
          FKCellKitExampleSampleData.sampleCellPaymentMethodCell(),
          FKCellKitExampleSampleData.sampleCellPresenceCell(),
          FKCellKitExampleSampleData.sampleCellProductCell(),
          FKCellKitExampleSampleData.sampleCellProfileCell(),
          FKCellKitExampleSampleData.sampleCellProgressCell(),
          FKCellKitExampleSampleData.sampleCellRatingCell(),
          FKCellKitExampleSampleData.sampleCellRecentSearchCell(),
          FKCellKitExampleSampleData.sampleCellSearchResultCell(),
          FKCellKitExampleSampleData.sampleCellSortFilterBarCell(),
          FKCellKitExampleSampleData.sampleCellStackedKeyValueCell(),
          FKCellKitExampleSampleData.sampleCellStatusCell(),
          FKCellKitExampleSampleData.sampleCellSyncStatusCell(),
          FKCellKitExampleSampleData.sampleCellTagCell(),
          FKCellKitExampleSampleData.sampleCellTipCell(),
          FKCellKitExampleSampleData.sampleCellValueDisclosureCell(),
          FKCellKitExampleSampleData.sampleCellZeroResultsCell(),
        ]),
      ]
    )
  }

  static func richDisplayGallery() -> FKCellKitExampleTableViewController {
    FKCellKitExampleTableViewController(
      title: "Rich Display",
      sections: [
        FKCellKitExampleSection(title: "Cards", rows: [
          FKCellKitExampleSampleData.sampleCellAlertActionCell(),
          FKCellKitExampleSampleData.sampleCellCouponCell(),
          FKCellKitExampleSampleData.sampleCellFeatureCardCell(),
          FKCellKitExampleSampleData.sampleCellHeroCell(),
          FKCellKitExampleSampleData.sampleCellImageCardCell(),
          FKCellKitExampleSampleData.sampleCellRegulatoryCell(),
          FKCellKitExampleSampleData.sampleCellRichTextCell(),
          FKCellKitExampleSampleData.sampleCellStatusDetailCell(),
          FKCellKitExampleSampleData.sampleCellStorageSummaryCell(),
          FKCellKitExampleSampleData.sampleCellThumbnailStripCell(),
          FKCellKitExampleSampleData.sampleCellTimelineNodeCell(),
        ]),
      ]
    )
  }

  static func longTailDisplayGallery() -> FKCellKitExampleTableViewController {
    FKCellKitExampleTableViewController(
      title: "Long-Tail Display",
      sections: [
        FKCellKitExampleSection(title: "Rows", rows: [
          FKCellKitExampleSampleData.sampleCellActivityCell(),
          FKCellKitExampleSampleData.sampleCellAppUpdateCell(),
          FKCellKitExampleSampleData.sampleCellComparisonCell(),
          FKCellKitExampleSampleData.sampleCellConflictCell(),
          FKCellKitExampleSampleData.sampleCellCourseProgressCell(),
          FKCellKitExampleSampleData.sampleCellDeviceCell(),
          FKCellKitExampleSampleData.sampleCellEnvironmentCell(),
          FKCellKitExampleSampleData.sampleCellEventCell(),
          FKCellKitExampleSampleData.sampleCellIndentedCell(),
          FKCellKitExampleSampleData.sampleCellInlineActionsCell(),
          FKCellKitExampleSampleData.sampleCellInlineEmptyCell(),
          FKCellKitExampleSampleData.sampleCellLanguageCell(),
          FKCellKitExampleSampleData.sampleCellLeaderboardCell(),
          FKCellKitExampleSampleData.sampleCellLiveBadgeCell(),
          FKCellKitExampleSampleData.sampleCellMarqueeCell(),
          FKCellKitExampleSampleData.sampleCellMonospaceBlockCell(),
          FKCellKitExampleSampleData.sampleCellNetworkCell(),
          FKCellKitExampleSampleData.sampleCellNowPlayingCell(),
          FKCellKitExampleSampleData.sampleCellPlayableMediaCell(),
          FKCellKitExampleSampleData.sampleCellPollResultCell(),
          FKCellKitExampleSampleData.sampleCellQuoteCell(),
          FKCellKitExampleSampleData.sampleCellReminderCell(),
          FKCellKitExampleSampleData.sampleCellReviewCell(),
          FKCellKitExampleSampleData.sampleCellShortcutGridCell(),
          FKCellKitExampleSampleData.sampleCellSkeletonRowCell(),
          FKCellKitExampleSampleData.sampleCellStepListCell(),
          FKCellKitExampleSampleData.sampleCellSubscriptionPlanCell(),
          FKCellKitExampleSampleData.sampleCellTaskCell(),
          FKCellKitExampleSampleData.sampleCellTransactionCell(),
        ]),
      ]
    )
  }

  static func formCellsGallery() -> FKCellKitExampleTableViewController {
    FKCellKitExampleTableViewController(
      title: "Form Cells",
      sections: [
        FKCellKitExampleSection(title: "Fields", rows: [
          FKCellKitExampleSampleData.sampleFormCellAgreementCell(),
          FKCellKitExampleSampleData.sampleFormCellBiometricCell(),
          FKCellKitExampleSampleData.sampleFormCellCalculatedPreviewCell(),
          FKCellKitExampleSampleData.sampleFormCellCaptchaCell(),
          FKCellKitExampleSampleData.sampleFormCellCharacterCountFooterCell(),
          FKCellKitExampleSampleData.sampleFormCellCheckboxGroupCell(),
          FKCellKitExampleSampleData.sampleFormCellColorCell(),
          FKCellKitExampleSampleData.sampleFormCellDateCell(),
          FKCellKitExampleSampleData.sampleFormCellDragUploadCell(),
          FKCellKitExampleSampleData.sampleFormCellDualButtonCell(),
          FKCellKitExampleSampleData.sampleFormCellEmailSuffixCell(),
          FKCellKitExampleSampleData.sampleFormCellEmojiPickerCell(),
          FKCellKitExampleSampleData.sampleFormCellFilterChipsCell(),
          FKCellKitExampleSampleData.sampleFormCellInlineExpandCell(),
          FKCellKitExampleSampleData.sampleFormCellInlineWheelCell(),
          FKCellKitExampleSampleData.sampleFormCellLinkButtonCell(),
          FKCellKitExampleSampleData.sampleFormCellMapRadiusCell(),
          FKCellKitExampleSampleData.sampleFormCellMediaGridCell(),
          FKCellKitExampleSampleData.sampleFormCellMediaPickerCell(),
          FKCellKitExampleSampleData.sampleFormCellMultilineCell(),
          FKCellKitExampleSampleData.sampleFormCellNPSScaleCell(),
          FKCellKitExampleSampleData.sampleFormCellOTPCell(),
          FKCellKitExampleSampleData.sampleFormCellPINIndicatorCell(),
          FKCellKitExampleSampleData.sampleFormCellPhoneCell(),
          FKCellKitExampleSampleData.sampleFormCellPickerCell(),
          FKCellKitExampleSampleData.sampleFormCellPrimaryButtonCell(),
          FKCellKitExampleSampleData.sampleFormCellRadioGroupCell(),
          FKCellKitExampleSampleData.sampleFormCellRangeCell(),
          FKCellKitExampleSampleData.sampleFormCellRichTextEditorCell(),
          FKCellKitExampleSampleData.sampleFormCellSMSCodeCell(),
          FKCellKitExampleSampleData.sampleFormCellSearchCell(),
          FKCellKitExampleSampleData.sampleFormCellSegmentCell(),
          FKCellKitExampleSampleData.sampleFormCellSettingsLinkCell(),
          FKCellKitExampleSampleData.sampleFormCellSocialAccountCell(),
          FKCellKitExampleSampleData.sampleFormCellSplitFieldCell(),
          FKCellKitExampleSampleData.sampleFormCellSwitchCaptionCell(),
          FKCellKitExampleSampleData.sampleFormCellSystemPickerCell(),
          FKCellKitExampleSampleData.sampleFormCellTextFieldCell(),
          FKCellKitExampleSampleData.sampleFormCellTimeCell(),
          FKCellKitExampleSampleData.sampleFormCellVoiceInputCell(),
        ]),
      ]
    )
  }

  /// Legacy single-screen gallery combining every table cell type.
  static func allCellsGallery() -> FKCellKitExampleTableViewController {
    let sections = [
      settingsControlsGallery().demoSections[0],
      generalDisplayGallery().demoSections[0],
      richDisplayGallery().demoSections[0],
      longTailDisplayGallery().demoSections[0],
      formCellsGallery().demoSections[0],
    ]
    return FKCellKitExampleTableViewController(title: "All Cell Types", sections: sections)
  }
}
