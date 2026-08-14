import FKUIKit
import UIKit

/// checkbox.list — IN LIST + FKSelectionListChrome.
final class FKCheckboxExampleListViewController: FKSelectionExampleScrollViewController {
  private let (status, updateStatus) = FKSelectionExampleSupport.statusLabel(prefix: "Selection")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "List + chrome"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Permission list")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("FKSelectionListChrome wraps rows with card chrome and inset separators."))

    let titles = ["Camera access", "Microphone", "Photo library", "Location"]
    let checkboxes = titles.map { FKCheckbox(title: $0) }
    for checkbox in checkboxes {
      checkbox.onStateChanged = { [weak self] _ in
        self?.refreshStatus(checkboxes)
      }
      checkbox.configuration.layout.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    let chrome = FKSelectionListChrome()
    chrome.setArrangedControls(checkboxes)
    box.addArrangedSubview(chrome)
    box.addArrangedSubview(status)
    contentStack.addArrangedSubview(box)
    refreshStatus(checkboxes)
  }

  private func refreshStatus(_ boxes: [FKCheckbox]) {
    let checked = boxes.filter(\.isChecked).compactMap { $0.content.title }
    updateStatus(checked.isEmpty ? "none" : checked.joined(separator: ", "))
  }
}
