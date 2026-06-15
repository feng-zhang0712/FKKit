import FKCoreKit
import UIKit

/// E4 — Demonstrates zipUnavailable when ZIP is disabled in configuration.
final class FKFileManagerExampleZipUnavailableViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ZipUnavailableFallback"
    addInfoLabel("Uses FKFileManager(configuration: .init(isZipEnabled: false)).")
    addActionButton("Attempt zipItem with isZipEnabled = false") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let disabled = FKFileManager(configuration: FKFileManagerConfiguration(isZipEnabled: false))
        self.appendLog("isZipEnabled instance flag = \(disabled.isZipEnabled)")
        let folder = FKFileManagerExampleSupport.scenarioDirectory("E4")
        let zipURL = folder.appendingPathComponent("blocked.zip")
        do {
          try await disabled.createDirectory(at: folder, intermediate: true)
          try await disabled.writeContent(.text("x"), to: folder.appendingPathComponent("x.txt"))
          try await disabled.zipItem(at: folder, to: zipURL)
          self.appendLog("Unexpected success.")
        } catch let error as FKFileManagerError {
          if case .zipUnavailable = error {
            self.appendLog("Caught zipUnavailable as expected.")
          } else {
            self.appendLog("Other error: \(error.localizedDescription)")
          }
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
