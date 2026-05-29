import FKUIKit
import UIKit

/// Tap, drag, and step snapping on an interactive five-star control.
final class FKRatingExampleInteractiveViewController: FKRatingExampleScrollViewController {

  private let rating = FKRatingControl.interactiveStars(value: 2, step: .whole)
  private let stepControl = UISegmentedControl(items: ["Whole", "Half"])
  private let dragSwitch = UISwitch()
  private let (valueLabel, updateValueLabel) = FKRatingExampleSupport.valueReadout()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Interactive"

    rating.onValueChanged = { [weak self] value in
      self?.updateValueLabel(value)
    }
    updateValueLabel(rating.value)

    stepControl.selectedSegmentIndex = 0
    stepControl.addAction(UIAction { [weak self] _ in
      self?.applyStep()
    }, for: .valueChanged)

    dragSwitch.isOn = true
    dragSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.rating.configuration.interaction.allowsDragSelection = self.dragSwitch.isOn
    }, for: .valueChanged)

    let box = FKRatingExampleSupport.sectionContainer(title: "Rate this order")
    box.addArrangedSubview(FKRatingExampleSupport.caption("Tap a star or drag across the row. Values snap to the selected step."))
    box.addArrangedSubview(FKRatingExampleSupport.embedRating(rating))
    box.addArrangedSubview(valueLabel)
    box.addArrangedSubview(FKRatingExampleSupport.labeledRow(title: "Step", control: stepControl))
    box.addArrangedSubview(FKRatingExampleSupport.labeledRow(title: "Allow drag", control: dragSwitch))
    contentStack.addArrangedSubview(box)
  }

  private func applyStep() {
    rating.configuration.interaction.step = stepControl.selectedSegmentIndex == 1 ? .half : .whole
    rating.setValue(rating.value, animated: false, sendsControlEvents: false)
    updateValueLabel(rating.value)
  }
}
