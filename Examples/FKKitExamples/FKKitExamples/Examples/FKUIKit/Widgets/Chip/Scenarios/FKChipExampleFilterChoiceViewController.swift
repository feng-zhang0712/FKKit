import FKUIKit
import UIKit

final class FKChipExampleFilterChoiceViewController: FKChipExampleScrollViewController {

  private let logLabel = FKChipExampleSupport.eventLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter & choice"

    contentStack.addArrangedSubview(FKChipExampleSupport.caption(
      "Standalone FKChip controls outside a group. Filter toggles selection locally; choice behaves the same until placed in a group with orchestration."
    ))

    contentStack.addArrangedSubview(makeFilterSection())
    contentStack.addArrangedSubview(makeChoiceSection())
    contentStack.addArrangedSubview(makeIndependentGroupSection())
    contentStack.addArrangedSubview(FKChipExampleSupport.sectionContainer(title: "Events").apply {
      $0.addArrangedSubview(logLabel)
    })
  }

  private func makeFilterSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "Filter · border when selected")

    var config = FKChipConfiguration()
    config.appearance.usesBorderWhenSelected = true
    config.interaction.hapticFeedbackOnSelection = true

    let specs: [(String, FKChipIcon?, Bool, Bool)] = [
      ("Free shipping", .symbol(name: "shippingbox"), false, true),
      ("In stock", .symbol(name: "checkmark.circle"), true, true),
      ("On sale", nil, false, true),
      ("Unavailable", nil, false, false),
    ]

    let row = FKChipExampleSupport.intrinsicWidthRow(spacing: 8)

    for spec in specs {
      let chip = FKChip(configuration: config, mode: .filter, title: spec.0)
      chip.leadingIcon = spec.1
      chip.isSelected = spec.2
      chip.isEnabled = spec.3
      chip.addAction(UIAction { [weak self, weak chip] _ in
        guard let self, let chip else { return }
        self.appendLog("filter · \(chip.title) → selected=\(chip.isSelected)")
      }, for: .valueChanged)
      row.addItem(chip)
    }

    box.addArrangedSubview(FKChipExampleSupport.caption(
      "usesBorderWhenSelected draws an outline fill instead of solid selected background. Haptic feedback fires on toggle."
    ))
    box.addArrangedSubview(row)
    return box
  }

  private func makeChoiceSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "Choice")

    let row = FKChipExampleSupport.intrinsicWidthRow(spacing: 8)
    for title in ["Daily", "Weekly", "Monthly"] {
      let chip = FKChip(mode: .choice, title: title)
      chip.isSelected = title == "Weekly"
      chip.addAction(UIAction { [weak self, weak chip] _ in
        guard let self, let chip else { return }
        row.subviews.compactMap { $0 as? FKChip }.forEach { $0.isSelected = ($0 === chip) }
        self.appendLog("choice · \(chip.title)")
      }, for: .valueChanged)
      row.addItem(chip)
    }

    box.addArrangedSubview(FKChipExampleSupport.caption("Choice chips behave like radio buttons when wired manually."))
    box.addArrangedSubview(row)
    return box
  }

  private func makeIndependentGroupSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "Group · selectionMode .none")

    var groupConfig = FKChipGroupConfiguration()
    groupConfig.chipMode = .filter
    let group = FKChipGroup(
      configuration: groupConfig,
      chips: [
        FKChipItem(id: "a", title: "Photos"),
        FKChipItem(id: "b", title: "Videos"),
        FKChipItem(id: "c", title: "Documents"),
      ],
      selectionMode: .none
    )
    group.onSelectionChange = { [weak self] ids in
      self?.appendLog("group(none) · selected IDs: \(ids.sorted())")
    }

    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Each chip toggles independently; the group reports the full selected set without enforcing single/multiple rules."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedGroup(group))
    return box
  }

  private func appendLog(_ line: String) {
    if logLabel.text == "Events will appear here." {
      logLabel.text = line
    } else {
      logLabel.text = (logLabel.text ?? "") + "\n" + line
    }
  }
}

private extension UIStackView {
  func apply(_ block: (UIStackView) -> Void) -> UIStackView {
    block(self)
    return self
  }
}
