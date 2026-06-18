import FKUIKit
import UIKit

final class FKMediaGalleryExampleReduceMotionViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Reduce Motion"
    super.viewDidLoad()

    let reduceMotion = UIAccessibility.isReduceMotionEnabled

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Hero fallback",
        description: "When Settings → Accessibility → Motion → Reduce Motion is enabled, hero transitions degrade to cross-dissolve without spring animation.",
        body: FKMediaGalleryExampleUI.button("Present hero gallery") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.singleImageItem(),
            configuration: FKMediaGalleryPresets.socialFeed()
          )
        }
      ),
      at: 0
    )
    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.caption(
        reduceMotion
          ? "Reduce Motion is currently ON — expect cross-dissolve."
          : "Reduce Motion is OFF — toggle it in Settings to compare hero vs cross-dissolve."
      ),
      at: 1
    )
  }
}
