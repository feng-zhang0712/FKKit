import FKCoreKit
import QuickLook
import UIKit

/// B8 — iOS share sheet and Quick Look preview helpers.
final class FKFileManagerExampleShareAndPreviewViewController: FKFileManagerExampleBaseViewController {
  private var previewDataSource: QLPreviewControllerDataSource?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B8 ShareAndPreview"
    addInfoLabel("makeShareController / makePreviewController require a local file URL.")
    addActionButton("Share demo text file") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let url = FKFileManagerExampleSupport.scenarioDirectory("B8").appendingPathComponent("share.txt")
        do {
          try await manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
          try await manager.writeContent(.text("Share sheet demo"), to: url)
          let controller = manager.makeShareController(for: url)
          if let pop = controller.popoverPresentationController {
            pop.sourceView = self.view
            pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 1, height: 1)
          }
          self.present(controller, animated: true)
          self.appendLog("Presenting UIActivityViewController.")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Quick Look preview") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let url = FKFileManagerExampleSupport.scenarioDirectory("B8").appendingPathComponent("preview.txt")
        do {
          try await manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
          try await manager.writeContent(.text("Quick Look preview content"), to: url)
          let pair = manager.makePreviewController(for: url)
          self.previewDataSource = pair.dataSource
          self.present(pair.controller, animated: true)
          self.appendLog("Presenting QLPreviewController (data source retained).")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
