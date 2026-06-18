import FKUIKit
import UIKit

final class FKMediaGalleryExamplePhotoPickerBridgeViewController: FKMediaGalleryExampleBaseViewController {
  private let picker = FKPhotoPicker()
  private var lastResults: [FKPhotoPickerResult] = []

  override func viewDidLoad() {
    title = "PhotoPicker Bridge"
    super.viewDidLoad()

    let body = UIStackView(arrangedSubviews: [
      FKMediaGalleryExampleUI.button("Pick up to 6 attachments") { [weak self] in
        self?.pickAttachments()
      },
      FKMediaGalleryExampleUI.button("Preview picked media in gallery") { [weak self] in
        self?.previewPickedMedia()
      },
    ])
    body.axis = .vertical
    body.spacing = 8

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryItem.from(FKPhotoPickerResult)",
        description: "Pick images/videos, map via FKMediaGalleryItem.from (prefers PHAsset localIdentifier when available), then preview in the lightbox.",
        body: body
      ),
      at: 0
    )
  }

  private func pickAttachments() {
    Task { @MainActor in
      do {
        let results = try await picker.pick(
          from: self,
          configuration: .chatAttachments(max: 6)
        )
        lastResults = results
        FKMediaGalleryExampleLog.shared.append("Picked \(results.count) result(s).")
      } catch {
        FKMediaGalleryExampleLog.shared.append("Pick failed: \(error.localizedDescription)")
      }
    }
  }

  private func previewPickedMedia() {
    let items = FKMediaGalleryItem.from(lastResults)
    guard !items.isEmpty else {
      FKMediaGalleryExampleLog.shared.append("Pick media first.")
      return
    }
    presentGallery(items: items, configuration: FKMediaGalleryPresets.chatAttachments())
  }
}
