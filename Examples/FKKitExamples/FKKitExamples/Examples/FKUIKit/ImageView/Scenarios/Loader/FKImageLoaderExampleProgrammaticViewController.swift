import FKCoreKit
import UIKit

final class FKImageLoaderExampleProgrammaticViewController: UIViewController {
  private let preview = UIImageView()
  private let logLabel = UILabel()
  private var loadTask: Task<Void, Never>?
  private let demoLoader = FKImageLoader()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Async load"
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
      "Programmatic FKImageLoader.loadImageResult with returnsSourceData and Task cancellation."
    ))
    preview.translatesAutoresizingMaskIntoConstraints = false
    preview.heightAnchor.constraint(equalToConstant: 200).isActive = true
    stack.addArrangedSubview(preview)
    stack.addArrangedSubview(logLabel)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "loadImageResult", action: UIAction { [weak self] _ in
      self?.startLoad()
    }))
    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Cancel Task", action: UIAction { [weak self] _ in
      self?.loadTask?.cancel()
      self?.appendLog("task.cancel()")
    }))
  }

  deinit {
    loadTask?.cancel()
  }

  private func startLoad() {
    loadTask?.cancel()
    let request = FKImageLoadRequest(
      url: FKImageViewExampleURLs.photo(id: 60, size: 320),
      targetSize: CGSize(width: 320, height: 320)
    )
    var options = FKImageLoadOptions()
    options.returnsSourceData = true
    loadTask = Task {
      do {
        appendLog("loading…")
        let result = try await demoLoader.loadImageResult(for: request, options: options)
        guard !Task.isCancelled else { return }
        preview.image = result.image
        let bytes = result.sourceData?.count ?? 0
        appendLog("success · cached=\(result.wasCached) · bytes=\(bytes)")
      } catch {
        appendLog("error: \(error)")
      }
    }
  }

  private func appendLog(_ line: String) {
    logLabel.text = (logLabel.text ?? "") + "\n" + line
  }
}
