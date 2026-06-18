import FKUIKit
import UIKit

final class FKMediaGalleryExampleRTLViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "RTL Gallery"
    super.viewDidLoad()

    view.semanticContentAttribute = .forceRightToLeft
    scrollView.semanticContentAttribute = .forceRightToLeft
    contentStack.semanticContentAttribute = .forceRightToLeft

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Right-to-left layout",
        description: "Gallery paging mirrors scroll direction and page indicator semantics under RTL. VoiceOver page-scrolled notifications still fire on index changes.",
        body: FKMediaGalleryExampleUI.button("Present RTL gallery") { [weak self] in
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
