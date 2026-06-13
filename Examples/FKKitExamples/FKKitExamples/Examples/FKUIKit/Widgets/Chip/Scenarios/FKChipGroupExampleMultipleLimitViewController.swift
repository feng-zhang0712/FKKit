import FKUIKit
import UIKit

final class FKChipGroupExampleMultipleLimitViewController: FKChipExampleScrollViewController {

  private let group = FKChipGroup()
  private let logLabel = FKChipExampleSupport.eventLogLabel()
  private let limitLabel = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Multiple limit"

    var config = FKChipGroupConfiguration()
    config.chipMode = .filter
    config.overflowBehavior = .notify

    group.configuration = config
    group.chips = FKChipExampleSupport.categoryItems()
    group.selectionMode = .multiple(max: 2)
    group.onSelectionChange = { [weak self] ids in
      self?.updateStatus(selected: ids)
    }
    group.onSelectionLimitReached = { [weak self] in
      self?.appendLog("onSelectionLimitReached — max 2 categories")
    }

    limitLabel.font = .preferredFont(forTextStyle: .body)
    limitLabel.textColor = .secondaryLabel
    limitLabel.numberOfLines = 0

    let behaviorControl = UISegmentedControl(items: ["notify", "ignoreTap"])
    behaviorControl.selectedSegmentIndex = 0
    behaviorControl.addAction(UIAction { [weak self] action in
      guard let self, let seg = action.sender as? UISegmentedControl else { return }
      var config = self.group.configuration
      config.overflowBehavior = seg.selectedSegmentIndex == 0 ? .notify : .ignoreTap
      self.group.configuration = config
      self.appendLog("overflowBehavior → \(seg.selectedSegmentIndex == 0 ? "notify" : "ignoreTap")")
    }, for: .valueChanged)

    let box = FKChipExampleSupport.sectionContainer(title: "multiple(max: 2)")
    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Pick up to two categories. When at capacity, notify fires (or taps are ignored with ignoreTap)."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedGroup(group))
    box.addArrangedSubview(limitLabel)
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Overflow", control: behaviorControl))
    box.addArrangedSubview(logLabel)

    contentStack.addArrangedSubview(box)
    updateStatus(selected: [])
  }

  private func updateStatus(selected ids: Set<String>) {
    limitLabel.text = "Selected \(ids.count)/2: \(ids.sorted().joined(separator: ", "))"
    appendLog("selectedIDs: \(ids.sorted())")
  }

  private func appendLog(_ line: String) {
    logLabel.text = line
  }
}
