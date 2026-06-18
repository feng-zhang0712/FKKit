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
  func setPagingEnabled(_ enabled: Bool)
  var isBlockingHorizontalPaging: Bool { get }
  var isBlockingInteractiveDismiss: Bool { get }
}

import FKCoreKit
