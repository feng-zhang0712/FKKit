import FKCoreKit
import UIKit

/// Demonstrates RTL layout behavior when Arabic is selected.
final class FKI18nRTLExampleViewController: FKI18nExampleBaseViewController {

  private let cardView = UIView()
  private let leadingLabel = UILabel()
  private let trailingLabel = UILabel()
  private let directionLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL Layout"

    cardView.backgroundColor = .secondarySystemBackground
    cardView.layer.cornerRadius = 12

    leadingLabel.font = .preferredFont(forTextStyle: .body)
    trailingLabel.font = .preferredFont(forTextStyle: .body)
    directionLabel.font = .preferredFont(forTextStyle: .footnote)
    directionLabel.textColor = .secondaryLabel
    directionLabel.numberOfLines = 0

    leadingLabel.translatesAutoresizingMaskIntoConstraints = false
    trailingLabel.translatesAutoresizingMaskIntoConstraints = false
    directionLabel.translatesAutoresizingMaskIntoConstraints = false
    cardView.translatesAutoresizingMaskIntoConstraints = false

    cardView.addSubview(leadingLabel)
    cardView.addSubview(trailingLabel)
    cardView.addSubview(directionLabel)

    NSLayoutConstraint.activate([
      cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
      leadingLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
      leadingLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
      trailingLabel.centerYAnchor.constraint(equalTo: leadingLabel.centerYAnchor),
      trailingLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
      directionLabel.topAnchor.constraint(equalTo: leadingLabel.bottomAnchor, constant: 12),
      directionLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
      directionLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
      directionLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
    ])

    stackView.insertArrangedSubview(cardView, at: 0)

    addInfoLabel("Switch to Arabic (ar) to flip semanticContentAttribute and leading/trailing edges.")
    addLanguagePickerButton()
    addActionButton("Switch to Arabic") {
      FKI18nManager.shared.setLanguageCode(FKI18nRecommendedLanguages.arabic)
    }
    addActionButton("Switch to English") {
      FKI18nManager.shared.setLanguageCode(FKI18nRecommendedLanguages.english)
    }

    refreshLocalizedContent()
  }

  override func refreshLocalizedContent() {
    let i18n = FKI18nManager.shared
    let semantic: UISemanticContentAttribute = i18n.isRightToLeft ? .forceRightToLeft : .forceLeftToRight
    view.semanticContentAttribute = semantic
    cardView.semanticContentAttribute = semantic

    leadingLabel.text = FKI18nExampleSupport.localized("i18n.demo.rtl.leading")
    trailingLabel.text = FKI18nExampleSupport.localized("i18n.demo.rtl.trailing")
    directionLabel.text = FKI18nExampleSupport.localized(
      "i18n.demo.rtl.direction",
      variables: ["direction": i18n.isRightToLeft ? "RTL" : "LTR"]
    )
  }
}
