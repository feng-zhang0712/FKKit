import FKUIKit
import UIKit

final class FKMediaGalleryExampleLivePhotoViewController: FKMediaGalleryExampleBaseViewController {
  private let picker = FKPhotoPicker()
  private var lastResults: [FKPhotoPickerResult] = []

  override func viewDidLoad() {
    title = "Live Photo"
    super.viewDidLoad()

    let body = UIStackView(arrangedSubviews: [
      FKMediaGalleryExampleUI.button("Pick Live Photos (up to 6)") { [weak self] in
        self?.pickLivePhotos()
      },
      FKMediaGalleryExampleUI.button("Preview in gallery") { [weak self] in
        self?.previewLivePhotos()
      },
    ])
    body.axis = .vertical
    body.spacing = 8

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Live Photo playback",
        description: "Pick Live Photos from the library, map to FKMediaGalleryItem.livePhoto, then press and hold in the gallery to play motion (PHLivePhotoView). Context menu is disabled on Live Photo pages so the press-and-hold gesture is reserved for playback.",
        body: body
      ),
      at: 0
    )
  }

  private func pickLivePhotos() {
    Task { @MainActor in
      do {
        var configuration = FKPhotoPickerConfiguration()
        configuration.mediaTypes = [.images, .livePhotos]
        configuration.selection = FKPhotoPickerSelectionPolicy(limit: 6)
        configuration.livePhoto = .stillImageOnly
        let results = try await picker.pick(from: self, configuration: configuration)
        lastResults = results
        let liveCount = results.filter { $0.mediaType == .livePhoto }.count
        FKMediaGalleryExampleLog.shared.append("Picked \(results.count) item(s), \(liveCount) Live Photo(s).")
      } catch {
        FKMediaGalleryExampleLog.shared.append("Pick failed: \(error.localizedDescription)")
      }
    }
  }

  private func previewLivePhotos() {
    let items = FKMediaGalleryItem.from(lastResults)
    guard !items.isEmpty else {
      FKMediaGalleryExampleLog.shared.append("Pick Live Photos first.")
      return
    }
    var configuration = FKMediaGalleryPresets.socialFeed()
    configuration.livePhoto.isMutedDuringPlayback = false
    presentGallery(items: items, configuration: configuration)
  }
}
