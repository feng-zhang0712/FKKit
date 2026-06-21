import FKUIKit
import UIKit

final class FKMediaGalleryExampleProductDetailViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Product Detail"
    super.viewDidLoad()

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryPresets.productDetail()",
        description: "High maximum zoom (6×), no autoplay, numeric page indicator, and caption overlay for e-commerce angles.",
        body: FKMediaGalleryExampleUI.button("Present product gallery") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.productDetailItems(),
            configuration: FKMediaGalleryPresets.productDetail()
          )
        }
      ),
      at: 0
    )
  }
}
