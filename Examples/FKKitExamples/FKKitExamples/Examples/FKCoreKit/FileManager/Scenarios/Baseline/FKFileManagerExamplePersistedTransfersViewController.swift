import FKCoreKit
import UIKit

/// B7 — persistedTransfers snapshot inspection.
final class FKFileManagerExamplePersistedTransfersViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "PersistedTransfers"
    addInfoLabel("Start a transfer in B3/B4, then refresh snapshots here.")
    addActionButton("Refresh persistedTransfers()") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let rows = await FKFileManagerExampleSupport.manager.persistedTransfers()
        if rows.isEmpty {
          self.appendLog("No persisted rows (start download/upload first).")
          return
        }
        self.appendLog("Latest \(rows.count) snapshot(s):")
        for row in rows.prefix(10) {
          self.appendLog(" id=\(row.id) kind=\(row.kind) state=\(row.state) updated=\(row.updatedAt)")
        }
      }
    }
    addActionButton("Kick off quick foreground download") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        guard let source = URL(string: "https://raw.githubusercontent.com/github/gitignore/main/Swift.gitignore") else { return }
        let request = FKDownloadRequest(
          sourceURL: source,
          destinationDirectory: manager.directoryURL(.caches),
          fileName: "B7-snapshot-demo.txt",
          allowsBackground: false
        )
        do {
          let id = try await manager.download(request, progress: nil, completion: nil)
          self.appendLog("Started download id=\(id); tap Refresh in a moment.")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
