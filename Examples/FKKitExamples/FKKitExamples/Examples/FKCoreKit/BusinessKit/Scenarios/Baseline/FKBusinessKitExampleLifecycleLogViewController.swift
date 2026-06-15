import UIKit
import FKCoreKit

/// B5 — lifecycle observation log.
final class FKBusinessKitExampleLifecycleLogViewController: FKBusinessKitExampleBaseViewController {
  private var lifecycleToken: FKBusinessObservationToken?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "LifecycleLog"
    addInfoLabel("Send app to background/foreground to see transitions.")
    lifecycleToken = kit.lifecycle.observe { [weak self] state in
      Task { @MainActor in
        self?.appendLog("State: \(state.rawValue)")
      }
    }
    appendLog("Current: \(kit.lifecycle.state.rawValue)")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if isMovingFromParent {
      lifecycleToken?.invalidate()
      lifecycleToken = nil
    }
  }
}
