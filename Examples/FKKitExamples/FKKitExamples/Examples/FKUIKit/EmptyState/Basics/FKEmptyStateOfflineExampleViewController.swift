import FKCoreKit
import FKUIKit
import UIKit

final class FKEmptyStateOfflineExampleViewController: UIViewController {
  private let container = UIView()
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Offline"
    view.backgroundColor = .systemBackground
    fk_embedFill(container, in: view)
    languageObservation = fk_observeEmptyStateLanguageRefresh { [weak self] in
      self?.render()
    }
    render()
  }

  private func render() {
    let model = FKEmptyStateExampleFactory.makeNoNetworkModel()
    container.fk_applyEmptyState(model) { [weak self] action in
      guard let self else { return }
      switch action.id {
      case "retry":
        self.fk_presentMessageAlert(title: "Retry", message: "Retry tapped.")
      case "docs":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      default:
        break
      }
    }
  }
}
