import FKCoreKit
import UIKit

/// E6 — Malicious ZIP entry paths are rejected (zip slip).
final class FKFileManagerExampleZipSlipBlockedViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "E6 ZipSlipBlocked"
    addInfoLabel("Extracts a crafted archive whose entry path contains ../")
    addActionButton("Unzip malicious fixture") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let root = FKFileManagerExampleSupport.scenarioDirectory("E6")
        let zipURL = root.appendingPathComponent("malicious.zip")
        let target = root.appendingPathComponent("safe-target", isDirectory: true)
        do {
          try await manager.createDirectory(at: root, intermediate: true)
          if manager.exists(at: zipURL) { try await manager.removeItem(at: zipURL) }
          try FKFileManagerExampleSupport.writeZipSlipFixture(to: zipURL)
          if manager.exists(at: target) { try await manager.removeItem(at: target) }
          try await manager.unzipItem(at: zipURL, to: target)
          self.appendLog("Unexpected unzip success (zip slip not blocked).")
        } catch let error as FKFileManagerError {
          if case let .zipEntryPathUnsafe(entry) = error {
            self.appendLog("Blocked zip slip entry: \(entry)")
          } else {
            self.appendLog("Error: \(error.localizedDescription)")
          }
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
