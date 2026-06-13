import FKUIKit
import UIKit

final class FKChipGroupExampleHorizontalScrollViewController: FKChipExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Horizontal scroll"

    var config = FKChipGroupConfiguration()
    config.layoutMode = .horizontalScroll
    config.chipMode = .filter
    config.itemSpacing = 8

    let group = FKChipGroup(
      configuration: config,
      chips: FKChipExampleSupport.filterBarItems(),
      selectionMode: .single
    )

    let box = FKChipExampleSupport.sectionContainer(title: "horizontalScroll layout")
    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Dense filter rails scroll horizontally. When content overflows, a trailing chip peeks at the edge; selecting a chip scrolls it into view while keeping the next chip partially visible."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedGroup(group))

    NSLayoutConstraint.activate([
      group.heightAnchor.constraint(equalToConstant: config.chipConfiguration.layout.size.height),
    ])

    contentStack.addArrangedSubview(box)
  }
}
