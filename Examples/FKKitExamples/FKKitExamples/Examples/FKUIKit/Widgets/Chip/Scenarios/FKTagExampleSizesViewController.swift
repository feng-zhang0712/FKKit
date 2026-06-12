import FKUIKit
import UIKit

final class FKTagExampleSizesViewController: FKChipExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sizes & truncation"

    contentStack.addArrangedSubview(makeSizesSection())
    contentStack.addArrangedSubview(makeTruncationSection())
  }

  private func makeSizesSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "FKChipSize presets")

    let row = FKChipExampleSupport.intrinsicWidthRow(spacing: 12)
    let specs: [(FKChipSize, String)] = [
      (.xs, "XS · 22 pt"),
      (.s, "S · 30 pt"),
      (.m, "M · 36 pt"),
    ]

    for spec in specs {
      var config = FKTagConfiguration()
      config.layout.size = spec.0
      let tag = FKTag(configuration: config, title: spec.1, variant: .brand)
      row.addItem(tag)
    }

    box.addArrangedSubview(row)
    return box
  }

  private func makeTruncationSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "maxWidth · truncating tail")

    var config = FKTagConfiguration()
    config.layout.maxWidth = 120
    let tag = FKTag(
      configuration: config,
      title: "Limited-time promotion",
      variant: .warning
    )
    tag.leadingIcon = .symbol(name: "clock")

    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Long titles truncate with byTruncatingTail when maxWidth is set. Dynamic Type scales the font and relayouts on trait changes."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedTag(tag, alignment: .leading))
    return box
  }
}
