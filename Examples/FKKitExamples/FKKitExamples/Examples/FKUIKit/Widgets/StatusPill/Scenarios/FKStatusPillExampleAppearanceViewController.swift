import FKUIKit
import UIKit

final class FKStatusPillExampleAppearanceViewController: FKStatusPillExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Light & dark"

    let pills = [
      FKStatusPillExampleSupport.makePill(title: "Shipped", style: .success, showsDot: true),
      FKStatusPillExampleSupport.makePill(title: "Processing", style: .info, showsDot: true),
      FKStatusPillExampleSupport.makePill(title: "Payment failed", style: .error),
    ]

    let stack = UIStackView(arrangedSubviews: pills)
    stack.axis = .vertical
    stack.spacing = 12
    stack.alignment = .leading

    let styleControl = UISegmentedControl(items: ["System", "Light", "Dark"])
    styleControl.selectedSegmentIndex = 0
    styleControl.addAction(UIAction { [weak self] action in
      guard let self, let seg = action.sender as? UISegmentedControl else { return }
      switch seg.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let box = FKStatusPillExampleSupport.sectionContainer(title: "Adaptive palettes")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "FKWidgetStatusColorTokens uses system semantic colors (.systemGreen, .systemBlue, …) and dynamic fills for dark mode contrast."
    ))
    box.addArrangedSubview(stack)
    box.addArrangedSubview(FKStatusPillExampleSupport.labeledRow(title: "Interface style", control: styleControl))
    contentStack.addArrangedSubview(box)
  }
}
