import UIKit
import FKUIKit

/// Message with footer action buttons (Learn more pattern).
final class FKCalloutPopoverActionsExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Tip anchor")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Footer actions"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "FKCalloutContent.messageWithActions renders trailing footer buttons.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor, height: 200)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Learn more (default action)") { [weak self] in
        self?.showLearnMore(style: .default)
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Got it (primary action)") { [weak self] in
        self?.showGotIt()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "FKPopover.show(message:actions:actionHandlers:) maps handlers by FKCalloutAction.id.",
        body: controls
      )
    )
  }

  private func showLearnMore(style: FKCalloutAction.Style) {
    let message = "This is a tip to help you accomplish a task."
    let action = FKCalloutAction(id: "learn-more", title: "Learn more", style: style)
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottom)
    config.maxWidth = 300
    FKPopover.show(
      message: message,
      actions: [action],
      actionHandlers: [
        action.id: { [weak self] in
          self?.log("Learn more tapped · id \(action.id)")
        },
      ],
      anchoredTo: anchor,
      placement: .bottom,
      configuration: config
    )
    log("FKPopover messageWithActions")
  }

  private func showGotIt() {
    let action = FKCalloutAction(id: "got-it", title: "Got it", style: .primary)
    var config = FKCalloutConfiguration.popoverDefault(placement: .top)
    config.maxWidth = 300
    FKPopover.show(
      message: "This is a tip to help you accomplish a task.",
      actions: [action],
      actionHandlers: [
        action.id: { [weak self] in
          self?.log("Got it tapped · id \(action.id)")
        },
      ],
      anchoredTo: anchor,
      placement: .top,
      configuration: config
    )
    log("Primary FKCalloutAction")
  }
}
