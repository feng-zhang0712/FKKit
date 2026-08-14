import FKUIKit
import UIKit

/// checkbox.selectAll — parent aggregate.
final class FKCheckboxExampleSelectAllViewController: FKSelectionExampleScrollViewController {
  private let parentBox = FKCheckbox(title: "Select all permissions", checkState: .unchecked)
  private var childBoxes: [FKCheckbox] = []
  private var isSyncing = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Select all"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Aggregate helper")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Parent uses applyAggregate / FKCheckboxStateAggregator. Tapping the parent selects or clears all children."))

    parentBox.onStateChanged = { [weak self] state in
      guard let self, !self.isSyncing else { return }
      let checked = state != .unchecked
      self.isSyncing = true
      for child in self.childBoxes {
        child.setCheckState(checked ? .checked : .unchecked, animated: true, sendActions: false)
      }
      self.isSyncing = false
      self.refreshParent(sendActions: false)
    }
    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(parentBox))

    let titles = ["Analytics", "Crash reports", "Personalized ads"]
    childBoxes = titles.map { FKCheckbox(title: $0) }
    for child in childBoxes {
      child.onStateChanged = { [weak self] _ in
        self?.refreshParent(sendActions: false)
      }
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(child))
    }
    contentStack.addArrangedSubview(box)
  }

  private func refreshParent(sendActions: Bool) {
    guard !isSyncing else { return }
    isSyncing = true
    parentBox.applyAggregate(fromChildCheckedFlags: childBoxes.map(\.isChecked), sendActions: sendActions)
    isSyncing = false
  }
}
