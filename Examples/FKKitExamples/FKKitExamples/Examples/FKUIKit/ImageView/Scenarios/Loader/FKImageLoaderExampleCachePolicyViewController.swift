import FKCoreKit
import UIKit

final class FKImageLoaderExampleCachePolicyViewController: UIViewController {
  private let preview = UIImageView()
  private let logLabel = UILabel()
  private let demoLoader = FKImageLoader()
  private let request = FKImageLoadRequest(
    url: FKImageViewExampleURLs.photo(id: 70, size: 200),
    targetSize: CGSize(width: 200, height: 200)
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Cache policies"
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
      "FKImageLoadOptions.cachePolicy and excludesFromDiskCache on a dedicated loader instance."
    ))
    preview.translatesAutoresizingMaskIntoConstraints = false
    preview.heightAnchor.constraint(equalToConstant: 180).isActive = true
    stack.addArrangedSubview(preview)
    stack.addArrangedSubview(logLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Warm cache (.default)", action: UIAction { [weak self] _ in
      self?.load(policy: .default, label: "default")
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "reloadIgnoringCache", action: UIAction { [weak self] _ in
      self?.load(policy: .reloadIgnoringCache, label: "reloadIgnoringCache")
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "cacheOnly (expect miss first)", action: UIAction { [weak self] _ in
      self?.load(policy: .cacheOnly, label: "cacheOnly")
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "excludesFromDiskCache", action: UIAction { [weak self] _ in
      self?.load(policy: .default, label: "excludesFromDiskCache", excludeDisk: true)
    }))
  }

  private func load(policy: FKImageLoadCachePolicy, label: String, excludeDisk: Bool = false) {
    Task {
      var options = FKImageLoadOptions()
      options.cachePolicy = policy
      options.excludesFromDiskCache = excludeDisk
      do {
        let result = try await demoLoader.loadImageResult(for: request, options: options)
        preview.image = result.image
        appendLog("\(label): success cached=\(result.wasCached)")
      } catch {
        appendLog("\(label): \(error)")
      }
    }
  }

  private func appendLog(_ line: String) {
    logLabel.text = (logLabel.text ?? "") + "\n" + line
  }
}
