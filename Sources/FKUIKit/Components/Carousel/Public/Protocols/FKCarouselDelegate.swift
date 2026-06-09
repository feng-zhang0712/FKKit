import Foundation

/// Optional delegate callbacks for ``FKCarousel``.
@MainActor
public protocol FKCarouselDelegate: AnyObject {
  /// Called when the settled page index changes.
  func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason)

  /// Called when the user selects a page.
  func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int)

  /// Called before auto-scroll advances; return `false` to cancel.
  func carousel(_ carousel: FKCarousel, willAutoAdvanceFrom from: Int, to: Int) -> Bool

  /// Called when the user ends dragging.
  func carouselDidEndDragging(_ carousel: FKCarousel, willDecelerate: Bool)

  /// Called while scroll progress changes when ``FKCarouselPagingConfiguration/reportsScrollProgress`` is enabled.
  func carousel(_ carousel: FKCarousel, didUpdateScrollProgress progress: CGFloat, fromPage: Int, toPage: Int)
}

extension FKCarouselDelegate {
  public func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason) {}
  public func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int) {}
  public func carousel(_ carousel: FKCarousel, willAutoAdvanceFrom from: Int, to: Int) -> Bool { true }
  public func carouselDidEndDragging(_ carousel: FKCarousel, willDecelerate: Bool) {}
  public func carousel(_ carousel: FKCarousel, didUpdateScrollProgress progress: CGFloat, fromPage: Int, toPage: Int) {}
}
