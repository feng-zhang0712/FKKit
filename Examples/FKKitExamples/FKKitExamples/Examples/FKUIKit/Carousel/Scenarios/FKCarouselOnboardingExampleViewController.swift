import FKUIKit
import UIKit

/// Custom UIView pages via pageProvider and onboarding preset.
final class FKCarouselOnboardingExampleViewController: FKCarouselExampleScrollViewController {
  private let carousel = FKCarousel(configuration: FKCarouselPresets.onboarding())

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Onboarding cards"
    installScrollRootChrome()

    carousel.pageProvider = { item, bounds in
      FKCarouselExampleSupport.makeOnboardingPage(item: item, bounds: bounds)
    }
    carousel.setItems(FKCarouselExampleSupport.onboardingItems())

    contentStack.addArrangedSubview(carousel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "FKCarouselPresets.onboarding(): full-bleed pages, fraction indicator below, no infinite loop, auto-scroll disabled. Pages are UIViews from pageProvider."
    ))
  }
}
