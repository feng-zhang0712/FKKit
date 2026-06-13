import FKUIKit
import UIKit

final class FKIconViewExampleWithBadgeViewController: FKIconViewExampleScrollViewController {

  private let countIcon = FKIconViewExampleSupport.makeIcon(
    size: .m,
    symbolName: "envelope.fill",
    backgroundStyle: .circle(fill: UIColor.systemBlue.withAlphaComponent(0.12)),
    tintColor: .systemBlue
  )

  private let dotIcon = FKIconViewExampleSupport.makeIcon(
    size: .l,
    symbolName: "person.crop.circle",
    backgroundStyle: .circle(fill: UIColor.systemPurple.withAlphaComponent(0.12)),
    tintColor: .systemPurple
  )

  private let textIcon = FKIconViewExampleSupport.makeIcon(
    size: .m,
    symbolName: "cart.fill",
    backgroundStyle: .circle(fill: UIColor.systemOrange.withAlphaComponent(0.15)),
    tintColor: .systemOrange
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "With badge"

    [countIcon, dotIcon, textIcon].forEach { $0.applyDefaultBadgeAnchor() }
    countIcon.fk_badge.showCount(12)
    dotIcon.fk_badge.showDot()
    textIcon.fk_badge.showText("NEW")

    let box = FKIconViewExampleSupport.sectionContainer(title: "FKBadge on FKIconView")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Call applyDefaultBadgeAnchor() for top-trailing placement with size-aware offset from FKWidgetLayoutMetrics. Badges attach as siblings — the icon view stays non-interactive."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Numeric count", control: countIcon))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Dot", control: dotIcon))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Text badge", control: textIcon))
    contentStack.addArrangedSubview(box)
  }
}
