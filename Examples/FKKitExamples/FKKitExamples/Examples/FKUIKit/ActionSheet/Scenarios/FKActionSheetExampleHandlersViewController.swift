import UIKit
import FKUIKit

final class FKActionSheetExampleHandlersViewController: FKActionSheetExampleBaseViewController {
  private let delegateProxy = DelegateProxy()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Handlers & Lifecycle"

    let timing = FKActionSheetExampleUI.row([
      FKActionSheetExampleUI.button("Before dismiss") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentHandlerTiming(.beforeDismiss, from: $0) }
      },
      FKActionSheetExampleUI.button("After animation") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentHandlerTiming(.afterDismissAnimation, from: $0) }
      },
    ])

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(timing)
    body.addArrangedSubview(FKActionSheetExampleUI.button("actionHandler") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentActionHandler(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Selection haptics") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentWithHaptics(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Delegate callbacks") { [weak self] in
      guard let self else { return }
      self.presentWithDelegate(from: self)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Callbacks",
        description: "handlerTiming, actionHandler precedence, optional haptics, hooks (logged below), and FKActionSheetDelegate.",
        body: body
      )
    )
    addClearLogButton()
  }

  private func presentWithDelegate(from presenter: UIViewController) {
    var config = FKActionSheetExamplePlaybook.withEventLogging(
      FKActionSheetConfiguration(
        header: .text(FKActionSheetHeader(message: "Delegate mirrors lifecycle + didSelect.")),
        sections: [FKActionSheetSection(actions: [FKActionSheetAction(title: "Select me") { }])],
        cancelAction: FKActionSheetExamplePlaybook.makeCancelAction()
      )
    )
    config.delegate = delegateProxy
    _ = FKActionSheetExamplePlaybook.present(config, from: presenter, logEvents: false)
  }

  private final class DelegateProxy: NSObject, FKActionSheetDelegate {
    func actionSheetWillPresent(_ handle: FKActionSheetHandle) {
      FKActionSheetExamplePlaybook.log("delegate willPresent")
    }

    func actionSheetDidPresent(_ handle: FKActionSheetHandle) {
      FKActionSheetExamplePlaybook.log("delegate didPresent")
    }

    func actionSheetWillDismiss(_ handle: FKActionSheetHandle, reason: FKActionSheetDismissReason) {
      FKActionSheetExamplePlaybook.log("delegate willDismiss(\(String(describing: reason)))")
    }

    func actionSheetDidDismiss(_ handle: FKActionSheetHandle, reason: FKActionSheetDismissReason) {
      FKActionSheetExamplePlaybook.log("delegate didDismiss(\(String(describing: reason)))")
    }

    func actionSheet(_ handle: FKActionSheetHandle, didSelect action: FKActionSheetAction) {
      FKActionSheetExamplePlaybook.log("delegate didSelect(\(action.title))")
    }
  }
}
