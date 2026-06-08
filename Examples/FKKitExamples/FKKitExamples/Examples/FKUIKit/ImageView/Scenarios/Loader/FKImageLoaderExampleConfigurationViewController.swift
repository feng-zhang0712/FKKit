import FKCoreKit
import UIKit

final class FKImageLoaderExampleConfigurationViewController: UIViewController {
  private let logLabel = UILabel()
  private var configuredLoader: FKImageLoader?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Configuration & events"
    view.backgroundColor = .systemBackground

    logLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "FKImageLoaderConfiguration · apply(_:) · onEvent · flushDiskCacheIndex."

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Custom memory/disk limits and metrics callbacks for cache hits, fetches, and evictions."
    ))
    stack.addArrangedSubview(logLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Create configured loader", action: UIAction { [weak self] _ in
      self?.createLoader()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Load with event log", action: UIAction { [weak self] _ in
      self?.loadWithEvents()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Apply tighter limits", action: UIAction { [weak self] _ in
      self?.applyTighterLimits()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "flushDiskCacheIndex", action: UIAction { [weak self] _ in
      self?.flushDisk()
    }))
  }

  private func createLoader() {
    var config = FKImageLoaderConfiguration(
      memoryCostLimit: 8 * 1024 * 1024,
      memoryCountLimit: 24,
      diskSizeLimit: 32 * 1024 * 1024,
      isLoggingEnabled: true
    )
    config.onEvent = { [weak self] event in
      Task { @MainActor in
        self?.appendLog(FKImageViewExampleFormatting.describe(event))
      }
    }
    configuredLoader = FKImageLoader(configuration: config)
    appendLog("created loader · memoryCountLimit=24")
  }

  private func applyTighterLimits() {
    guard let loader = configuredLoader else {
      appendLog("create loader first")
      return
    }
    loader.apply { config in
      config.memoryCountLimit = 8
      config.memoryCostLimit = 2 * 1024 * 1024
    }
    appendLog("apply tighter memory limits")
  }

  private func loadWithEvents() {
    if configuredLoader == nil {
      createLoader()
    }
    guard let loader = configuredLoader else { return }
    let request = FKImageLoadRequest(
      url: FKImageViewExampleURLs.photo(id: 95, size: 240),
      targetSize: CGSize(width: 240, height: 240)
    )
    Task {
      do {
        _ = try await loader.loadImage(for: request)
        appendLog("load finished")
      } catch {
        appendLog("load error: \(error)")
      }
    }
  }

  private func flushDisk() {
    guard let loader = configuredLoader else {
      appendLog("create loader first")
      return
    }
    Task {
      await loader.flushDiskCacheIndex()
      appendLog("flushDiskCacheIndex()")
    }
  }

  private func appendLog(_ line: String) {
    logLabel.text = (logLabel.text ?? "") + "\n" + line
  }
}
