import UIKit
import FKCoreKit
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
  private struct LongListTopic: Hashable {
    let id: UUID
    let title: String
  }

  private static let longListTopics: [LongListTopic] = [
    LongListTopic(id: UUID(), title: "Announcements"),
    LongListTopic(id: UUID(), title: "Product updates"),
    LongListTopic(id: UUID(), title: "Security alerts"),
    LongListTopic(id: UUID(), title: "Billing"),
    LongListTopic(id: UUID(), title: "Comments"),
    LongListTopic(id: UUID(), title: "Mentions"),
    LongListTopic(id: UUID(), title: "Direct messages"),
    LongListTopic(id: UUID(), title: "Team invites"),
    LongListTopic(id: UUID(), title: "Calendar"),
    LongListTopic(id: UUID(), title: "Tasks"),
    LongListTopic(id: UUID(), title: "Reviews"),
    LongListTopic(id: UUID(), title: "Shipping"),
    LongListTopic(id: UUID(), title: "Inventory"),
    LongListTopic(id: UUID(), title: "Marketing"),
    LongListTopic(id: UUID(), title: "Surveys"),
    LongListTopic(id: UUID(), title: "Newsletter"),
    LongListTopic(id: UUID(), title: "Webhooks"),
    LongListTopic(id: UUID(), title: "API usage"),
    LongListTopic(id: UUID(), title: "Deployments"),
    LongListTopic(id: UUID(), title: "Incidents"),
    LongListTopic(id: UUID(), title: "Compliance"),
    LongListTopic(id: UUID(), title: "Privacy"),
    LongListTopic(id: UUID(), title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_tabbar_scenarios_accessibility_.accessibility.d660049bc1")),
    LongListTopic(id: UUID(), title: "Localization"),
    LongListTopic(id: UUID(), title: FKExamplesI18n.string("examples.scenario.examples_fkuikit_tabbar_scenarios_performance_fk.performance.63c9045599")),
    LongListTopic(id: UUID(), title: "Experiments"),
    LongListTopic(id: UUID(), title: "Beta features"),
    LongListTopic(id: UUID(), title: "Account settings"),
  ]

  private var selectedLongListTopicIDs: Set<UUID> = []
  private let exportSectionID = UUID()

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
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Single (section scope)") { [weak self] in
      self?.presentSectionScopedExportSheet()
    })
    singleBody.addArrangedSubview(FKActionSheetExampleUI.button("Keeps sheet open (single)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentSingleSelectionKeepsSheetOpen(from: self)
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
    multiBody.addArrangedSubview(FKActionSheetExampleUI.button("Multi long list (max 5, scroll)") { [weak self] in
      self?.presentLongListMultiSelectSheet()
    })

    let validation = UIStackView()
    validation.axis = .vertical
    validation.spacing = 8
    validation.addArrangedSubview(FKActionSheetExampleUI.button("Validation: too many pre-selected") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentSelectionValidationFailure(from: self)
    })
    validation.addArrangedSubview(FKActionSheetExampleUI.button("Centered card + radio") { [weak self] in
      guard let self else { return }
      _ = FKActionSheetExamplePlaybook.presentCenteredSingleSelection(from: self)
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
        description: "Toggle rows, then tap Done. Use keepsSheetPresentedOnSelection = true so rows toggle without dismissing.",
        body: multiBody
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Validation",
        description: "init/present validate selection against maxSelectionCount. Over-limit pre-selection fails with FKActionSheetValidationError and localizedMessage for UI.",
        body: validation
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

  private func presentSectionScopedExportSheet() {
    let exportActions = ExportSize.allCases.map { size in
      FKActionSheetAction(id: exportActionIDs[size]!, title: size.title) { [weak self] in
        guard let self else { return }
        self.selectedSize = size
        FKActionSheetExamplePlaybook.log("Scoped export: \(size.title)")
      }
    }
    let config = FKActionSheetConfiguration(
      header: .text(
        FKActionSheetHeader(
          title: "Export",
          message: "Selection applies only to the Export section."
        )
      ),
      sections: [
        FKActionSheetSection(
          id: exportSectionID,
          title: "Export",
          actions: exportActions
        ),
        FKActionSheetSection(
          title: "Notes",
          actions: [
            FKActionSheetAction(title: "Formats are lossless in this demo") {
              FKActionSheetExamplePlaybook.log("Notes row tapped")
            },
          ]
        ),
      ],
      cancelAction: FKActionSheetExamplePlaybook.makeCancelAction(),
      selection: FKActionSheetSelectionConfiguration(
        mode: .single(scope: .section(id: exportSectionID)),
        keepsSheetPresentedOnSelection: false,
        selectedActionID: exportActionIDs[selectedSize],
        indicatorStyle: .check
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

  private func presentLongListMultiSelectSheet() {
    let maxSelectionCount = 5
    let actions = Self.longListTopics.map { topic in
      FKActionSheetAction(id: topic.id, title: topic.title)
    }
    let selectedSummary = Self.longListTopics
      .filter { selectedLongListTopicIDs.contains($0.id) }
      .map(\.title)
      .joined(separator: ", ")

    var presentation = FKActionSheetPresentationConfiguration.default
    presentation.maximumPanelHeight = 360

    let config = FKActionSheetConfiguration(
      header: .text(
        FKActionSheetHeader(
          title: "Notification topics",
          message: "Pick up to \(maxSelectionCount). Selected: \(selectedSummary.isEmpty ? "none" : selectedSummary)"
        )
      ),
      sections: [FKActionSheetSection(actions: actions)],
      cancelAction: FKActionSheetAction(title: "Done", style: .cancel) { [weak self] in
        guard let self else { return }
        let titles = Self.longListTopics
          .filter { self.selectedLongListTopicIDs.contains($0.id) }
          .map(\.title)
        FKActionSheetExamplePlaybook.log("Long list Done — \(titles.joined(separator: ", "))")
      },
      presentation: presentation,
      selection: FKActionSheetSelectionConfiguration(
        mode: .multiple(
          FKActionSheetSelectionConfiguration.MultipleSelection(
            scope: .allSections,
            maxSelectionCount: maxSelectionCount,
            disablesUnselectedRowsAtMax: true
          )
        ),
        keepsSheetPresentedOnSelection: true,
        selectedActionIDs: selectedLongListTopicIDs,
        indicatorStyle: .check,
        scrollsToSelectionOnPresent: true
      ),
      hooks: FKActionSheetLifecycleHooks(
        willDismiss: { [weak self] _ in
          guard let self, let sheet = self.activeSheet else { return }
          self.applySelectedLongListTopics(from: sheet.configuration)
        },
        didSelect: { [weak self] action in
          guard let self else { return }
          if action.isSelected {
            self.selectedLongListTopicIDs.insert(action.id)
          } else {
            self.selectedLongListTopicIDs.remove(action.id)
          }
          let titles = Self.longListTopics
            .filter { self.selectedLongListTopicIDs.contains($0.id) }
            .map(\.title)
          FKActionSheetExamplePlaybook.log("Long list: \(titles.joined(separator: ", "))")
        }
      )
    )
    presentConfiguration(config)
  }

  private func applySelectedLongListTopics(from configuration: FKActionSheetConfiguration) {
    guard case .multiple = configuration.selection.mode else { return }
    selectedLongListTopicIDs = configuration.selection.selectedActionIDs
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
