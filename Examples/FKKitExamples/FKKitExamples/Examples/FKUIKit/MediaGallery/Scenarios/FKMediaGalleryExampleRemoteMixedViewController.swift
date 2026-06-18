import FKUIKit
import UIKit

final class FKMediaGalleryExampleRemoteMixedViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Remote Mixed"
    super.viewDidLoad()

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Remote HTTPS + streaming",
        description: "Same items array mixes FKImageView remote loads with FKVideoPlayer MP4 and HLS VOD items.",
        body: FKMediaGalleryExampleUI.button("Present remote mixed gallery") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.remoteMixedItems(),
            configuration: FKMediaGalleryPresets.socialFeed()
          )
        }
      ),
      at: 0
    )
    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.caption("Network required for all three pages."),
      at: 1
    )
  }
}
