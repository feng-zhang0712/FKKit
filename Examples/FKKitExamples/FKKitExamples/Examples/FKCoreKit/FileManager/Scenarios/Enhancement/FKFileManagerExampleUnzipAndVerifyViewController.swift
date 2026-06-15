import FKCoreKit
import UIKit

/// E2 — Unzip an archive and verify content hashes match.
final class FKFileManagerExampleUnzipAndVerifyViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UnzipAndVerify"
    addInfoLabel("Zips a file, unzips to a fresh directory, compares SHA-256 of extracted content.")
    addActionButton("Zip → unzip → verify hash") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let root = FKFileManagerExampleSupport.scenarioDirectory("E2")
        let sourceFile = root.appendingPathComponent("payload.txt")
        let zipURL = root.appendingPathComponent("payload.zip")
        let extractDir = root.appendingPathComponent("extracted", isDirectory: true)
        do {
          try await manager.createDirectory(at: root, intermediate: true)
          try await manager.writeContent(.text("hash verification payload"), to: sourceFile)
          let beforeHash = try await FKFileManagerExampleSupport.sha256Hex(ofFileAt: sourceFile)
          if manager.exists(at: zipURL) { try await manager.removeItem(at: zipURL) }
          try await manager.zipItem(at: sourceFile, to: zipURL, options: .init(includesRootDirectoryName: false))
          if manager.exists(at: extractDir) { try await manager.removeItem(at: extractDir) }
          try await manager.unzipItem(at: zipURL, to: extractDir, options: .init(overwritePolicy: .replaceExisting))
          let extracted = extractDir.appendingPathComponent("payload.txt")
          let afterHash = try await FKFileManagerExampleSupport.sha256Hex(ofFileAt: extracted)
          self.appendLog("SHA-256 before=\(beforeHash)")
          self.appendLog("SHA-256 after =\(afterHash)")
          self.appendLog(afterHash == beforeHash ? "Match ✅" : "Mismatch ❌")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
