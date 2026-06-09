import FKUIKit
import UIKit

/// E-commerce peek cards with corner shadow chrome.
final class FKImageBannerCardPeekExampleViewController: FKCarouselExampleScrollViewController {
  private let banner = FKImageBanner(configuration: FKImageBannerPresets.compactPromo())

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Card peek"
    installScrollRootChrome()

    banner.setSlides(FKCarouselExampleSlides.promoSlides())
    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "FKImageBannerPresets.compactPromo() maps to FKCarouselPresets.cardPeek with cardStyle corner radius and FKCornerShadow on each page cell."
    ))
  }
}
