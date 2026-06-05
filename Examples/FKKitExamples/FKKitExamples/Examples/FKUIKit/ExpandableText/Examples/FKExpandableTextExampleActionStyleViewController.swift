import FKCoreKit
import FKUIKit
import UIKit

final class FKExpandableTextExampleActionStyleViewController: FKExpandableTextExampleBaseViewController {
  private let label = UILabel()
  private var languageObservation: FKI18nObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom action styling"

    let card = makeCard(
      title: "Token + action fonts",
      subtitle: "`buttonPlacement: .trailingBottom`"
    )
    let slot = cardContentView(from: card)
    FKExpandableTextExampleSupport.configureBodyLabel(label)

    slot.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: slot.topAnchor),
      label.leadingAnchor.constraint(equalTo: slot.leadingAnchor),
      label.trailingAnchor.constraint(equalTo: slot.trailingAnchor),
      label.bottomAnchor.constraint(equalTo: slot.bottomAnchor),
    ])

    contentStackView.addArrangedSubview(card)
    languageObservation = FKI18nManager.shared.observeLanguageChange { [weak self] _ in
      Task { @MainActor in self?.applyExpandableText() }
    }
    fk_expandableText_runWhenLaidOut { [weak self] in
      self?.applyExpandableText()
    }
  }

  private func applyExpandableText() {
    let configuration = FKExpandableTextConfiguration(
      truncationToken: NSAttributedString(
        string: "… ",
        attributes: [
          .foregroundColor: UIColor.systemOrange,
          .font: UIFont.preferredFont(forTextStyle: .body),
        ]
      ),
      expandActionText: NSAttributedString(
        string: FKUIKitI18n.string("fkuikit.expandable_text.read_more"),
        attributes: [
          .foregroundColor: UIColor.systemRed,
          .font: UIFont.systemFont(ofSize: 16, weight: .bold),
        ]
      ),
      collapseActionText: NSAttributedString(
        string: FKUIKitI18n.string("fkuikit.expandable_text.collapse"),
        attributes: [
          .foregroundColor: UIColor.systemGreen,
          .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
        ]
      ),
      collapseRule: .lines(3),
      buttonPlacement: .trailingBottom,
      interactionMode: .buttonOnly
    )
    label.fk_setExpandableText(FKExpandableTextExampleSupport.makeBodyParagraph(), configuration: configuration)
  }
}
