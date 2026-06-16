import UIKit
import FKCoreKit

/// B9 — system alert presentOnce de-duplication.
final class FKBusinessKitExampleAlertPresentOnceViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "AlertPresentOnce"
    kit.updateConfiguration { $0.alertBackend = .systemAlert }
    addInfoLabel("Tap rapidly — only one alert shows per id until dismissed.")
    addActionButton("Present once (system alert)") { [weak self] in
      self?.kit.utils.alerts.presentOnce(
        id: "businesskit.b9.demo",
        title: "Present Once",
        message: "Duplicate ids are suppressed while visible.",
        actions: [FKAlertAction(title: "OK", style: .default, handler: nil)],
        presenter: self
      )
    }
  }
}
