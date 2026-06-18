import FKUIKit
import UIKit

final class FKMediaGalleryExamplePresetsViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Presets"
    super.viewDidLoad()

    let items = FKMediaGalleryExampleCatalog.remoteMixedItems()
    let buttons = UIStackView()
    buttons.axis = .vertical
    buttons.spacing = 8

    let presets: [(String, FKMediaGalleryConfiguration)] = [
      ("socialFeed()", FKMediaGalleryPresets.socialFeed()),
      ("chatAttachments()", FKMediaGalleryPresets.chatAttachments()),
      ("productDetail()", FKMediaGalleryPresets.productDetail()),
      ("previewOnly()", FKMediaGalleryPresets.previewOnly()),
      ("authenticatedCDN()", FKMediaGalleryPresets.authenticatedCDN()),
    ]

    for (name, configuration) in presets {
      buttons.addArrangedSubview(FKMediaGalleryExampleUI.button("Present · \(name)") { [weak self] in
        self?.presentGallery(items: items, configuration: configuration)
      })
    }

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryPresets",
        description: "Each factory returns a sendable FKMediaGalleryConfiguration tuned for a product flow. Compare transition, chrome, video, and context menu defaults.",
        body: buttons
      ),
      at: 0
    )
  }
}
