import FKUIKit
import UIKit

final class FKMediaGalleryExampleLocalMixedViewController: FKMediaGalleryExampleBaseViewController {
  private var preparedItems: [FKMediaGalleryItem] = []
  private let statusLabel = UILabel()

  override func viewDidLoad() {
    title = "Local Mixed"
    super.viewDidLoad()

    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Prepare local assets once (downloads sample MP4 to temp)."

    let body = UIStackView(arrangedSubviews: [
      statusLabel,
      FKMediaGalleryExampleUI.button("Prepare local assets") { [weak self] in
        Task { @MainActor in
          await self?.prepareAssets()
        }
      },
      FKMediaGalleryExampleUI.button("Present local mixed gallery") { [weak self] in
        guard let self, !self.preparedItems.isEmpty else {
          FKMediaGalleryExampleLog.shared.append("Prepare local assets first.")
          return
        }
        self.presentGallery(items: self.preparedItems, configuration: FKMediaGalleryPresets.chatAttachments())
      },
    ])
    body.axis = .vertical
    body.spacing = 8

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Local sources",
        description: "UIImage in memory, file:// JPEG from temp, and file:// MP4 via FKVideoPlayer.",
        body: body
      ),
      at: 0
    )
  }

  private func prepareAssets() async {
    do {
      preparedItems = try await FKMediaGalleryExampleCatalog.localMixedItems()
      statusLabel.text = "Ready · \(preparedItems.count) local item(s)."
      FKMediaGalleryExampleLog.shared.append("Local assets prepared.")
    } catch {
      statusLabel.text = "Prepare failed: \(error.localizedDescription)"
      FKMediaGalleryExampleLog.shared.append("Prepare failed: \(error.localizedDescription)")
    }
  }
}
