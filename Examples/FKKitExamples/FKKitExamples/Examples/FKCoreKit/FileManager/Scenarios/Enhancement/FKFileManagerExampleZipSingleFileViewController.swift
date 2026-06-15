import FKCoreKit
import UIKit

/// E3 — Archive a single file without a root directory entry.
final class FKFileManagerExampleZipSingleFileViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ZipSingleFile"
    addActionLabel()
    addActionButton("Zip one file (includesRootDirectoryName: false)") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let root = FKFileManagerExampleSupport.scenarioDirectory("E3")
        let file = root.appendingPathComponent("single.txt")
        let zipURL = root.appendingPathComponent("single.zip")
        do {
          try await manager.createDirectory(at: root, intermediate: true)
          try await manager.writeContent(.text("single file archive"), to: file)
          if manager.exists(at: zipURL) { try await manager.removeItem(at: zipURL) }
          try await manager.zipItem(
            at: file,
            to: zipURL,
            options: FKZipOptions(includesRootDirectoryName: false, compressionMethod: .deflate)
          )
          let info = try await manager.fileInfo(at: zipURL)
          self.appendLog("Archive size=\(info.sizeInBytes) bytes at \(zipURL.lastPathComponent)")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }

  private func addActionLabel() {
    addInfoLabel("Uses FKZipOptions with includesRootDirectoryName = false for flat single-file archives.")
  }
}
