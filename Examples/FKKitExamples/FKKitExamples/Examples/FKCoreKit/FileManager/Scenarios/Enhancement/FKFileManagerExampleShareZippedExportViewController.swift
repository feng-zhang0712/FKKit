import FKCoreKit
import UIKit

/// E8 — Zip a folder and present the iOS share sheet for the archive.
final class FKFileManagerExampleShareZippedExportViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ShareZippedExport"
    addInfoLabel("Creates a ZIP under Documents, then makeShareController(for:).")
    addActionButton("Zip demo folder and share") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let root = FKFileManagerExampleSupport.scenarioDirectory("E8")
        let folder = root.appendingPathComponent("export", isDirectory: true)
        let zipURL = root.appendingPathComponent("export.zip")
        do {
          try await manager.createDirectory(at: folder, intermediate: true)
          try await manager.writeContent(.text("exported content"), to: folder.appendingPathComponent("readme.txt"))
          if manager.exists(at: zipURL) { try await manager.removeItem(at: zipURL) }
          try await manager.zipItem(at: folder, to: zipURL)
          let controller = manager.makeShareController(for: zipURL)
          if let pop = controller.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 1, height: 1)
          }
          self.present(controller, animated: true)
          self.appendLog("Sharing \(zipURL.lastPathComponent)")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
