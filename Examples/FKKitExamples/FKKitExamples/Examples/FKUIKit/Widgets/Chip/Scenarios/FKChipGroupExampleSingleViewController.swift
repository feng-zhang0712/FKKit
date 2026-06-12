import FKUIKit
import UIKit

final class FKChipGroupExampleSingleViewController: FKChipExampleScrollViewController {

  private let group = FKChipGroup()
  private let logLabel = FKChipExampleSupport.eventLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Single selection"

    var config = FKChipGroupConfiguration()
    config.chipMode = .filter
    config.layoutMode = .flow()

    group.configuration = config
    group.chips = FKChipExampleSupport.filterBarItems()
    group.selectionMode = .single
    group.onSelectionChange = { [weak self] ids in
      self?.logLabel.text = "selectedIDs: \(ids.sorted())"
    }

    let clearButton = UIButton(type: .system)
    clearButton.setTitle("Clear (setSelectedIDs)", for: .normal)
    clearButton.addAction(UIAction { [weak self] _ in
      self?.group.setSelectedIDs([], animated: true)
      self?.logLabel.text = "selectedIDs: [] (cleared programmatically)"
    }, for: .touchUpInside)

    let selectSaleButton = UIButton(type: .system)
    selectSaleButton.setTitle("Select \"On sale\"", for: .normal)
    selectSaleButton.addAction(UIAction { [weak self] _ in
      self?.group.setSelectedIDs(["sale"], animated: true)
      self?.logLabel.text = "selectedIDs: [\"sale\"] (set programmatically)"
    }, for: .touchUpInside)

    let buttonRow = FKChipExampleSupport.horizontalRow(spacing: 16)
    buttonRow.addArrangedSubview(clearButton)
    buttonRow.addArrangedSubview(selectSaleButton)

    let box = FKChipExampleSupport.sectionContainer(title: "Filter bar · .single")
    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Exactly one chip stays selected. setSelectedIDs(_:animated:) updates chips without re-firing onSelectionChange."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedGroup(group))
    box.addArrangedSubview(buttonRow)
    box.addArrangedSubview(logLabel)

    contentStack.addArrangedSubview(box)
    logLabel.text = "selectedIDs: [\"all\"]"
  }
}
