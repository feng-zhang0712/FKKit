import UIKit
import FKUIKit

/// Handler timing, haptics, lifecycle hooks, and dismiss reasons.
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

    let callbacks = UIStackView()
    callbacks.axis = .vertical
    callbacks.spacing = 8
    callbacks.addArrangedSubview(timing)
    callbacks.addArrangedSubview(FKActionSheetExampleUI.button("actionHandler") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentActionHandler(from: $0) }
    })
    callbacks.addArrangedSubview(FKActionSheetExampleUI.button("Selection haptics") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentWithHaptics(from: $0) }
    })
    callbacks.addArrangedSubview(FKActionSheetExampleUI.button("hooks.didSelect") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentHooksDidSelect(from: $0) }
    })

    let dismiss = UIStackView()
    dismiss.axis = .vertical
    dismiss.spacing = 8
    dismiss.addArrangedSubview(FKActionSheetExampleUI.button("Log all dismiss reasons") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentDismissReasonsDemo(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Handlers",
        description: "handlerTiming controls when actionHandler runs relative to dismissal. Optional haptics fire on row selection.",
        body: callbacks
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Dismiss reasons",
        description: "hooks.willDismiss / didDismiss receive FKActionSheetDismissReason: actionSelected, userCancel, tapOutside, programmatic.",
        body: dismiss
      )
    )
    addClearLogButton()
  }
}
