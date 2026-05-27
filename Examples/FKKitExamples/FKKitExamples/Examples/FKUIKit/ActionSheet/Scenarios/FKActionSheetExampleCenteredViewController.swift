import UIKit
import FKUIKit

/// Demonstrates ``FKActionSheetPresentationStyle/centered`` (dimmed backdrop + floating card).
final class FKActionSheetExampleCenteredViewController: FKActionSheetExampleBaseViewController {
  private weak var loadingSheet: FKActionSheet?
  private var fetchTask: Task<Void, Never>?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Centered"

    let appearance = UIStackView()
    appearance.axis = .vertical
    appearance.spacing = 8
    appearance.addArrangedSubview(FKActionSheetExampleUI.button("Card preset (default)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredCard(from: $0) }
    })
    appearance.addArrangedSubview(FKActionSheetExampleUI.button("Plain preset") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredPlain(from: $0) }
    })
    appearance.addArrangedSubview(FKActionSheetExampleUI.button("System preset") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredSystem(from: $0) }
    })

    let presentation = UIStackView()
    presentation.axis = .vertical
    presentation.spacing = 8
    presentation.addArrangedSubview(FKActionSheetExampleUI.button("Backdrop dismiss disabled") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredBackdropDismissDisabled(from: $0) }
    })
    presentation.addArrangedSubview(FKActionSheetExampleUI.button("Strong backdrop (alpha 0.6)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredStrongBackdrop(from: $0) }
    })
    presentation.addArrangedSubview(FKActionSheetExampleUI.button("Compact card (300pt wide)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredCompactCard(from: $0) }
    })

    let content = UIStackView()
    content.axis = .vertical
    content.spacing = 8
    content.addArrangedSubview(FKActionSheetExampleUI.button("Destructive confirmation") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredDestructive(from: $0) }
    })
    content.addArrangedSubview(FKActionSheetExampleUI.button("Scrollable list (max height 280)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCenteredScrollableList(from: $0) }
    })
    content.addArrangedSubview(FKActionSheetExampleUI.button("Single selection (radio)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentCenteredSingleSelection(from: self)
    })

    let loading = UIStackView()
    loading.axis = .vertical
    loading.spacing = 8
    loading.addArrangedSubview(FKActionSheetExampleUI.button("Loading → fetch") { [weak self] in
      self?.presentCenteredLoadingFetch()
    })
    loading.addArrangedSubview(FKActionSheetExampleUI.button("Simulate fetch success") { [weak self] in
      self?.finishCenteredLoadingFetch(succeeded: true)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Centered presentation",
        description: "Set presentation to .centered (or FKActionSheetPresentationConfiguration.centered). The card is vertically centered with a dimmed backdrop; tap-outside dismiss is configurable.",
        body: presentation
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Appearance presets",
        description: "Card, plain, and system presets on the same centered layout.",
        body: appearance
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Content",
        description: "Destructive flows, in-card scrolling, and single-selection groups.",
        body: content
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Loading on centered card",
        description: "contentMode = .loading with presentation: .centered, then finishLoading when data arrives.",
        body: loading
      )
    )
    addClearLogButton()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    fetchTask?.cancel()
    fetchTask = nil
  }

  private func presentCenteredLoadingFetch() {
    fetchTask?.cancel()
    guard let sheet = FKActionSheetExamplePlaybook.presentCenteredLoading(from: self) else { return }
    loadingSheet = sheet
    fetchTask = Task { @MainActor [weak self] in
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard !Task.isCancelled else { return }
      self?.finishCenteredLoadingFetch(succeeded: true)
    }
  }

  private func finishCenteredLoadingFetch(succeeded: Bool) {
    guard succeeded else { return }
    guard let sheet = loadingSheet, sheet.isPresented else {
      FKActionSheetExamplePlaybook.log("No presented centered loading sheet")
      return
    }
    let share = FKActionSheetAction(title: "Messages", symbolName: "message.fill") {
      FKActionSheetExamplePlaybook.log("Centered Messages")
    }
    let mail = FKActionSheetAction(title: "Mail", symbolName: "envelope.fill") {
      FKActionSheetExamplePlaybook.log("Centered Mail")
    }
    if sheet.finishLoading(
      sections: [FKActionSheetSection(actions: [share, mail])],
      header: .text(FKActionSheetHeader(title: "Share", message: "Loaded on centered card"))
    ) {
      FKActionSheetExamplePlaybook.log("Centered finishLoading succeeded")
    }
  }
}
