import FKCoreKit
import UIKit

/// E5 — Compression blocked when disk space guard fails.
final class FKFileManagerExampleInsufficientDiskSpaceViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "E5 InsufficientDiskSpace"
    addInfoLabel("Uses an extreme zipDiskSpaceSafetyFactor to trigger pre-zip disk checks.")
    addActionButton("Zip with inflated disk requirement") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        var config = FKFileManagerConfiguration()
        config.zipDiskSpaceSafetyFactor = 1_000_000_000
        let manager = FKFileManager(configuration: config)
        let folder = FKFileManagerExampleSupport.scenarioDirectory("E5")
        let zipURL = folder.appendingPathComponent("too-big.zip")
        do {
          try await manager.createDirectory(at: folder, intermediate: true)
          try await manager.writeContent(.text("tiny"), to: folder.appendingPathComponent("tiny.txt"))
          try await manager.zipItem(at: folder, to: zipURL)
          self.appendLog("Unexpected zip success.")
        } catch let error as FKFileManagerError {
          if case let .insufficientDiskSpace(required, available) = error {
            self.appendLog("insufficientDiskSpace required=\(required) available=\(available)")
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
