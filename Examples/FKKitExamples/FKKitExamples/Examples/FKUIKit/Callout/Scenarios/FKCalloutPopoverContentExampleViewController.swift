import UIKit
import FKUIKit

/// Popover message, title+subtitle, and inset header card with light/dark chrome.
final class FKCalloutPopoverContentExampleViewController: FKCalloutExampleBaseViewController {
  private let anchor = FKCalloutExampleUI.anchorButton("Popover anchor")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Popover content"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Anchor",
        description: "Popover preset keeps the bubble until you tap outside or dismiss manually.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: anchor)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.row([
        FKCalloutExampleUI.button("Top") { [weak self] in self?.showTitle(placement: .top) },
        FKCalloutExampleUI.button("Bottom") { [weak self] in self?.showTitle(placement: .bottom) },
      ])
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Plain message") { [weak self] in
        guard let self else { return }
        FKPopover.show(
          message: "A message which appears when a cursor is positioned over an icon.",
          anchoredTo: self.anchor,
          placement: .top,
          configuration: self.popoverConfig(placement: .top)
        )
        self.log("FKPopover.show(message:)")
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Header card (dark)") { [weak self] in
        guard let self else { return }
        let header = FKCalloutHeaderPanel(
          title: "Popover on the top",
          backgroundColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
              ? UIColor(white: 0.22, alpha: 1)
              : UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
          },
          textColor: .white
        )
        FKPopover.show(
          header: header,
          body: FKCalloutExamplePlaybook.popoverBody,
          anchoredTo: self.anchor,
          placement: .bottom,
          configuration: self.popoverConfig(placement: .bottom)
        )
        self.log("FKPopover.show(header:body:)")
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Header card (light)") { [weak self] in
        guard let self else { return }
        FKPopover.show(
          header: FKCalloutHeaderPanel(title: "Popover on the top"),
          body: FKCalloutExamplePlaybook.popoverBody,
          anchoredTo: self.anchor,
          placement: .bottom,
          configuration: self.popoverConfig(placement: .bottom)
        )
        self.log("FKPopover header panel · default colors")
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "FKPopover.show(title:message:), show(message:), and show(header:body:).",
        body: controls
      )
    )
  }

  private func showTitle(placement: FKCalloutPlacement) {
    var config = FKCalloutConfiguration.popoverDefault(placement: placement)
    config.maxWidth = 340
    FKPopover.show(
      title: "Popover on the top",
      message: FKCalloutExamplePlaybook.popoverBody,
      anchoredTo: anchor,
      placement: placement,
      configuration: config
    )
    log("FKPopover.show(title:message:) · .\(placement)")
  }

  private func popoverConfig(placement: FKCalloutPlacement) -> FKCalloutConfiguration {
    var config = FKCalloutConfiguration.popoverDefault(placement: placement)
    config.maxWidth = 340
    return config
  }
}
