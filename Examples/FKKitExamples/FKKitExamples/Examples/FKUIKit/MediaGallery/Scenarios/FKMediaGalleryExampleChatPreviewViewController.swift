import FKUIKit
import UIKit

final class FKMediaGalleryExampleChatPreviewViewController: FKMediaGalleryExampleBaseViewController {
  private var draftItems = FKMediaGalleryExampleCatalog.chatDraftItems()

  override func viewDidLoad() {
    title = "Chat Preview"
    super.viewDidLoad()

    let body = UIStackView(arrangedSubviews: [
      FKMediaGalleryExampleUI.button("Present chat attachments preview") { [weak self] in
        guard let self else { return }
        self.presentGallery(
          items: self.draftItems,
          configuration: FKMediaGalleryPresets.chatAttachments()
        )
      },
      FKMediaGalleryExampleUI.button("Delete current attachment (updateItems)") { [weak self] in
        self?.deleteCurrentAttachment()
      },
    ])
    body.axis = .vertical
    body.spacing = 8

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryViewController.updateItems",
        description: "Simulates send-before-delete: open the gallery, then remove the current page while it stays presented. Page indicator and index clamp automatically.",
        body: body
      ),
      at: 0
    )
    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.caption("Remaining draft count: \(draftItems.count)"),
      at: 1
    )
  }

  private func deleteCurrentAttachment() {
    guard let host = gallery.viewController else {
      FKMediaGalleryExampleLog.shared.append("Open the gallery first.")
      return
    }
    guard !draftItems.isEmpty else {
      FKMediaGalleryExampleLog.shared.append("No attachments left.")
      return
    }
    let index = host.currentIndex
    guard draftItems.indices.contains(index) else { return }
    let removed = draftItems.remove(at: index)
    do {
      try host.updateItems(draftItems, animated: true)
      FKMediaGalleryExampleLog.shared.append("Removed id=\(removed.id) · remaining=\(draftItems.count)")
    } catch {
      FKMediaGalleryExampleLog.shared.append("updateItems failed: \(error.localizedDescription)")
    }
  }
}
