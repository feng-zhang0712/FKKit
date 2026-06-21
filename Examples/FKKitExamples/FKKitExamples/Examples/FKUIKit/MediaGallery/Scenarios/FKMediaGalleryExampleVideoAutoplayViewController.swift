import FKUIKit
import UIKit

final class FKMediaGalleryExampleVideoAutoplayViewController: FKMediaGalleryExampleBaseViewController {
  override func viewDidLoad() {
    title = "Video Autoplay"
    super.viewDidLoad()

    var configuration = FKMediaGalleryPresets.socialFeed()
    configuration.video.autoplayCurrentVideo = true
    configuration.video.cellularAutoplayPolicy = .wifiOnly
    configuration.video.allowsScrubbing = true
    configuration.video.teardownPlayerWhenOffscreen = true
    configuration.video.playerConfiguration = .galleryEmbedded()

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKVideoPlayer in gallery",
        description: "Current video autoplays on Wi‑Fi only. Swipe to another clip to pause/teardown. Scrub the slim progress bar on the active page.",
        body: FKMediaGalleryExampleUI.button("Present video autoplay demo") { [weak self] in
          self?.presentGallery(
            items: FKMediaGalleryExampleCatalog.videoAutoplayItems(),
            configuration: configuration
          )
        }
      ),
      at: 0
    )
    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.caption("On cellular, poster + play button remain until manual play."),
      at: 1
    )
  }
}
