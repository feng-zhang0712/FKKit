import UIKit
import FKUIKit

/// Popover with ``FKCalloutAppearance/usesFrostedGlassBackground``.
final class FKCalloutFrostedGlassExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Frosted anchor")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Frosted glass"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Material blur fills the bubble body and beak; content stays on top.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor, height: 180)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show frosted popover") { [weak self] in
        self?.showFrostedPopover()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "FKCalloutAppearance.usesFrostedGlassBackground on a title+body popover. Frosted menus are in Action menu.",
        body: controls
      )
    )
  }

  private func showFrostedPopover() {
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottom)
    config.maxWidth = 340
    config.anchorAlignment = .center
    config.appearance = FKCalloutAppearance(
      style: .light,
      cornerRadius: 14,
      beakWidth: 16,
      beakHeight: 8,
      showsShadow: true,
      shadowOpacity: 0.2,
      shadowRadius: 18,
      shadowOffset: CGSize(width: 0, height: 10),
      borderColor: UIColor.white.withAlphaComponent(0.35),
      borderWidth: 0.5,
      usesFrostedGlassBackground: true
    )
    FKPopover.show(
      title: "Frosted panel",
      message: "Background uses system material blur. Place content over busy UI to see the effect.",
      anchoredTo: anchor,
      placement: .bottom,
      configuration: config
    )
    log("FKPopover.show · usesFrostedGlassBackground")
  }
}
