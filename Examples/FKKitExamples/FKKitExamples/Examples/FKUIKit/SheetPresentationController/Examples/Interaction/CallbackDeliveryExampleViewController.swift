import UIKit
import FKUIKit

/// Compares ``FKSheetPresentationCallbackDelivery`` modes side by side.
final class CallbackDeliveryExampleViewController: FKSheetPresentationExamplePageViewController, FKSheetPresentationControllerDelegate {
  private var deliveryIndex: Int = 1
  private let logLabel = UILabel()
  private var activePresentation: FKSheetPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Callback delivery",
      subtitle: "Choose delegate-only, handlers-only, or both lifecycle channels.",
      notes: """
      Default is `.handlersOnly`. Pick one channel in production to avoid duplicate analytics or state updates.
      """
    )

    logLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
    logLabel.textColor = .secondaryLabel
    logLabel.numberOfLines = 0
    logLabel.text = "Events will appear here."
    addView(logLabel)

    addView(
      FKExampleControls.segmented(
        title: "Delivery",
        items: ["Delegate", "Handlers", "Both"],
        selectedIndex: deliveryIndex
      ) { [weak self] idx in
        self?.deliveryIndex = idx
      }
    )

    addPrimaryButton(title: "Present") { [weak self] in
      self?.presentSample()
    }
  }

  private func presentSample() {
    appendLog("— presenting —")
    let delivery: FKSheetPresentationCallbackDelivery
    switch deliveryIndex {
    case 0: delivery = .delegateOnly
    case 1: delivery = .handlersOnly
    default: delivery = .both
    }

    var configuration = FKSheetPresentationExampleHelpers.bottomSheetConfiguration()
    configuration.sheet.detents = [.fixed(280), .full]

    let handlers = FKSheetPresentationLifecycleHandlers(
      willPresent: { [weak self] in self?.appendLog("[handler] willPresent") },
      didPresent: { [weak self] in self?.appendLog("[handler] didPresent") },
      willDismiss: { [weak self] in self?.appendLog("[handler] willDismiss") },
      didDismiss: { [weak self] in
        self?.appendLog("[handler] didDismiss")
        self?.activePresentation = nil
      }
    )

    activePresentation = FKSheetPresentationController.present(
      contentController: FKExampleLabelContentViewController(text: "Callback delivery"),
      from: self,
      configuration: configuration,
      delegate: delivery == .handlersOnly ? nil : self,
      handlers: handlers,
      callbackDelivery: delivery,
      animated: true,
      completion: nil
    )
  }

  private func appendLog(_ line: String) {
    let existing = logLabel.text ?? ""
    logLabel.text = existing.isEmpty || existing == "Events will appear here." ? line : existing + "\n" + line
  }

  func presentationControllerWillPresent(_ controller: FKSheetPresentationController) {
    appendLog("[delegate] willPresent")
  }

  func presentationControllerDidPresent(_ controller: FKSheetPresentationController) {
    appendLog("[delegate] didPresent")
  }

  func presentationControllerWillDismiss(_ controller: FKSheetPresentationController) {
    appendLog("[delegate] willDismiss")
  }

  func presentationControllerDidDismiss(_ controller: FKSheetPresentationController) {
    appendLog("[delegate] didDismiss")
  }
}
