import UIKit

/// Presentation dependency-injection surface.
@MainActor
public protocol FKMediaGalleryPresenting: AnyObject {
  /// Presents a full-screen gallery over the given view controller.
  func present(
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int,
    transitionSource: FKMediaGalleryTransitionSource?,
    configuration: FKMediaGalleryConfiguration
  ) throws
}

/// Gallery lifecycle and action callbacks.
@MainActor
public protocol FKMediaGalleryDelegate: AnyObject {
  func mediaGallery(_ gallery: FKMediaGallery, willPresentWith itemCount: Int)
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didChangeCurrentIndex: Int,
    previousIndex: Int
  )
  func mediaGallery(_ gallery: FKMediaGallery, didDismissAt finalIndex: Int?)
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didFailToLoad item: FKMediaGalleryItem,
    at index: Int,
    error: FKMediaGalleryError
  )
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestShare item: FKMediaGalleryItem,
    at index: Int,
    sourceView: UIView
  ) -> Bool
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestSaveToPhotos item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool
  func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestEdit item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool
  func mediaGallery(
    _ gallery: FKMediaGallery,
    requestFullScreenVideoPlayerFor item: FKMediaGalleryItem,
    at index: Int,
    player: FKVideoPlayer
  ) -> Bool
}

extension FKMediaGalleryDelegate {
  public func mediaGallery(_ gallery: FKMediaGallery, willPresentWith itemCount: Int) {}
  public func mediaGallery(
    _ gallery: FKMediaGallery,
    didChangeCurrentIndex: Int,
    previousIndex: Int
  ) {}
  public func mediaGallery(_ gallery: FKMediaGallery, didDismissAt finalIndex: Int?) {}
  public func mediaGallery(
    _ gallery: FKMediaGallery,
    didFailToLoad item: FKMediaGalleryItem,
    at index: Int,
    error: FKMediaGalleryError
  ) {}
  public func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestShare item: FKMediaGalleryItem,
    at index: Int,
    sourceView: UIView
  ) -> Bool { false }
  public func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestSaveToPhotos item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool { false }
  public func mediaGallery(
    _ gallery: FKMediaGallery,
    didRequestEdit item: FKMediaGalleryItem,
    at index: Int
  ) -> Bool { false }
  public func mediaGallery(
    _ gallery: FKMediaGallery,
    requestFullScreenVideoPlayerFor item: FKMediaGalleryItem,
    at index: Int,
    player: FKVideoPlayer
  ) -> Bool { false }
}

/// Optional per-page overlay injection for custom chrome.
@MainActor
public protocol FKMediaGalleryChromeProviding: AnyObject {
  func mediaGallery(
    _ gallery: FKMediaGalleryViewController,
    overlayForPageAt index: Int,
    item: FKMediaGalleryItem
  ) -> UIView?
}
