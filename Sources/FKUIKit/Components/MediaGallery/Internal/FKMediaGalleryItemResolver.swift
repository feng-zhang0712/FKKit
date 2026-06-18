import FKCoreKit
import Network
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
      let url = bundle.url(forResource: name, withExtension: ext) ?? URL(fileURLWithPath: "/dev/null")
      return FKVideoItem(
        id: itemID,
        source: .url(url),
        posterURL: posterURL
      )
    }
  }

  static func photoAssetIdentifier(for source: FKMediaGalleryImageSource) -> String? {
    if case let .assetLocalIdentifier(identifier) = source {
      return identifier
    }
    return nil
  }

  static func isVideo(_ item: FKMediaGalleryItem) -> Bool {
    if case .video = item.kind { return true }
    return false
  }
}

/// One-shot Wi‑Fi reachability check for autoplay policy.
enum FKMediaGalleryNetworkPolicy {
  static func allowsAutoplay(for policy: FKMediaGalleryAutoplayPolicy) -> Bool {
    switch policy {
    case .always:
      return true
    case .never:
      return false
    case .wifiOnly:
      return isOnWiFi()
    }
  }

  private static func isOnWiFi() -> Bool {
    final class Box: @unchecked Sendable {
      var value = false
    }
    let box = Box()
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "com.fkkit.media_gallery.network")
    let semaphore = DispatchSemaphore(value: 0)
    monitor.pathUpdateHandler = { path in
      box.value = path.status == .satisfied && path.usesInterfaceType(.wifi)
      semaphore.signal()
      monitor.cancel()
    }
    monitor.start(queue: queue)
    _ = semaphore.wait(timeout: .now() + 0.25)
    return box.value
  }
}
