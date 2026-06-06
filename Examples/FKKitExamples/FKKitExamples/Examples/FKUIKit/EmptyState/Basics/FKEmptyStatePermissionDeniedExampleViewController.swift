import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStatePermissionDeniedExampleViewController: UIViewController {
  private let container = UIView()
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Permission Denied"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.render()
    }
    render()
  }

  private func render() {
    var model = FKEmptyStateConfiguration.scenario(.noPermission)
    model.content.setImage(UIImage(systemName: "lock.shield"))
    container.fk_applyEmptyState(model) { [weak self] _ in
      self?.fk_presentMessageAlert(title: "Permission", message: "Primary action tapped.")
    }
  }
}
