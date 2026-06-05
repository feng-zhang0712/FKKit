import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateBasicExampleViewController: UIViewController {
  private let container = UIView()
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basic"
    view.backgroundColor = .systemBackground

    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)
    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.applyEmptyState()
    }
    applyEmptyState()
  }

  private func applyEmptyState() {
    let model = FKEmptyStateExampleFactory.makeBasicModel()
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.fk_presentMessageAlert(title: "Action", message: "Primary action tapped.")
    }
  }
}
