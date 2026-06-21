import FKUIKit
import UIKit

final class FKMediaGalleryExampleAuthenticatedViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Authenticated CDN"
    super.viewDidLoad()

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryVideoSource.url headers",
        description: "Demonstrates wiring Authorization headers into FKVideoItem / FKMediaSource. The sample CDN ignores the token but shows the integration path for authenticated streams.",
        body: FKMediaGalleryExampleUI.button("Present authenticated video") { [weak self] in
          self?.presentGallery(
            items: [FKMediaGalleryExampleCatalog.authenticatedVideoItem()],
            configuration: FKMediaGalleryPresets.authenticatedCDN()
          )
        }
      ),
      at: 0
    )
  }
}
