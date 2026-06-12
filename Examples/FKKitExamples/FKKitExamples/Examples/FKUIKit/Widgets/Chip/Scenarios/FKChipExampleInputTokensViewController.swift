import FKUIKit
import UIKit

final class FKChipExampleInputTokensViewController: FKChipExampleScrollViewController {

  private let group = FKChipGroup()
  private let logLabel = FKChipExampleSupport.eventLogLabel()
  private let addField = UITextField()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Input tokens"

    var config = FKChipGroupConfiguration()
    config.chipMode = .input
    config.layoutMode = .flow()
    group.configuration = config
    group.chips = FKChipExampleSupport.inputTokenItems()
    group.selectionMode = .none
    group.onChipRemoved = { [weak self] id in
      self?.appendLog("removed token id=\(id) · remaining=\(self?.group.chips.count ?? 0)")
    }
    group.onSelectionChange = { [weak self] ids in
      self?.appendLog("onSelectionChange · chips=\(self?.group.chips.count ?? 0) · selectedIDs=\(ids.sorted())")
    }

    addField.placeholder = "Add a tag…"
    addField.borderStyle = .roundedRect
    addField.returnKeyType = .done
    addField.addAction(UIAction { [weak self] _ in self?.addToken() }, for: .editingDidEndOnExit)

    let addButton = UIButton(type: .system)
    addButton.setTitle("Add", for: .normal)
    addButton.addAction(UIAction { [weak self] _ in self?.addToken() }, for: .touchUpInside)

    let fieldRow = FKChipExampleSupport.horizontalRow()
    fieldRow.addArrangedSubview(addField)
    fieldRow.addArrangedSubview(addButton)

    let box = FKChipExampleSupport.sectionContainer(title: "Removable input chips")
    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Input mode shows a remove affordance. Only taps in the trailing gutter (✕ and its padding) remove the token — title taps do not. VoiceOver exposes a custom remove action."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedGroup(group))
    box.addArrangedSubview(fieldRow)
    box.addArrangedSubview(logLabel)

    contentStack.addArrangedSubview(box)
  }

  private func addToken() {
    let raw = addField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !raw.isEmpty else { return }
    let id = "token-\(UUID().uuidString.prefix(6))"
    var items = group.chips
    items.append(FKChipItem(id: id, title: raw, showsRemoveButton: true))
    group.chips = items
    addField.text = nil
    appendLog("added token \"\(raw)\"")
  }

  private func appendLog(_ line: String) {
    logLabel.text = line
  }
}
