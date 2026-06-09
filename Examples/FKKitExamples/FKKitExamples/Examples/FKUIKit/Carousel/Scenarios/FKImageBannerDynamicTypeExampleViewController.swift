import FKUIKit
import UIKit

/// Dynamic Type with overlay expansion policies.
final class FKImageBannerDynamicTypeExampleViewController: FKCarouselExampleScrollViewController {
  private let fixedBanner = FKImageBanner()
  private let growingBanner = FKImageBanner()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic Type"
    installScrollRootChrome()

    let slides = [
      FKImageBannerSlide(
        id: "large-text",
        imageSource: .url(FKCarouselExampleURLs.banner(id: 501)),
        title: "Headline grows with Dynamic Type settings in Settings → Accessibility → Display & Text Size.",
        subtitle: "Subtitle also scales.",
        overlayStyle: FKImageBannerOverlayStyle(ctaTitle: "Action", visibility: .always)
      ),
    ]

    var fixed = FKImageBannerConfiguration()
    fixed.overlayExpansionPolicy = .fixedBannerHeight
    fixed.maximumTitleLines = 3
    fixed.maximumSubtitleLines = 2
    fixed.carousel = FKCarouselPresets.fullWidth(aspectRatio: 16.0 / 9.0)
    fixedBanner.configuration = fixed
    fixedBanner.setSlides(slides)

    var grow = fixed
    grow.overlayExpansionPolicy = .growBanner
    growingBanner.configuration = grow
    growingBanner.setSlides(slides)

    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("fixedBannerHeight"))
    contentStack.addArrangedSubview(fixedBanner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.sectionTitle("growBanner"))
    contentStack.addArrangedSubview(growingBanner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "Change text size in iOS Settings to compare overlayExpansionPolicy behavior. Both banners share the same slide copy."
    ))
  }
}
