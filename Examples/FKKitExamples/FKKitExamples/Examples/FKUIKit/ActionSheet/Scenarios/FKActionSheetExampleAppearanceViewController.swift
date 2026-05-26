import UIKit
import FKUIKit

final class FKActionSheetExampleAppearanceViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Appearance"

    let presets = FKActionSheetExampleUI.row([
      FKActionSheetExampleUI.button("System") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentAppearancePreset(.system, from: $0) }
      },
      FKActionSheetExampleUI.button("Card") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentAppearancePreset(.card, from: $0) }
      },
      FKActionSheetExampleUI.button("Plain") { [weak self] in
        self.map { FKActionSheetExamplePlaybook.presentAppearancePreset(.plain, from: $0) }
      },
    ])

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(presets)
    body.addArrangedSubview(FKActionSheetExampleUI.button("Leading alignment") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentLeadingAlignment(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("No separators") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentNoSeparators(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Appearance presets",
        description: "FKActionSheetAppearancePreset, row alignment, separatorStyle, and grouped section titles.",
        body: body
      )
    )
    addClearLogButton()
  }
}
