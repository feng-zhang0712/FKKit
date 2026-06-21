@testable import FKUIKit
import XCTest

final class FKMediaGalleryItemResolverTests: XCTestCase {
  func testImageURLReturnsRemoteURLOnly() {
    let remote = URL(string: "https://cdn.example.com/photo.jpg")!

    XCTAssertEqual(
      FKMediaGalleryItemResolver.imageURL(for: .url(remote)),
      remote
    )
    XCTAssertNil(FKMediaGalleryItemResolver.imageURL(for: .image(UIImage())))
  }

  func testInlineImageReturnsUIImageOnly() {
    let image = UIImage()
    XCTAssertIdentical(
      FKMediaGalleryItemResolver.inlineImage(for: .image(image)),
      image
    )
    XCTAssertNil(
      FKMediaGalleryItemResolver.inlineImage(for: .url(URL(string: "https://example.com/a.jpg")!))
    )
  }

  func testPhotoAssetIdentifierExtractsLocalIdentifier() {
    XCTAssertEqual(
      FKMediaGalleryItemResolver.photoAssetIdentifier(for: .assetLocalIdentifier("asset-1")),
      "asset-1"
    )
    XCTAssertNil(
      FKMediaGalleryItemResolver.photoAssetIdentifier(for: .image(UIImage()))
    )
  }

  func testVideoItemMapsRemoteURLSource() {
    let url = URL(string: "https://cdn.example.com/video.mp4")!
    let item = FKMediaGalleryItemResolver.videoItem(
      for: .url(url, posterURL: nil, headers: ["Authorization": "Bearer token"], fallbackURLs: []),
      itemID: "clip-1"
    )

    XCTAssertEqual(item.id, "clip-1")
    if case let .url(resolvedURL, fallbackURLs, headers) = item.source {
      XCTAssertEqual(resolvedURL, url)
      XCTAssertEqual(headers["Authorization"], "Bearer token")
      XCTAssertTrue(fallbackURLs.isEmpty)
    } else {
      XCTFail("Expected URL video source")
    }
  }

  func testVideoItemMapsExistingFKVideoItem() {
    let existing = FKVideoItem(
      id: "existing",
      source: .url(URL(string: "https://example.com/a.mp4")!)
    )

    let item = FKMediaGalleryItemResolver.videoItem(for: .item(existing), itemID: "ignored")

    XCTAssertEqual(item.source, existing.source)
  }

  func testBundleVideoURLResolvesBundleResource() {
    let bundle = Bundle(for: FKMediaGalleryItemResolverTests.self)
    let url = bundle.url(forResource: "Info", withExtension: "plist")

    if let url {
      let resolved = FKMediaGalleryItemResolver.bundleVideoURL(
        for: .bundleResource(name: "Info", ext: "plist", bundle: bundle)
      )
      XCTAssertEqual(resolved, url)
    } else {
      XCTAssertNil(
        FKMediaGalleryItemResolver.bundleVideoURL(
          for: .bundleResource(name: "Missing", ext: "mp4", bundle: bundle)
        )
      )
    }
  }

  func testIsVideoDetectsVideoKind() {
    let video = FKMediaGalleryItem(
      id: "v",
      kind: .video(.url(URL(string: "https://example.com/a.mp4")!))
    )
    let image = FKMediaGalleryItem(
      id: "i",
      kind: .image(.image(UIImage()))
    )

    XCTAssertTrue(FKMediaGalleryItemResolver.isVideo(video))
    XCTAssertFalse(FKMediaGalleryItemResolver.isVideo(image))
  }

  func testIsLivePhotoDetectsLivePhotoKind() {
    let live = FKMediaGalleryItem(
      id: "l",
      kind: .livePhoto(.assetLocalIdentifier("live-id"))
    )

    XCTAssertTrue(FKMediaGalleryItemResolver.isLivePhoto(live))
    XCTAssertFalse(
      FKMediaGalleryItemResolver.isLivePhoto(
        FKMediaGalleryItem(id: "i", kind: .image(.image(UIImage())))
      )
    )
  }

  func testPhotoAssetVideoIdentifierExtractsLocalIdentifier() {
    XCTAssertEqual(
      FKMediaGalleryItemResolver.photoAssetVideoIdentifier(for: .assetLocalIdentifier("video-asset")),
      "video-asset"
    )
  }

  func testBundleImageLoadsNamedResourceWhenPresent() {
    let bundle = Bundle(for: FKMediaGalleryItemResolverTests.self)
    let image = FKMediaGalleryItemResolver.bundleImage(
      for: .bundleResource(name: "NonexistentAsset", bundle: bundle)
    )

    XCTAssertNil(image)
  }
}
