import FKUIKit
import UIKit

final class FKMediaGalleryExampleLocalRemoteMixedViewController: FKMediaGalleryExampleBaseViewController {
  private var preparedItems: [FKMediaGalleryItem] = []

  override func viewDidLoad() {
    title = "Local + Remote"
    super.viewDidLoad()

    let body = UIStackView(arrangedSubviews: [
      FKMediaGalleryExampleUI.button("Prepare items") { [weak self] in
        Task { @MainActor in
          await self?.prepare()
        }
      },
      FKMediaGalleryExampleUI.button("Present mixed gallery") { [weak self] in
        guard let self, !self.preparedItems.isEmpty else {
          FKMediaGalleryExampleLog.shared.append("Prepare items first.")
          return
        }
        self.presentGallery(items: self.preparedItems, configuration: FKMediaGalleryPresets.socialFeed())
      },
    ])
    body.axis = .vertical
    body.spacing = 8

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Cross-source items array",
        description: "Local UIImage and file video sit beside remote image, MP4, and HLS in one session.",
        body: body
      ),
      at: 0
    )
  }

  private func prepare() async {
    do {
      preparedItems = try await FKMediaGalleryExampleCatalog.localRemoteMixedItems()
      FKMediaGalleryExampleLog.shared.append("Prepared \(preparedItems.count) mixed items.")
    } catch {
      FKMediaGalleryExampleLog.shared.append("Prepare failed: \(error.localizedDescription)")
    }
  }
}
