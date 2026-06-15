import UIKit
import FKCoreKit

/// B1 — optional version check with mock remote provider.
final class FKBusinessKitExampleVersionCheckViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "VersionCheck"
    addInfoLabel("Uses DemoRemoteVersionProvider in optionalUpdate mode.")
    addActionButton("Check (async) + present prompt") { [weak self] in
      guard let self else { return }
      Task {
        do {
          let provider = FKBusinessKitDemoRemoteVersionProvider(mode: .optionalUpdate)
          let result = try await self.kit.version.checkForUpdate(using: provider)
          self.appendLog("Decision: \(result.decision)")
          self.kit.version.presentUpdatePromptIfNeeded(result: result, presenter: self)
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
  }
}
