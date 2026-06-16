import FKCoreKit
import UIKit

/// Demonstrates `FKImageLoading` and `FKImageCaching`.
final class FKPluggableMediaExampleViewController: FKPluggableExampleBaseViewController {

  private let cache = DemoImageCache()
  private let loader = DemoImageLoader()
  private let imagePreview = UIImageView()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Pluggable · Media"
    loader.cache = cache
    loader.onLoad = { [weak self] line in
      Task { @MainActor in self?.appendOutput(line) }
    }

    imagePreview.contentMode = .scaleAspectFit
    imagePreview.backgroundColor = .tertiarySystemFill
    imagePreview.layer.cornerRadius = 8
    imagePreview.heightAnchor.constraint(equalToConstant: 80).isActive = true
    stackView.insertArrangedSubview(imagePreview, at: 0)

    addActionButton("1) loadImage (cache miss)") { [weak self] in
      Task { await self?.loadImage(useCacheKey: "avatar") }
    }
    addActionButton("2) loadImage (cache hit)") { [weak self] in
      Task { await self?.loadImage(useCacheKey: "avatar") }
    }
    addActionButton("3) cancelLoad") { [weak self] in
      let request = FKImageLoadRequest(url: URL(string: "https://cdn.example.com/large.jpg")!)
      self?.loader.cancelLoad(for: request)
    }
    addActionButton("4) removeImage(forKey:)") { [weak self] in
      self?.cache.removeImage(forKey: "avatar")
      self?.appendOutput("Removed cache key 'avatar'")
    }
    addActionButton("5) removeAllImages()") { [weak self] in
      self?.cache.removeAllImages()
      self?.imagePreview.image = nil
      self?.appendOutput("Cache cleared")
    }
    addActionButton("6) FKMockImageLoader (offline stub)") { [weak self] in
      Task { await self?.loadWithMockLoader() }
    }
    addActionButton("Clear log") { [weak self] in self?.clearOutput() }
  }

  private func loadImage(useCacheKey key: String) async {
    let request = FKImageLoadRequest(
      url: URL(string: "https://cdn.example.com/avatars/demo.png")!,
      targetWidth: 80,
      targetHeight: 80,
      cacheKey: key
    )
    do {
      let image = try await loader.loadImage(for: request)
      imagePreview.image = image
      appendOutput("UIImage size: \(image.size)")
    } catch {
      appendOutput("Load failed: \(error.localizedDescription)")
    }
  }

  private func loadWithMockLoader() async {
    let mock = FKMockImageLoader()
    let request = FKImageLoadRequest(
      url: URL(string: "https://cdn.example.com/offline.png")!,
      targetWidth: 80,
      targetHeight: 80
    )
    do {
      let image = try await mock.loadImage(for: request)
      imagePreview.image = image
      appendOutput("FKMockImageLoader calls=\(mock.loadCallCount), size=\(image.size)")
    } catch {
      appendOutput("Mock load failed: \(error.localizedDescription)")
    }
  }
}
