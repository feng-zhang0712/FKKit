import FKCoreKit
import UIKit

enum FKMediaGalleryItemResolver {
  static func imageURL(for source: FKMediaGalleryImageSource) -> URL? {
    switch source {
    case let .url(url, _):
      return url
    case .image, .bundleResource, .assetLocalIdentifier:
      return nil
    }
  }

  static func bundleImage(for source: FKMediaGalleryImageSource) -> UIImage? {
    switch source {
    case let .bundleResource(name, bundle):
      return UIImage(named: name, in: bundle, compatibleWith: nil)
    default:
      return nil
    }
  }

  static func inlineImage(for source: FKMediaGalleryImageSource) -> UIImage? {
    if case let .image(image) = source {
      return image
    }
    return nil
  }

  static func videoItem(for source: FKMediaGalleryVideoSource, itemID: String) -> FKVideoItem {
    switch source {
    case let .url(url, posterURL, headers, fallbackURLs):
      return FKVideoItem(
        id: itemID,
        source: .url(url, fallbackURLs: fallbackURLs, headers: headers),
        posterURL: posterURL
      )
    case let .item(item):
      return item
    case let .bundleResource(name, ext, bundle, posterURL):
      guard let url = bundle.url(forResource: name, withExtension: ext) else {
        return FKVideoItem(
          id: itemID,
          source: .url(URL(fileURLWithPath: "")),
          posterURL: posterURL
        )
      }
      return FKVideoItem(
        id: itemID,
        source: .url(url),
        posterURL: posterURL
      )
    case let .assetLocalIdentifier(identifier):
      return FKVideoItem(
        id: itemID,
        source: .photoAsset(localIdentifier: identifier)
      )
    }
  }

  static func photoAssetIdentifier(for source: FKMediaGalleryImageSource) -> String? {
    if case let .assetLocalIdentifier(identifier) = source {
      return identifier
    }
    return nil
  }

  static func photoAssetVideoIdentifier(for source: FKMediaGalleryVideoSource) -> String? {
    if case let .assetLocalIdentifier(identifier) = source {
      return identifier
    }
    return nil
  }

  static func isVideo(_ item: FKMediaGalleryItem) -> Bool {
    if case .video = item.kind { return true }
    return false
  }

  static func isLivePhoto(_ item: FKMediaGalleryItem) -> Bool {
    if case .livePhoto = item.kind { return true }
    return false
  }

  static func bundleVideoURL(for source: FKMediaGalleryVideoSource) -> URL? {
    guard case let .bundleResource(name, ext, bundle, _) = source else { return nil }
    return bundle.url(forResource: name, withExtension: ext)
  }
}
