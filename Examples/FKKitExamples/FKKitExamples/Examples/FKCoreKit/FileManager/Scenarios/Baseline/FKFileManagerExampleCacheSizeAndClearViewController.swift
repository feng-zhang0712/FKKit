import FKCoreKit
import UIKit

/// B5 — Directory size measurement and cache/temp cleanup.
final class FKFileManagerExampleCacheSizeAndClearViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "CacheSizeAndClear"
    addInfoLabel("clearCaches() removes the entire Caches sandbox — demo uses size before/after.")
    addActionButton("Measure Caches size") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        do {
          let caches = manager.directoryURL(.caches)
          let bytes = try await manager.directorySize(at: caches)
          self.appendLog("directorySize(caches) = \(bytes) bytes")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("clearCaches() then measure again") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        do {
          let caches = manager.directoryURL(.caches)
          let before = try await manager.directorySize(at: caches)
          try await manager.clearCaches()
          let after = try await manager.directorySize(at: caches)
          self.appendLog("clearCaches: \(before) -> \(after) bytes")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("clearTemporaryFiles()") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        do {
          try await FKFileManagerExampleSupport.manager.clearTemporaryFiles()
          self.appendLog("clearTemporaryFiles() finished.")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
