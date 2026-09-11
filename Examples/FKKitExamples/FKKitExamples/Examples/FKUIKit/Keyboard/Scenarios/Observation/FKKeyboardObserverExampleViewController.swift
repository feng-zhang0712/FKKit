import UIKit
import FKUIKit

/// Demonstrates ``FKKeyboardObserver`` and ``FKKeyboardInfo`` (including `from(notification:)`).
final class FKKeyboardObserverExampleViewController: FKKeyboardExamplePageViewController {
  private let observer = FKKeyboardObserver()
  private let statusLabel = FKKeyboardExampleUI.monospaceLabel()
  private let parsedLabel = FKKeyboardExampleUI.monospaceLabel()
  private let field = FKKeyboardExampleUI.makeTextField(placeholder: "Tap to show the keyboard")
  private var rawNotificationToken: NSObjectProtocol?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Observer & KeyboardInfo"
    addIntro(
      title: "Live keyboard snapshots",
      body: "Shows frame, duration, curve, isLocal, isVisible, and overlapHeight(in:). Also rebuilds info via FKKeyboardInfo.from(notification:)."
    )
    contentStack.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(parsedLabel)
    addField(title: "Text field", field: field)

    observer.onChange = { [weak self] info in
      self?.render(info)
    }
    render(observer.current)

    rawNotificationToken = NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillChangeFrameNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let parsed = FKKeyboardInfo.from(notification: note)
      Task { @MainActor in
        self?.parsedLabel.text = "from(notification:): visible=\(parsed.isVisible) local=\(parsed.isLocal)"
      }
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    observer.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    observer.stop()
    if let rawNotificationToken {
      NotificationCenter.default.removeObserver(rawNotificationToken)
      self.rawNotificationToken = nil
    }
  }

  private func render(_ info: FKKeyboardInfo) {
    let overlap = info.overlapHeight(in: view)
    statusLabel.text = """
    isVisible: \(info.isVisible)
    isLocal: \(info.isLocal)
    duration: \(String(format: "%.3f", info.animationDuration))s
    curve raw: \(info.animationCurveRawValue) (\(info.animationCurve.rawValue))
    endFrame: \(NSCoder.string(for: info.endFrameInScreen))
    overlapHeight(in: view): \(String(format: "%.1f", overlap))
    """
  }
}
