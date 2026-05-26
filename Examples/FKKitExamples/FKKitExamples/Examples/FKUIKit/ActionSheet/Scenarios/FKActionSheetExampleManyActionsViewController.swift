import UIKit
import FKUIKit

final class FKActionSheetExampleManyActionsViewController: FKActionSheetExampleBaseViewController {
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
    title = "Many Actions"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("28 options (scroll, default max height)") { [weak self] in
      self?.presentLanguageSheet(indicatorStyle: .check, remembersSelection: false)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Language picker (check + memory)") { [weak self] in
      self?.presentLanguageSheet(indicatorStyle: .check, remembersSelection: true)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Language picker (highlight + memory)") { [weak self] in
      self?.presentLanguageSheet(indicatorStyle: .highlightedTitle, remembersSelection: true)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Language picker (memory, no auto-scroll)") { [weak self] in
      self?.presentLanguageSheet(
        indicatorStyle: .check,
        remembersSelection: true,
        scrollsToSelectionOnPresent: false
      )
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Centered card + memory + scroll") { [weak self] in
      var presentation = FKActionSheetPresentationConfiguration.centered
      presentation.maximumPanelHeight = 360
      self?.presentLanguageSheet(
        indicatorStyle: .check,
        remembersSelection: true,
        presentation: presentation
      )
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Scrollable list",
        description: "No header. Scroll cap uses min(screen fraction, maximumPanelHeight). With selection memory, scrolls to the restored row on present unless scrollsToSelectionOnPresent is false.",
        body: body
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
        let name = option.title
        FKActionSheetExamplePlaybook.log("Selected \(name)")
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
    resolvedPresentation.maximumPanelHeight = 360

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
