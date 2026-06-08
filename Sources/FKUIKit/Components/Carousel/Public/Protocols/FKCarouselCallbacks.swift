import Foundation

/// Closure-based alternative to ``FKCarouselDelegate`` for SwiftUI and lightweight hosts.
public struct FKCarouselCallbacks: Sendable {
  /// Called when the settled page index changes.
  public var onPageChanged: (@MainActor (Int, FKCarouselPageChangeReason) -> Void)?

  /// Called when the user selects a page.
  public var onPageSelected: (@MainActor (Int) -> Void)?

  /// Called before auto-scroll advances; return `false` to cancel.
  public var onWillAutoAdvance: (@MainActor (Int, Int) -> Bool)?

  /// Called when dragging ends.
  public var onDidEndDragging: (@MainActor (Bool) -> Void)?

  /// Called while scroll progress updates.
  public var onScrollProgress: (@MainActor (CGFloat, Int, Int) -> Void)?

  /// Creates callback container.
  public init(
    onPageChanged: (@MainActor (Int, FKCarouselPageChangeReason) -> Void)? = nil,
    onPageSelected: (@MainActor (Int) -> Void)? = nil,
    onWillAutoAdvance: (@MainActor (Int, Int) -> Bool)? = nil,
    onDidEndDragging: (@MainActor (Bool) -> Void)? = nil,
    onScrollProgress: (@MainActor (CGFloat, Int, Int) -> Void)? = nil
  ) {
    self.onPageChanged = onPageChanged
    self.onPageSelected = onPageSelected
    self.onWillAutoAdvance = onWillAutoAdvance
    self.onDidEndDragging = onDidEndDragging
    self.onScrollProgress = onScrollProgress
  }
}

/// Closure-based alternative to ``FKImageBannerDelegate``.
public struct FKImageBannerCallbacks: Sendable {
  /// Called when the settled slide index changes.
  public var onSlideChanged: (@MainActor (Int, FKCarouselPageChangeReason) -> Void)?

  /// Called when the user taps a slide.
  public var onSlideTap: (@MainActor (Int) -> Void)?

  /// Called before opening a link URL.
  public var onShouldOpenLink: (@MainActor (URL, Int) -> Bool)?

  /// Called when the CTA is tapped.
  public var onCTATap: (@MainActor (Int) -> Void)?

  /// Creates callback container.
  public init(
    onSlideChanged: (@MainActor (Int, FKCarouselPageChangeReason) -> Void)? = nil,
    onSlideTap: (@MainActor (Int) -> Void)? = nil,
    onShouldOpenLink: (@MainActor (URL, Int) -> Bool)? = nil,
    onCTATap: (@MainActor (Int) -> Void)? = nil
  ) {
    self.onSlideChanged = onSlideChanged
    self.onSlideTap = onSlideTap
    self.onShouldOpenLink = onShouldOpenLink
    self.onCTATap = onCTATap
  }
}
