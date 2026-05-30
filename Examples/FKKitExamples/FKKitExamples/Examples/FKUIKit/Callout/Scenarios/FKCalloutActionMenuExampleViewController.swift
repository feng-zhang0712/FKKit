import UIKit
import FKUIKit

/// Sectioned action menu popover (Options-style).
final class FKCalloutActionMenuExampleViewController: FKCalloutExampleBaseViewController {
  private let optionsButton: UIButton = {
    var config = UIButton.Configuration.filled()
    config.title = "Options"
    config.image = UIImage(systemName: "chevron.down")
    config.imagePlacement = .trailing
    config.imagePadding = 6
    config.baseBackgroundColor = .systemGray3
    config.baseForegroundColor = .white
    config.cornerStyle = .medium
    let button = UIButton(configuration: config)
    button.heightAnchor.constraint(equalToConstant: 44).isActive = true
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Action menu"

    let canvas = FKCalloutExampleUI.anchorCanvas(anchor: optionsButton, height: 160)
    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Trigger",
        description: "FKPopover.showMenu with grouped sections, header rows, and frosted appearance.",
        body: canvas
      )
    )

    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show options menu") { [weak self] in
        self?.showMenu()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show header menu") { [weak self] in
        self?.showHeaderMenu()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Show frosted menu") { [weak self] in
        self?.showFrostedMenu()
      }
    )
    controls.addArrangedSubview(
      FKCalloutExampleUI.button("Dismiss") { FKPopover.dismissActive() }
    )

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Controls",
        description: "Uses FKPopover.menuConfiguration / FKCalloutConfiguration.menuDefault.",
        body: controls
      )
    )
  }

  private func showMenu() {
    optionsButton.layoutIfNeeded()
    var config = FKCalloutConfiguration.menuDefault(placement: .bottom)
    config.anchorAlignment = .center
    config.maxWidth = 320
    config.minWidth = nil
    config.matchesAnchorWidth = false
    FKPopover.showMenu(
      FKCalloutExamplePlaybook.optionsMenu(),
      anchoredTo: optionsButton,
      placement: .bottom,
      onSelect: { [weak self] item in
        self?.log("Selected: \(item.title)")
      },
      configuration: config
    )
    log("FKPopover.showMenu · options")
  }

  private func showHeaderMenu() {
    optionsButton.layoutIfNeeded()
    var config = FKCalloutConfiguration.menuDefault(placement: .bottom)
    config.anchorAlignment = .center
    config.maxWidth = 340
    config.minWidth = nil
    config.matchesAnchorWidth = false
    FKPopover.showMenu(
      FKCalloutExamplePlaybook.headerMenu(),
      anchoredTo: optionsButton,
      placement: .bottom,
      onSelect: { [weak self] item in
        self?.log("Selected: \(item.title)")
      },
      configuration: config
    )
    log("FKPopover.showMenu · FKCalloutMenu header + subtitle rows")
  }

  private func showFrostedMenu() {
    optionsButton.layoutIfNeeded()
    var config = FKCalloutConfiguration.menuDefault(placement: .bottom)
    config.anchorAlignment = .center
    config.maxWidth = 320
    config.minWidth = nil
    config.matchesAnchorWidth = false
    config.appearance.usesFrostedGlassBackground = true
    config.appearance.borderColor = UIColor.white.withAlphaComponent(0.35)
    config.appearance.borderWidth = 0.5
    FKPopover.showMenu(
      FKCalloutExamplePlaybook.optionsMenu(),
      anchoredTo: optionsButton,
      placement: .bottom,
      configuration: config
    )
    log("FKPopover.showMenu · frosted")
  }
}
