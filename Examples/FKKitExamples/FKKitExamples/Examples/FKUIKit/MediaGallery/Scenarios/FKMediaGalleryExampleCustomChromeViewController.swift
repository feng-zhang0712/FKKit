import FKUIKit
import UIKit

final class FKMediaGalleryExampleCustomChromeViewController: FKMediaGalleryExampleBaseViewController {
  private let overlayProvider = FKMediaGalleryExampleOverlayProvider()

  override func viewDidLoad() {
    title = "Custom Chrome"
    super.viewDidLoad()
    gallery.chromeProvider = overlayProvider

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryChromeProviding",
        description: "Inject a host-owned overlay per page (for example reactions or product SKU) while keeping default close/page chrome.",
        body: FKMediaGalleryExampleUI.button("Present with custom overlay") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.productDetailItems(),
            configuration: FKMediaGalleryPresets.socialFeed()
          )
        }
      ),
      at: 0
    )
  }
}

@MainActor
private final class FKMediaGalleryExampleOverlayProvider: FKMediaGalleryChromeProviding {
  func mediaGallery(
    _ gallery: FKMediaGalleryViewController,
    overlayForPageAt index: Int,
    item: FKMediaGalleryItem
  ) -> UIView? {
    let pill = UILabel()
    pill.text = "  Host overlay · page \(index + 1)  "
    pill.font = .preferredFont(forTextStyle: .caption1)
    pill.textColor = .white
    pill.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.85)
    pill.layer.cornerRadius = 14
    pill.clipsToBounds = true
    pill.textAlignment = .center
    return pill
  }
}
