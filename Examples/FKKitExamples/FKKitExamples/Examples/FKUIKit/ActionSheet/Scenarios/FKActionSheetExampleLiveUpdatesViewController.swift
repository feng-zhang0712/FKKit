import UIKit
import FKUIKit

final class FKActionSheetExampleLiveUpdatesViewController: FKActionSheetExampleBaseViewController {
  private weak var liveSheet: FKActionSheet?
  private var autoDemoTask: Task<Void, Never>?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Live Updates"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Live",
      menu: makeLiveDemoMenu()
    )

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Present + auto demo") { [weak self] in
      self?.presentLiveSheet(shouldStartAutoDemo: true)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Present (manual only)") { [weak self] in
      self?.presentLiveSheet(shouldStartAutoDemo: false)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Dismiss retained sheet") { [weak self] in
      guard let sheet = self?.liveSheet, sheet.isPresented else {
        FKActionSheetExamplePlaybook.log("No presented sheet to dismiss")
        return
      }
      sheet.dismiss(reason: .programmatic, animated: true)
      FKActionSheetExamplePlaybook.log("dismiss(reason: .programmatic)")
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("presentOnce (same id)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentOnceDemo(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.row([
      FKActionSheetExampleUI.button("isPresenting") {
        FKActionSheetExamplePlaybook.log("isPresenting = \(FKActionSheet.isPresenting)")
      },
      FKActionSheetExampleUI.button("dismissActive") {
        FKActionSheet.dismissActive()
        FKActionSheetExamplePlaybook.log("dismissActive()")
      },
    ]))

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Retained FKActionSheet",
        description: "Present via init(configuration:) + present(from:), keep a weak reference, then call reload(configuration:), updateAction(_:), or dismiss(reason:). Static isPresenting / dismissActive() target the most recent static convenience present.",
        body: body
      )
    )
    addClearLogButton()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    cancelAutoDemo()
  }

  private func presentLiveSheet(shouldStartAutoDemo: Bool) {
    cancelAutoDemo()
    liveSheet = FKActionSheetExamplePlaybook.presentForLiveReload(from: self)
    guard shouldStartAutoDemo, liveSheet != nil else { return }
    scheduleAutoDemo()
  }

  private func scheduleAutoDemo() {
    autoDemoTask?.cancel()
    autoDemoTask = Task { @MainActor [weak self] in
      FKActionSheetExamplePlaybook.log("Auto demo: reload in 2s…")
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard !Task.isCancelled, let self, let sheet = self.liveSheet, sheet.isPresented else { return }
      FKActionSheetExamplePlaybook.applyLiveReload(to: sheet)

      FKActionSheetExamplePlaybook.log("Auto demo: loading row in 2s…")
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard !Task.isCancelled, let sheet = self.liveSheet, sheet.isPresented else { return }
      FKActionSheetExamplePlaybook.applyLiveUpdateLoading(to: sheet)

      FKActionSheetExamplePlaybook.log("Auto demo: ready row in 2s…")
      try? await Task.sleep(nanoseconds: 2_000_000_000)
      guard !Task.isCancelled, let sheet = self.liveSheet, sheet.isPresented else { return }
      FKActionSheetExamplePlaybook.applyLiveUpdateReady(to: sheet)
      FKActionSheetExamplePlaybook.log("Auto demo finished")
    }
  }

  private func cancelAutoDemo() {
    autoDemoTask?.cancel()
    autoDemoTask = nil
  }

  private func makeLiveDemoMenu() -> UIMenu {
    UIMenu(children: [
      UIAction(title: "Reload configuration") { [weak self] _ in
        guard let sheet = self?.liveSheet else {
          FKActionSheetExamplePlaybook.log("No sheet — present first")
          return
        }
        FKActionSheetExamplePlaybook.applyLiveReload(to: sheet)
      },
      UIAction(title: "updateAction → loading") { [weak self] _ in
        guard let sheet = self?.liveSheet else {
          FKActionSheetExamplePlaybook.log("No sheet — present first")
          return
        }
        FKActionSheetExamplePlaybook.applyLiveUpdateLoading(to: sheet)
      },
      UIAction(title: "updateAction → ready") { [weak self] _ in
        guard let sheet = self?.liveSheet else {
          FKActionSheetExamplePlaybook.log("No sheet — present first")
          return
        }
        FKActionSheetExamplePlaybook.applyLiveUpdateReady(to: sheet)
      },
      UIAction(title: "Run auto demo") { [weak self] _ in
        guard let self, self.liveSheet?.isPresented == true else {
          FKActionSheetExamplePlaybook.log("Present the sheet first")
          return
        }
        self.scheduleAutoDemo()
      },
      UIAction(title: "isPresenting") { _ in
        FKActionSheetExamplePlaybook.log("isPresenting = \(FKActionSheet.isPresenting)")
      },
      UIAction(title: "dismissActive") { _ in
        FKActionSheet.dismissActive()
        FKActionSheetExamplePlaybook.log("dismissActive()")
      },
    ])
  }
}
