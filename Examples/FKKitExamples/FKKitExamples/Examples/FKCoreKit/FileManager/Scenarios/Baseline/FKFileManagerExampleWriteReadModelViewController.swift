import FKCoreKit
import UIKit

/// B2 — Codable writeModel / readModel round-trip.
final class FKFileManagerExampleWriteReadModelViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "WriteReadModel"
    addInfoLabel("Persists a Sendable Codable model as JSON under the demo folder.")
    addActionButton("writeModel → readModel") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        let url = FKFileManagerExampleSupport.scenarioDirectory("B2").appendingPathComponent("transfer.json")
        do {
          try await manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
          let model = FKPersistedTransfer(
            id: 42,
            kind: .download,
            state: .running,
            sourceURL: URL(string: "https://example.com/b2")!,
            destinationPath: url.deletingLastPathComponent().path,
            updatedAt: Date()
          )
          try await manager.writeModel(model, to: url)
          let loaded = try await manager.readModel(FKPersistedTransfer.self, from: url)
          self.appendLog("Written id=\(model.id); read id=\(loaded.id) kind=\(loaded.kind)")
        } catch {
          self.appendLog("Error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
