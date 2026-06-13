import FKUIKit
import UIKit

final class FKTagExampleVariantsViewController: FKChipExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tag variants"

    contentStack.addArrangedSubview(FKChipExampleSupport.caption(
      "FKTag is read-only metadata — categories, promos, roles. For workflow status words use FKStatusPill."
    ))

    let specs: [(String, FKTagVariant, FKTagIcon?)] = [
      ("Neutral", .neutral, nil),
      ("Brand", .brand, .symbol(name: "star.fill")),
      ("Success", .success, .symbol(name: "checkmark")),
      ("Warning", .warning, .symbol(name: "exclamationmark.triangle")),
      ("Error", .error, .symbol(name: "xmark.octagon")),
      ("Outline", .outline, nil),
      (
        "Custom",
        .custom(FKTagCustomVariant(
          backgroundColor: UIColor.systemPurple.withAlphaComponent(0.15),
          foregroundColor: .systemPurple,
          borderColor: .systemPurple,
          borderWidth: 1
        )),
        .symbol(name: "paintpalette")
      ),
    ]

    for spec in specs {
      let tag = FKTag(title: spec.0, variant: spec.1)
      tag.leadingIcon = spec.2
      let box = FKChipExampleSupport.sectionContainer(title: spec.0)
      box.addArrangedSubview(FKChipExampleSupport.embedTag(tag, alignment: .leading))
      contentStack.addArrangedSubview(box)
    }
  }
}
