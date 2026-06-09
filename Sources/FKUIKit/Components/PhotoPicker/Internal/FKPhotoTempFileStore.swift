import Foundation

/// Tracks and optionally deletes temporary export files.
final class FKPhotoTempFileStore: @unchecked Sendable {
  private let policy: FKPhotoPickerTempFilePolicy
  private let lock = NSLock()
  private var urls: [URL] = []
  private var scheduledCleanup: Task<Void, Never>?

  init(policy: FKPhotoPickerTempFilePolicy) {
    self.policy = policy
  }

  deinit {
    if case .deleteOnDeinit = policy {
      deleteAll()
    }
  }

  func register(_ url: URL) {
    lock.lock()
    defer { lock.unlock() }
    urls.append(url)
  }

  func scheduleCleanupIfNeeded() {
    guard case let .deleteAfterCompletion(seconds) = policy else { return }
    let delay = max(seconds, 0)
    scheduledCleanup?.cancel()
    scheduledCleanup = Task { [weak self] in
      let nanoseconds = UInt64(delay * 1_000_000_000)
      try? await Task.sleep(nanoseconds: nanoseconds)
      guard !Task.isCancelled else { return }
      self?.deleteAll()
    }
  }

  func deleteAll() {
    lock.lock()
    let targets = urls
    urls.removeAll()
    lock.unlock()

    let fileManager = FileManager.default
    for url in targets {
      try? fileManager.removeItem(at: url)
    }
  }

  static func makeUniqueURL(fileExtension: String) throws -> URL {
    let directory = try ensureDirectory()
    let name = UUID().uuidString + (fileExtension.hasPrefix(".") ? fileExtension : ".\(fileExtension)")
    return directory.appendingPathComponent(name, isDirectory: false)
  }

  static func ensureDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("FKPhotoPicker", isDirectory: true)
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) {
      if isDirectory.boolValue { return directory }
      throw FKPhotoPickerError.processingFailed(underlyingDescription: "Temporary directory path conflict.")
    }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}
