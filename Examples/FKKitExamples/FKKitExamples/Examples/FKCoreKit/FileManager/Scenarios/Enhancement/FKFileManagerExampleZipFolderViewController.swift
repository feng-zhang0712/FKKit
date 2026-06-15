import FKCoreKit
import UIKit

/// E1 — Compress a folder into a ZIP archive.
final class FKFileManagerExampleZipFolderViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "E1 ZipFolder"
    addInfoLabel("FKFileManager.isZipAvailable = \(FKFileManager.isZipAvailable)")
    addActionButton("Seed folder and zipItem") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let folder = FKFileManagerExampleSupport.scenarioDirectory("E1/source")
        let zipURL = FKFileManagerExampleSupport.scenarioDirectory("E1").appendingPathComponent("folder.zip")
        do {
          try await manager.createDirectory(at: folder, intermediate: true)
          try await manager.writeContent(.text("nested"), to: folder.appendingPathComponent("nested/hello.txt"))
          if manager.exists(at: zipURL) { try await manager.removeItem(at: zipURL) }
          try await manager.zipItem(
            at: folder,
            to: zipURL,
            options: FKZipOptions(includesRootDirectoryName: true, compressionMethod: .deflate)
          )
          let info = try await manager.fileInfo(at: zipURL)
          self.appendLog("Created \(zipURL.lastPathComponent) size=\(info.sizeInBytes) bytes")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
