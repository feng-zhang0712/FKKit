import FKUIKit
import UIKit

final class FKMediaGalleryExampleZoomGesturesViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Zoom Gestures"
    super.viewDidLoad()

    var configuration = FKMediaGalleryPresets.socialFeed()
    configuration.zoom.maximumZoomScale = 5
    configuration.zoom.doubleTapZoomScale = 3
    configuration.zoom.doubleTapZoomsToFocalPoint = true

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryZoomConfiguration",
        description: "Pinch to zoom, double-tap toward the tap point, and horizontal paging is blocked while zoom scale > 1.",
        body: FKMediaGalleryExampleUI.button("Present zoom demo") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.zoomGestureItems(),
            configuration: configuration
          )
        }
      ),
      at: 0
    )
  }
}
