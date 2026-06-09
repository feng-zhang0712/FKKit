import UIKit
import FKUIKit

final class FKAlertExampleQueuedAlertsViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Queued Alerts"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKAlertExampleUI.button("Enqueue three alerts (singleActive)") { [weak self] in
      guard let self else { return }
      var configuration = FKAlertConfiguration()
      configuration.queue = .singleActive
      self.presentAlert(
        FKAlertExamplePlaybook.queueContent(title: "First alert", message: "Dismiss to see the second."),
        configuration: configuration,
        label: "queue #1"
      )
      self.presentAlert(
        FKAlertExamplePlaybook.queueContent(title: "Second alert", message: "FIFO order."),
        configuration: configuration,
        label: "queue #2"
      )
      self.presentAlert(
        FKAlertExamplePlaybook.queueContent(title: "Third alert", message: "Final queued item."),
        configuration: configuration,
        label: "queue #3"
      )
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Replace current alert") { [weak self] in
      guard let self else { return }
      var configuration = FKAlertConfiguration()
      configuration.queue = .singleActive
      self.presentAlert(
        FKAlertExamplePlaybook.queueContent(title: "Original alert", message: "Will be replaced in 1s."),
        configuration: configuration,
        label: "replace original"
      )
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        var replaceConfiguration = FKAlertConfiguration()
        replaceConfiguration.queue = .replaceCurrent
        let result = await FKAlertPresenter.shared.present(
          FKAlertExamplePlaybook.queueContent(title: "Replacement alert", message: "Previous alert dismissed without handlers."),
          from: self,
          configuration: replaceConfiguration
        )
        FKAlertExampleLog.log("replacement: \(FKAlertExampleLog.describe(result))")
      }
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "FKAlertQueuePolicy",
        description: "singleActive queues additional present calls until the active alert dismisses. replaceCurrent dismisses the visible alert without invoking action handlers.",
        body: body
      )
    )
    addClearLogButton()
  }
}
