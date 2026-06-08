import FKUIKit
import UIKit

/// fixedPageWidth, insetCard, and external indicator spacing.
final class FKCarouselLayoutModesExampleViewController: FKCarouselExampleScrollViewController {
  private let fixedCarousel = FKCarousel()
  private let insetCarousel = FKCarousel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layout modes"
    installScrollRootChrome()

    let items = FKCarouselExampleSupport.onboardingItems()
    let pageProvider: (FKCarouselItem, CGRect) -> UIView = { item, bounds in
      FKCarouselExampleSupport.makeOnboardingPage(item: item, bounds: bounds)
    }

    var fixed = FKCarouselConfiguration()
    fixed.layout.layoutMode = .fixedPageWidth(280)
    fixed.layout.heightStrategy = .fixed(180)
    fixed.layout.interPageSpacing = 12
    fixed.indicator.placement = .below(spacing: 8)
    fixedCarousel.configuration = fixed
    fixedCarousel.pageProvider = pageProvider
    fixedCarousel.setItems(items)

    var inset = FKCarouselConfiguration()
    inset.layout.layoutMode = .insetCard(cornerRadius: 16, horizontalInset: 20)
    inset.layout.heightStrategy = .aspectRatio(16.0 / 9.0)
    inset.layout.interPageSpacing = 10
    inset.indicator.placement = .below(spacing: 8)
    insetCarousel.configuration = inset
    insetCarousel.pageProvider = pageProvider
    insetCarousel.setItems(items)

    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("fixedPageWidth(280) centered"))
    contentStack.addArrangedSubview(fixedCarousel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("insetCard + interPageSpacing"))
    contentStack.addArrangedSubview(insetCarousel)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "FKCarouselLayoutMode.fixedPageWidth and .insetCard with FKCarouselHeightStrategy.fixed / .aspectRatio."
    ))
  }
}
