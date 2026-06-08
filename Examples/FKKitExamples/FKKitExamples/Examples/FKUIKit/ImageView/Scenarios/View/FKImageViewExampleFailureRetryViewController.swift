import FKUIKit
import UIKit

final class FKImageViewExampleFailureRetryViewController: UIViewController {
  private let imageView = FKImageView()
  private let stubLoader = FKImageExampleStubLoader()
  private let stateLabel = FKImageViewExampleLayout.stateLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Failure & retry"
    view.backgroundColor = .systemBackground

    imageView.imageLoader = stubLoader
    imageView.apply {
      $0.failure.isRetryEnabled = true
      $0.failure.retryButtonTitle = nil
      $0.interaction.retryDebounceInterval = 0.3
    }

    let stack = FKImageViewExampleLayout.installScrollableForm(in: view, safeArea: view.safeAreaLayoutGuide)
    stack.addArrangedSubview(FKImageViewExampleLayout.caption(
      "Stub loader simulates HTTP 404, offline, and decode failures. Tap overlay to retry when no button title is set."
    ))
    let host = FKImageViewExampleLayout.imageHost()
    FKImageViewExampleLayout.embed(imageView, in: host)
    stack.addArrangedSubview(host)
    stack.addArrangedSubview(stateLabel)
    FKImageViewExampleFactory.bindState(imageView, label: stateLabel)

    let modes = ["404", "Offline", "Decode", "Retry button"]
    let picker = UISegmentedControl(items: modes)
    picker.selectedSegmentIndex = 0
    stack.addArrangedSubview(picker)

    stack.addArrangedSubview(FKImageViewExampleLayout.primaryButton(title: "Trigger load", action: UIAction { [weak self] _ in
      self?.applyMode(picker.selectedSegmentIndex)
    }))

    applyMode(0)
  }

  private func applyMode(_ index: Int) {
    switch index {
    case 0:
      stubLoader.mode = .httpError(404)
      imageView.apply { $0.failure.retryButtonTitle = nil }
    case 1:
      stubLoader.mode = .offline
      imageView.apply { $0.failure.retryButtonTitle = nil }
    case 2:
      stubLoader.mode = .decodeFailed
      imageView.apply { $0.failure.retryButtonTitle = nil }
    default:
      stubLoader.mode = .httpError(404)
      imageView.apply { $0.failure.retryButtonTitle = "Try again" }
    }
    imageView.load(url: FKImageViewExampleURLs.photo(id: 1))
  }
}
