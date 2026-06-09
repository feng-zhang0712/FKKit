import FKUIKit
import UIKit

/// Broken remote URL with failurePolicy placeholder handling.
final class FKImageBannerFailureFallbackExampleViewController: FKCarouselExampleScrollViewController {
  private let banner = FKImageBanner()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Failure fallback"
    installScrollRootChrome()

    var config = FKImageBannerConfiguration()
    config.failurePolicy = .showErrorPlaceholder
    config.carousel = FKCarouselPresets.fullWidth()
    config.carousel.autoScroll.isEnabled = false
    banner.configuration = config
    banner.setSlides(FKCarouselExampleSlides.failureSlides())

    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Middle slide uses httpbin 404. failurePolicy.showErrorPlaceholder keeps the page visible with a symbol placeholder. Third slide uses an in-memory UIImage."
    ))
  }
}
