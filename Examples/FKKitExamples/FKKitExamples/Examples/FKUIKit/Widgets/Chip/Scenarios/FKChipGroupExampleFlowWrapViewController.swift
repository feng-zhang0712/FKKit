import FKUIKit
import UIKit

final class FKChipGroupExampleFlowWrapViewController: FKChipExampleScrollViewController {

  private let group = FKChipGroup()
  private var widthConstraint: NSLayoutConstraint!
  private let wrapControl = UISegmentedControl(items: ["Wrap", "Single line"])
  private let textScaleControl = UISegmentedControl(items: ["Default", "Large", "AX3"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Flow wrap"

    var config = FKChipGroupConfiguration()
    config.layoutMode = .flow(wrap: true)
    config.chipMode = .filter

    group.configuration = config
    group.chips = FKChipExampleSupport.filterBarItems() + FKChipExampleSupport.categoryItems()
    group.selectionMode = .multiple(max: nil)

    wrapControl.selectedSegmentIndex = 0
    wrapControl.addAction(UIAction { [weak self] _ in self?.applyWrapMode() }, for: .valueChanged)

    let widthSlider = UISlider()
    widthSlider.minimumValue = 200
    widthSlider.maximumValue = Float(UIScreen.main.bounds.width - 40)
    widthSlider.value = 280
    widthSlider.addAction(UIAction { [weak self] action in
      guard let self, let slider = action.sender as? UISlider else { return }
      self.widthConstraint.constant = CGFloat(slider.value)
      self.group.setNeedsLayout()
      self.group.invalidateIntrinsicContentSize()
      self.view.layoutIfNeeded()
    }, for: .valueChanged)

    textScaleControl.selectedSegmentIndex = 0
    textScaleControl.addAction(UIAction { [weak self] _ in self?.applyTextScale() }, for: .valueChanged)

    group.translatesAutoresizingMaskIntoConstraints = false
    widthConstraint = group.widthAnchor.constraint(equalToConstant: 280)

    let box = FKChipExampleSupport.sectionContainer(title: "flow(wrap:)")
    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Flow layout wraps chips when wrap is on. Drag Container width to narrow the rail and preview reflow. Single line switches to horizontalScroll."
    ))

    let groupRow = UIStackView(arrangedSubviews: [group])
    groupRow.axis = .vertical
    groupRow.alignment = .leading
    box.addArrangedSubview(groupRow)
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Wrap", control: wrapControl))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Container width", control: widthSlider))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Text scale", control: textScaleControl))

    contentStack.addArrangedSubview(box)

    NSLayoutConstraint.activate([widthConstraint])
    applyTextScale()
  }

  private func applyWrapMode() {
    var config = group.configuration
    config.layoutMode = wrapControl.selectedSegmentIndex == 0 ? .flow(wrap: true) : .horizontalScroll
    group.configuration = config
  }

  private func applyTextScale() {
    var config = group.configuration
    var chipConfig = config.chipConfiguration
    switch textScaleControl.selectedSegmentIndex {
    case 1:
      chipConfig.appearance.titleFont = .systemFont(ofSize: 17, weight: .medium)
    case 2:
      chipConfig.appearance.titleFont = .systemFont(ofSize: 22, weight: .medium)
    default:
      chipConfig.appearance.titleFont = FKChipDefaults.configuration.appearance.titleFont
    }
    config.chipConfiguration = chipConfig
    group.configuration = config
  }
}
