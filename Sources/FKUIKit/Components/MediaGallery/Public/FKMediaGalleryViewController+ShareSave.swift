import FKCoreKit
import UIKit

extension FKMediaGalleryViewController {
  func shareCurrentItem() {
    guard let item = currentItem else { return }
    shareGalleryItem(item, at: currentIndex, sourceView: chrome.shareAnchorView)
  }

  func shareGalleryItem(_ item: FKMediaGalleryItem, at index: Int, sourceView: UIView) {
    guard let gallery else {
      performDefaultShare(item: item, sourceView: sourceView)
      return
    }
    if galleryDelegate?.mediaGallery(gallery, didRequestShare: item, at: index, sourceView: sourceView) == true {
      return
    }
    performDefaultShare(item: item, sourceView: sourceView)
  }

  func saveGalleryItemToPhotos(_ item: FKMediaGalleryItem, at index: Int) async {
    guard let gallery else {
      await performDefaultSave(item: item)
      return
    }
    if galleryDelegate?.mediaGallery(gallery, didRequestSaveToPhotos: item, at: index) == true {
      return
    }
    await performDefaultSave(item: item)
  }

  private func performDefaultShare(item: FKMediaGalleryItem, sourceView: UIView) {
    let anchor = PopoverAnchor(sourceView: sourceView, sourceRect: sourceView.bounds)
    switch item.kind {
    case let .image(source):
      if let image = FKMediaGalleryItemResolver.inlineImage(for: source) {
        presentShare(
          UIActivityViewController(activityItems: [image], applicationActivities: nil),
          anchor: anchor
        )
        return
      }
      if let url = FKMediaGalleryItemResolver.imageURL(for: source) {
        presentShare(FKFileManager().makeShareController(for: url), anchor: anchor)
        return
      }
      FKToast.show(FKMediaGalleryI18n.shareItemUnavailableMessage, style: .error)
    case let .video(source):
      let videoItem = FKMediaGalleryItemResolver.videoItem(for: source, itemID: item.id)
      if let url = videoItem.source.primaryURL ?? videoItem.source.assetURL {
        presentShare(FKFileManager().makeShareController(for: url), anchor: anchor)
        return
      }
      FKToast.show(FKMediaGalleryI18n.shareItemUnavailableMessage, style: .error)
    case .livePhoto(_):
      FKToast.show(FKMediaGalleryI18n.shareItemUnavailableMessage, style: .error)
    }
  }

  private struct PopoverAnchor {
    let sourceView: UIView
    let sourceRect: CGRect
  }

  private func presentShare(_ controller: UIActivityViewController, anchor: PopoverAnchor) {
    if controller.traitCollection.userInterfaceIdiom == .pad,
       let popover = controller.popoverPresentationController {
      popover.sourceView = anchor.sourceView
      popover.sourceRect = anchor.sourceRect
      popover.permittedArrowDirections = [.up, .down]
    }
    present(controller, animated: true)
  }

  private func performDefaultSave(item: FKMediaGalleryItem) async {
    let permission = await FKPermissions.shared.request(.photoLibraryAddOnly)
    guard permission.isGranted else {
      FKToast.show(FKMediaGalleryI18n.saveToPhotosDeniedMessage, style: .error)
      return
    }
    switch item.kind {
    case let .image(source):
      if let image = FKMediaGalleryItemResolver.inlineImage(for: source) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        FKToast.show(FKMediaGalleryI18n.savedToPhotosMessage)
        return
      }
      if let url = FKMediaGalleryItemResolver.imageURL(for: source),
         let data = try? Data(contentsOf: url),
         let image = UIImage(data: data) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        FKToast.show(FKMediaGalleryI18n.savedToPhotosMessage)
        return
      }
    case let .video(source):
      let videoItem = FKMediaGalleryItemResolver.videoItem(for: source, itemID: item.id)
      if let url = videoItem.source.primaryURL ?? videoItem.source.assetURL {
        UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
        FKToast.show(FKMediaGalleryI18n.savedToPhotosMessage)
        return
      }
    case .livePhoto(_):
      break
    }
    FKToast.show(FKMediaGalleryI18n.shareItemUnavailableMessage, style: .error)
  }
}
