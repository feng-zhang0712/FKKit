import FKCoreKit
import UIKit

final class FKImageLoaderExamplePrefetchViewController: UIViewController {
  private let logLabel = UILabel()
  private let requests: [FKImageLoadRequest] = (80 ... 84).map { id in
    FKImageLoadRequest(
      url: FKImageViewExampleURLs.photo(id: id, size: 120),
      targetSize: CGSize(width: 120, height: 120)
    )
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Loader prefetch"
    view.backgroundColor = .systemBackground

    logLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Batch prefetch / cancelPrefetch on FKImageLoader.shared."

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Use prefetch before scrolling lists. Pair with UITableViewDataSourcePrefetching in the list reuse demo."
    ))
    stack.addArrangedSubview(logLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Prefetch batch (5 URLs)", action: UIAction { [weak self] _ in
      self?.prefetchBatch()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "prefetch(urls:)", action: UIAction { [weak self] _ in
      self?.prefetchURLs()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Cancel all prefetch", action: UIAction { [weak self] _ in
      self?.cancelAll()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Show cache stats", action: UIAction { [weak self] _ in
      self?.showStats()
    }))
  }

  private func prefetchBatch() {
    Task {
      appendLog("prefetching \(requests.count) requests…")
      for request in requests {
        await FKImageLoader.shared.prefetch(request)
      }
      await showStatsInline()
    }
  }

  private func prefetchURLs() {
    let urls = requests.map(\.url)
    Task {
      appendLog("prefetch(urls: \(urls.count))…")
      await FKImageLoader.shared.prefetch(urls: urls, targetSize: CGSize(width: 120, height: 120))
      await showStatsInline()
    }
  }

  private func showStatsInline() async {
    let stats = await FKImageLoader.shared.cacheStatistics()
    appendLog("done · memory=\(stats.memoryEntryCount) disk=\(stats.diskEntryCount)")
  }

  private func cancelAll() {
    for request in requests {
      FKImageLoader.shared.cancelPrefetch(for: request)
    }
    appendLog("cancelPrefetch for \(requests.count) requests")
  }

  private func showStats() {
    Task {
      let stats = await FKImageLoader.shared.cacheStatistics()
      appendLog("stats · memory=\(stats.memoryEntryCount) disk=\(stats.diskEntryCount) bytes=\(stats.diskByteCount)")
    }
  }

  private func appendLog(_ line: String) {
    logLabel.text = (logLabel.text ?? "") + "\n" + line
  }
}
