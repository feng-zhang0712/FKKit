import UIKit
import FKUIKit

/// ``FKActionSheetPresentationStyle/centered`` — floating card on a dimmed backdrop.
final class FKActionSheetExampleCenteredViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Centered Card"

    let card = UIStackView()
    card.axis = .vertical
    card.spacing = 8
    card.addArrangedSubview(FKActionSheetExampleUI.button("Compact card (300pt wide)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredCompactCard(from: $0) }
    })
    card.addArrangedSubview(FKActionSheetExampleUI.button("Destructive confirmation") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredDestructive(from: $0) }
    })
    card.addArrangedSubview(FKActionSheetExampleUI.button("Scrollable list (max height 280)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredScrollableList(from: $0) }
    })

    let backdrop = UIStackView()
    backdrop.axis = .vertical
    backdrop.spacing = 8
    backdrop.addArrangedSubview(FKActionSheetExampleUI.button("Backdrop dismiss disabled") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredBackdropDismissDisabled(from: $0) }
    })
    backdrop.addArrangedSubview(FKActionSheetExampleUI.button("Strong backdrop (alpha 0.6)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredStrongBackdrop(from: $0) }
    })

    let presets = FKActionSheetExampleUI.row([
      FKActionSheetExampleUI.button("Card preset") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentCenteredCard(from: $0) }
      },
      FKActionSheetExampleUI.button("Plain") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentCenteredPlain(from: $0) }
      },
      FKActionSheetExampleUI.button("System") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentCenteredSystem(from: $0) }
      },
    ])

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Centered presentation",
        description: "Use presentation: .centered or FKActionSheetPresentationConfiguration.centered. Card animates with alert-like scale + fade (see PresentationController center mode).",
        body: card
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Backdrop",
        description: "allowsTapOutsideDismiss and backdropAlpha tune how the presenting UI is dimmed and whether taps pass through to dismiss.",
        body: backdrop
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Appearance on centered layout",
        description: "Appearance presets apply to the same centered chrome — compare card vs plain vs system.",
        body: presets
      )
    )
    addClearLogButton()
  }
}
