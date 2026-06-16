import FKCoreKit
import UIKit

/// E7 — Background download recovery checklist and snapshot inspection.
final class FKFileManagerExampleBackgroundRecoveryViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "BackgroundRecovery"
    addInfoLabel(
      """
      Production wiring:
      1. Enable Background Modes for your target.
      2. Set a unique backgroundSessionIdentifier in FKFileManagerConfiguration.
      3. In AppDelegate application(_:handleEventsForBackgroundURLSession:completionHandler:), call
         FKFileManager.shared.registerBackgroundSessionCompletionHandler(_:forSessionWithIdentifier:).
      4. On cold start, read persistedTransfers() to rebuild UI; re-bind progress handlers for new downloads.
      """
    )
    addActionButton("Show persistedTransfers()") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let rows = await FKFileManagerExampleSupport.manager.persistedTransfers()
        if rows.isEmpty {
          self.appendLog("No rows — start a background download in B3 first.")
        } else {
          for row in rows.prefix(8) {
            self.appendLog("id=\(row.id) kind=\(row.kind) state=\(row.state)")
          }
        }
      }
    }
    addActionButton("Simulate completion handler registration") { [weak self] in
      guard let self else { return }
      let identifier = FKFileManagerConfiguration().backgroundSessionIdentifier
      FKFileManager.shared.registerBackgroundSessionCompletionHandler({
        // Demo only — real handler must call system completionHandler.
      }, forSessionWithIdentifier: identifier)
      self.appendLog("Registered demo handler for identifier \(identifier)")
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
