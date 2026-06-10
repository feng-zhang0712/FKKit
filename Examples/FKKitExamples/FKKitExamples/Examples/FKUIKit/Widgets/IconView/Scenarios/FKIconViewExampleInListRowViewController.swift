import FKUIKit
import UIKit

final class FKIconViewExampleInListRowViewController: FKIconViewExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings list row"

    func rowIcon(symbol: String, fill: UIColor, tint: UIColor) -> FKIconView {
      var config = FKIconViewConfiguration()
      config.layout.size = .m
      config.appearance.backgroundStyle = .roundedRect(cornerRadius: 8, fill: fill)
      config.appearance.defaultTintColor = tint
      config.accessibility.isDecorative = true
      return FKIconView(configuration: config, symbolName: symbol)
    }

    let notifications = rowIcon(
      symbol: "bell.fill",
      fill: UIColor.systemRed.withAlphaComponent(0.15),
      tint: .systemRed
    )
    let privacy = rowIcon(
      symbol: "hand.raised.fill",
      fill: UIColor.systemBlue.withAlphaComponent(0.15),
      tint: .systemBlue
    )
    let storage = rowIcon(
      symbol: "internaldrive.fill",
      fill: UIColor.systemGray.withAlphaComponent(0.18),
      tint: .label
    )

    let box = FKIconViewExampleSupport.sectionContainer(title: "Settings-style rows")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "FKIconView keeps leading icons at a consistent 28 pt box. Pair with decorative accessibility so VoiceOver reads the row title only."
    ))

    for (title, icon) in [
      ("Notifications", notifications),
      ("Privacy", privacy),
      ("Storage", storage),
    ] {
      let row = FKIconViewExampleSupport.settingsRow(title: title, icon: icon)
      row.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
      row.isLayoutMarginsRelativeArrangement = true
      box.addArrangedSubview(row)
      if title != "Storage" {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        box.addArrangedSubview(separator)
      }
    }

    contentStack.addArrangedSubview(box)
  }
}
