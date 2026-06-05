import UIKit

/// User-visible strings for the built-in ``FKDefaultRefreshContentView``.
///
/// Localize these strings at app launch, or override them per screen (e.g. for feature-specific copy).
public struct FKRefreshText: Equatable, Sendable {

  // MARK: Pull header

  public var pullToRefresh: String
  public var releaseToRefresh: String
  public var headerLoading: String
  public var headerFinished: String
  public var headerListEmpty: String
  public var headerFailed: String

  // MARK: Load-more footer

  public var footerLoading: String
  public var footerFinished: String
  public var footerNoMoreData: String
  public var footerFailed: String
  public var footerTapToRetry: String

  public init(
    pullToRefresh: String = FKUIKitI18n.string("fkuikit.refresh.pull"),
    releaseToRefresh: String = FKUIKitI18n.string("fkuikit.refresh.release"),
    headerLoading: String = FKUIKitI18n.string("fkuikit.refresh.header.loading"),
    headerFinished: String = FKUIKitI18n.string("fkuikit.refresh.header.finished"),
    headerListEmpty: String = FKUIKitI18n.string("fkuikit.refresh.header.empty"),
    headerFailed: String = FKUIKitI18n.string("fkuikit.refresh.header.failed"),
    footerLoading: String = FKUIKitI18n.string("fkuikit.refresh.footer.loading"),
    footerFinished: String = FKUIKitI18n.string("fkuikit.refresh.footer.finished"),
    footerNoMoreData: String = FKUIKitI18n.string("fkuikit.refresh.footer.no_more"),
    footerFailed: String = FKUIKitI18n.string("fkuikit.refresh.footer.failed"),
    footerTapToRetry: String = FKUIKitI18n.string("fkuikit.refresh.footer.tap_retry")
  ) {
    self.pullToRefresh = pullToRefresh
    self.releaseToRefresh = releaseToRefresh
    self.headerLoading = headerLoading
    self.headerFinished = headerFinished
    self.headerListEmpty = headerListEmpty
    self.headerFailed = headerFailed
    self.footerLoading = footerLoading
    self.footerFinished = footerFinished
    self.footerNoMoreData = footerNoMoreData
    self.footerFailed = footerFailed
    self.footerTapToRetry = footerTapToRetry
  }

  public static var `default`: FKRefreshText { FKRefreshText() }
}
