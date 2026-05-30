import UIKit
import FKUIKit

/// Select-style dropdown with checkmark; menu width hugs the longest option.
final class FKCalloutSelectMenuExampleViewController: FKCalloutExampleBaseViewController {
  private var selectedName = "Wade Cooper"

  private lazy var valueButton: UIButton = {
    var config = UIButton.Configuration.bordered()
    config.title = selectedName
    config.image = UIImage(systemName: "chevron.up.chevron.down")
    config.imagePlacement = .trailing
    config.imagePadding = 6
    config.cornerStyle = .medium
    config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 12)
    let button = UIButton(configuration: config)
    button.addAction(UIAction { [weak self] _ in
      self?.toggleMenu()
    }, for: .touchUpInside)
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Select menu"

    let row = UIStackView(arrangedSubviews: [valueButton])
    row.axis = .horizontal
    row.alignment = .center
    row.distribution = .equalSpacing

    contentStack.addArrangedSubview(
      FKCalloutExampleUI.section(
        title: "Trigger",
        description: "Menu width follows the longest option; the popover is centered on the trigger.",
        body: row
      )
    )

    log("Tap the select control to open the menu.")
  }

  private func toggleMenu() {
    if FKPopover.isPresenting {
      FKPopover.dismissActive()
      return
    }
    valueButton.layoutIfNeeded()
    var config = FKCalloutConfiguration.menuDefault(placement: .bottom)
    config.anchorAlignment = .center
    config.matchesAnchorWidth = false
    config.minWidth = nil
    config.maxWidth = 280
    FKPopover.showMenu(
      FKCalloutExamplePlaybook.selectMenu(selectedName: selectedName),
      anchoredTo: valueButton,
      placement: .bottom,
      onSelect: { [weak self] item in
        guard let self else { return }
        self.selectedName = item.title
        var buttonConfig = self.valueButton.configuration
        buttonConfig?.title = item.title
        self.valueButton.configuration = buttonConfig
        self.log("Selected: \(item.title)")
      },
      configuration: config
    )
    log("FKPopover.showMenu · select")
  }
}
