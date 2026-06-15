import UIKit
import FKCoreKit

/// E3 — documents version check → host banner composition (FKBanner not shipped in FKKit).
final class FKBusinessKitExampleBannerVersionComposeViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "E3 BannerVersionCompose"
    addInfoLabel(
      """
      BusinessKit detects updates; the host shows FKBanner (when available) instead of presentUpdatePromptIfNeeded.
      Pattern: checkForUpdate → if optionalUpdate, show persistent banner with updateURL action.
      """
    )
    addActionButton("Simulate check → banner decision log") { [weak self] in
      guard let self else { return }
      Task {
        do {
          let provider = FKBusinessKitDemoRemoteVersionProvider(mode: .optionalUpdate)
          let result = try await self.kit.version.checkForUpdate(using: provider)
          self.appendLog("Decision: \(result.decision)")
          switch result.decision {
          case .upToDate:
            self.appendLog("Host: hide banner")
          case .optionalUpdate:
            self.appendLog("Host: show FKBanner(title: Update Available, action: open \(result.remote.updateURL?.absoluteString ?? ""))")
          case .forceUpdate:
            self.appendLog("Host: show blocking banner or force alert")
          }
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
  }
}
