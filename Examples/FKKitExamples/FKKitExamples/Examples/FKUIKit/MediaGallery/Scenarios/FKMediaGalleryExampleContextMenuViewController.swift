import FKUIKit
import UIKit

final class FKMediaGalleryExampleContextMenuViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Context Menu"
    super.viewDidLoad()

    var configuration = FKMediaGalleryPresets.socialFeed()
    configuration.contextMenu.isEnabled = true
    configuration.contextMenu.showsSaveToPhotosAction = true
    configuration.contextMenu.showsShareAction = true
    configuration.contextMenu.showsCopyLinkAction = true

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Long-press actions",
        description: "Long-press for UIContextMenu preview with save (FKPermissions), share (FKFileManager), or copy shareURL.",
        body: FKMediaGalleryExampleUI.button("Present context menu demo") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.contextMenuItems(),
            configuration: configuration
          )
        }
      ),
      at: 0
    )
  }
}
