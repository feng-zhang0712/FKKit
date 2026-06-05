import FKUIKit
import UIKit

/// Brand-inspired refresh presets for FKRefreshExamples (not public library API).
enum FKRefreshAppStylePreset: String, CaseIterable {

  case indicatorOnly
  case twitter
  case instagram
  case weChat
  case tikTokFeed
  case reddit
  case appleMail

  struct Bundle {
    let screenTitle: String
    let summary: String
    let header: FKRefreshConfiguration
    let footer: FKRefreshConfiguration
    let requestDelay: TimeInterval
    let initialCount: Int
    let pageSize: Int
    let maxItems: Int
  }

  var bundle: Bundle {
    switch self {
    case .indicatorOnly:
      return Self.makeIndicatorOnly()
    case .twitter:
      return Self.makeTwitter()
    case .instagram:
      return Self.makeInstagram()
    case .weChat:
      return Self.makeWeChat()
    case .tikTokFeed:
      return Self.makeTikTokFeed()
    case .reddit:
      return Self.makeReddit()
    case .appleMail:
      return Self.makeAppleMail()
    }
  }

  // MARK: - Presets

  private static func makeIndicatorOnly() -> Bundle {
    var header = FKRefreshConfiguration()
    header.statusTextMode = .indicatorOnly
    header.finishedHoldDuration = 0
    header.tintColor = .systemBlue
    header.expandedHeight = 52
    header.minimumLoadingVisibilityDuration = 0.3

    var footer = header
    footer.finishedHoldDuration = 0.15
    footer.noMoreDataBehavior = .hideFooter

    return Bundle(
      screenTitle: "Indicator only",
      summary: "Spinner/arrow without status text (`statusTextMode: .indicatorOnly`).",
      header: header,
      footer: footer,
      requestDelay: 0.9,
      initialCount: 16,
      pageSize: 8,
      maxItems: 40
    )
  }

  private static func makeTwitter() -> Bundle {
    let blue = UIColor(red: 29 / 255, green: 161 / 255, blue: 242 / 255, alpha: 1)

    var header = FKRefreshConfiguration()
    header.statusTextMode = .indicatorOnly
    header.finishedHoldDuration = 0
    header.collapseDuration = 0.25
    header.tintColor = blue
    header.expandedHeight = 48
    header.isHapticFeedbackEnabled = false
    header.minimumLoadingVisibilityDuration = 0.35

    var footer = header
    footer.loadMorePreloadOffset = 120
    footer.noMoreDataBehavior = .hideFooter
    footer.finishedHoldDuration = 0

    return Bundle(
      screenTitle: "Twitter / X timeline",
      summary: "Minimal pull header, early preload, footer hides when the feed ends.",
      header: header,
      footer: footer,
      requestDelay: 1.0,
      initialCount: 20,
      pageSize: 10,
      maxItems: 50
    )
  }

  private static func makeInstagram() -> Bundle {
    var header = FKRefreshConfiguration()
    header.defaultContentLayout = .vertical
    header.tintColor = UIColor { traits in
      traits.userInterfaceStyle == .dark ? .secondaryLabel : .tertiaryLabel
    }
    header.finishedHoldDuration = 0.2
    header.expandedHeight = 72
    header.texts = FKRefreshText(
      pullToRefresh: "",
      releaseToRefresh: "",
      headerLoading: "",
      headerFinished: "",
      headerListEmpty: "No posts yet",
      headerFailed: "Couldn't refresh",
      footerLoading: "",
      footerFinished: "",
      footerNoMoreData: "",
      footerFailed: "Couldn't load",
      footerTapToRetry: "Tap to retry"
    )
    header.statusTextMode = .indicatorOnly

    var footer = header
    footer.loadMorePreloadOffset = 160
    footer.noMoreDataBehavior = .hideFooter
    footer.finishedHoldDuration = 0

    return Bundle(
      screenTitle: "Instagram feed",
      summary: "Vertical indicator stack, muted tint, silent terminal states, feed-style footer.",
      header: header,
      footer: footer,
      requestDelay: 0.85,
      initialCount: 12,
      pageSize: 6,
      maxItems: 36
    )
  }

