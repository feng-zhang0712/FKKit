import FKUIKit
import UIKit

/// Sample items and asset helpers for MediaGallery examples.
enum FKMediaGalleryExampleCatalog {
  private static let postPrefix = "post/demo"

  // MARK: - Images

  static func generatedImage(label: String, color: UIColor) -> UIImage {
    let size = CGSize(width: 320, height: 320)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(origin: .zero, size: size))
      let attrs: [NSAttributedString.Key: Any] = [
        .font: UIFont.boldSystemFont(ofSize: 28),
        .foregroundColor: UIColor.white,
      ]
      let textSize = (label as NSString).size(withAttributes: attrs)
      let origin = CGPoint(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2
      )
      (label as NSString).draw(at: origin, withAttributes: attrs)
    }
  }

  static func localFileImageURL() -> URL {
    FKImageViewExampleFactory.makeLocalFileURL()
  }

  static func remoteImageURL(id: Int, size: Int = 800) -> URL {
    FKImageViewExampleURLs.photo(id: id, size: size)
  }

  static func remoteThumbnailURL(id: Int) -> URL {
    FKImageViewExampleURLs.photo(id: id, size: 240)
  }

  // MARK: - Video

  static var localVideoFileURL: URL {
    get async throws {
      let destination = FileManager.default.temporaryDirectory
        .appendingPathComponent("fkgallery-local-demo.mp4")
      if FileManager.default.fileExists(atPath: destination.path) {
        return destination
      }
      let (tempURL, _) = try await URLSession.shared.download(from: FKVideoPlayerExampleCatalog.progressiveMP4)
      if FileManager.default.fileExists(atPath: destination.path) {
        try? FileManager.default.removeItem(at: destination)
      }
      try FileManager.default.moveItem(at: tempURL, to: destination)
      return destination
    }
  }

  // MARK: - Item builders

  static func socialFeedItems() -> [FKMediaGalleryItem] {
    var items: [FKMediaGalleryItem] = []
    let imageIDs = FKImageViewExampleURLs.feedIDs(count: 9)
    for (index, photoID) in imageIDs.enumerated() {
      let full = remoteImageURL(id: photoID, size: 1200)
      let thumb = remoteThumbnailURL(id: photoID)
      items.append(
        FKMediaGalleryItem(
          id: "\(postPrefix)/image/\(index)",
          kind: .image(.url(
            full,
            options: FKMediaGalleryImageRequestOptions(
              cacheKey: "\(postPrefix)/image/\(index)",
              thumbnailURL: thumb,
              thumbnailCacheKey: "\(postPrefix)/thumb/\(index)"
            )
          )),
          caption: "Photo \(index + 1) of the post",
          shareURL: full
        )
      )
    }
    items.insert(
      FKMediaGalleryItem(
        id: "\(postPrefix)/video/0",
        kind: .video(.url(
          FKVideoPlayerExampleCatalog.progressiveMP4,
          posterURL: remoteThumbnailURL(id: 60)
        )),
        caption: "Clip from the same post"
      ),
      at: 4
    )
    return items
  }

  static func localMixedItems() async throws -> [FKMediaGalleryItem] {
    let videoURL = try await localVideoFileURL
    return [
      FKMediaGalleryItem(
        id: "local.image.inline",
        kind: .image(.image(generatedImage(label: "Memory", color: .systemIndigo))),
        caption: "In-memory UIImage"
      ),
      FKMediaGalleryItem(
        id: "local.image.file",
        kind: .image(.url(localFileImageURL())),
        caption: "Local file:// image"
      ),
      FKMediaGalleryItem(
        id: "local.video.file",
        kind: .video(.url(videoURL, posterURL: nil)),
        caption: "Local file:// MP4"
      ),
    ]
  }

  static func remoteMixedItems() -> [FKMediaGalleryItem] {
    [
      FKMediaGalleryItem(
        id: "remote.image",
        kind: .image(.url(remoteImageURL(id: 42))),
        caption: "Remote HTTPS image"
      ),
      FKMediaGalleryItem(
        id: "remote.mp4",
        kind: .video(.item(FKVideoPlayerExampleCatalog.progressiveItem())),
        caption: "Remote progressive MP4"
      ),
      FKMediaGalleryItem(
        id: "remote.hls",
        kind: .video(.item(FKVideoPlayerExampleCatalog.hlsVODItem())),
        caption: "Remote HLS VOD"
      ),
    ]
  }

  static func localRemoteMixedItems() async throws -> [FKMediaGalleryItem] {
    var remote = remoteMixedItems()
    remote.insert(
      FKMediaGalleryItem(
        id: "mixed.local",
        kind: .image(.image(generatedImage(label: "Local", color: .systemOrange)))
      ),
      at: 0
    )
    let videoURL = try await localVideoFileURL
    remote.append(
      FKMediaGalleryItem(
        id: "mixed.local.video",
        kind: .video(.url(videoURL))
      )
    )
    return remote
  }

  static func remoteLoadingItems() -> [FKMediaGalleryItem] {
    [
      FKMediaGalleryItem(
        id: "slow.image",
        kind: .image(.url(remoteImageURL(id: 15))),
        caption: "Progress indicator while loading"
      ),
      FKMediaGalleryItem(
        id: "broken.image",
        kind: .image(.url(FKImageViewExampleURLs.notFound)),
        caption: "404 — failure UI + delegate"
      ),
    ]
  }

  static func authenticatedVideoItem() -> FKMediaGalleryItem {
    FKMediaGalleryItem(
      id: "auth.video",
      kind: .video(.url(
        FKVideoPlayerExampleCatalog.progressiveMP4,
        posterURL: remoteThumbnailURL(id: 30),
        headers: ["Authorization": "Bearer demo-token"]
      )),
      caption: "FKMediaGalleryVideoSource.url headers → FKVideoItem"
    )
  }

  static func chatDraftItems() -> [FKMediaGalleryItem] {
    (0 ..< 4).map { index in
      FKMediaGalleryItem(
        id: "chat.\(index)",
        kind: .image(.image(generatedImage(label: "\(index + 1)", color: [.systemTeal, .systemPurple, .systemGreen, .systemPink][index % 4]))),
        caption: "Attachment \(index + 1) — delete before send"
      )
    }
  }

  static func singleImageItem() -> [FKMediaGalleryItem] {
    [
      FKMediaGalleryItem(
        id: "single",
        kind: .image(.url(remoteImageURL(id: 50))),
        caption: "Only one page — indicator hidden"
      ),
    ]
  }

  static func productDetailItems() -> [FKMediaGalleryItem] {
    (0 ..< 3).map { index in
      FKMediaGalleryItem(
        id: "product.\(index)",
        kind: .image(.url(remoteImageURL(id: 20 + index * 5, size: 1600))),
        caption: "Product angle \(index + 1) — pinch up to 6×"
      )
    }
  }

  static func zoomGestureItems() -> [FKMediaGalleryItem] {
    [
      FKMediaGalleryItem(
        id: "zoom.image",
        kind: .image(.url(remoteImageURL(id: 64, size: 1400))),
        caption: "Double-tap focal zoom · pinch · page arbitration"
      ),
    ]
  }

  static func videoAutoplayItems() -> [FKMediaGalleryItem] {
    [
      FKMediaGalleryItem(
        id: "autoplay.1",
        kind: .video(.item(FKVideoPlayerExampleCatalog.progressiveItem(title: "Clip A"))),
        caption: "Wi‑Fi only autoplay policy"
      ),
      FKMediaGalleryItem(
        id: "autoplay.2",
        kind: .video(.item(FKVideoPlayerExampleCatalog.progressiveItem(title: "Clip B"))),
        caption: "Swipe away to pause + teardown"
      ),
    ]
  }

  static func contextMenuItems() -> [FKMediaGalleryItem] {
    [
      FKMediaGalleryItem(
        id: "menu.image",
        kind: .image(.image(generatedImage(label: "Share", color: .systemPink))),
        caption: "Long-press for save / share / copy link",
        shareURL: URL(string: "https://example.com/media/demo")
      ),
    ]
  }

  static func cacheSharedFeedItem(index: Int) -> FKMediaGalleryItem {
    let id = 33
    return FKMediaGalleryItem(
      id: "cache/\(index)",
      kind: .image(.url(
        remoteImageURL(id: id, size: 1200),
        options: FKMediaGalleryImageRequestOptions(
          cacheKey: "feed/post/cache-demo",
          thumbnailURL: remoteThumbnailURL(id: id),
          thumbnailCacheKey: "feed/post/cache-demo"
        )
      )),
      caption: "Feed thumbnail and gallery share cacheKey"
    )
  }
}
