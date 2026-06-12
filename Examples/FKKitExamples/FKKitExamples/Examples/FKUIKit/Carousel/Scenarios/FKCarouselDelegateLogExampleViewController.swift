import FKUIKit
import UIKit

/// Combined delegate and callbacks logging for carousel and image banner.
final class FKCarouselDelegateLogExampleViewController: FKCarouselExampleScrollViewController, FKCarouselDelegate, FKImageBannerDelegate {
  private let carousel = FKCarousel(configuration: FKCarouselPresets.onboarding())
  private let banner = FKImageBanner()
  private let log = FKCarouselExampleSupport.makeEventLogView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate log"
    installScrollRootChrome()

    carousel.delegate = self
    carousel.callbacks.onPageSelected = { [weak self] index in
      self?.append("callbacks.onPageSelected(\(index))")
    }
    carousel.pageProvider = { item, bounds in
      FKCarouselExampleSupport.makeOnboardingPage(item: item, bounds: bounds)
    }
    carousel.setItems(FKCarouselExampleSupport.onboardingItems())

    banner.delegate = self
    banner.callbacks.onSlideTap = { [weak self] index in
      self?.append("callbacks.onSlideTap(\(index))")
    }
    var bannerConfig = FKImageBannerConfiguration()
    bannerConfig.carousel.autoScroll.isEnabled = false
    banner.configuration = bannerConfig
    banner.setSlides(Array(FKCarouselExampleSlides.heroSlides(count: 2)))

    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("FKCarousel"))
    contentStack.addArrangedSubview(carousel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("FKImageBanner"))
    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Events"))
    contentStack.addArrangedSubview(log)
  }

  private func append(_ message: String) {
    FKCarouselExampleSupport.appendEvent(message, to: log)
  }

  func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason) {
    append("carousel didScrollToPage \(index) · \(reason)")
  }

  func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int) {
    append("carousel didSelectPageAt \(index)")
  }

  func carousel(_ carousel: FKCarousel, willAutoAdvanceFrom from: Int, to: Int) -> Bool {
    append("carousel willAutoAdvance \(from)→\(to)")
    return true
  }

  func carouselDidEndDragging(_ carousel: FKCarousel, willDecelerate: Bool) {
    append("carouselDidEndDragging decelerate=\(willDecelerate)")
  }

  func imageBanner(_ banner: FKImageBanner, didScrollToSlide index: Int, reason: FKCarouselPageChangeReason) {
    append("imageBanner didScrollToSlide \(index) · \(reason)")
  }

  func imageBanner(_ banner: FKImageBanner, didSelectSlideAt index: Int) {
    append("imageBanner didSelectSlideAt \(index)")
  }
}
