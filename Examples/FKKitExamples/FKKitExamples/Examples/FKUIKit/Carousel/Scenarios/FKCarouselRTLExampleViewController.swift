import FKUIKit
import UIKit

/// Forces RTL layout to validate mirrored paging and overlay constraints.
final class FKCarouselRTLExampleViewController: FKCarouselExampleScrollViewController {
  private let banner = FKImageBanner(configuration: FKImageBannerPresets.homeHero())
  private var previousSemantic: UISemanticContentAttribute = .unspecified

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL layout"
    installScrollRootChrome()

    banner.setSlides(FKCarouselExampleSlides.heroSlides(count: 3))
    banner.semanticContentAttribute = .forceRightToLeft

    contentStack.addArrangedSubview(banner)
    contentStack.addArrangedSubview(FKCarouselExampleSupport.captionLabel(
      "semanticContentAttribute = .forceRightToLeft on FKImageBanner. Swipe direction and overlay leading/trailing constraints mirror for Arabic-style layouts."
    ))
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    previousSemantic = UIView.appearance().semanticContentAttribute
    UIView.appearance().semanticContentAttribute = .forceRightToLeft
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    UIView.appearance().semanticContentAttribute = previousSemantic
  }
}
