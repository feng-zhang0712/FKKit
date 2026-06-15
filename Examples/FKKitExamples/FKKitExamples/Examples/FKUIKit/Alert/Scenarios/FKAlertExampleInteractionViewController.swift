import FKCoreKit
import UIKit
import FKUIKit

private final class FKAlertExampleDelegate: NSObject, FKAlertDelegate {
  func alertWillPresent(_ alert: FKAlertViewController) {
    FKAlertExampleLog.log("delegate: willPresent \"\(alert.content.title ?? "")\"")
  }

  func alertDidDismiss(_ alert: FKAlertViewController, result: FKAlertResult) {
    FKAlertExampleLog.log("delegate: didDismiss → \(FKAlertExampleLog.describe(result))")
  }
}

final class FKAlertExampleInteractionViewController: FKAlertExampleBaseViewController {
  private let exampleDelegate = FKAlertExampleDelegate()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Interaction & Lifecycle"
    FKAlertPresenter.shared.delegate = exampleDelegate

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKAlertExampleUI.button("Loading state (setLoading)") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        let content = FKAlertContent(
          title: "Upload photo?",
          message: "Primary/destructive buttons show a loading overlay while work runs.",
          actions: [
            FKAlertAction(title: "Upload", style: .default),
            FKAlertAction(title: "Cancel", style: .cancel),
          ]
        )
        async let result = FKAlertPresenter.shared.present(content, from: self)
        try? await Task.sleep(nanoseconds: 400_000_000)
        FKAlertPresenter.shared.setLoading(true)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        FKAlertPresenter.shared.setLoading(false)
        FKAlertPresenter.shared.dismiss(animated: true)
        FKAlertExampleLog.log("loading demo: \(FKAlertExampleLog.describe(await result))")
      }
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Stay open on primary (dismissOnPrimaryAction: false)") { [weak self] in
      guard let self else { return }
      var configuration = FKAlertConfiguration()
      configuration.interaction.dismissOnPrimaryAction = false
      let content = FKAlertContent(
        title: "Apply filter?",
        message: "Primary invokes handler without dismissing. Dismiss programmatically or tap Cancel.",
        actions: [
          FKAlertAction(title: "Apply", style: .default) {
            Task { @MainActor in FKAlertExampleLog.log("handler: filter applied (alert stays open)") }
          },
          FKAlertAction(title: "Cancel", style: .cancel),
        ]
      )
      self.presentAlert(content, configuration: configuration, label: "stay open")
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Destructive haptic preset") { [weak self] in
      var configuration = FKAlertPresets.destructiveConfirm()
      configuration.interaction.hapticOnDestructive = true
      self?.presentAlert(
        FKAlertExamplePlaybook.destructiveDeleteContent(),
        configuration: configuration,
        label: "haptic destructive"
      )
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Programmatic dismiss") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.informationalContent(),
        configuration: FKAlertPresets.informational(),
        label: "programmatic target"
      )
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        FKAlertPresenter.shared.dismiss(animated: true)
        FKAlertExampleLog.log("presenter.dismiss() called")
      }
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "FKAlertDelegate & interaction config",
        description: "FKAlertPresenter.shared.delegate receives willPresent/didDismiss. setLoading(_:) disables primary/destructive buttons. dismissOnPrimaryAction=false keeps the alert open after primary taps.",
        body: body
      )
    )
    addClearLogButton()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      FKAlertPresenter.shared.delegate = nil
    }
  }
}
