import FKCoreKit
import FKUIKit
import UIKit

final class FKImageViewExamplePrefetchViewController: UIViewController {
  private let imageView = FKImageView()
  private let logLabel = UILabel()
  private let url = FKImageViewExampleURLs.photo(id: 77, size: 200)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Prefetch"
    view.backgroundColor = .systemBackground

    logLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Prefetch warms FKImageLoader cache before the view loads."

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "prefetch(_:) then load into FKImageView — second run should hit memory cache when checksMemoryCachePreview is enabled."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(logLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "1. Prefetch into cache", action: UIAction { [weak self] _ in
      self?.prefetch()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "2. Load into FKImageView", action: UIAction { [weak self] _ in
      self?.imageView.load(url: self?.url)
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Cancel prefetch", action: UIAction { [weak self] _ in
      guard let self else { return }
      let request = FKImageLoadRequest(url: url, targetSize: CGSize(width: 200, height: 200))
      FKImageLoader.shared.cancelPrefetch(for: request)
      appendLog("cancelPrefetch called")
    }))
  }

  private func prefetch() {
    let request = FKImageLoadRequest(url: url, targetSize: CGSize(width: 200, height: 200))
    Task {
      await FKImageLoader.shared.prefetch(request)
      let stats = await FKImageLoader.shared.cacheStatistics()
      appendLog("prefetch done · memory entries=\(stats.memoryEntryCount)")
    }
  }

  private func appendLog(_ line: String) {
    logLabel.text = (logLabel.text ?? "") + "\n" + line
  }
}
