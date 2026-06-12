import FKUIKit
import UIKit

/// Single-slide behavior and empty collapse policy.
final class FKImageBannerStatesExampleViewController: FKCarouselExampleScrollViewController {
  private let banner = FKImageBanner()
  private let emptyBanner = FKImageBanner()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Single & empty"
    installScrollRootChrome()

    var singleConfig = FKImageBannerConfiguration()
    singleConfig.carousel = FKCarouselPresets.fullWidth()
    singleConfig.carousel.autoScroll.isEnabled = true
    banner.configuration = singleConfig
    banner.setSlides(Array(FKCarouselExampleSlides.heroSlides(count: 1)))

    var emptyConfig = FKImageBannerConfiguration()
    emptyConfig.carousel.emptyState = .collapse
    emptyBanner.configuration = emptyConfig
    emptyBanner.setSlides([])

    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Single slide (indicator hidden, auto-scroll off)"))
    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("Empty slides (zero height collapse)"))
    contentStack.addArrangedSubview(emptyBanner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "FKImageBanner disables auto-scroll and hides the indicator when slide count ≤ 1. Empty policy .collapse yields zero intrinsic height."
    ))

    let toggle = FKCarouselExampleSupport.makeActionButton("Toggle single vs multi") { [weak self] in
      guard let self else { return }
      if self.banner.slides.count == 1 {
        self.banner.setSlides(FKCarouselExampleSlides.heroSlides(count: 3))
      } else {
        self.banner.setSlides(Array(FKCarouselExampleSlides.heroSlides(count: 1)))
      }
    }
    contentStack.addArrangedSubview(toggle)
  }
}
