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

  private enum ShareChannel: String, CaseIterable {
    case messages
    case mail
    case copyLink
    case saveImage
    case more

    var title: String {
      switch self {
      case .messages: return "Messages"
      case .mail: return "Mail"
      case .copyLink: return "Copy Link"
      case .saveImage: return "Save Image"
      case .more: return "More"
      }
    }
  }

  private var selectedSize: ExportSize = .small
  private var selectedChannels: Set<ShareChannel> = [.messages]
  private weak var activeSheet: FKActionSheet?
  private let exportActionIDs: [ExportSize: UUID] = Dictionary(
    uniqueKeysWithValues: ExportSize.allCases.map { ($0, UUID()) }
  )
  private let channelActionIDs: [ShareChannel: UUID] = Dictionary(
    uniqueKeysWithValues: ShareChannel.allCases.map { ($0, UUID()) }
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Selection"

    let singleBody = UIStackView()
    singleBody.axis = .vertical
    singleBody.spacing = 8
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Check") { [weak self] in
      self?.presentExportSheet(style: .check)
    })
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Radio") { [weak self] in
      self?.presentExportSheet(style: .radio)
    })
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Highlighted title") { [weak self] in
      self?.presentExportSheet(style: .highlightedTitle)
    })
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Check + highlight") { [weak self] in
      self?.presentExportSheet(style: .checkAndHighlightedTitle)
    })
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Radio + highlight") { [weak self] in
      self?.presentExportSheet(style: .radioAndHighlightedTitle)
    })

    let multiBody = UIStackView()
    multiBody.axis = .vertical
    multiBody.spacing = 8
    multiBody.addArrangedSubview(FKActionSheetExampleUI.button("Multi (max 3, disable rest)") { [weak self] in
      self?.presentMultiSelectSheet(disablesUnselectedRowsAtMax: true)
    })
    multiBody.addArrangedSubview(FKActionSheetExampleUI.button("Multi (max 2)") { [weak self] in
      self?.presentMultiSelectSheet(maxSelectionCount: 2, disablesUnselectedRowsAtMax: true)
    })
    multiBody.addArrangedSubview(FKActionSheetExampleUI.button("Multi (max 3, keep enabled)") { [weak self] in
      self?.presentMultiSelectSheet(disablesUnselectedRowsAtMax: false)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Single selection",
        description: "Re-open the sheet to see the previous choice restored via selection.selectedActionID. Selecting a row dismisses the sheet automatically.",
        body: singleBody
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Multiple selection",
        description: "Toggle rows, then tap Done. Selection is validated on present (e.g. too many pre-selected items for a lower max shows a toast).",
        body: multiBody
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
    presentConfiguration(config)
  }

  private func presentMultiSelectSheet(
    maxSelectionCount: Int = 3,
    disablesUnselectedRowsAtMax: Bool
  ) {
    let actions = ShareChannel.allCases.map { channel in
      FKActionSheetAction(id: channelActionIDs[channel]!, title: channel.title)
    }
    let selectedIDs = Set(selectedChannels.compactMap { channelActionIDs[$0] })
    let selectionSummary = selectedChannels.map(\.title).sorted().joined(separator: ", ")

    let config = FKActionSheetConfiguration(
      header: .text(
        FKActionSheetHeader(
          title: "Share via",
          message: "Pick up to \(maxSelectionCount). Selected: \(selectionSummary.isEmpty ? "none" : selectionSummary)"
        )
      ),
      sections: [FKActionSheetSection(actions: actions)],
      cancelAction: FKActionSheetAction(title: "Done", style: .cancel) { [weak self] in
        guard let self else { return }
        FKActionSheetExamplePlaybook.log("Done — channels: \(self.selectedChannels.map(\.title).sorted().joined(separator: ", "))")
      },
      selection: FKActionSheetSelectionConfiguration(
        mode: .multiple(
          FKActionSheetSelectionConfiguration.MultipleSelection(
            scope: .allSections,
            maxSelectionCount: maxSelectionCount,
            disablesUnselectedRowsAtMax: disablesUnselectedRowsAtMax
          )
        ),
        keepsSheetPresentedOnSelection: true,
        selectedActionIDs: selectedIDs,
        indicatorStyle: .checkAndHighlightedTitle
      ),
      hooks: FKActionSheetLifecycleHooks(
        willDismiss: { [weak self] _ in
          guard let self, let sheet = self.activeSheet else { return }
          self.applySelectedChannels(from: sheet.configuration)
        },
        didSelect: { [weak self] action in
          guard let self else { return }
          guard let channel = self.channelActionIDs.first(where: { $0.value == action.id })?.key else { return }
          if action.isSelected {
            self.selectedChannels.insert(channel)
          } else {
            self.selectedChannels.remove(channel)
          }
          FKActionSheetExamplePlaybook.log("Channels: \(self.selectedChannels.map(\.title).sorted().joined(separator: ", "))")
        }
      )
    )
    presentConfiguration(config)
  }

  private func applySelectedChannels(from configuration: FKActionSheetConfiguration) {
    guard case .multiple = configuration.selection.mode else { return }
    let selectedIDs = configuration.selection.selectedActionIDs
    selectedChannels = Set(
      channelActionIDs.compactMap { selectedIDs.contains($0.value) ? $0.key : nil }
    )
  }

  /// Dismisses any in-flight modal before presenting to avoid UIKit presentation conflicts.
  private func presentConfiguration(_ configuration: FKActionSheetConfiguration) {
    let present = { [weak self] in
      guard let self else { return }
      self.activeSheet = FKActionSheetExamplePlaybook.presentInstance(configuration, from: self)
    }
    if let presentedViewController {
      presentedViewController.dismiss(animated: false, completion: present)
    } else {
      present()
    }
  }
}
