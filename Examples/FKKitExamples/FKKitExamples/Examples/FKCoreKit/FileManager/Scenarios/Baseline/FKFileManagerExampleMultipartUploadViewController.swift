import FKCoreKit
import UIKit

/// B4 — Multipart upload with multiple files and text fields.
final class FKFileManagerExampleMultipartUploadViewController: FKFileManagerExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "B4 MultipartUpload"
    addInfoLabel("Posts two local files plus form fields to httpbin.org (requires network).")
    addActionButton("Upload two files + fields") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        do {
          let folder = FKFileManagerExampleSupport.scenarioDirectory("B4")
          try await manager.createDirectory(at: folder, intermediate: true)
          let first = folder.appendingPathComponent("part-a.txt")
          let second = folder.appendingPathComponent("part-b.txt")
          try await manager.writeContent(.text("Part A"), to: first)
          try await manager.writeContent(.text("Part B"), to: second)
          var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
          request.httpMethod = "POST"
          let upload = FKUploadRequest(
            urlRequest: request,
            files: [
              FKUploadFile(fieldName: "files", fileURL: first),
              FKUploadFile(fieldName: "files", fileURL: second),
            ],
            formFields: ["scene": "B4", "userId": "demo"]
          )
          _ = try await manager.upload(
            upload,
            progress: { [weak self] progress in
              Task { @MainActor [weak self] in
                self?.appendLog("Upload \(Int(progress.progress * 100))%")
              }
            },
            completion: { [weak self] result in
              Task { @MainActor [weak self] in
                switch result {
                case let .success(value):
                  self?.appendLog("Response bytes=\(value.responseData.count)")
                case let .failure(error):
                  self?.appendLog("Upload failed: \(error.localizedDescription)")
                }
              }
            }
          )
        } catch {
          self.appendLog("Setup error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
