import UIKit

/// A single page in a media gallery session.
public struct FKMediaGalleryItem: @unchecked Sendable, Identifiable {
  /// Stable identifier for diffing, hero transitions, and runtime updates.
  public var id: String
  /// Image or video payload for this page.
  public var kind: FKMediaGalleryItemKind
  /// Optional caption shown in chrome when enabled.
  public var caption: String?
  /// VoiceOver label override; falls back to caption or localized kind label.
  public var accessibilityLabel: String?
  /// Optional link copied by the context menu (for example an original media URL).
  public var shareURL: URL?

  public init(
    id: String = UUID().uuidString,
    kind: FKMediaGalleryItemKind,
    caption: String? = nil,
    accessibilityLabel: String? = nil,
    shareURL: URL? = nil
  ) {
    self.id = id
    self.kind = kind
    self.caption = caption
    self.accessibilityLabel = accessibilityLabel
    self.shareURL = shareURL
  }
}

/// Media payload kind for a gallery page.
public enum FKMediaGalleryItemKind: @unchecked Sendable {
  case image(FKMediaGalleryImageSource)
  case video(FKMediaGalleryVideoSource)
  case livePhoto(FKMediaGalleryLivePhotoSource)
}

extension FKMediaGalleryItemKind: Equatable {
  public static func == (lhs: FKMediaGalleryItemKind, rhs: FKMediaGalleryItemKind) -> Bool {
    switch (lhs, rhs) {
    case let (.image(l), .image(r)):
      return l == r
    case let (.video(l), .video(r)):
      return l == r
    case let (.livePhoto(l), .livePhoto(r)):
      return l == r
    default:
      return false
    }
  }
}

extension FKMediaGalleryItem: Equatable {
  public static func == (lhs: FKMediaGalleryItem, rhs: FKMediaGalleryItem) -> Bool {
    lhs.id == rhs.id
      && lhs.kind == rhs.kind
      && lhs.caption == rhs.caption
      && lhs.accessibilityLabel == rhs.accessibilityLabel
      && lhs.shareURL == rhs.shareURL
  }
}

/// Progressive and cache options for remote gallery images.
public struct FKMediaGalleryImageRequestOptions: Sendable, Equatable {
  /// Shared cache key with feed thumbnails for instant cache hits.
  public var cacheKey: String?
  /// Smaller URL shown first; full-size loaded progressively when set.
  public var thumbnailURL: URL?
  /// Optional cache key for the thumbnail request.
  public var thumbnailCacheKey: String?

  public init(
    cacheKey: String? = nil,
    thumbnailURL: URL? = nil,
    thumbnailCacheKey: String? = nil
  ) {
    self.cacheKey = cacheKey
    self.thumbnailURL = thumbnailURL
    self.thumbnailCacheKey = thumbnailCacheKey
  }
}

/// Image source variants supported by the gallery.
public enum FKMediaGalleryImageSource: @unchecked Sendable {
  case url(URL, options: FKMediaGalleryImageRequestOptions = .init())
  case image(UIImage)
  case bundleResource(name: String, bundle: Bundle = .main)
  case assetLocalIdentifier(String)
}

extension FKMediaGalleryImageSource: Equatable {
  public static func == (lhs: FKMediaGalleryImageSource, rhs: FKMediaGalleryImageSource) -> Bool {
    switch (lhs, rhs) {
    case let (.url(lURL, lOptions), .url(rURL, rOptions)):
      return lURL == rURL && lOptions == rOptions
    case let (.image(lImage), .image(rImage)):
      return lImage === rImage
    case let (.bundleResource(lName, lBundle), .bundleResource(rName, rBundle)):
      return lName == rName && lBundle == rBundle
    case let (.assetLocalIdentifier(lID), .assetLocalIdentifier(rID)):
      return lID == rID
    default:
      return false
    }
  }
}

/// Video source variants supported by the gallery.
public enum FKMediaGalleryVideoSource: Sendable, Equatable {
  case url(
    URL,
    posterURL: URL? = nil,
    headers: [String: String] = [:],
    fallbackURLs: [URL] = []
  )
  case item(FKVideoItem)
  case bundleResource(name: String, ext: String, bundle: Bundle = .main, posterURL: URL? = nil)
  /// Plays a library video via ``FKMediaSource/photoAsset(localIdentifier:)``.
  case assetLocalIdentifier(String)
}

/// Live Photo source variants supported by the gallery.
public enum FKMediaGalleryLivePhotoSource: Sendable, Equatable {
  /// Loads paired still + motion from the photo library via ``PHAsset/localIdentifier``.
  case assetLocalIdentifier(String)
}
