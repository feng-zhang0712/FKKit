import FKCoreKit
import FKUIKit
import UIKit

/// Demo callbacks shared across CellKit examples.
@MainActor
final class FKCellKitExampleCallbacks {
  var onToast: ((String) -> Void)?
  var onSwitchChanged: ((String, Bool) -> Void)?
  var onLinkTapped: ((String) -> Void)?
  var onSelectionChanged: ((String) -> Void)?
  var onAction: ((String) -> Void)?
}

/// Type-erased table row for CellKit demos.
@MainActor
struct FKCellKitExampleRow {
  let register: (UITableView) -> Void
  let dequeue: (UITableView, IndexPath) -> UITableViewCell
  let title: String

  static func make<Cell: FKCellReusable>(
    _ type: Cell.Type,
    title: String,
    configure: @MainActor @escaping (Cell) -> Void
  ) -> FKCellKitExampleRow {
    FKCellKitExampleRow(
      register: { $0.register(Cell.self) },
      dequeue: { tableView, indexPath in
        let cell = tableView.dequeue(Cell.self, for: indexPath)
        configure(cell)
        return cell
      },
      title: title
    )
  }
}

@MainActor
struct FKCellKitExampleSection {
  var title: String?
  var footer: String?
  var headerConfiguration: FKCellSectionHeaderConfiguration?
  var footerConfiguration: FKCellSectionFooterConfiguration?
  var rows: [FKCellKitExampleRow]
}

