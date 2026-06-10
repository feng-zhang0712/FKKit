import FKUIKit
import UIKit

final class FKChipExampleSuggestionViewController: FKChipExampleScrollViewController {

  private let logLabel = FKChipExampleSupport.eventLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Suggestion"

    contentStack.addArrangedSubview(FKChipExampleSupport.caption(
      "Suggestion chips fire primaryActionTriggered on tap and never stay selected — ideal for one-shot search refinements."
    ))

    contentStack.addArrangedSubview(makeStandaloneSection())
    contentStack.addArrangedSubview(makeGroupSection())
    contentStack.addArrangedSubview(FKChipExampleSupport.sectionContainer(title: "Events").apply {
      $0.addArrangedSubview(logLabel)
    })
  }

  private func makeStandaloneSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "Standalone suggestion chips")

    let row = FKChipExampleSupport.intrinsicWidthRow(spacing: 8)
    for title in ["Near me", "Open now", "Top rated"] {
      let chip = FKChip(mode: .suggestion, title: title)
      chip.addAction(UIAction { [weak self, weak chip] _ in
        guard let self, let chip else { return }
        self.appendLog("primaryActionTriggered · \(chip.title) (selected=\(chip.isSelected))")
      }, for: .primaryActionTriggered)
      row.addItem(chip)
    }

    box.addArrangedSubview(row)
    return box
  }

  private func makeGroupSection() -> UIStackView {
    let box = FKChipExampleSupport.sectionContainer(title: "FKChipGroup · suggestion mode")

    var config = FKChipGroupConfiguration()
    config.chipMode = .suggestion
    config.layoutMode = .horizontalScroll

    let group = FKChipGroup(
      configuration: config,
      chips: FKChipExampleSupport.suggestionItems(),
      selectionMode: .none
    )
    group.onChipPrimaryAction = { [weak self] id in
      let title = group.chips.first(where: { $0.id == id })?.title ?? id
      self?.appendLog("group suggestion tap · id=\(id) · title=\"\(title)\"")
    }
    group.onSelectionChange = { [weak self] ids in
      self?.appendLog("onSelectionChange · selectedIDs=\(ids.sorted()) (unchanged)")
    }

    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Use onChipPrimaryAction to learn which suggestion was tapped; onSelectionChange still fires without mutating selectedIDs."
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
