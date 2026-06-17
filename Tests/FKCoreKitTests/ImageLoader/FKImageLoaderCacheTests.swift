import FKCoreKit
import UIKit
import XCTest

@MainActor
final class FKImageLoaderCacheTests: XCTestCase {
  private var tempDirectory: URL!

  override func setUp() {
    super.setUp()
    tempDirectory = FileManager.default.temporaryDirectory
      .appendingPathComponent("FKImageLoaderCacheTests-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
  }

  override func tearDown() {
    try? FileManager.default.removeItem(at: tempDirectory)
    tempDirectory = nil
    super.tearDown()
  }

  func testStorePersistsToDiskAndReadsBackAfterMemoryClear() async throws {
    let loader = makeLoader()
    let cacheKey = "disk-round-trip"
    let image = makeSolidImage(color: .systemOrange)
    let request = FKImageLoadRequest(
      url: URL(string: "https://image-loader.test/\(cacheKey).png")!,
      cacheKey: cacheKey
    )

    loader.store(image, forKey: cacheKey, persistsToDisk: true)
    try await Task.sleep(nanoseconds: 300_000_000)
    await loader.clearMemoryCache()

    XCTAssertNil(loader.cachedImage(forKey: cacheKey))
    XCTAssertNotNil(loader.cachedImage(for: request))
  }

  func testRemoveImageClearsMemoryAndDiskEntry() async throws {
    let loader = makeLoader()
    let cacheKey = "remove-me"
    let request = FKImageLoadRequest(
      url: URL(string: "https://image-loader.test/remove.png")!,
      cacheKey: cacheKey
    )

    loader.store(makeSolidImage(color: .systemRed), forKey: cacheKey, persistsToDisk: true)
    try await Task.sleep(nanoseconds: 300_000_000)
    await loader.removeImage(forKey: cacheKey)

    XCTAssertNil(loader.cachedImage(forKey: cacheKey))
    XCTAssertNil(loader.cachedImage(for: request))
  }

  func testCachedImageForRequestUsesExplicitCacheKeyOverride() {
    let loader = makeLoader()
    let image = makeSolidImage(color: .systemPurple)
    let cacheKey = "explicit-key"
    loader.store(image, forKey: cacheKey)

    let request = FKImageLoadRequest(
      url: URL(string: "https://image-loader.test/other-path.png")!,
      cacheKey: cacheKey
    )

    XCTAssertNotNil(loader.cachedImage(for: request))
  }

  // MARK: - Helpers

  private func makeLoader() -> FKImageLoader {
    var configuration = FKImageLoaderConfiguration(
      memoryCostLimit: 8 * 1024 * 1024,
      memoryCountLimit: 20,
      diskSizeLimit: 8 * 1024 * 1024,
      diskCacheDirectoryURL: tempDirectory,
      allowsSynchronousDiskCacheRead: true,
      isLoggingEnabled: false
    )
    return FKImageLoader(configuration: configuration)
  }

  private func makeSolidImage(color: UIColor) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
    return renderer.image { context in
      color.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
    }
  }
}
