import FKUIKit
import UIKit

final class FKMediaGalleryExampleFullVideoHandoffViewController: FKMediaGalleryExampleBaseViewController {
  private let handoffDelegate = FKMediaGalleryExampleHandoffDelegate()

  override func viewDidLoad() {
    title = "Full Video Player"
    super.viewDidLoad()
    gallery.delegate = handoffDelegate

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "requestFullScreenVideoPlayerFor",
        description: "Delegate intercepts the handoff and presents FKVideoPlayerViewController with the active FKVideoPlayer instance for PiP-ready full chrome.",
        body: FKMediaGalleryExampleUI.button("Present video handoff demo") { [weak self] in
          guard let self else { return }
          var configuration = FKMediaGalleryPresets.socialFeed()
          configuration.video.autoplayCurrentVideo = true
          self.presentGallery(
            items: FKMediaGalleryExampleCatalog.videoAutoplayItems(),
            configuration: configuration
          )
        }
      ),
      at: 0
    )
  }
}

@MainActor
private final class FKMediaGalleryExampleHandoffDelegate: NSObject, FKMediaGalleryDelegate {
  func mediaGallery(
    _ gallery: FKMediaGallery,
    requestFullScreenVideoPlayerFor item: FKMediaGalleryItem,
    at index: Int,
    player: FKVideoPlayer
  ) -> Bool {
    FKMediaGalleryExampleLog.shared.append("handoff @\(index) → FKVideoPlayerViewController")
    guard let presenter = gallery.viewController else { return false }
    let controller = FKVideoPlayerViewController(player: player)
    presenter.present(controller, animated: true)
    return true
  }
}
