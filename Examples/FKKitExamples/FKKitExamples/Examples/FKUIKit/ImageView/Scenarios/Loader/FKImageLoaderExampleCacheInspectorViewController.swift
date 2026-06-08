import FKCoreKit
import UIKit

final class FKImageLoaderExampleCacheInspectorViewController: UIViewController {
  private let preview = UIImageView()
  private let logLabel = UILabel()
  private let request = FKImageLoadRequest(
    url: FKImageViewExampleURLs.photo(id: 90, size: 160),
    targetSize: CGSize(width: 160, height: 160)
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cache management"
    view.backgroundColor = .systemBackground

    preview.contentMode = .scaleAspectFit
    preview.backgroundColor = .secondarySystemBackground
    preview.layer.cornerRadius = 12
    preview.clipsToBounds = true

    logLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "cachedImage(for:), store(_:forKey:), removeImage(forKey:), removeAllImages(), trimMemoryCache, cacheStatistics."
    ))
    preview.translatesAutoresizingMaskIntoConstraints = false
    preview.heightAnchor.constraint(equalToConstant: 160).isActive = true
    stack.addArrangedSubview(preview)
    stack.addArrangedSubview(logLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Load & cache", action: UIAction { [weak self] _ in
      self?.loadAndShow()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "cachedImage lookup", action: UIAction { [weak self] _ in
      self?.lookupCached()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "store synthetic bitmap", action: UIAction { [weak self] _ in
      self?.storeSynthetic()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "removeImage(forKey:)", action: UIAction { [weak self] _ in
      self?.removeOne()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "trimMemoryCache", action: UIAction { [weak self] _ in
      self?.trim()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "removeAllImages", action: UIAction { [weak self] _ in
      self?.clearAll()
    }))
  }

  private func loadAndShow() {
    Task {
      do {
        let image = try await FKImageLoader.shared.loadImage(for: request)
        preview.image = image
        appendLog("loadImage success")
        await logStats()
      } catch {
        appendLog("load failed: \(error)")
      }
    }
  }

  private func lookupCached() {
    let cached = FKImageLoader.shared.cachedImage(for: request)
    preview.image = cached
    appendLog("cachedImage: \(cached == nil ? "nil" : "hit")")
    Task { await logStats() }
  }

  private func storeSynthetic() {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
    let image = renderer.image { context in
      UIColor.systemOrange.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
    }
    let key = "demo-synthetic-\(UUID().uuidString.prefix(6))"
    FKImageLoader.shared.store(image, forKey: key)
    preview.image = FKImageLoader.shared.cachedImage(forKey: key)
    appendLog("store(_:forKey:) · key=\(key)")
    Task { await logStats() }
  }

  private func removeOne() {
    Task {
      await FKImageLoader.shared.removeImage(forKey: request.resolvedCacheKey)
      appendLog("removeImage(forKey:) for request key")
      await logStats()
    }
  }

  private func trim() {
    Task {
      await FKImageLoader.shared.trimMemoryCache(toCost: 512 * 1024)
      appendLog("trimMemoryCache(toCost: 512KB)")
      await logStats()
    }
  }

  private func clearAll() {
    Task {
      await FKImageLoader.shared.removeAllImages()
      preview.image = nil
      appendLog("removeAllImages()")
      await logStats()
    }
  }

  private func logStats() async {
    let stats = await FKImageLoader.shared.cacheStatistics()
    appendLog("memory=\(stats.memoryEntryCount) disk=\(stats.diskEntryCount) bytes=\(stats.diskByteCount)")
  }

  private func appendLog(_ line: String) {
    logLabel.text = (logLabel.text ?? "") + "\n" + line
  }
}
