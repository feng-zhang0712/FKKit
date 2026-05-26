import UIKit
import FKUIKit

final class FKActionSheetExampleHandlersViewController: FKActionSheetExampleBaseViewController {
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
    body.addArrangedSubview(FKActionSheetExampleUI.button("hooks.didSelect") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentHooksDidSelect(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Callbacks",
        description: "handlerTiming, actionHandler, optional haptics, and FKActionSheetLifecycleHooks (will/did present & dismiss, didSelect).",
        body: body
      )
    )
    addClearLogButton()
  }
}
