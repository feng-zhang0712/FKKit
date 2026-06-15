import UIKit
import FKCoreKit

/// B2 — forced update decision and non-dismissible prompt path.
final class FKBusinessKitExampleVersionForceUpdateViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B2 VersionForceUpdate"
    addInfoLabel("Mock remote marks isForceUpdate=true.")
    addActionButton("Check (closure) + present force prompt") { [weak self] in
      guard let self else { return }
      let provider = FKBusinessKitDemoRemoteVersionProvider(mode: .forceUpdate)
      self.kit.version.checkForUpdate(using: provider) { result in
        Task { @MainActor in
          switch result {
          case let .success(check):
            self.appendLog("Decision: \(check.decision)")
            self.kit.version.presentUpdatePromptIfNeeded(result: check, presenter: self)
          case let .failure(error):
            self.appendLog("Error: \(error.localizedDescription)")
          }
        }
      }
    }
  }
}
