import UIKit
import FKUIKit

final class FKActionSheetExampleSelectionViewController: FKActionSheetExampleBaseViewController {
  private enum ExportSize: String, CaseIterable {
    case small
    case medium
    case large

    var title: String {
      switch self {
      case .small: return "Small"
      case .medium: return "Medium"
      case .large: return "Large"
      }
    }
  }

  private var selectedSize: ExportSize = .small
  private let exportActionIDs: [ExportSize: UUID] = Dictionary(
    uniqueKeysWithValues: ExportSize.allCases.map { ($0, UUID()) }
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Selection"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Check") { [weak self] in
      self?.presentExportSheet(style: .check)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Radio") { [weak self] in
      self?.presentExportSheet(style: .radio)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Highlighted title") { [weak self] in
      self?.presentExportSheet(style: .highlightedTitle)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Check + highlight") { [weak self] in
      self?.presentExportSheet(style: .checkAndHighlightedTitle)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Radio + highlight") { [weak self] in
      self?.presentExportSheet(style: .radioAndHighlightedTitle)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Selection styles",
        description: "Re-open the sheet to see the previous choice restored via selection.selectedActionID. Selecting a row dismisses the sheet automatically.",
        body: body
      )
    )
    addClearLogButton()
  }

  private func presentExportSheet(style: FKActionSheetSelectionIndicatorStyle) {
    let actions = ExportSize.allCases.map { size in
      FKActionSheetAction(id: exportActionIDs[size]!, title: size.title) { [weak self] in
        guard let self else { return }
        self.selectedSize = size
        FKActionSheetExamplePlaybook.log("Export size: \(size.title)")
      }
    }
    let selectedID = exportActionIDs[selectedSize]

    let config = FKActionSheetConfiguration(
      header: .text(FKActionSheetHeader(title: "Export size")),
      sections: [FKActionSheetSection(actions: actions)],
      selection: FKActionSheetSelectionConfiguration(
        mode: .single(scope: .allSections),
        keepsSheetPresentedOnSelection: false,
        selectedActionID: selectedID,
        indicatorStyle: style
      )
    )
    _ = FKActionSheetExamplePlaybook.present(config, from: self)
  }
}
