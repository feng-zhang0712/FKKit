import Foundation

/// Delegate callbacks for ``FKImageBanner``.
@MainActor
public protocol FKImageBannerDelegate: AnyObject {
  /// Called when the settled slide index changes.
  func imageBanner(_ banner: FKImageBanner, didScrollToSlide index: Int, reason: FKCarouselPageChangeReason)

  /// Called when the user taps a slide.
  func imageBanner(_ banner: FKImageBanner, didSelectSlideAt index: Int)

  /// Called before opening a slide link URL; return `false` to cancel.
  func imageBanner(_ banner: FKImageBanner, shouldOpenLink url: URL, forSlideAt index: Int) -> Bool

  /// Called when the CTA button is tapped.
  func imageBanner(_ banner: FKImageBanner, didTapCTAForSlideAt index: Int)
}

extension FKImageBannerDelegate {
  public func imageBanner(_ banner: FKImageBanner, didScrollToSlide index: Int, reason: FKCarouselPageChangeReason) {}
  public func imageBanner(_ banner: FKImageBanner, didSelectSlideAt index: Int) {}
  public func imageBanner(_ banner: FKImageBanner, shouldOpenLink url: URL, forSlideAt index: Int) -> Bool { true }
  public func imageBanner(_ banner: FKImageBanner, didTapCTAForSlideAt index: Int) {}
}
