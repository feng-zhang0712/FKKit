import UIKit
import FKUIKit

/// Tooltip placement, multiline copy, icon messages, and light/dark presets.
final class FKCalloutTooltipBasicsExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Anchor")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tooltip basics"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Present tooltips relative to the indigo button. Tap outside does not dismiss (tooltip preset); auto-dismiss after 3s unless overridden.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor)
      )
    )

    let placementControls = UIStackView()
    placementControls.axis = .vertical
    placementControls.spacing = 8
    placementControls.addArrangedSubview(
      FKCalloutExampleUI.row([
        makeShowButton("Top", placement: .top, text: "Tooltip on the top"),
        makeShowButton("Bottom", placement: .bottom, text: "Tooltip on the bottom"),
      ])
    )
    placementControls.addArrangedSubview(
      FKCalloutExampleUI.row([
        makeShowButton("Left", placement: .leading, text: "Tooltip on the left"),
        makeShowButton("Right", placement: .trailing, text: "Tooltip on the right"),
      ])
    )
    placementControls.addArrangedSubview(
      FKCalloutExampleUI.button("Multiline (bottom)") { [weak self] in
        guard let self else { return }
        var config = FKCalloutConfiguration.tooltipDefault(placement: .bottom)
        config.maxWidth = 280
        config.autoDismissDuration = nil
        FKTooltip.show(
          FKCalloutExamplePlaybook.longTooltipText,
          anchoredTo: self.anchor,
          configuration: config
        )
        self.log("FKTooltip.show multiline · placement .bottom")
      }
    )
    placementControls.addArrangedSubview(
      FKCalloutExampleUI.button("Light tooltip on dark style") { [weak self] in
        guard let self else { return }
        var config = FKCalloutConfiguration.tooltipDefault(placement: .top)
        config.appearance = FKCalloutAppearance(style: .light, showsShadow: true)
        FKTooltip.show("Light theme tooltip", anchoredTo: self.anchor, configuration: config)
        self.log("Custom tooltip configuration · appearance .light")
      }
    )
    placementControls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss active") {
        FKTooltip.dismissActive()
      }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Placements",
        description: "Uses FKTooltip.show and FKTooltip.dismissActive. See Placements & beak for the full 12-placement matrix.",
        body: placementControls
      )
    )

    let iconControls = UIStackView()
    iconControls.axis = .vertical
    iconControls.spacing = 8
    iconControls.addArrangedSubview(
      FKCalloutExampleUI.button("Icon · automatic placement") { [weak self] in
        self?.showIcon(placement: .automatic)
      }
    )
    iconControls.addArrangedSubview(
      FKCalloutExampleUI.button("Icon · top leading") { [weak self] in
        self?.showIcon(placement: .topLeading)
      }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Icon message",
        description: "FKCalloutContent.iconMessage with FKCalloutIcon (SF Symbol).",
        body: iconControls
      )
    )
  }

  private func makeShowButton(_ title: String, placement: FKCalloutPlacement, text: String) -> UIButton {
    FKCalloutExampleUI.button(title) { [weak self] in
      guard let self else { return }
      var config = FKCalloutConfiguration.tooltipDefault(placement: placement)
      config.maxWidth = 280
      config.autoDismissDuration = nil
      FKTooltip.show(text, anchoredTo: self.anchor, configuration: config)
      self.log("FKTooltip.show · placement .\(placement)")
    }
  }

  private func showIcon(placement: FKCalloutPlacement) {
    var config = FKCalloutConfiguration.tooltipDefault(placement: placement)
    config.maxWidth = 300
    let icon = FKCalloutIcon(symbolName: "questionmark.circle")
    FKTooltip.show(
      icon: icon,
      message: "This is a tip to help you accomplish a task.",
      anchoredTo: anchor,
      configuration: config
    )
    log("FKTooltip iconMessage · placement .\(placement)")
  }
}
