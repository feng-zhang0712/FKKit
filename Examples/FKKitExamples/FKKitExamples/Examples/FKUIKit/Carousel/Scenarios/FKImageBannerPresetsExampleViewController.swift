import FKUIKit
import UIKit

/// Side-by-side preset configurations.
final class FKImageBannerPresetsExampleViewController: FKCarouselExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presets"
    installScrollRootChrome()

    let presets: [(String, FKImageBannerConfiguration)] = [
      ("homeHero", FKImageBannerPresets.homeHero()),
      ("compactPromo", FKImageBannerPresets.compactPromo()),
      ("edgeToEdge", FKImageBannerPresets.edgeToEdge()),
      ("onboarding", FKImageBannerPresets.onboarding()),
    ]

    for (name, preset) in presets {
      let banner = FKImageBanner(configuration: preset)
      banner.setSlides(FKCarouselExampleSlides.promoSlides(count: 3))
      contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("FKImageBannerPresets.\(name)()"))
      contentStack.addArrangedSubview(banner)
    }

    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Factory presets map FKImageBannerConfiguration to underlying FKCarouselConfiguration (layout, indicator, auto-scroll, loop)."
    ))
  }
}
