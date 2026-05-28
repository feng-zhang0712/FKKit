import UIKit
import FKUIKit

/// Scrollable action lists, selection memory, and scroll-to-selection on present.
final class FKActionSheetExampleLongListViewController: FKActionSheetExampleBaseViewController {
  private struct LanguageOption {
    let id: UUID
    let title: String
  }

  private static let languages: [LanguageOption] = [
    LanguageOption(id: UUID(), title: "English"),
    LanguageOption(id: UUID(), title: "Spanish"),
    LanguageOption(id: UUID(), title: "French"),
    LanguageOption(id: UUID(), title: "German"),
    LanguageOption(id: UUID(), title: "Italian"),
    LanguageOption(id: UUID(), title: "Portuguese"),
    LanguageOption(id: UUID(), title: "Dutch"),
    LanguageOption(id: UUID(), title: "Swedish"),
    LanguageOption(id: UUID(), title: "Norwegian"),
    LanguageOption(id: UUID(), title: "Danish"),
    LanguageOption(id: UUID(), title: "Finnish"),
    LanguageOption(id: UUID(), title: "Polish"),
    LanguageOption(id: UUID(), title: "Czech"),
    LanguageOption(id: UUID(), title: "Hungarian"),
    LanguageOption(id: UUID(), title: "Romanian"),
    LanguageOption(id: UUID(), title: "Greek"),
    LanguageOption(id: UUID(), title: "Turkish"),
    LanguageOption(id: UUID(), title: "Arabic"),
    LanguageOption(id: UUID(), title: "Hebrew"),
    LanguageOption(id: UUID(), title: "Hindi"),
    LanguageOption(id: UUID(), title: "Japanese"),
    LanguageOption(id: UUID(), title: "Korean"),
    LanguageOption(id: UUID(), title: "Chinese (Simplified)"),
    LanguageOption(id: UUID(), title: "Chinese (Traditional)"),
    LanguageOption(id: UUID(), title: "Vietnamese"),
    LanguageOption(id: UUID(), title: "Thai"),
    LanguageOption(id: UUID(), title: "Indonesian"),
    LanguageOption(id: UUID(), title: "Malay"),
  ]

  private var selectedLanguageID: UUID?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long List & Scroll"

    let scroll = UIStackView()
    scroll.axis = .vertical
    scroll.spacing = 8
    scroll.addArrangedSubview(FKActionSheetExampleUI.button("28 options (default height cap)") { [weak self] in
      self?.presentLanguageSheet(indicatorStyle: .check, remembersSelection: false)
    })
    scroll.addArrangedSubview(FKActionSheetExampleUI.button("Tight cap (maxPanelHeight 240)") { [weak self] in
      var presentation = FKActionSheetPresentationConfiguration.default
      presentation.maximumPanelHeight = 240
      self?.presentLanguageSheet(
        indicatorStyle: .check,
        remembersSelection: false,
        presentation: presentation
      )
    })

    let selection = UIStackView()
    selection.axis = .vertical
    selection.spacing = 8
    selection.addArrangedSubview(FKActionSheetExampleUI.button("Check + memory (re-open restores)") { [weak self] in
      self?.presentLanguageSheet(indicatorStyle: .check, remembersSelection: true)
    })
    selection.addArrangedSubview(FKActionSheetExampleUI.button("Highlighted title + memory") { [weak self] in
      self?.presentLanguageSheet(indicatorStyle: .highlightedTitle, remembersSelection: true)
    })
    selection.addArrangedSubview(FKActionSheetExampleUI.button("Memory without auto-scroll") { [weak self] in
      self?.presentLanguageSheet(
        indicatorStyle: .check,
        remembersSelection: true,
        scrollsToSelectionOnPresent: false
      )
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Scrollable list",
        description: "Panel height uses min(screen × maximumFitContentHeightFraction, maximumPanelHeight). No header keeps the list compact.",
        body: scroll
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Selection + scroll restore",
        description: "Set selectedActionID and leave scrollsToSelectionOnPresent at true (default) to scroll the restored row near the center on present.",
        body: selection
      )
    )
    addClearLogButton()
  }

  private func presentLanguageSheet(
    indicatorStyle: FKActionSheetSelectionIndicatorStyle,
    remembersSelection: Bool,
    scrollsToSelectionOnPresent: Bool = true,
    presentation: FKActionSheetPresentationConfiguration? = nil
  ) {
    let actions = Self.languages.map { option in
      FKActionSheetAction(id: option.id, title: option.title) { [weak self] in
        guard let self else { return }
        self.selectedLanguageID = option.id
        FKActionSheetExamplePlaybook.log("Selected \(option.title)")
      }
    }

    let selection = FKActionSheetSelectionConfiguration(
      mode: remembersSelection ? .single(scope: .allSections) : .none,
      keepsSheetPresentedOnSelection: false,
      selectedActionID: remembersSelection ? selectedLanguageID : nil,
      indicatorStyle: indicatorStyle,
      scrollsToSelectionOnPresent: scrollsToSelectionOnPresent
    )

    var resolvedPresentation = presentation ?? FKActionSheetPresentationConfiguration.default
    if resolvedPresentation.maximumPanelHeight == nil {
      resolvedPresentation.maximumPanelHeight = 360
    }

    let config = FKActionSheetConfiguration(
      sections: [FKActionSheetSection(actions: actions)],
      cancelAction: FKActionSheetExamplePlaybook.makeCancelAction(),
      presentation: resolvedPresentation,
      dismissesAfterActionSelection: true,
      selection: selection
    )

    _ = FKActionSheetExamplePlaybook.present(config, from: self)
  }
}
