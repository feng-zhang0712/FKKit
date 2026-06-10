import FKUIKit
import UIKit

final class FKStatusPillExamplePlaygroundViewController: FKStatusPillExampleScrollViewController {

  private let pill = FKStatusPill(title: "Awaiting carrier scan at regional hub", style: .warning, showsDot: true)
  private let widthSlider = UISlider()
  private let cornerControl = UISegmentedControl(items: ["Capsule", "Fixed 8"])
  private let dotTintSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Configuration playground"

    widthSlider.minimumValue = 100
    widthSlider.maximumValue = 320
    widthSlider.value = 180

    cornerControl.selectedSegmentIndex = 0
    dotTintSwitch.isOn = false

    [widthSlider, cornerControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }
    dotTintSwitch.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)

    let previewHost = UIView()
    previewHost.translatesAutoresizingMaskIntoConstraints = false
    previewHost.addSubview(pill)
    pill.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      pill.topAnchor.constraint(equalTo: previewHost.topAnchor),
      pill.leadingAnchor.constraint(equalTo: previewHost.leadingAnchor),
      pill.bottomAnchor.constraint(equalTo: previewHost.bottomAnchor),
    ])

    let box = FKStatusPillExampleSupport.sectionContainer(title: "Live preview")
    box.addArrangedSubview(previewHost)
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "maxWidth truncates long status copy. cornerStyle.fixed(8) suits dense tables. dotColorOverride tints the leading dot independently."
    ))

    let widthRow = UIStackView()
    widthRow.axis = .horizontal
    widthRow.spacing = 12
    widthRow.alignment = .center
    widthRow.addArrangedSubview(widthSlider)

    box.addArrangedSubview(FKStatusPillExampleSupport.labeledRow(title: "Max width", control: widthRow))
    box.addArrangedSubview(FKStatusPillExampleSupport.labeledRow(title: "Corner", control: cornerControl))
    box.addArrangedSubview(FKStatusPillExampleSupport.labeledRow(title: "Custom dot tint", control: dotTintSwitch))

    contentStack.addArrangedSubview(box)
    applyConfiguration()
  }

  private func applyConfiguration() {
    var config = FKStatusPillConfiguration()
    config.layout.maxWidth = CGFloat(widthSlider.value)
    config.appearance.cornerStyle = cornerControl.selectedSegmentIndex == 0 ? .capsule : .fixed(8)
    config.appearance.dotColorOverride = dotTintSwitch.isOn ? .systemPink : nil
    pill.configuration = config
    pill.title = "Awaiting carrier scan at regional hub"
    pill.style = .warning
    pill.showsDot = true
  }
}
