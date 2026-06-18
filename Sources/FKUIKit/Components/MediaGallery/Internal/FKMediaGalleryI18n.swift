import FKCoreKit

enum FKMediaGalleryI18n {
  static var closeTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.close")
  }

  static var shareTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.share")
  }

  static var saveTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.save")
  }

  static var copyLinkTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.copy_link")
  }

  static var editTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.edit")
  }

  static var muteTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.mute")
  }

  static var unmuteTitle: String {
    FKUIKitI18n.string("fkuikit.media_gallery.action.unmute")
  }

  static var emptyItemsMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.empty_items")
  }

  static var alreadyPresentingMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.already_presenting")
  }

  static var presenterDeallocatedMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.presenter_deallocated")
  }

  static var transitionSourceUnavailableMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.transition_source_unavailable")
  }

  static func imageLoadFailedMessage(_ description: String) -> String {
    FKUIKitI18n.format("fkuikit.media_gallery.error.image_load_failed", description)
  }

  static func videoLoadFailedMessage(_ underlying: String) -> String {
    FKUIKitI18n.format("fkuikit.media_gallery.error.video_load_failed", underlying)
  }

  static var unsupportedItemKindMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.unsupported_item_kind")
  }

  static var saveToPhotosDeniedMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.save_denied")
  }

  static var shareItemUnavailableMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.error.share_unavailable")
  }

  static func updateItemsFailedMessage(_ reason: String) -> String {
    FKUIKitI18n.format("fkuikit.media_gallery.error.update_failed", reason)
  }

  static func photoPageIndicator(current: Int, total: Int) -> String {
    FKUIKitI18n.format("fkuikit.media_gallery.page.photo", current, total)
  }

  static func videoPageIndicator(current: Int, total: Int) -> String {
    FKUIKitI18n.format("fkuikit.media_gallery.page.video", current, total)
  }

  static func mixedPageIndicator(current: Int, total: Int) -> String {
    FKUIKitI18n.format("fkuikit.media_gallery.page.mixed", current, total)
  }

  static var linkCopiedMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.toast.link_copied")
  }

  static var savedToPhotosMessage: String {
    FKUIKitI18n.string("fkuikit.media_gallery.toast.saved_to_photos")
  }
}
