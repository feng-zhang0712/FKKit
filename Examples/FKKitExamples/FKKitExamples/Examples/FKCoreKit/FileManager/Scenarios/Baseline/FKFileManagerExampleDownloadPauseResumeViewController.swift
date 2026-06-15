import FKCoreKit
import UIKit

/// B3 — Breakpoint download with pause, resume, and cancel.
final class FKFileManagerExampleDownloadPauseResumeViewController: FKFileManagerExampleBaseViewController {
  private var taskID: Int?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "DownloadPauseResume"
    addInfoLabel("Downloads a small public file, then pause/resume/cancel using task IDs.")
    addActionButton("Start background download") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let manager = FKFileManagerExampleSupport.manager
        guard let source = URL(string: "https://raw.githubusercontent.com/github/gitignore/main/Swift.gitignore") else { return }
        let request = FKDownloadRequest(
          sourceURL: source,
          destinationDirectory: manager.directoryURL(.caches),
          fileName: "B3-Swift.gitignore",
          allowsBackground: true
        )
        do {
          let id = try await manager.download(
            request,
            progress: { [weak self] progress in
              Task { @MainActor [weak self] in
                self?.appendLog("Progress \(Int(progress.progress * 100))% id=\(progress.taskID)")
              }
            },
            completion: { [weak self] result in
              Task { @MainActor [weak self] in
                switch result {
                case let .success(value):
                  self?.appendLog("Completed -> \(value.fileURL.lastPathComponent)")
                case let .failure(error):
                  self?.appendLog("Failed: \(error.localizedDescription)")
                }
              }
            }
          )
          self.taskID = id
          self.appendLog("Started download taskID=\(id)")
        } catch {
          self.appendLog("Start error: \(error.localizedDescription)")
        }
      }
    }
    addActionButton("pauseDownload(taskID:)") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self, let id = self.taskID else {
          self?.appendLog("No active task id.")
          return
        }
        await FKFileManagerExampleSupport.manager.pauseDownload(taskID: id)
        self.appendLog("Paused task \(id)")
      }
    }
    addActionButton("resumeDownload(taskID:)") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self, let id = self.taskID else {
          self?.appendLog("No active task id.")
          return
        }
        await FKFileManagerExampleSupport.manager.resumeDownload(taskID: id)
        self.appendLog("Resume requested for \(id) (URLSession may assign a new id)")
      }
    }
    addActionButton("cancel(taskID:)") { [weak self] in
      Task { @MainActor [weak self] in
        guard let self, let id = self.taskID else {
          self?.appendLog("No active task id.")
          return
        }
        await FKFileManagerExampleSupport.manager.cancel(taskID: id)
        self.taskID = nil
        self.appendLog("Cancelled task \(id)")
      }
    }
    addActionButton("Clear log") { [weak self] in self?.clearLog() }
  }
}
