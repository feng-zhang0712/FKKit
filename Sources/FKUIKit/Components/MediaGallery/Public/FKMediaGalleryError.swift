import Foundation

/// Typed failures for media gallery presentation and per-item actions.
public enum FKMediaGalleryError: Error, Sendable, Equatable {
  case emptyItems
  case alreadyPresenting
  case presenterDeallocated
  case transitionSourceUnavailable
  case imageLoadFailed(index: Int, description: String)
  case videoLoadFailed(index: Int, underlying: String)
  case unsupportedItemKind
  case saveToPhotosDenied
  case shareItemUnavailable
  case updateItemsFailed(reason: String)
}

extension FKMediaGalleryError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyItems:
      return FKMediaGalleryI18n.emptyItemsMessage
    case .alreadyPresenting:
      return FKMediaGalleryI18n.alreadyPresentingMessage
    case .presenterDeallocated:
      return FKMediaGalleryI18n.presenterDeallocatedMessage
    case .transitionSourceUnavailable:
      return FKMediaGalleryI18n.transitionSourceUnavailableMessage
    case let .imageLoadFailed(_, description):
      return FKMediaGalleryI18n.imageLoadFailedMessage(description)
    case let .videoLoadFailed(_, underlying):
      return FKMediaGalleryI18n.videoLoadFailedMessage(underlying)
    case .unsupportedItemKind:
      return FKMediaGalleryI18n.unsupportedItemKindMessage
    case .saveToPhotosDenied:
      return FKMediaGalleryI18n.saveToPhotosDeniedMessage
    case .shareItemUnavailable:
      return FKMediaGalleryI18n.shareItemUnavailableMessage
    case let .updateItemsFailed(reason):
      return FKMediaGalleryI18n.updateItemsFailedMessage(reason)
    }
  }
}
