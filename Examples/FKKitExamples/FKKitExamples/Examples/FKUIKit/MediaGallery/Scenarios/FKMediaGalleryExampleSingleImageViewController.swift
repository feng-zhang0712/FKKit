import FKUIKit
import UIKit

final class FKMediaGalleryExampleSingleImageViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Single Image"
    super.viewDidLoad()

    var configuration = FKMediaGalleryPresets.previewOnly()
    configuration.chrome.pageIndicatorStyle = .none
    configuration.chrome.showsPageIndicator = false

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "One item",
        description: "When only one page exists, the numeric indicator and dot strip stay hidden.",
        body: FKMediaGalleryExampleUI.button("Present single image") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.singleImageItem(),
            configuration: configuration
          )
        }
      ),
      at: 0
    )
  }
}
