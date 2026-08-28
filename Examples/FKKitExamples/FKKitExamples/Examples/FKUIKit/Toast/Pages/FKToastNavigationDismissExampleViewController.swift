import FKUIKit
import UIKit

/// Demonstrates automatic toast dismissal when the presenting screen leaves the hierarchy.
final class FKToastNavigationDismissExampleViewController: FKToastExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Navigation Dismiss"

    contentStack.addArrangedSubview(
      FKToastExampleUI.section(
        title: "Host screen lifecycle",
        description: "Toast and snackbar dismiss by default when you push or pop away from the screen that triggered them. HUD keeps showing until timeout or manual dismiss.",
        body: FKToastExampleUI.row([
          FKToastExampleUI.button("Show toast") { [weak self] in
            self?.showContextualToast()
          },
          FKToastExampleUI.button("Show HUD") {
            FKHUD.showLoading("Uploading…", interceptTouches: false, timeout: 12)
          },
        ])
      )
    )
    contentStack.addArrangedSubview(
      FKToastExampleUI.button("Push detail (toast should dismiss)") { [weak self] in
        self?.navigationController?.pushViewController(FKToastNavigationDismissDetailViewController(), animated: true)
      }
    )
  }

  private func showContextualToast() {
    FKToast.show(
      "Saved locally. This toast dismisses when you leave this screen.",
      configuration: .init(kind: .toast, style: .success, position: .bottom, duration: 10)
    )
  }
}

private final class FKToastNavigationDismissDetailViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Detail"
    view.backgroundColor = .systemBackground

    let label = UILabel()
    label.text = "The toast from the previous screen should already be gone."
    label.numberOfLines = 0
    label.textAlignment = .center
    label.font = .preferredFont(forTextStyle: .body)
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
      label.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
    ])
  }
}
