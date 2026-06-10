import FKUIKit
import UIKit

final class FKIconViewExampleThreeSizesViewController: FKIconViewExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Three sizes"

    let small = FKIconViewExampleSupport.makeIcon(size: .s, symbolName: "bell.fill", tintColor: .systemOrange)
    let medium = FKIconViewExampleSupport.makeIcon(size: .m, symbolName: "bell.fill", tintColor: .systemOrange)
    let large = FKIconViewExampleSupport.makeIcon(size: .l, symbolName: "bell.fill", tintColor: .systemOrange)

    let labels = [FKIconViewSize.s, .m, .l].map { size -> UILabel in
      let label = UILabel()
      label.text = FKIconViewExampleSupport.sizeLabel(for: size)
      label.font = .preferredFont(forTextStyle: .caption1)
      label.textColor = .secondaryLabel
      label.textAlignment = .center
      return label
    }

    func column(icon: FKIconView, label: UILabel) -> UIStackView {
      let stack = UIStackView(arrangedSubviews: [icon, label])
      stack.axis = .vertical
      stack.alignment = .center
      stack.spacing = 8
      return stack
    }

    let row = UIStackView(arrangedSubviews: [
      column(icon: small, label: labels[0]),
      column(icon: medium, label: labels[1]),
      column(icon: large, label: labels[2]),
    ])
    row.axis = .horizontal
    row.distribution = .equalSpacing
    row.alignment = .center

    let box = FKIconViewExampleSupport.sectionContainer(title: "Size tiers")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Intrinsic content size matches the container side. Symbol point sizes scale with each tier (13 / 15 / 17 pt)."
    ))
    box.addArrangedSubview(row)
    contentStack.addArrangedSubview(box)
  }
}
