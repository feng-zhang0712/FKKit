import FKUIKit
import UIKit

final class FKIconViewExamplePlaygroundViewController: FKIconViewExampleScrollViewController {

  private let icon = FKIconView(symbolName: "wand.and.stars")
  private let sizeControl = UISegmentedControl(items: ["S", "M", "L"])
  private let backgroundControl = UISegmentedControl(items: ["None", "Circle", "Rounded"])
  private let weightControl = UISegmentedControl(items: ["Regular", "Medium", "Bold"])
  private let tintControl = UISegmentedControl(items: ["Label", "Blue", "Pink"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"

    sizeControl.selectedSegmentIndex = 1
    backgroundControl.selectedSegmentIndex = 1
    weightControl.selectedSegmentIndex = 1
    tintControl.selectedSegmentIndex = 1

    [sizeControl, backgroundControl, weightControl, tintControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }

    let previewRow = UIStackView(arrangedSubviews: [icon])
    previewRow.axis = .vertical
    previewRow.alignment = .center

    let box = FKIconViewExampleSupport.sectionContainer(title: "Live preview")
    box.addArrangedSubview(previewRow)
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Size", control: sizeControl, trailing: false))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Background", control: backgroundControl, trailing: false))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Symbol weight", control: weightControl, trailing: false))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "Tint", control: tintControl, trailing: false))

    contentStack.addArrangedSubview(box)
    applyConfiguration()
  }

  private func applyConfiguration() {
    var config = FKIconViewConfiguration()
    config.layout.size = resolvedSize()
    config.appearance.backgroundStyle = resolvedBackground()
    config.appearance.symbolWeight = resolvedWeight()
    config.appearance.defaultTintColor = resolvedTint()
    config.appearance.placeholderSymbolName = "sparkle"
    icon.configuration = config
    icon.iconTintColor = resolvedTint()
  }

  private func resolvedSize() -> FKIconViewSize {
    switch sizeControl.selectedSegmentIndex {
    case 0: .s
    case 2: .l
    default: .m
    }
  }

  private func resolvedBackground() -> FKIconViewBackgroundStyle {
    switch backgroundControl.selectedSegmentIndex {
    case 0:
      .none
    case 2:
      .roundedRect(cornerRadius: 8, fill: resolvedTint().withAlphaComponent(0.15))
    default:
      .circle(fill: resolvedTint().withAlphaComponent(0.15))
    }
  }

  private func resolvedWeight() -> UIImage.SymbolWeight {
    switch weightControl.selectedSegmentIndex {
    case 0: .regular
    case 2: .bold
    default: .medium
    }
  }

  private func resolvedTint() -> UIColor {
    switch tintControl.selectedSegmentIndex {
    case 0: .label
    case 2: .systemPink
    default: .systemBlue
    }
  }
}
