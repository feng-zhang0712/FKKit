import UIKit
import FKUIKit

/// Demonstrates sourceRect, maxContentHeight scrolling, keyboard avoidance, and edge flip behavior.
final class FKCalloutLayoutBehaviorExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Layout anchor")
  private let textField: UITextField = {
    let field = UITextField()
    field.placeholder = "Tap to show keyboard"
    field.borderStyle = .roundedRect
    field.translatesAutoresizingMaskIntoConstraints = false
    field.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return field
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Layout behavior"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Exercises sourceRect, maxContentHeight, keyboardAvoidance, and flipsPlacementWhenNeeded.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor, height: 160)
      )
    )
    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Keyboard field",
        description: "Use the keyboard relayout button, then focus this field.",
        body: textField
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("sourceRect (leading half)") { [weak self] in
        self?.showSourceRectPopover()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Scrollable menu (maxContentHeight)") { [weak self] in
        self?.showScrollableMenu()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Keyboard relayout popover") { [weak self] in
        self?.showKeyboardRelayoutPopover()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Keyboard dismiss popover") { [weak self] in
        self?.showKeyboardDismissPopover()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Edge flip (automatic)") { [weak self] in
        self?.showEdgeFlipTooltip()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dim backdrop (no spotlight)") { [weak self] in
        self?.showDimBackdropPopover()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKTooltip.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "Scroll the screen near the bottom to see automatic placement flip.",
        body: controls
      )
    )
  }

  private func showSourceRectPopover() {
    anchor.layoutIfNeeded()
    let rect = CGRect(x: 0, y: 0, width: anchor.bounds.width * 0.5, height: anchor.bounds.height)
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottomLeading)
    config.maxWidth = 260
    FKPopover.show(
      message: "Anchored to the leading half via sourceRect.",
      anchoredTo: anchor,
      sourceRect: rect,
      placement: .bottomLeading,
      configuration: config
    )
    log("FKPopover.show · sourceRect leading half")
  }

  private func showScrollableMenu() {
    anchor.layoutIfNeeded()
    var config = FKCalloutConfiguration.menuDefault(placement: .bottom)
    config.anchorAlignment = .center
    config.matchesAnchorWidth = true
    config.maxWidth = anchor.bounds.width
    config.maxContentHeight = 220
    FKPopover.showMenu(
      FKCalloutExamplePlaybook.optionsMenu(),
      anchoredTo: anchor,
      configuration: config
    )
    log("FKPopover.showMenu · maxContentHeight 220")
  }

  private func showKeyboardRelayoutPopover() {
    textField.becomeFirstResponder()
    var config = FKCalloutConfiguration.popoverDefault(placement: .automatic)
    config.keyboardAvoidance = .relayout
    config.maxWidth = 280
    FKPopover.show(
      title: "Keyboard avoidance",
      message: "This bubble relayouts when the keyboard appears.",
      anchoredTo: anchor,
      configuration: config
    )
    log("keyboardAvoidance .relayout")
  }

  private func showKeyboardDismissPopover() {
    textField.becomeFirstResponder()
    var config = FKCalloutConfiguration.popoverDefault(placement: .automatic)
    config.keyboardAvoidance = .dismiss
    config.maxWidth = 280
    FKPopover.show(
      title: "Keyboard dismiss",
      message: "This bubble dismisses when the keyboard will show.",
      anchoredTo: anchor,
      configuration: config
    )
    log("keyboardAvoidance .dismiss")
  }

  private func showEdgeFlipTooltip() {
    var config = FKCalloutConfiguration.tooltipDefault(placement: .automatic)
    config.autoDismissDuration = nil
    config.flipsPlacementWhenNeeded = true
    config.maxWidth = 240
    FKTooltip.show(
      "Automatic placement picks the side with the most room.",
      anchoredTo: anchor,
      configuration: config
    )
    log("flipsPlacementWhenNeeded · .automatic")
  }

  private func showDimBackdropPopover() {
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottom)
    config.backdrop = FKCalloutBackdropStyle(showsDimmedBackdrop: true, spotlightsAnchor: false)
    config.maxWidth = 280
    FKPopover.show(
      message: "Dimmed backdrop without an anchor spotlight cutout.",
      anchoredTo: anchor,
      configuration: config
    )
    log("backdrop dim · spotlightsAnchor false")
  }
}
