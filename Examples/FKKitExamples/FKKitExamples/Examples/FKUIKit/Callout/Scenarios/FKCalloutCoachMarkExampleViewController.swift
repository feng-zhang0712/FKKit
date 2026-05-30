import UIKit
import FKUIKit

/// Onboarding-style coach mark with close and primary action.
final class FKCalloutCoachMarkExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Personal ▾")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Coach mark"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "FKPopover.showCoachMark enables dimmed backdrop and anchor spotlight by default.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor, height: 200)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show coach mark (bottom)") { [weak self] in
        self?.presentCoachMark(placement: .bottom)
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show coach mark (top)") { [weak self] in
        self?.presentCoachMark(placement: .top)
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "Handlers run before auto-dismiss; primary action and close both dismiss the popover.",
        body: controls
      )
    )
  }

  private func presentCoachMark(placement: FKCalloutPlacement) {
    let content = FKCalloutCoachMarkContent(
      title: "Tap to switch profiles",
      message: "Switch between your profiles for unique app experiences",
      primaryActionTitle: "Got it",
      showsCloseButton: true
    )
    FKPopover.showCoachMark(
      content,
      anchoredTo: anchor,
      placement: placement,
      primaryAction: { [weak self] in
        self?.log("Primary action · Got it")
      },
      onClose: { [weak self] in
        self?.log("Close tapped")
      }
    )
    log("FKPopover.showCoachMark · .\(placement)")
  }
}