  private static func makeWeChat() -> Bundle {
    let green = UIColor(red: 7 / 255, green: 193 / 255, blue: 96 / 255, alpha: 1)

    let texts = FKRefreshText(
      pullToRefresh: "Pull down to refresh",
      releaseToRefresh: "Release to refresh",
      headerLoading: "Refreshing…",
      headerFinished: "Updated",
      headerListEmpty: "No messages",
      headerFailed: "Refresh failed",
      footerLoading: "Loading earlier messages…",
      footerFinished: "Loaded",
      footerNoMoreData: "No earlier messages",
      footerFailed: "Couldn't load messages",
      footerTapToRetry: "Tap to retry"
    )

    var header = FKRefreshConfiguration()
    header.texts = texts
    header.tintColor = green
    header.defaultContentLayout = .horizontal
    header.finishedHoldDuration = 0.45
    header.expandedHeight = 56

    var footer = header
    footer.finishedHoldDuration = 0.35

    return Bundle(
      screenTitle: "WeChat chat list",
      summary: "Text-forward pull header and paging footer with messaging-style copy.",
      header: header,
      footer: footer,
      requestDelay: 0.75,
      initialCount: 18,
      pageSize: 10,
      maxItems: 48
    )
  }

  private static func makeTikTokFeed() -> Bundle {
    var header = FKRefreshConfiguration()
    header.statusTextMode = .indicatorOnly
    header.finishedHoldDuration = 0
    header.tintColor = .label
    header.expandedHeight = 44
    header.minimumLoadingVisibilityDuration = 0.25
    header.isHapticFeedbackEnabled = true

    var footer = header
    footer.loadMorePreloadOffset = 240
    footer.loadMoreTriggerMode = .automatic
    footer.noMoreDataBehavior = .hideFooter
    footer.finishedHoldDuration = 0
    footer.footerSafeAreaPadding = 8

    return Bundle(
      screenTitle: "TikTok-style feed",
      summary: "Indicator-only header/footer, aggressive preload, footer disappears at end of feed.",
      header: header,
      footer: footer,
      requestDelay: 0.7,
      initialCount: 8,
      pageSize: 4,
      maxItems: 28
    )
  }

  private static func makeReddit() -> Bundle {
    let orange = UIColor(red: 1, green: 69 / 255, blue: 0, alpha: 1)

    let texts = FKRefreshText(
      pullToRefresh: "Pull to refresh",
      releaseToRefresh: "Release to refresh",
      headerLoading: "Refreshing feed…",
      headerFinished: "Feed updated",
      headerListEmpty: "Nothing here yet",
      headerFailed: "Couldn't refresh feed",
      footerLoading: "Loading more posts…",
      footerFinished: "More posts loaded",
      footerNoMoreData: "You've reached the end",
      footerFailed: "Couldn't load more",
      footerTapToRetry: "Tap to try again"
    )

    var header = FKRefreshConfiguration()
    header.texts = texts
    header.tintColor = orange
    header.finishedHoldDuration = 0.55
    header.minimumLoadingVisibilityDuration = 0.4

    var footer = header
    footer.finishedHoldDuration = 0.45

    return Bundle(
      screenTitle: "Reddit feed",
      summary: "Full status copy, orange accent, explicit no-more and tap-to-retry footer.",
      header: header,
      footer: footer,
      requestDelay: 1.1,
      initialCount: 15,
      pageSize: 8,
      maxItems: 39
    )
  }

  private static func makeAppleMail() -> Bundle {
    var header = FKRefreshConfiguration()
    header.tintColor = .secondaryLabel
    header.finishedHoldDuration = 0.5
    header.expandedHeight = 64
    header.isHapticFeedbackEnabled = true

    var footer = header
    footer.loadMorePreloadOffset = 0

    return Bundle(
      screenTitle: "Apple Mail inbox",
      summary: "Stock iOS defaults: system tint, standard copy, balanced timing.",
      header: header,
      footer: footer,
      requestDelay: 0.95,
      initialCount: 14,
      pageSize: 7,
      maxItems: 35
    )
  }
}
