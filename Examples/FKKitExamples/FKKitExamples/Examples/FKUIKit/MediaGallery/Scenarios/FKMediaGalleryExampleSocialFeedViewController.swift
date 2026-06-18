import FKUIKit
import UIKit

final class FKMediaGalleryExampleSocialFeedViewController: FKMediaGalleryExampleBaseViewController {
  private let feedGrid = FKMediaGalleryExampleFeedGridView()
  private lazy var feedItems = FKMediaGalleryExampleCatalog.socialFeedItems()

  override func viewDidLoad() {
    title = "Social Feed"
    super.viewDidLoad()

    feedGrid.setItems(feedItems)
    feedGrid.onSelect = { [weak self] index, thumbnailView in
      guard let self else { return }
      self.presentGallery(
        items: self.feedItems,
        startIndex: index,
        transitionSource: FKMediaGalleryTransitionSource(
          thumbnailView: thumbnailView,
          placeholderImage: thumbnailView.image ?? nil,
          itemIndex: index
        ),
        configuration: FKMediaGalleryPresets.socialFeed()
      )
    }

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "FKMediaGalleryPresets.socialFeed()",
        description: "Tap a thumbnail to hero into the gallery at that index. Progressive loading uses shared cache keys between feed cells and full-size URLs.",
        body: feedGrid
      ),
      at: 0
    )
    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.caption("Includes 9 remote images + 1 MP4 inserted at index 4."),
      at: 1
    )
  }
}
