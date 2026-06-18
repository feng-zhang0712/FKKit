import FKUIKit
import UIKit

final class FKMediaGalleryExampleSwipeToDismissViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Swipe to Dismiss"
    super.viewDidLoad()

    var configuration = FKMediaGalleryPresets.socialFeed()
    configuration.dismissGesture.allowsInteractiveDismiss = true
    configuration.dismissGesture.dismissDistanceRatio = 0.18

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryDismissGestureConfiguration",
        description: "Drag down to interactively dismiss with dimming and scale. Close button remains available in chrome.",
        body: FKMediaGalleryExampleUI.button("Present swipe-to-dismiss demo") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.productDetailItems(),
            configuration: configuration
          )
        }
      ),
      at: 0
    )
  }
}
