import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateErrorRetryExampleViewController: UIViewController {
  private let container = UIView()
  private var isRetrying = false
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Error + Retry"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.showError()
    }
    showError()
  }

  private func showError() {
    var model = FKEmptyStateExampleFactory.makeLoadFailedModel()
    if isRetrying {
      model.actions = FKEmptyStateActionSet(
        primary: FKEmptyStateAction(
          id: "retry",
          title: FKEmptyStateConfiguration.defaultRetryButtonTitle,
          kind: .primary,
          isLoading: true
        )
      )
    }
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.startRetryFlow()
    }
  }

  private func startRetryFlow() {
    guard !isRetrying else { return }
    isRetrying = true
    showError()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      guard let self else { return }
      self.isRetrying = false
      self.container.fk_applyEmptyState(FKEmptyStateExampleFactory.makeBasicModel())
    }
  }
}
