import UIKit
import FKUIKit

final class FKActionSheetExampleLiveUpdatesViewController: FKActionSheetExampleBaseViewController {
  private weak var liveSheet: FKActionSheet?
  private var autoDemoTask: Task<Void, Never>?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Live Updates"

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
    body.addArrangedSubview(FKActionSheetExampleUI.button("Present again (alreadyPresented)") { [weak self] in
      guard let self, let sheet = self.liveSheet else {
        FKActionSheetExamplePlaybook.log("No retained sheet — present first")
        return
      }
      do {
        try sheet.present(from: self)
        FKActionSheetExamplePlaybook.log("Unexpected: second present succeeded")
      } catch {
        FKActionSheetExamplePlaybook.log("Second present rejected: \(error)")
      }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Retained FKActionSheet",
        description: "Present via init(configuration:) + present(from:), keep a weak reference, then call reload(configuration:), updateAction(_:), or dismiss(reason:).",
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
}
