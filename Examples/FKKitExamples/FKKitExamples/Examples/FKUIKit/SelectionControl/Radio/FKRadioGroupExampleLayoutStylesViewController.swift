import FKUIKit
import UIKit

/// radio.group.plain / horizontal.
final class FKRadioGroupExampleLayoutStylesViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Plain & horizontal"

    var plainConfig = FKRadioGroupConfiguration()
    plainConfig.layout.style = .plain
    let plain = FKRadioGroup(configuration: plainConfig, options: [
      FKRadioOption(id: "a", title: "Option A"),
      FKRadioOption(id: "b", title: "Option B"),
      FKRadioOption(id: "c", title: "Option C"),
    ])
    plain.selectedOptionID = "a"

    let plainBox = FKSelectionExampleSupport.sectionContainer(title: "Plain")
    plainBox.addArrangedSubview(FKSelectionExampleSupport.caption("No card chrome — useful inside an existing grouped table."))
    plainBox.addArrangedSubview(plain)
    contentStack.addArrangedSubview(plainBox)

    var horizontalConfig = FKRadioGroupConfiguration()
    horizontalConfig.layout.style = .horizontal
    horizontalConfig.layout.axisSpacing = 12
    horizontalConfig.layout.rowContentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    let horizontal = FKRadioGroup(configuration: horizontalConfig, options: [
      FKRadioOption(id: "s", title: "S"),
      FKRadioOption(id: "m", title: "M"),
      FKRadioOption(id: "l", title: "L"),
      FKRadioOption(id: "xl", title: "XL"),
      FKRadioOption(id: "xxl", title: "XXL"),
    ])
    horizontal.selectedOptionID = "m"

    let horizontalBox = FKSelectionExampleSupport.sectionContainer(title: "Horizontal")
    horizontalBox.addArrangedSubview(FKSelectionExampleSupport.caption("Horizontal stack; overflows may scroll."))
    horizontalBox.addArrangedSubview(horizontal)
    contentStack.addArrangedSubview(horizontalBox)
  }
}
