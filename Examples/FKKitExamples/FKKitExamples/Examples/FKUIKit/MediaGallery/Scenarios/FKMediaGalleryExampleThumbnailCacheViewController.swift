import FKUIKit
import UIKit

final class FKMediaGalleryExampleThumbnailCacheViewController: FKMediaGalleryExampleBaseViewController {
  private let feedImageView = FKImageView(profile: .listCell)
  private lazy var galleryItem = FKMediaGalleryExampleCatalog.cacheSharedFeedItem(index: 0)

  override func viewDidLoad() {
    title = "Shared Cache Key"
    super.viewDidLoad()

    feedImageView.translatesAutoresizingMaskIntoConstraints = false
    feedImageView.layer.cornerRadius = 8
    feedImageView.clipsToBounds = true
    feedImageView.heightAnchor.constraint(equalToConstant: 160).isActive = true

    if case let .image(.url(_, options)) = galleryItem.kind {
      feedImageView.cacheKey = options.thumbnailCacheKey ?? options.cacheKey
      feedImageView.load(url: options.thumbnailURL)
    }

    let body = UIStackView(arrangedSubviews: [
      feedImageView,
      FKMediaGalleryExampleUI.button("Open gallery from feed thumbnail") { [weak self] in
        guard let self else { return }
        self.presentGallery(
          items: [self.galleryItem],
          transitionSource: FKMediaGalleryTransitionSource(
            thumbnailView: self.feedImageView,
            placeholderImage: self.feedImageView.image
          ),
          configuration: FKMediaGalleryPresets.socialFeed()
        )
      },
    ])
    body.axis = .vertical
    body.spacing = 12

    contentStack.insertArrangedSubview(
      FKMediaGalleryExampleUI.section(
        title: "Feed → full-screen cache continuity",
        description: "Both FKImageView and FKMediaGallery use cacheKey feed/post/cache-demo. Gallery should show the cached thumbnail instantly, then cross-fade to full size.",
        body: body
      ),
      at: 0
    )
  }
}
