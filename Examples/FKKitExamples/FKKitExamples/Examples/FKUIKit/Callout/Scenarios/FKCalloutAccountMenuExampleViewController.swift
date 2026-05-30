import UIKit
import FKUIKit

/// Account/workspace menu using a fixed-size ``UICollectionView`` inside ``FKPopover/show(customView:)``.
final class FKCalloutAccountMenuExampleViewController: FKCalloutExampleBaseViewController {
  private let avatarButton = FKCalloutExampleUI.anchorButton("Account")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Account menu"

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Trigger",
        description: "Single-column account sheet with symmetric insets; beak stays centered on the Account anchor.",
        body: FKCalloutExampleUI.anchorCanvas(anchor: avatarButton, height: 160)
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show account menu") { [weak self] in
        self?.showAccountMenu()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "FKPopover.show(customView:) · UICollectionView compositional layout, controlled height.",
        body: controls
      )
    )
  }

  private func showAccountMenu() {
    var config = FKCalloutConfiguration.popoverDefault(placement: .bottom)
    config.maxWidth = FKCalloutAccountMenuCollectionContentView.preferredContentSize.width + 32
    config.minWidth = FKCalloutAccountMenuCollectionContentView.preferredContentSize.width
    config.anchorAlignment = .center
    config.matchesAnchorWidth = false
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)

    FKPopover.show(
      customView: { [weak self] in
        let menu = FKCalloutAccountMenuCollectionContentView()
        menu.onSelect = { [weak self] row in
          FKPopover.dismissActive()
          self?.log("Selected: \(row.title)")
        }
        return menu
      },
      anchoredTo: avatarButton,
      placement: .bottom,
      configuration: config
    )
    log("FKPopover.show(customView:) · account collection")
  }
}
