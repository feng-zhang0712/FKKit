import UIKit

@MainActor
protocol FKMediaGalleryPageView: AnyObject {
  var pageIndex: Int { get set }
  func prepareForDisplay(
    item: FKMediaGalleryItem,
    configuration: FKMediaGalleryConfiguration,
    imageLoader: (any FKImageLoading)?,
    placeholder: UIImage?
  )
  func didBecomeCurrent(configuration: FKMediaGalleryConfiguration)
  func didEndDisplaying()
  func galleryWillDismiss()
  /// Releases heavy image bitmaps when the page is far from the current index or under memory pressure.
  func releaseRetainedImageContent()
  /// Snapshot of visible media for interactive swipe-to-dismiss; `nil` when unavailable.
  func makeInteractiveDismissSnapshot() -> UIView?
  /// Bitmap used for aspect-fit interactive dismiss; preferred over raw snapshots.
  func interactiveDismissVisualContent() -> (image: UIImage, contentSize: CGSize)?
  var isBlockingHorizontalPaging: Bool { get }
  var isBlockingInteractiveDismiss: Bool { get }
}

import FKCoreKit
