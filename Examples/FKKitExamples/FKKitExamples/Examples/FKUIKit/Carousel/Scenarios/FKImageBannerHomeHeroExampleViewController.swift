import FKUIKit
import UIKit

/// Home feed hero: infinite loop, auto-scroll, delegate link handling.
final class FKImageBannerHomeHeroExampleViewController: FKCarouselExampleScrollViewController, FKImageBannerDelegate {
  private let banner = FKImageBanner(configuration: FKImageBannerPresets.homeHero())
  private let log = FKCarouselExampleSupport.makeEventLogView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Home hero"
    installScrollRootChrome()

    banner.delegate = self
    banner.setSlides(FKCarouselExampleSlides.heroSlides())

    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Uses FKImageBannerPresets.homeHero(): 16:9 aspect ratio, dot indicator overlay, 4s auto-scroll, infinite loop. Tap a slide to log selection; links are callback-only in this demo."
    ))
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Event log"))
    contentStack.addArrangedSubview(log)
  }

  func imageBanner(_ banner: FKImageBanner, didScrollToSlide index: Int, reason: FKCarouselPageChangeReason) {
    FKCarouselExampleSupport.appendEvent("didScrollToSlide \(index) · \(reason)", to: log)
  }

  func imageBanner(_ banner: FKImageBanner, didSelectSlideAt index: Int) {
    FKCarouselExampleSupport.appendEvent("didSelectSlideAt \(index)", to: log)
  }

  func imageBanner(_ banner: FKImageBanner, shouldOpenLink url: URL, forSlideAt index: Int) -> Bool {
    FKCarouselExampleSupport.appendEvent("shouldOpenLink \(url.host ?? url.absoluteString) slide \(index)", to: log)
    return false
  }

  func imageBanner(_ banner: FKImageBanner, didTapCTAForSlideAt index: Int) {
    FKCarouselExampleSupport.appendEvent("didTapCTA slide \(index)", to: log)
  }
}
