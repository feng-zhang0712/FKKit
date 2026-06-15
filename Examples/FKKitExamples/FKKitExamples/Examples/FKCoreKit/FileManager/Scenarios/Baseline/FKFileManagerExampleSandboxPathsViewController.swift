import FKCoreKit
import UIKit

/// B1 — Resolves and prints all four sandbox directory URLs.
final class FKFileManagerExampleSandboxPathsViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SandboxPaths"
    addInfoLabel("Calls directoryURL(_:) for each FKSandboxDirectory case.")
    addActionButton("Print home, documents, caches, temporary") { [weak self] in
      guard let self else { return }
      let manager = FKFileManagerExampleSupport.manager
      self.appendLog(".home       -> \(manager.directoryURL(.home).path)")
      self.appendLog(".documents -> \(manager.directoryURL(.documents).path)")
      self.appendLog(".caches     -> \(manager.directoryURL(.caches).path)")
      self.appendLog(".temporary -> \(manager.directoryURL(.temporary).path)")
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
