import FKUIKit
import UIKit

/// Overlay visibility variants on image slides.
final class FKImageBannerMixedOverlayExampleViewController: FKCarouselExampleScrollViewController, FKImageBannerDelegate {
  private let banner = FKImageBanner()
  private let log = FKCarouselExampleSupport.makeEventLogView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Mixed overlay"
    installScrollRootChrome()

    var config = FKImageBannerConfiguration()
    config.defaultCTATitle = "Learn more"
    config.carousel = FKCarouselPresets.fullWidth(aspectRatio: 16.0 / 9.0)
    banner.configuration = config
    banner.delegate = self
    banner.setSlides(FKCarouselExampleSlides.overlayVariants())

    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Slides demonstrate title-only, title+subtitle, per-slide CTA override, and accessibilityOnly overlay visibility."
    ))
    contentStack.addArrangedSubview(log)
  }

  func imageBanner(_ banner: FKImageBanner, didTapCTAForSlideAt index: Int) {
    FKCarouselExampleSupport.appendEvent("CTA tapped on slide \(index)", to: log)
  }
}
