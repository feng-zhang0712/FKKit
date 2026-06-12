import FKUIKit
import UIKit

final class FKCopyChipExampleCallbacksViewController: FKCopyChipExampleScrollViewController {

  private let chip = FKCopyChip()
  private let logLabel = FKCopyChipExampleSupport.eventLogLabel()
  private var notificationObserver: NSObjectProtocol?

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent, let notificationObserver {
      NotificationCenter.default.removeObserver(notificationObserver)
      self.notificationObserver = nil
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Callbacks"

    chip.text = "REF-9001"
    chip.copyText = "REF-9001-full-reference"
    chip.onCopy = { [weak self] copied in
      self?.appendLog("onCopy(\(copied))")
    }
    chip.addAction(UIAction { [weak self] _ in
      self?.appendLog("primaryActionTriggered")
    }, for: .primaryActionTriggered)

    notificationObserver = NotificationCenter.default.addObserver(
      forName: .fk_copyChipDidCopy,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let text = note.userInfo?[FKCopyChipNotificationKeys.copiedText] as? String ?? "?"
      Task { @MainActor in
        self?.appendLog("Notification fk_copyChipDidCopy · \"\(text)\"")
      }
    }

    let box = FKCopyChipExampleSupport.sectionContainer(title: "Hooks")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "Integrators can observe Notification.Name.fk_copyChipDidCopy globally or use onCopy / primaryActionTriggered on the control."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(logLabel)

    contentStack.addArrangedSubview(box)
  }

  private func appendLog(_ line: String) {
    if logLabel.text?.hasPrefix("Tap a chip") == true {
      logLabel.text = line
    } else {
      logLabel.text = (logLabel.text ?? "") + "\n" + line
    }
  }
}
