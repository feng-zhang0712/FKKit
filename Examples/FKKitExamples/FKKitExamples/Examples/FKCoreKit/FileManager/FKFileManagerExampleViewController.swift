import FKCoreKit
import QuickLook
import UIKit

/// Interactive catalog of **every** `FKFileManager` surface: sandbox URLs, CRUD, content I/O (async + closure),
/// directory utilities, disk checks, downloads (foreground/background, pause/resume/cancel), uploads, transfer
/// bookkeeping, and iOS helpers (`makeShareController`, `makePreviewController`).
final class FKFileManagerExampleViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private let outputView = UITextView()

  private let manager = FKFileManager.shared

  /// Tracks the latest download task identifier (note: `resumeDownload` may replace the system task id).
  private var activeDownloadTaskID: Int?

  /// Hold strongly while `QLPreviewController` is visible.
  private var quickLookDataSource: QLPreviewControllerDataSource?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKFileManager"
    view.backgroundColor = .systemBackground
    buildLayout()
    appendOutput("Loaded. Scroll for grouped demos; the log explains each API.")
  }

  // MARK: - Layout

  private func buildLayout() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 6

    outputView.translatesAutoresizingMaskIntoConstraints = false
    outputView.isEditable = false
    outputView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    outputView.backgroundColor = .secondarySystemBackground
    outputView.layer.cornerRadius = 8

    let sections: [(title: String, rows: [(String, Selector)])] = [
      (
        "1. Sandbox — directoryURL(_:)",
        [
          ("Print .home, .documents, .caches, .temporary", #selector(demoSandboxAllDirectories)),
        ]
      ),
      (
        "2. File operations — async (create / write / copy / move / rename / remove)",
        [
          ("Full pipeline on disk under Documents", #selector(demoFilePipelineAsync)),
          ("copyItem only (duplicate a demo file)", #selector(demoCopyItemOnly)),
          ("removeItem only (delete one demo file)", #selector(demoRemoveItemOnly)),
        ]
      ),
      (
        "3. File operations — closure conveniences",
        [
          ("createDirectory(at:intermediate:completion:)", #selector(demoCreateDirectoryClosure)),
          ("removeItem(at:completion:)", #selector(demoRemoveItemClosure)),
        ]
      ),
      (
        "4. Content I/O — async/await",
        [
          ("writeContent .text / .jsonObject, readText, readData", #selector(demoReadWriteStructuredAsync)),
          ("writeModel / readModel (Codable)", #selector(demoCodableAsync)),
        ]
      ),
      (
        "5. Content I/O — closure conveniences",
        [
          ("writeContent + readText (completion)", #selector(demoReadWriteClosure)),
          ("readData + readModel (completion)", #selector(demoReadDataAndModelClosure)),
        ]
      ),
      (
        "6. Binary & typing helpers",
        [
          ("writeContent .data (PNG) + isImageFile(_:)", #selector(demoWriteImageAndMime)),
        ]
      ),
      (
        "7. Directory utilities",
        [
          ("enumerateFiles (default options)", #selector(demoEnumerateDefault)),
          ("enumerateFiles (only .txt, non-recursive)", #selector(demoEnumerateFiltered)),
          ("directorySize under demo folder", #selector(demoDirectorySize)),
          ("clearCaches + log directorySize of Caches", #selector(demoClearCaches)),
          ("clearTemporaryFiles", #selector(demoClearTemporaryFiles)),
        ]
      ),
      (
        "8. ZIP (placeholders)",
        [
          ("zipItem / unzipItem (expect zipUnavailable on current build)", #selector(demoZipPlaceholders)),
        ]
      ),
      (
        "9. Metadata & disk",
        [
          ("exists + fileInfo", #selector(demoExistsAndFileInfo)),
          ("ensureSufficientDiskSpace()", #selector(demoEnsureDiskSpace)),
        ]
      ),
      (
        "10. Download — URLSession tasks",
        [
          ("download (background) + progress + completion → store taskID", #selector(demoStartBackgroundDownload)),
          ("download (foreground, allowsBackground: false)", #selector(demoStartForegroundDownload)),
          ("download async + nil progress + completion (overload disambiguation)", #selector(demoDownloadClosureOnly)),
          ("Extension download(_:completion:) → Result<Int,>", #selector(demoExtensionDownloadIntOnly)),
          ("pauseDownload(taskID:)", #selector(demoPauseDownload)),
          ("resumeDownload(taskID:) (refreshes tracked id)", #selector(demoResumeDownload)),
          ("cancel(taskID:) download", #selector(demoCancelDownload)),
        ]
      ),
      (
        "11. Upload — multipart",
        [
          ("upload async + progress + completion (single file)", #selector(demoSingleUpload)),
          ("upload async + nil progress + completion (multi-part)", #selector(demoMultiUploadClosure)),
          ("Extension upload(_:completion:) → Result<Int,>", #selector(demoExtensionUploadIntOnly)),
        ]
      ),
      (
        "12. Global transfer control",
        [
          ("cancelAll()", #selector(demoCancelAllTransfers)),
          ("persistedTransfers()", #selector(demoPersistedTransfers)),
        ]
      ),
      (
        "13. iOS helpers",
        [
          ("makeShareController (UIActivityViewController)", #selector(demoPresentShareSheet)),
          ("makePreviewController (QLPreviewController)", #selector(demoPresentQuickLook)),
        ]
      ),
      (
        "14. Output",
        [
          ("Clear log", #selector(clearOutput)),
        ]
      ),
    ]

    for section in sections {
      stackView.addArrangedSubview(makeSectionTitle(section.title))
      for row in section.rows {
        stackView.addArrangedSubview(makeButton(title: row.0, action: row.1))
      }
      stackView.setCustomSpacing(14, after: stackView.arrangedSubviews.last!)
    }

    view.addSubview(scrollView)
    scrollView.addSubview(stackView)
    view.addSubview(outputView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      scrollView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.52),

      stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

      outputView.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
      outputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      outputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      outputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func makeSectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = .preferredFont(forTextStyle: .subheadline)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.accessibilityTraits.insert(.header)
    return label
  }

  private func makeButton(title: String, action: Selector) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.textAlignment = .left
    button.contentHorizontalAlignment = .leading
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  // MARK: - 1) Sandbox

  @objc private func demoSandboxAllDirectories() {
    appendOutput("[directoryURL] Resolving standard locations:")
    appendOutput("  .home -> \(manager.directoryURL(.home).path)")
    appendOutput("  .documents -> \(manager.directoryURL(.documents).path)")
    appendOutput("  .caches -> \(manager.directoryURL(.caches).path)")
    appendOutput("  .temporary -> \(manager.directoryURL(.temporary).path)")
  }

  // MARK: - 2) File ops async

  @objc private func demoFilePipelineAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let demoDir = self.demoDirectoryURL()
        let source = demoDir.appendingPathComponent("pipeline-source.txt")
        let moved = demoDir.appendingPathComponent("pipeline-moved.txt")
        try await self.manager.createDirectory(at: demoDir, intermediate: true)
        try await self.manager.writeContent(.text("pipeline"), to: source)
        try await self.manager.moveItem(from: source, to: moved)
        let renamed = try await self.manager.renameItem(at: moved, newName: "pipeline-renamed.txt")
        try await self.manager.removeItem(at: renamed)
        appendOutput("[createDirectory, writeContent, moveItem, renameItem, removeItem] Pipeline OK -> \(renamed.deletingLastPathComponent().path)")
      } catch {
        appendOutput("Pipeline error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoCopyItemOnly() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let demoDir = self.demoDirectoryURL()
        try await self.manager.createDirectory(at: demoDir, intermediate: true)
        let original = demoDir.appendingPathComponent("copy-original.txt")
        let duplicate = demoDir.appendingPathComponent("copy-duplicate.txt")
        try await self.manager.writeContent(.text("copy source"), to: original)
        if self.manager.exists(at: duplicate) { try await self.manager.removeItem(at: duplicate) }
        try await self.manager.copyItem(from: original, to: duplicate)
        appendOutput("[copyItem] duplicate bytes: \(try await self.manager.readData(from: duplicate).count)")
      } catch {
        appendOutput("copyItem error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoRemoveItemOnly() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = self.demoDirectoryURL().appendingPathComponent("removal-target.txt")
        try await self.manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
        try await self.manager.writeContent(.text("delete me"), to: url)
        try await self.manager.removeItem(at: url)
        appendOutput("[removeItem] removed \(url.lastPathComponent); exists=\(self.manager.exists(at: url))")
      } catch {
        appendOutput("removeItem error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 3) Closure file ops

  @objc private func demoCreateDirectoryClosure() {
    let url = demoDirectoryURL().appendingPathComponent("ClosureSubfolder", isDirectory: true)
    manager.createDirectory(at: url, intermediate: true) { [weak self] result in
      switch result {
      case .success:
        self?.appendOutput("[createDirectory completion] Created \(url.lastPathComponent)")
      case let .failure(err):
        self?.appendOutput("[createDirectory completion] \(err.localizedDescription)")
      }
    }
  }

  @objc private func demoRemoveItemClosure() {
    let url = demoDirectoryURL().appendingPathComponent("closure-removal.txt")
    Task { @MainActor [weak self] in
      guard let self else { return }
      try? await self.manager.writeContent(.text("temp"), to: url)
      self.manager.removeItem(at: url) { [weak self] result in
        switch result {
        case .success:
          self?.appendOutput("[removeItem completion] Removed closure-removal.txt")
        case let .failure(err):
          self?.appendOutput("[removeItem completion] \(err.localizedDescription)")
        }
      }
    }
  }

  // MARK: - 4) Async content

  @objc private func demoReadWriteStructuredAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let folder = self.demoDirectoryURL()
        try await self.manager.createDirectory(at: folder, intermediate: true)
        let textURL = folder.appendingPathComponent("note.txt")
        try await self.manager.writeContent(.text("Hello FKFileManager"), to: textURL)
        let text = try await self.manager.readText(from: textURL)
        appendOutput("[readText] \(text)")
        let jsonURL = folder.appendingPathComponent("sample.json")
        try await self.manager.writeContent(
          .jsonObject([
            "module": AnySendable("FKFileManager"),
            "version": AnySendable(1),
            "stable": AnySendable(true),
          ]),
          to: jsonURL
        )
        let bytes = try await self.manager.readData(from: jsonURL)
        appendOutput("[readData] JSON byte count: \(bytes.count)")
      } catch {
        appendOutput("Structured read/write error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoCodableAsync() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = self.demoDirectoryURL().appendingPathComponent("profile.json")
        try await self.manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
        let original = FKPersistedTransfer(
          id: 9_001,
          kind: .upload,
          state: .running,
          sourceURL: URL(string: "https://example.com/demo.bin")!,
          destinationPath: self.demoDirectoryURL().path,
          updatedAt: Date()
        )
        try await self.manager.writeModel(original, to: url)
        let loaded = try await self.manager.readModel(FKPersistedTransfer.self, from: url)
        appendOutput("[writeModel/readModel] id=\(loaded.id) kind=\(loaded.kind) state=\(loaded.state)")
      } catch {
        appendOutput("Codable error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 5) Closure content

  @objc private func demoReadWriteClosure() {
    let url = demoDirectoryURL().appendingPathComponent("closure-note.txt")
    manager.writeContent(.text("Written via completion handler"), to: url) { [weak self] writeResult in
      switch writeResult {
      case .success:
        self?.appendOutput("[writeContent completion] success")
        self?.manager.readText(from: url) { readResult in
          switch readResult {
          case let .success(text):
            self?.appendOutput("[readText completion] \(text)")
          case let .failure(err):
            self?.appendOutput("[readText completion] \(err.localizedDescription)")
          }
        }
      case let .failure(err):
        self?.appendOutput("[writeContent completion] \(err.localizedDescription)")
      }
    }
  }

  @objc private func demoReadDataAndModelClosure() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let url = self.demoDirectoryURL().appendingPathComponent("closure-model.json")
      let sample = FKPersistedTransfer(
        id: 9_002,
        kind: .download,
        state: .paused,
        sourceURL: URL(string: "https://example.com/closure.json")!,
        destinationPath: nil,
        updatedAt: Date()
      )
      try? await self.manager.writeModel(sample, to: url)
      self.manager.readData(from: url) { [weak self] dataResult in
        switch dataResult {
        case let .success(data):
          self?.appendOutput("[readData completion] \(data.count) bytes")
        case let .failure(err):
          self?.appendOutput("[readData completion] \(err.localizedDescription)")
        }
      }
      self.manager.readModel(FKPersistedTransfer.self, from: url) { [weak self] modelResult in
        switch modelResult {
        case let .success(model):
          self?.appendOutput("[readModel completion] id=\(model.id) state=\(model.state)")
        case let .failure(err):
          self?.appendOutput("[readModel completion] \(err.localizedDescription)")
        }
      }
    }
  }

  // MARK: - 6) Image

  @objc private func demoWriteImageAndMime() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let image = Self.makeDemoImage()
        guard let png = image.pngData() else {
          appendOutput("PNG encoding failed.")
          return
        }
        let url = self.demoDirectoryURL().appendingPathComponent("demo.png")
        try await self.manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
        try await self.manager.writeContent(.data(png), to: url)
        let imageFlag = self.manager.isImageFile(url)
        appendOutput("[writeContent .data] bytes=\(png.count); [isImageFile]=\(imageFlag)")
      } catch {
        appendOutput("Image demo error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 7) Directories

  @objc private func demoEnumerateDefault() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let folder = self.demoDirectoryURL()
        try await self.manager.createDirectory(at: folder, intermediate: true)
        let items = try await self.manager.enumerateFiles(at: folder, options: .init())
        appendOutput("[enumerateFiles default] count=\(items.count) (files only, skips directories)")
      } catch {
        appendOutput("enumerateFiles error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoEnumerateFiltered() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let folder = self.demoDirectoryURL()
        try await self.manager.createDirectory(at: folder, intermediate: true)
        try await self.manager.writeContent(.text("a"), to: folder.appendingPathComponent("a.txt"))
        try await self.manager.writeContent(.text("b"), to: folder.appendingPathComponent("b.json"))
        let opts = FKFileTraversalOptions(recursive: false, includeHiddenFiles: false, allowedExtensions: ["txt"])
        let items = try await self.manager.enumerateFiles(at: folder, options: opts)
        appendOutput("[enumerateFiles filtered] .txt only, non-recursive: \(items.map(\.lastPathComponent))")
      } catch {
        appendOutput("Filtered enumerate error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoDirectorySize() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let folder = self.demoDirectoryURL()
        try await self.manager.createDirectory(at: folder, intermediate: true)
        let bytes = try await self.manager.directorySize(at: folder)
        appendOutput("[directorySize] \(folder.lastPathComponent) -> \(bytes) bytes")
      } catch {
        appendOutput("directorySize error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoClearCaches() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let caches = self.manager.directoryURL(.caches)
        let before = try await self.manager.directorySize(at: caches)
        try await self.manager.clearCaches()
        let after = try await self.manager.directorySize(at: caches)
        appendOutput("[clearCaches] directorySize caches before/after: \(before) -> \(after)")
      } catch {
        appendOutput("clearCaches error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoClearTemporaryFiles() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        try await self.manager.clearTemporaryFiles()
        appendOutput("[clearTemporaryFiles] Finished (tmp sweep).")
      } catch {
        appendOutput("clearTemporaryFiles error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 8) ZIP

  @objc private func demoZipPlaceholders() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let folder = self.demoDirectoryURL()
      let zip = self.manager.directoryURL(.documents).appendingPathComponent("FKFileManagerDemoArchive.zip")
      do {
        try await self.manager.zipItem(at: folder, to: zip)
        appendOutput("[zipItem] Unexpected success at \(zip.path)")
      } catch {
        appendOutput("[zipItem] \(error.localizedDescription)")
      }
      do {
        try await self.manager.unzipItem(at: zip, to: folder.appendingPathComponent("unzipped", isDirectory: true))
        appendOutput("[unzipItem] Unexpected success")
      } catch {
        appendOutput("[unzipItem] \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 9) Metadata & disk

  @objc private func demoExistsAndFileInfo() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = self.demoDirectoryURL().appendingPathComponent("meta-check.txt")
        try await self.manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
        try await self.manager.writeContent(.text("meta"), to: url)
        let exists = self.manager.exists(at: url)
        appendOutput("[exists] \(url.lastPathComponent) -> \(exists)")
        let info = try await self.manager.fileInfo(at: url)
        appendOutput("[fileInfo] size=\(info.sizeInBytes) mime=\(info.mimeType) modified=\(String(describing: info.modifiedAt))")
      } catch {
        appendOutput("exists/fileInfo error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoEnsureDiskSpace() {
    do {
      try manager.ensureSufficientDiskSpace()
      appendOutput("[ensureSufficientDiskSpace] Passed using default threshold from FKFileManagerConfiguration.")
    } catch {
      appendOutput("[ensureSufficientDiskSpace] \(error.localizedDescription)")
    }
  }

  // MARK: - 10) Downloads

  private func sampleDownloadRequest(fileName: String, allowsBackground: Bool) -> FKDownloadRequest? {
    guard let sourceURL = URL(string: "https://raw.githubusercontent.com/github/gitignore/main/Swift.gitignore") else {
      return nil
    }
    return FKDownloadRequest(
      sourceURL: sourceURL,
      destinationDirectory: manager.directoryURL(.caches),
      fileName: fileName,
      allowsBackground: allowsBackground
    )
  }

  @objc private func demoStartBackgroundDownload() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      guard let request = self.sampleDownloadRequest(fileName: "Swift.gitignore.bg", allowsBackground: true) else {
        appendOutput("Invalid download URL.")
        return
      }
      do {
        let taskID = try await self.manager.download(
          request,
          progress: { [weak self] p in
            self?.appendOutput("[download progress] \(Int(p.progress * 100))% \(p.completedBytes)/\(p.totalBytes) id=\(p.taskID)")
          },
          completion: { [weak self] result in
            switch result {
            case let .success(out):
              self?.appendOutput("[download completion] saved \(out.fileURL.path)")
            case let .failure(err):
              self?.appendOutput("[download completion] \(err.localizedDescription)")
            }
          }
        )
        self.activeDownloadTaskID = taskID
        appendOutput("[download async] started background taskID=\(taskID)")
      } catch {
        appendOutput("[download async] \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoStartForegroundDownload() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      guard let request = self.sampleDownloadRequest(fileName: "Swift.gitignore.fg", allowsBackground: false) else {
        appendOutput("Invalid download URL.")
        return
      }
      do {
        let taskID = try await self.manager.download(request, progress: nil, completion: nil)
        self.activeDownloadTaskID = taskID
        appendOutput("[download async] foreground session taskID=\(taskID) (allowsBackground=false)")
      } catch {
        appendOutput("[download async] foreground error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoDownloadClosureOnly() {
    guard let request = sampleDownloadRequest(fileName: "Swift.gitignore.closure", allowsBackground: true) else {
      appendOutput("Invalid download URL.")
      return
    }
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let taskID = try await self.manager.download(
          request,
          progress: nil,
          completion: { [weak self] result in
            switch result {
            case let .success(out):
              self?.appendOutput("[download completion] finished file=\(out.fileURL.lastPathComponent)")
            case let .failure(err):
              self?.appendOutput("[download completion] \(err.localizedDescription)")
            }
          }
        )
        self.activeDownloadTaskID = taskID
        self.appendOutput("[download async] taskID=\(taskID) (progress nil; completion for terminal state)")
      } catch {
        self.appendOutput("[download async] \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoExtensionDownloadIntOnly() {
    guard let request = sampleDownloadRequest(fileName: "Swift.gitignore.ext-int", allowsBackground: true) else {
      appendOutput("Invalid download URL.")
      return
    }
    typealias DownloadStarter = (FKDownloadRequest, @escaping @Sendable (Result<Int, FKFileManagerError>) -> Void) -> Void
    let starter: DownloadStarter = { [weak self] req, completion in
      guard let self else { return }
      self.manager.download(req, completion: completion)
    }
    starter(request) { [weak self] result in
      switch result {
      case let .success(taskID):
        self?.activeDownloadTaskID = taskID
        self?.appendOutput("[FKFileManager+Convenience download] taskID=\(taskID)")
      case let .failure(err):
        self?.appendOutput("[FKFileManager+Convenience download] \(err.localizedDescription)")
      }
    }
  }

  @objc private func demoPauseDownload() {
    Task { @MainActor [weak self] in
      guard let self, let id = self.activeDownloadTaskID else {
        self?.appendOutput("[pauseDownload] No tracked task id. Start a download first.")
        return
      }
      await self.manager.pauseDownload(taskID: id)
      appendOutput("[pauseDownload] taskID=\(id)")
    }
  }

  @objc private func demoResumeDownload() {
    Task { @MainActor [weak self] in
      guard let self, let id = self.activeDownloadTaskID else {
        self?.appendOutput("[resumeDownload] No tracked task id.")
        return
      }
      await self.manager.resumeDownload(taskID: id)
      let running = await self.manager.persistedTransfers()
        .filter { $0.kind == .download && $0.state == .running }
        .max(by: { $0.updatedAt < $1.updatedAt })
      if let newID = running?.id {
        self.activeDownloadTaskID = newID
        appendOutput("[resumeDownload] issued for \(id); URLSession may reissue id -> now tracking \(newID)")
      } else {
        appendOutput("[resumeDownload] issued for \(id); no running snapshot (task may have finished).")
      }
    }
  }

  @objc private func demoCancelDownload() {
    Task { @MainActor [weak self] in
      guard let self, let id = self.activeDownloadTaskID else {
        self?.appendOutput("[cancel] No tracked download id.")
        return
      }
      await self.manager.cancel(taskID: id)
      self.activeDownloadTaskID = nil
      appendOutput("[cancel(taskID:)] cancelled download id=\(id)")
    }
  }

  // MARK: - 11) Uploads

  @objc private func demoSingleUpload() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let fileURL = try await self.createUploadFile(name: "single-upload.txt", content: "Single-part upload demo.")
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        let upload = FKUploadRequest(
          urlRequest: request,
          files: [FKUploadFile(fieldName: "file", fileURL: fileURL)],
          formFields: ["scene": "single-async"]
        )
        _ = try await self.manager.upload(
          upload,
          progress: { [weak self] p in
            self?.appendOutput("[upload progress] \(Int(p.progress * 100))% id=\(p.taskID)")
          },
          completion: { [weak self] result in
            switch result {
            case let .success(value):
              self?.appendOutput("[upload completion] bytes=\(value.responseData.count)")
            case let .failure(err):
              self?.appendOutput("[upload completion] \(err.localizedDescription)")
            }
          }
        )
      } catch {
        appendOutput("Single upload error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoExtensionUploadIntOnly() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let fileURL = try await self.createUploadFile(name: "ext-upload.txt", content: "Extension-only upload starter.")
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        let upload = FKUploadRequest(urlRequest: request, files: [FKUploadFile(fieldName: "file", fileURL: fileURL)], formFields: [:])
        typealias UploadStarter = (FKUploadRequest, @escaping @Sendable (Result<Int, FKFileManagerError>) -> Void) -> Void
        let starter: UploadStarter = { [weak self] req, completion in
          guard let self else { return }
          self.manager.upload(req, completion: completion)
        }
        starter(upload) { [weak self] result in
          switch result {
          case let .success(taskID):
            self?.appendOutput("[FKFileManager+Convenience upload] taskID=\(taskID)")
          case let .failure(err):
            self?.appendOutput("[FKFileManager+Convenience upload] \(err.localizedDescription)")
          }
        }
      } catch {
        appendOutput("Extension upload setup error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoMultiUploadClosure() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let first = try await self.createUploadFile(name: "multi-1.txt", content: "First file.")
        let second = try await self.createUploadFile(name: "multi-2.txt", content: "Second file.")
        var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
        request.httpMethod = "POST"
        let upload = FKUploadRequest(
          urlRequest: request,
          files: [
            FKUploadFile(fieldName: "files", fileURL: first),
            FKUploadFile(fieldName: "files", fileURL: second),
          ],
          formFields: ["scene": "multi-closure"]
        )
        let taskID = try await self.manager.upload(
          upload,
          progress: nil,
          completion: { [weak self] result in
            switch result {
            case let .success(out):
              self?.appendOutput("[upload completion] response bytes=\(out.responseData.count)")
            case let .failure(err):
              self?.appendOutput("[upload completion] \(err.localizedDescription)")
            }
          }
        )
        self.appendOutput("[upload async] started taskID=\(taskID) (multi-part, progress nil)")
      } catch {
        appendOutput("Multi upload setup error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 12) Global control

  @objc private func demoCancelAllTransfers() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      await self.manager.cancelAll()
      self.activeDownloadTaskID = nil
      self.appendOutput("[cancelAll] Invoked for downloads + uploads.")
    }
  }

  @objc private func demoPersistedTransfers() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let rows = await self.manager.persistedTransfers().prefix(8)
      if rows.isEmpty {
        appendOutput("[persistedTransfers] empty (start a transfer first).")
      } else {
        appendOutput("[persistedTransfers] latest snapshots:")
        for row in rows {
          appendOutput("  id=\(row.id) kind=\(row.kind) state=\(row.state) updated=\(row.updatedAt)")
        }
      }
    }
  }

  // MARK: - 13) iOS helpers

  @objc private func demoPresentShareSheet() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = self.demoDirectoryURL().appendingPathComponent("share-demo.txt")
        try await self.manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
        try await self.manager.writeContent(.text("Share sheet demo"), to: url)
        let controller = self.manager.makeShareController(for: url)
        if let pop = controller.popoverPresentationController {
          pop.sourceView = self.view
          pop.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 1, height: 1)
        }
        self.present(controller, animated: true)
        self.appendOutput("[makeShareController] Presenting UIActivityViewController.")
      } catch {
        appendOutput("Share demo error: \(error.localizedDescription)")
      }
    }
  }

  @objc private func demoPresentQuickLook() {
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let url = self.demoDirectoryURL().appendingPathComponent("ql-demo.txt")
        try await self.manager.createDirectory(at: url.deletingLastPathComponent(), intermediate: true)
        try await self.manager.writeContent(.text("Quick Look text preview"), to: url)
        let pair = self.manager.makePreviewController(for: url)
        self.quickLookDataSource = pair.dataSource
        self.present(pair.controller, animated: true)
        self.appendOutput("[makePreviewController] Presenting QLPreviewController (data source retained).")
      } catch {
        appendOutput("Quick Look error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: - 14) Output

  @objc private func clearOutput() {
    outputView.text = ""
    appendOutput("Log cleared.")
  }

  // MARK: - Helpers

  private func demoDirectoryURL() -> URL {
    manager.directoryURL(.documents).appendingPathComponent("FKFileManagerDemo", isDirectory: true)
  }

  private func createUploadFile(name: String, content: String) async throws -> URL {
    let url = manager.directoryURL(.temporary).appendingPathComponent(name)
    try await manager.writeContent(.text(content), to: url)
    return url
  }

  private nonisolated func appendOutput(_ message: String) {
    Task { @MainActor [weak self] in
      guard let self else { return }
      let stamp = DateFormatter.fileManagerDemoFormatter.string(from: Date())
      self.outputView.text.append("[\(stamp)] \(message)\n")
      let range = NSRange(location: max(self.outputView.text.count - 1, 0), length: 1)
      self.outputView.scrollRangeToVisible(range)
    }
  }

  private static func makeDemoImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
    return renderer.image { context in
      UIColor.systemBlue.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 120, height: 120))
      UIColor.white.setFill()
      context.fill(CGRect(x: 16, y: 16, width: 88, height: 88))
    }
  }
}

private extension DateFormatter {
  static let fileManagerDemoFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f
  }()
}