/// Builds sample rows for gallery scenarios.
@MainActor
enum FKCellKitExampleSampleData {
  static func sampleCellActionCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellActionCell.self, title: "Action") { cell in
      cell.configure(with: FKCellActionRow(id: "demo-id", title: "Action", style: .default, alignment: .leading, isEnabled: true, separatorPolicy: .automatic, isLastInSection: true))
    }
  }

  static func sampleCellActivityCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellActivityCell.self, title: "Activity") { cell in
      cell.configure(with: FKCellActivityRow(id: "demo-id", configuration: FKCellActivityConfiguration(actorName: "Demo", actionText: "Sample", targetPreview: nil, timestamp: nil, avatarConfiguration: .init(), isEnabled: true, separatorPolicy: .automatic, isLastInSection: false), imageURL: nil, image: nil))
    }
  }

  static func sampleCellAddressCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellAddressCell.self, title: "Address") { cell in
      cell.configure(with: FKCellAddressRow(id: "demo-id", configuration: FKCellAddressConfiguration(addressLines: ["Sample"], contactLine: nil, badge: nil, showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellAlertActionCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellAlertActionCell.self, title: "AlertAction") { cell in
      cell.configure(with: FKCellAlertActionRow(id: "demo-id", configuration: FKCellAlertActionConfiguration(title: "AlertAction", warningSymbolName: nil, body: "Detail", primaryAction: FKCellActionLink(title: "Learn More"), separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellAppUpdateCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellAppUpdateCell.self, title: "AppUpdate") { cell in
      cell.configure(with: FKCellAppUpdateRow(id: "demo-id", configuration: FKCellAppUpdateConfiguration(versionText: "Sample", releaseNotes: nil, showsUpdateBadge: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellArticleCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellArticleCell.self, title: "Article") { cell in
      cell.configure(with: FKCellArticleRow(id: "demo-id", configuration: FKCellArticleConfiguration(thumbnail: nil, title: "Article", source: nil, timestamp: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellAudioTrackCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellAudioTrackCell.self, title: "AudioTrack") { cell in
      cell.configure(with: FKCellAudioTrackRow(id: "demo-id", configuration: FKCellAudioTrackConfiguration(cover: FKCellImageContent(), title: "AudioTrack", artist: nil, duration: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellBadgeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellBadgeCell.self, title: "Badge") { cell in
      cell.configure(with: FKCellBadgeRow(id: "demo-id", configuration: FKCellBadgeConfiguration(leadingIcon: FKCellIconContent(symbolName: "star.fill"), title: "Badge", subtitle: nil, badgeConfiguration: FKBadgeConfiguration(), badgeCount: 0, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellCheckboxCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellCheckboxCell.self, title: "Checkbox") { cell in
      cell.configure(with: FKCellCheckboxRow(id: "demo-id", configuration: FKCellCheckboxConfiguration(title: "Checkbox", subtitle: nil, isChecked: false, placement: .leading, togglesOnRowTap: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellComparisonCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellComparisonCell.self, title: "Comparison") { cell in
      cell.configure(with: FKCellComparisonRow(id: "demo-id", configuration: FKCellComparisonConfiguration(leftTitle: "Comparison", leftValue: "Value", rightTitle: "Comparison", rightValue: "Value", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellConflictCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellConflictCell.self, title: "Conflict") { cell in
      cell.configure(with: FKCellConflictRow(id: "demo-id", configuration: FKCellConflictConfiguration(message: "Sample", detail: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellContactCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellContactCell.self, title: "Contact") { cell in
      cell.configure(with: FKCellContactRow(id: "demo-id", imageURL: nil, image: nil, configuration: FKCellContactConfiguration(avatarConfiguration: FKAvatarConfiguration(), name: "Demo", detail: nil, showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellConversationCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellConversationCell.self, title: "Conversation") { cell in
      cell.configure(with: FKCellConversationRow(id: "demo-id", imageURL: nil, image: nil, configuration: FKCellConversationConfiguration(avatarConfiguration: FKAvatarConfiguration(), title: "Conversation", preview: nil, timestamp: nil, unread: FKCellUnreadPresentation(), isPinned: false, isMuted: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellCopyableValueCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellCopyableValueCell.self, title: "CopyableValue") { cell in
      cell.configure(with: FKCellCopyableValueRow(id: "demo-id", configuration: FKCellCopyableValueConfiguration(label: "Label", value: "Value", copyChipConfiguration: nil, usesMonospaceValue: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellCouponCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellCouponCell.self, title: "Coupon") { cell in
      cell.configure(with: FKCellCouponRow(id: "demo-id", configuration: FKCellCouponConfiguration(accentColor: .label, amountText: "$12.00", title: "Coupon", rulesText: "Sample", actionTitle: nil, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellCourseProgressCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellCourseProgressCell.self, title: "CourseProgress") { cell in
      cell.configure(with: FKCellCourseProgressRow(id: "demo-id", configuration: FKCellCourseProgressConfiguration(courseTitle: "CourseProgress", progress: 0.72, percentText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellDeviceCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellDeviceCell.self, title: "Device") { cell in
      cell.configure(with: FKCellDeviceRow(id: "demo-id", configuration: FKCellDeviceConfiguration(deviceName: "Demo", statusText: "Sample", statusStyle: .info, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellDisclosureCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellDisclosureCell.self, title: "Disclosure") { cell in
      cell.configure(with: FKCellDisclosureRow(id: "demo-id", title: "Disclosure", isEnabled: true, showsDisclosure: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellEditingCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellEditingCell.self, title: "Editing") { cell in
      cell.configure(with: FKCellEditingRow(id: "demo-id", configuration: FKCellEditingConfiguration(title: "Editing", subtitle: nil, showsReorderControl: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellEnvironmentCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellEnvironmentCell.self, title: "Environment") { cell in
      cell.configure(with: FKCellEnvironmentRow(id: "demo-id", configuration: FKCellEnvironmentConfiguration(name: "Demo", token: "Sample", dotColor: .label, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellEventCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellEventCell.self, title: "Event") { cell in
      cell.configure(with: FKCellEventRow(id: "demo-id", configuration: FKCellEventConfiguration(monthText: "Sample", dayText: "Sample", title: "Event", subtitle: nil, accentColor: .label, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellExpandableCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellExpandableCell.self, title: "Expandable") { cell in
      cell.configure(with: FKCellExpandableRow(id: "demo-id", configuration: FKCellExpandableConfiguration(title: "Expandable", body: nil, isExpanded: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellFavoriteCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellFavoriteCell.self, title: "Favorite") { cell in
      cell.configure(with: FKCellFavoriteRow(id: "demo-id", configuration: FKCellFavoriteConfiguration(title: "Favorite", subtitle: nil, isFavorite: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellFeatureCardCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellFeatureCardCell.self, title: "FeatureCard") { cell in
      cell.configure(with: FKCellFeatureCardRow(id: "demo-id", configuration: FKCellFeatureCardConfiguration(icon: FKCellIconContent(symbolName: "star.fill"), title: "FeatureCard", description: "Description text.", primaryAction: FKCellActionLink(title: "Learn More"), separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellFileCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellFileCell.self, title: "File") { cell in
      cell.configure(with: FKCellFileRow(id: "demo-id", configuration: FKCellFileConfiguration(fileIcon: FKCellIconContent(symbolName: "star.fill"), fileName: "Demo", meta: nil, cloudState: nil, showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellFilterSummaryCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellFilterSummaryCell.self, title: "FilterSummary") { cell in
      cell.configure(with: FKCellFilterSummaryRow(id: "demo-id", configuration: FKCellFilterSummaryConfiguration(chipLabels: ["Sample"], clearButtonTitle: "Clear", showsClearButton: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellHeroCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellHeroCell.self, title: "Hero") { cell in
      cell.configure(with: FKCellHeroRow(id: "demo-id", configuration: FKCellHeroConfiguration(icon: FKCellIconContent(symbolName: "star.fill"), title: "Hero", description: "Description text.", textAlignment: .natural, separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellIconDisclosureCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellIconDisclosureCell.self, title: "IconDisclosure") { cell in
      cell.configure(with: FKCellIconDisclosureRow(id: "demo-id", icon: FKCellIconContent(symbolName: "star.fill"), title: "IconDisclosure", showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellIconSwitchCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellIconSwitchCell.self, title: "IconSwitch") { cell in
      cell.configure(with: FKCellIconSwitchRow(id: "demo-id", icon: FKCellIconContent(symbolName: "star.fill"), title: "IconSwitch", subtitle: nil, isOn: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellIconValueDisclosureCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellIconValueDisclosureCell.self, title: "IconValueDisclosure") { cell in
      cell.configure(with: FKCellIconValueDisclosureRow(id: "demo-id", icon: FKCellIconContent(symbolName: "star.fill"), title: "IconValueDisclosure", subtitle: nil, value: "Value", showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellImageCardCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellImageCardCell.self, title: "ImageCard") { cell in
      cell.configure(with: FKCellImageCardRow(id: "demo-id", configuration: FKCellImageCardConfiguration(image: FKCellImageContent(), title: "ImageCard", summary: "Sample", separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellIndentedCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellIndentedCell.self, title: "Indented") { cell in
      cell.configure(with: FKCellIndentedRow(id: "demo-id", configuration: FKCellIndentedConfiguration(title: "Indented", subtitle: nil, indentLevel: 1, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellInfoCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellInfoCell.self, title: "Info") { cell in
      cell.configure(with: FKCellInfoRow(id: "demo-id", icon: FKCellIconContent(symbolName: "star.fill"), title: "Info", subtitles: ["Sample"], isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellInlineActionsCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellInlineActionsCell.self, title: "InlineActions") { cell in
      cell.configure(with: FKCellInlineActionsRow(
        id: "demo-id",
        configuration: FKCellInlineActionsConfiguration(actions: [
          FKCellInlineAction(title: "Edit"),
          FKCellInlineAction(title: "Delete", isDestructive: true),
        ])
      ))
    }
  }

  static func sampleCellInlineEmptyCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellInlineEmptyCell.self, title: "InlineEmpty") { cell in
      cell.configure(with: FKCellInlineEmptyRow(id: "demo-id", configuration: FKCellInlineEmptyConfiguration(title: "InlineEmpty", message: nil, iconSymbolName: "tray", actionTitle: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellInlineNoticeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellInlineNoticeCell.self, title: "InlineNotice") { cell in
      cell.configure(with: FKCellInlineNoticeRow(id: "demo-id", configuration: FKCellInlineNoticeConfiguration(message: "Sample", backgroundColor: .label, textColor: .label, showsCloseButton: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellKeyValueCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellKeyValueCell.self, title: "KeyValue") { cell in
      cell.configure(with: FKCellKeyValueRow(id: "demo-id", title: "KeyValue", value: "Value", valueEmphasis: .secondary, valueNumberOfLines: 1, isSelectable: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellLanguageCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellLanguageCell.self, title: "Language") { cell in
      cell.configure(with: FKCellLanguageRow(id: "demo-id", configuration: FKCellLanguageConfiguration(languageName: "Demo", nativeName: nil, flagIcon: FKCellIconContent(symbolName: "star.fill"), isSelected: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellLeaderboardCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellLeaderboardCell.self, title: "Leaderboard") { cell in
      cell.configure(with: FKCellLeaderboardRow(id: "demo-id", configuration: FKCellLeaderboardConfiguration(rank: 1, name: "Demo", scoreText: "980", avatarConfiguration: .init(), isEnabled: true, separatorPolicy: .automatic, isLastInSection: false), imageURL: nil, image: nil))
    }
  }

  static func sampleCellLinkCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellLinkCell.self, title: "Link") { cell in
      cell.configure(with: FKCellLinkRow(id: "demo-id", title: "Link", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellLiveBadgeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellLiveBadgeCell.self, title: "LiveBadge") { cell in
      cell.configure(with: FKCellLiveBadgeRow(id: "demo-id", configuration: FKCellLiveBadgeConfiguration(title: "LiveBadge", liveBadgeText: "LIVE", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellLoadMoreCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellLoadMoreCell.self, title: "LoadMore") { cell in
      cell.configure(with: FKCellLoadMoreRow(id: "demo-id", configuration: FKCellLoadMoreConfiguration(title: "Load more", isLoading: false, isEnabled: true)))
    }
  }

  static func sampleCellMarqueeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellMarqueeCell.self, title: "Marquee") { cell in
      cell.configure(with: FKCellMarqueeRow(id: "demo-id", configuration: FKCellMarqueeConfiguration(text: "Sample", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellMediaThumbnailCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellMediaThumbnailCell.self, title: "MediaThumbnail") { cell in
      cell.configure(with: FKCellMediaThumbnailRow(id: "demo-id", configuration: FKCellMediaThumbnailConfiguration(image: FKCellImageContent(), title: "MediaThumbnail", subtitle: nil, durationBadge: nil, showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellMonospaceBlockCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellMonospaceBlockCell.self, title: "MonospaceBlock") { cell in
      cell.configure(with: FKCellMonospaceBlockRow(id: "demo-id", configuration: FKCellMonospaceBlockConfiguration(codeText: "Sample", maxLines: 4, showsExpand: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellNetworkCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellNetworkCell.self, title: "Network") { cell in
      cell.configure(with: FKCellNetworkRow(id: "demo-id", configuration: FKCellNetworkConfiguration(networkName: "Demo", statusText: "Sample", statusStyle: .info, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellNotificationCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellNotificationCell.self, title: "Notification") { cell in
      cell.configure(with: FKCellNotificationRow(id: "demo-id", configuration: FKCellNotificationConfiguration(icon: FKCellIconContent(symbolName: "star.fill"), title: "Notification", body: nil, timestamp: nil, unread: FKCellUnreadPresentation(), isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellNowPlayingCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellNowPlayingCell.self, title: "NowPlaying") { cell in
      cell.configure(with: FKCellNowPlayingRow(id: "demo-id", configuration: FKCellNowPlayingConfiguration(title: "NowPlaying", artist: nil, cover: FKCellImageContent(), isPlaying: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellPaymentMethodCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellPaymentMethodCell.self, title: "PaymentMethod") { cell in
      cell.configure(with: FKCellPaymentMethodRow(id: "demo-id", configuration: FKCellPaymentMethodConfiguration(brandIcon: FKCellIconContent(symbolName: "star.fill"), maskedNumber: "Sample", expiry: nil, badge: nil, showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellPickerCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellPickerCell.self, title: "Picker") { cell in
      cell.configure(with: FKCellPickerRow(id: "demo-id", configuration: FKCellPickerConfiguration(title: "Picker", icon: FKCellIconContent(symbolName: "star.fill"), value: "Value", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellPlayableMediaCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellPlayableMediaCell.self, title: "PlayableMedia") { cell in
      cell.configure(with: FKCellPlayableMediaRow(id: "demo-id", configuration: FKCellPlayableMediaConfiguration(title: "PlayableMedia", subtitle: nil, cover: FKCellImageContent(), isNowPlaying: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellPollResultCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellPollResultCell.self, title: "PollResult") { cell in
      cell.configure(with: FKCellPollResultRow(id: "demo-id", configuration: FKCellPollResultConfiguration(optionTitle: "PollResult", percent: 0, percentText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellPresenceCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellPresenceCell.self, title: "Presence") { cell in
      cell.configure(with: FKCellPresenceRow(id: "demo-id", imageURL: nil, image: nil, configuration: FKCellPresenceConfiguration(avatarConfiguration: FKAvatarConfiguration(), name: "Demo", statusText: nil, presenceState: .offline, timestamp: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellPreviewPickerCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellPreviewPickerCell.self, title: "PreviewPicker") { cell in
      cell.configure(with: FKCellPreviewPickerRow(id: "demo-id", configuration: FKCellPreviewPickerConfiguration(title: "PreviewPicker", value: "Value", icon: FKCellIconContent(symbolName: "star.fill"), previewImage: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellProductCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellProductCell.self, title: "Product") { cell in
      cell.configure(with: FKCellProductRow(id: "demo-id", configuration: FKCellProductConfiguration(image: FKCellImageContent(), title: "Product", specText: nil, price: "Sample", quantityText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellProfileCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellProfileCell.self, title: "Profile") { cell in
      cell.configure(with: FKCellProfileRow(id: "demo-id", imageURL: nil, image: nil, displayName: nil, configuration: FKCellProfileConfiguration(layout: .horizontal, avatarConfiguration: FKAvatarConfiguration(), title: "Profile", subtitle: nil, accessory: .disclosure, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellProgressCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellProgressCell.self, title: "Progress") { cell in
      cell.configure(with: FKCellProgressRow(id: "demo-id", configuration: FKCellProgressConfiguration(leadingIcon: FKCellIconContent(symbolName: "star.fill"), title: "Progress", progress: 0, percentText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellQuoteCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellQuoteCell.self, title: "Quote") { cell in
      cell.configure(with: FKCellQuoteRow(id: "demo-id", configuration: FKCellQuoteConfiguration(quoteText: "Sample", attribution: nil, isItalic: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellRatingCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellRatingCell.self, title: "Rating") { cell in
      cell.configure(with: FKCellRatingRow(id: "demo-id", configuration: FKCellRatingConfiguration(rating: 0.72, maxRating: 5, reviewCountText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellRecentSearchCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellRecentSearchCell.self, title: "RecentSearch") { cell in
      cell.configure(with: FKCellRecentSearchRow(id: "demo-id", configuration: FKCellRecentSearchConfiguration(query: "Sample", showsDeleteButton: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellRegulatoryCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellRegulatoryCell.self, title: "Regulatory") { cell in
      cell.configure(with: FKCellRegulatoryRow(
        id: "demo-id",
        configuration: FKCellRegulatoryConfiguration(
          regionTitle: "United States",
          contentBlocks: [.text("Model identification and regulatory compliance information.")],
          footerMetadata: "FK-DEMO-001",
          separatorPolicy: .automatic,
          isLastInSection: false
        )
      ))
    }
  }

  static func sampleCellReminderCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellReminderCell.self, title: "Reminder") { cell in
      cell.configure(with: FKCellReminderRow(id: "demo-id", configuration: FKCellReminderConfiguration(title: "Reminder", timeText: "Sample", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellReorderCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellReorderCell.self, title: "Reorder") { cell in
      cell.configure(with: FKCellReorderRow(id: "demo-id", configuration: FKCellReorderConfiguration(title: "Reorder", subtitle: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellReviewCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellReviewCell.self, title: "Review") { cell in
      cell.configure(with: FKCellReviewRow(id: "demo-id", configuration: FKCellReviewConfiguration(authorName: "Demo", excerpt: "Sample", rating: 0.72, maxRating: 5, timestamp: nil, avatarConfiguration: .init(), isEnabled: true, separatorPolicy: .automatic, isLastInSection: false), imageURL: nil, image: nil))
    }
  }

  static func sampleCellRichTextCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellRichTextCell.self, title: "RichText") { cell in
      cell.configure(with: FKCellRichTextRow(id: "demo-id", configuration: FKCellRichTextConfiguration(style: .standard, leadingIcon: FKCellIconContent(symbolName: "star.fill"), title: "RichText", body: "Detail", bodyLinkRanges: [], footerAction: FKCellActionLink(title: "Learn More"), separatorBeforeFooter: true, timestamp: nil, separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellSearchResultCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSearchResultCell.self, title: "SearchResult") { cell in
      cell.configure(with: FKCellSearchResultRow(id: "demo-id", configuration: FKCellSearchResultConfiguration(title: "SearchResult", subtitle: nil, query: "", leadingIcon: FKCellIconContent(symbolName: "star.fill"), isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellSegmentCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSegmentCell.self, title: "Segment") { cell in
      cell.configure(with: FKCellSegmentRow(id: "demo-id", configuration: FKCellSegmentConfiguration(segments: ["Sample"], selectedIndex: 0, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellSelectionCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSelectionCell.self, title: "Selection") { cell in
      cell.configure(with: FKCellSelectionRow(id: "demo-id", title: "Selection", subtitle: nil, isSelected: false, selectionMode: .single, reservesLeadingSpaceWhenUnselected: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellShortcutGridCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellShortcutGridCell.self, title: "ShortcutGrid") { cell in
      cell.configure(with: FKCellShortcutGridRow(
        id: "demo-id",
        configuration: FKCellShortcutGridConfiguration(items: [
          FKCellShortcutItem(title: "Scan", icon: FKCellIconContent(symbolName: "qrcode.viewfinder")),
          FKCellShortcutItem(title: "Pay", icon: FKCellIconContent(symbolName: "creditcard")),
          FKCellShortcutItem(title: "Send", icon: FKCellIconContent(symbolName: "paperplane")),
          FKCellShortcutItem(title: "More", icon: FKCellIconContent(symbolName: "ellipsis")),
        ])
      ))
    }
  }

  static func sampleCellSkeletonRowCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSkeletonRowCell.self, title: "SkeletonRow") { cell in
      cell.configure(with: FKCellSkeletonRowRow(id: "demo-id", configuration: FKCellSkeletonRowConfiguration(lineCount: 2, isEnabled: true, separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellSliderCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSliderCell.self, title: "Slider") { cell in
      cell.configure(with: FKCellSliderRow(id: "demo-id", configuration: FKCellSliderConfiguration(title: "Slider", value: 0.72, minimumValue: 0, maximumValue: 1, valueText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellSortFilterBarCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSortFilterBarCell.self, title: "SortFilterBar") { cell in
      cell.configure(with: FKCellSortFilterBarRow(id: "demo-id", configuration: FKCellSortFilterBarConfiguration(sortTitle: "Sort", filterTitle: "Filter", showsSort: true, showsFilter: true, isEnabled: true)))
    }
  }

  static func sampleCellStackedKeyValueCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellStackedKeyValueCell.self, title: "StackedKeyValue") { cell in
      cell.configure(with: FKCellStackedKeyValueRow(
        id: "demo-id",
        configuration: FKCellStackedKeyValueConfiguration(entries: [
          FKCellStackedKeyValueEntry(title: "Subtotal", value: "$42.00"),
          FKCellStackedKeyValueEntry(title: "Shipping", value: "Free", valueEmphasis: .primary),
        ])
      ))
    }
  }

  static func sampleCellStatusCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellStatusCell.self, title: "Status") { cell in
      cell.configure(with: FKCellStatusRow(id: "demo-id", configuration: FKCellStatusConfiguration(leadingIcon: FKCellIconContent(symbolName: "star.fill"), title: "Status", trailing: .none, badgeCount: 0, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellStatusDetailCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellStatusDetailCell.self, title: "StatusDetail") { cell in
      cell.configure(with: FKCellStatusDetailRow(id: "demo-id", configuration: FKCellStatusDetailConfiguration(leadingIcon: FKCellIconContent(symbolName: "star.fill"), title: "StatusDetail", statusText: nil, statusColor: .label, body: "Detail", bodyLinkRanges: [], footerAction: FKCellActionLink(title: "Learn More"), separatorBeforeFooter: true, separatorPolicy: .automatic, isLastInSection: true)))
    }
  }

  static func sampleCellStepListCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellStepListCell.self, title: "StepList") { cell in
      cell.configure(with: FKCellStepListRow(id: "demo-id", configuration: FKCellStepListConfiguration(stepNumber: 0, title: "StepList", detail: nil, state: .pending, statusText: nil, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellStepperCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellStepperCell.self, title: "Stepper") { cell in
      cell.configure(with: FKCellStepperRow(id: "demo-id", configuration: FKCellStepperConfiguration(title: "Stepper", value: 0.72, minimumValue: 0, maximumValue: 100, stepValue: 1, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellStorageSummaryCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellStorageSummaryCell.self, title: "StorageSummary") { cell in
      cell.configure(with: FKCellStorageSummaryRow(
        id: "demo-id",
        configuration: FKCellStorageSummaryConfiguration(
          title: "iPhone Storage",
          usageText: "128 GB of 256 GB used",
          segments: [
            FKCellStorageSegment(name: "Apps", color: .systemBlue, proportion: 0.42),
            FKCellStorageSegment(name: "Photos", color: .systemGreen, proportion: 0.28),
            FKCellStorageSegment(name: "System", color: .systemGray, proportion: 0.18),
          ],
          progress: 0.5,
          separatorPolicy: .automatic,
          isLastInSection: true
        )
      ))
    }
  }

  static func sampleCellSubscriptionPlanCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSubscriptionPlanCell.self, title: "SubscriptionPlan") { cell in
      cell.configure(with: FKCellSubscriptionPlanRow(id: "demo-id", configuration: FKCellSubscriptionPlanConfiguration(planName: "Demo", priceText: "Sample", features: ["Sample"], isSelected: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellSwitchCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSwitchCell.self, title: "Switch") { cell in
      cell.configure(with: FKCellSwitchRow(id: "demo-id", title: "Switch", isOn: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellSyncStatusCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellSyncStatusCell.self, title: "SyncStatus") { cell in
      cell.configure(with: FKCellSyncStatusRow(id: "demo-id", configuration: FKCellSyncStatusConfiguration(title: "SyncStatus", statusText: nil, syncState: .idle, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellTagCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellTagCell.self, title: "Tag") { cell in
      cell.configure(with: FKCellTagRow(id: "demo-id", configuration: FKCellTagConfiguration(title: nil, chipLabels: ["Sample"], isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellTaskCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellTaskCell.self, title: "Task") { cell in
      cell.configure(with: FKCellTaskRow(id: "demo-id", configuration: FKCellTaskConfiguration(title: "Task", dueDateText: nil, isCompleted: false, isOverdue: false, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellThumbnailStripCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellThumbnailStripCell.self, title: "ThumbnailStrip") { cell in
      cell.configure(with: FKCellThumbnailStripRow(id: "demo-id", configuration: FKCellThumbnailStripConfiguration(thumbnails: [FKCellImageContent()], itemSize: 72, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellTimelineNodeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellTimelineNodeCell.self, title: "TimelineNode") { cell in
      cell.configure(with: FKCellTimelineNodeRow(id: "demo-id", configuration: FKCellTimelineNodeConfiguration(state: .completed, title: "TimelineNode", subtitle: nil, timestamp: nil, isFirst: false, isLast: false, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellTipCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellTipCell.self, title: "Tip") { cell in
      cell.configure(with: FKCellTipRow(id: "demo-id", configuration: FKCellTipConfiguration(text: "Sample", isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellTransactionCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellTransactionCell.self, title: "Transaction") { cell in
      cell.configure(with: FKCellTransactionRow(id: "demo-id", configuration: FKCellTransactionConfiguration(title: "Transaction", subtitle: nil, amountText: "$12.00", kind: .neutral, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false)))
    }
  }

  static func sampleCellValueDisclosureCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellValueDisclosureCell.self, title: "ValueDisclosure") { cell in
      cell.configure(with: FKCellValueDisclosureRow(id: "demo-id", title: "ValueDisclosure", value: "Value", valueNumberOfLines: 1, showsDisclosure: true, isEnabled: true, separatorPolicy: .automatic, isLastInSection: false))
    }
  }

  static func sampleCellZeroResultsCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKCellZeroResultsCell.self, title: "ZeroResults") { cell in
      cell.configure(with: FKCellZeroResultsRow(id: "demo-id", configuration: FKCellZeroResultsConfiguration(iconSymbolName: "magnifyingglass", title: "ZeroResults", subtitle: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellAgreementCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellAgreementCell.self, title: "Agreement") { cell in
      cell.configure(with: FKFormAgreementRow(id: "demo-id", text: "Sample", linkRanges: [], isChecked: false, isEnabled: true))
    }
  }

  static func sampleFormCellBiometricCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellBiometricCell.self, title: "Biometric") { cell in
      cell.configure(with: FKFormCellBiometricRow(id: "demo-id", text: "", configuration: FKFormCellBiometricConfiguration(label: nil, buttonTitle: "Authenticate", authReason: "Confirm your identity", errorText: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellCalculatedPreviewCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellCalculatedPreviewCell.self, title: "CalculatedPreview") { cell in
      cell.configure(with: FKFormCellCalculatedPreviewRow(id: "demo-id", configuration: FKFormCellCalculatedPreviewConfiguration(label: nil, placeholder: nil, text: "", previewText: "", isEnabled: true), text: "", previewText: ""))
    }
  }

  static func sampleFormCellCaptchaCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellCaptchaCell.self, title: "Captcha") { cell in
      cell.configure(with: FKFormCaptchaRow(id: "demo-id", text: "", configuration: FKFormCellCaptchaConfiguration(layout: .underline, label: nil, placeholder: nil, captchaImage: nil, validation: .init(), linkageID: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellCharacterCountFooterCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellCharacterCountFooterCell.self, title: "CharacterCountFooter") { cell in
      cell.configure(with: FKFormCellCharacterCountFooterRow(id: "demo-id", text: "", configuration: FKFormCellCharacterCountFooterConfiguration(layout: .underline, label: nil, placeholder: nil, maxLength: 280, text: "", validation: .init(), isEnabled: true)))
    }
  }

  static func sampleFormCellCheckboxGroupCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellCheckboxGroupCell.self, title: "CheckboxGroup") { cell in
      cell.configure(with: FKFormCheckboxGroupRow(
        id: "demo-id",
        options: [
          FKFormCheckboxOption(id: "email", title: "Email updates"),
          FKFormCheckboxOption(id: "sms", title: "SMS alerts", isChecked: true),
        ],
        configuration: FKFormCellCheckboxGroupConfiguration(label: "Notifications", options: [
          FKFormCheckboxOption(id: "email", title: "Email updates"),
          FKFormCheckboxOption(id: "sms", title: "SMS alerts", isChecked: true),
        ])
      ))
    }
  }

  static func sampleFormCellColorCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellColorCell.self, title: "Color") { cell in
      cell.configure(with: FKFormCellColorRow(id: "demo-id", text: "", configuration: FKFormCellColorConfiguration(label: nil, selectedColor: .label, showsHexField: true, hexText: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellDateCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellDateCell.self, title: "Date") { cell in
      cell.configure(with: FKFormDateRow(id: "demo-id", date: Date(), layout: .underline, label: nil, isRequired: false))
    }
  }

  static func sampleFormCellDragUploadCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellDragUploadCell.self, title: "DragUpload") { cell in
      cell.configure(with: FKFormCellDragUploadRow(id: "demo-id", text: "", configuration: FKFormCellDragUploadConfiguration(title: "Drag files here or tap to upload", subtitle: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellDualButtonCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellDualButtonCell.self, title: "DualButton") { cell in
      cell.configure(with: FKFormDualButtonRow(id: "demo-id", configuration: FKFormCellDualButtonConfiguration(primaryTitle: "DualButton", secondaryTitle: "DualButton", layout: .horizontal, isPrimaryEnabled: true, isSecondaryEnabled: true, isPrimaryLoading: false, isSecondaryLoading: false)))
    }
  }

  static func sampleFormCellEmailSuffixCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellEmailSuffixCell.self, title: "EmailSuffix") { cell in
      cell.configure(with: FKFormCellEmailSuffixRow(id: "demo-id", text: "", configuration: FKFormCellEmailSuffixConfiguration(layout: .underline, label: nil, placeholder: nil, localPart: "", selectedSuffix: "@example.com", suffixOptions: ["Sample"], validation: .init(), isEnabled: true)))
    }
  }

  static func sampleFormCellEmojiPickerCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellEmojiPickerCell.self, title: "EmojiPicker") { cell in
      cell.configure(with: FKFormCellEmojiPickerRow(id: "demo-id", configuration: FKFormCellEmojiPickerConfiguration(label: nil, emojis: ["Sample"], selectedEmoji: nil, isEnabled: true), selectedEmoji: nil))
    }
  }

  static func sampleFormCellFilterChipsCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellFilterChipsCell.self, title: "FilterChips") { cell in
      cell.configure(with: FKFormFilterChipsRow(
        id: "demo-id",
        selectedIDs: ["all"],
        configuration: FKFormCellFilterChipsConfiguration(
          chips: [
            FKChipItem(id: "all", title: "All", isSelected: true),
            FKChipItem(id: "unread", title: "Unread"),
            FKChipItem(id: "flagged", title: "Flagged"),
          ],
          selectionMode: .single,
          selectedIDs: ["all"],
          isEnabled: true
        )
      ))
    }
  }

  static func sampleFormCellInlineExpandCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellInlineExpandCell.self, title: "InlineExpand") { cell in
      cell.configure(with: FKFormCellInlineExpandRow(id: "demo-id", configuration: FKFormCellInlineExpandConfiguration(toggleTitle: "InlineExpand", fieldLabel: nil, fieldPlaceholder: nil, isExpanded: false, fieldText: "", isEnabled: true), isExpanded: false, fieldText: ""))
    }
  }

  static func sampleFormCellInlineWheelCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellInlineWheelCell.self, title: "InlineWheel") { cell in
      cell.configure(with: FKFormCellInlineWheelRow(id: "demo-id", configuration: FKFormCellInlineWheelConfiguration(label: nil, options: ["Sample"], selectedIndex: 0, isExpanded: true, isEnabled: true), selectedIndex: 0))
    }
  }

  static func sampleFormCellLinkButtonCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellLinkButtonCell.self, title: "LinkButton") { cell in
      cell.configure(with: FKFormLinkButtonRow(id: "demo-id", title: "LinkButton", isEnabled: true))
    }
  }

  static func sampleFormCellMapRadiusCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellMapRadiusCell.self, title: "MapRadius") { cell in
      cell.configure(with: FKFormCellMapRadiusRow(id: "demo-id", configuration: FKFormCellMapRadiusConfiguration(label: nil, mapImage: nil, radiusMeters: 1000, minimumRadius: 500, maximumRadius: 5000, isEnabled: true), radiusMeters: 1000))
    }
  }

  static func sampleFormCellMediaGridCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellMediaGridCell.self, title: "MediaGrid") { cell in
      cell.configure(with: FKFormCellMediaGridRow(id: "demo-id", configuration: FKFormCellMediaGridConfiguration(label: nil, images: [FKCellImageContent()], maxCount: 9, isEnabled: true), images: [FKCellImageContent()]))
    }
  }

  static func sampleFormCellMediaPickerCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellMediaPickerCell.self, title: "MediaPicker") { cell in
      cell.configure(with: FKFormMediaPickerRow(id: "demo-id", displayName: "Demo", imageURL: nil, actionTitle: "Change Photo"))
    }
  }

  static func sampleFormCellMultilineCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellMultilineCell.self, title: "Multiline") { cell in
      cell.configure(with: FKFormMultilineRow(id: "demo-id", text: "", layout: .underline, label: nil, placeholder: nil, maxLength: nil, isRequired: false))
    }
  }

  static func sampleFormCellNPSScaleCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellNPSScaleCell.self, title: "NPSScale") { cell in
      cell.configure(with: FKFormCellNPSScaleRow(id: "demo-id", configuration: FKFormCellNPSScaleConfiguration(label: nil, minimumScore: 0, maximumScore: 10, selectedScore: nil, isEnabled: true), selectedScore: nil))
    }
  }

  static func sampleFormCellOTPCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellOTPCell.self, title: "OTP") { cell in
      cell.configure(with: FKFormOTPRow(id: "demo-id", code: "", layout: .underline, label: nil, length: 6, linkageID: nil, isRequired: true))
    }
  }

  static func sampleFormCellPINIndicatorCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellPINIndicatorCell.self, title: "PINIndicator") { cell in
      cell.configure(with: FKFormCellPINIndicatorRow(id: "demo-id", configuration: FKFormCellPINIndicatorConfiguration(label: nil, slotCount: 6, filledCount: 0, isEnabled: true), filledCount: 0))
    }
  }

  static func sampleFormCellPhoneCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellPhoneCell.self, title: "Phone") { cell in
      cell.configure(with: FKFormPhoneRow(id: "demo-id", phoneNumber: "", layout: .underline, label: nil, placeholder: nil, countryPicker: FKFormCountryPickerConfiguration(dialCode: "Sample", flagEmoji: nil, countryName: nil), isRequired: true))
    }
  }

  static func sampleFormCellPickerCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellPickerCell.self, title: "Picker") { cell in
      cell.configure(with: FKFormPickerRow(id: "demo-id", value: nil, configuration: FKFormCellPickerConfiguration(layout: .underline, label: nil, placeholder: nil, presentation: .dropdown, validation: .init(), linkageID: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellPrimaryButtonCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellPrimaryButtonCell.self, title: "PrimaryButton") { cell in
      cell.configure(with: FKFormPrimaryButtonRow(id: "demo-id", title: "PrimaryButton", isEnabled: true, isLoading: false))
    }
  }

  static func sampleFormCellRadioGroupCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellRadioGroupCell.self, title: "RadioGroup") { cell in
      cell.configure(with: FKFormRadioGroupRow(id: "demo-id", selectedOptionID: nil, label: nil, options: [FKFormRadioOption(id: "1", title: "Option")]))
    }
  }

  static func sampleFormCellRangeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellRangeCell.self, title: "Range") { cell in
      cell.configure(with: FKFormCellRangeRow(id: "demo-id", configuration: FKFormCellRangeConfiguration(layout: .underline, label: nil, minLabel: "Minimum", maxLabel: "Maximum", minPlaceholder: nil, maxPlaceholder: nil, minText: "", maxText: "", validation: .init(), isEnabled: true), minText: "", maxText: ""))
    }
  }

  static func sampleFormCellRichTextEditorCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellRichTextEditorCell.self, title: "RichTextEditor") { cell in
      cell.configure(with: FKFormCellRichTextEditorRow(id: "demo-id", text: "", configuration: FKFormCellRichTextEditorConfiguration(label: nil, placeholder: nil, text: "", maxLength: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellSMSCodeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSMSCodeCell.self, title: "SMSCode") { cell in
      cell.configure(with: FKFormSMSCodeRow(id: "demo-id", code: "", layout: .underline, label: nil, placeholder: nil, codeLength: 6, isRequired: true))
    }
  }

  static func sampleFormCellSearchCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSearchCell.self, title: "Search") { cell in
      cell.configure(with: FKFormSearchRow(id: "demo-id", text: "", configuration: FKFormCellSearchConfiguration(style: .capsule, placeholder: "Search", searchFieldConfiguration: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellSegmentCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSegmentCell.self, title: "Segment") { cell in
      cell.configure(with: FKFormSegmentRow(id: "demo-id", selectedIndex: 0, label: nil, segmentTitles: ["Sample"]))
    }
  }

  static func sampleFormCellSettingsLinkCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSettingsLinkCell.self, title: "SettingsLink") { cell in
      cell.configure(with: FKFormCellSettingsLinkRow(id: "demo-id", text: "", configuration: FKFormCellSettingsLinkConfiguration(body: "Detail", linkTitle: "Open Settings", isEnabled: true)))
    }
  }

  static func sampleFormCellSocialAccountCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSocialAccountCell.self, title: "SocialAccount") { cell in
      cell.configure(with: FKFormSocialAccountRow(id: "demo-id", username: "", configuration: FKFormCellSocialAccountConfiguration(layout: .underline, label: nil, placeholder: nil, platformPicker: FKFormPlatformPickerConfiguration(platformName: "Platform"), validation: .init(), linkageID: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellSplitFieldCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSplitFieldCell.self, title: "SplitField") { cell in
      cell.configure(with: FKFormCellSplitFieldRow(id: "demo-id", leftText: "", rightText: "", configuration: FKFormCellSplitFieldConfiguration(layout: .underline, leftLabel: nil, rightLabel: nil, leftText: "", rightText: "", leftPlaceholder: nil, rightPlaceholder: nil, isEnabled: true)))
    }
  }

  static func sampleFormCellSwitchCaptionCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSwitchCaptionCell.self, title: "SwitchCaption") { cell in
      cell.configure(with: FKFormSwitchCaptionRow(id: "demo-id", isOn: false, configuration: FKFormCellSwitchCaptionConfiguration(title: "SwitchCaption", subtitle: nil, isOn: false, isEnabled: true)))
    }
  }

  static func sampleFormCellSystemPickerCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellSystemPickerCell.self, title: "SystemPicker") { cell in
      cell.configure(with: FKFormCellSystemPickerRow(id: "demo-id", configuration: FKFormCellSystemPickerConfiguration(label: nil, summary: "Nothing selected", chooseButtonTitle: "Choose…", isEnabled: true), summary: ""))
    }
  }

  static func sampleFormCellTextFieldCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellTextFieldCell.self, title: "TextField") { cell in
      cell.configure(with: FKFormTextFieldRow(id: "demo-id", text: "", layout: .underline, label: nil, placeholder: nil, isRequired: false))
    }
  }

  static func sampleFormCellTimeCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellTimeCell.self, title: "Time") { cell in
      cell.configure(with: FKFormTimeRow(id: "demo-id", time: Date(), layout: .underline, label: nil, isRequired: false))
    }
  }

  static func sampleFormCellVoiceInputCell(callbacks: FKCellKitExampleCallbacks = .init()) -> FKCellKitExampleRow {
    .make(FKFormCellVoiceInputCell.self, title: "VoiceInput") { cell in
      cell.configure(with: FKFormCellVoiceInputRow(id: "demo-id", text: "", configuration: FKFormCellVoiceInputConfiguration(label: nil, placeholder: nil, text: "", isEnabled: true)))
    }
  }

}