import FKCoreKit
import UIKit

/// B6 — ensureSufficientDiskSpace guard before large operations.
final class FKFileManagerExampleDiskSpaceGuardViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B6 DiskSpaceGuard"
    addInfoLabel("Default threshold comes from FKFileManagerConfiguration.minimumRequiredDiskSpace (50 MB).")
    addActionButton("ensureSufficientDiskSpace() default") { [weak self] in
      guard let self else { return }
      do {
        try FKFileManagerExampleSupport.manager.ensureSufficientDiskSpace()
        self.appendLog("Default threshold passed.")
      } catch {
        self.appendLog("Blocked: \(error.localizedDescription)")
      }
    }
    addActionButton("ensureSufficientDiskSpace(requiredBytes: 1 PiB)") { [weak self] in
      guard let self else { return }
      do {
        try FKFileManagerExampleSupport.manager.ensureSufficientDiskSpace(requiredBytes: 1_024 * 1_024 * 1_024 * 1_024)
        self.appendLog("Unexpected pass for 1 PiB requirement.")
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
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
