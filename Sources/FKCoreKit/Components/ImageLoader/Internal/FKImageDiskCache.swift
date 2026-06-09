import CryptoKit
import Foundation

/// Metadata stored alongside cached image bytes for conditional GET.
struct FKImageDiskCacheMetadata: Sendable, Equatable {
  var etag: String?
  var lastModified: String?
}

/// On-disk cache storing original image bytes keyed by logical cache keys.
final class FKImageDiskCache: @unchecked Sendable {
  struct IndexEntry: Codable, Sendable {
    var fileName: String
    var byteCount: Int
    var createdAt: TimeInterval
    var lastAccessAt: TimeInterval
    var etag: String?
    var lastModified: String?
  }

  private struct IndexFile: Codable {
    var entries: [String: IndexEntry]
  }

  private let rootDirectory: URL
  private let indexURL: URL
  private let fileManager: FileManager
  private let queue = DispatchQueue(label: "com.fkkit.imageloader.disk", qos: .utility)
  private var index = IndexFile(entries: [:])
  private var indexDirty = false
  private var persistWorkItem: DispatchWorkItem?
  private var persistDelay: TimeInterval = 2

  init(
    directoryURL: URL,
    persistDelay: TimeInterval = 2,
    fileManager: FileManager = .default
  ) throws {
    self.fileManager = fileManager
    self.persistDelay = max(0, persistDelay)
    rootDirectory = directoryURL
    indexURL = directoryURL.appendingPathComponent("index.json", isDirectory: false)
    try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
    if fileManager.fileExists(atPath: indexURL.path),
      let data = try? Data(contentsOf: indexURL),
      let decoded = try? JSONDecoder().decode(IndexFile.self, from: data)
    {
      index = decoded
    } else {
      try persistIndexImmediately()
    }
  }

  func setPersistDelay(_ delay: TimeInterval) {
    queue.sync {
      persistDelay = max(0, delay)
    }
  }

  func metadata(forKey key: String, ttl: TimeInterval?) -> FKImageDiskCacheMetadata? {
    queue.sync {
      guard let entry = validEntry(forKey: key, ttl: ttl) else { return nil }
      return FKImageDiskCacheMetadata(etag: entry.etag, lastModified: entry.lastModified)
    }
  }

  func data(
    forKey key: String,
    ttl: TimeInterval?,
    now: TimeInterval = Date().timeIntervalSince1970
  ) -> Data? {
    queue.sync {
      guard var entry = validEntry(forKey: key, ttl: ttl, now: now) else { return nil }
      guard let data = try? Data(contentsOf: fileURL(for: entry.fileName)) else {
        removeEntryLocked(key: key, entry: entry, persistImmediately: true)
        return nil
      }
      entry.lastAccessAt = now
      index.entries[key] = entry
      markIndexDirtyLocked()
      return data
    }
  }

  func store(
    _ data: Data,
    forKey key: String,
    metadata: FKImageDiskCacheMetadata = .init(),
    now: TimeInterval = Date().timeIntervalSince1970
  ) {
    queue.sync {
      if let existing = index.entries[key] {
        try? fileManager.removeItem(at: fileURL(for: existing.fileName))
      }
      let fileName = Self.fileName(for: key)
      let url = fileURL(for: fileName)
      do {
        try data.write(to: url, options: .atomic)
        index.entries[key] = IndexEntry(
          fileName: fileName,
          byteCount: data.count,
          createdAt: now,
          lastAccessAt: now,
          etag: metadata.etag,
          lastModified: metadata.lastModified
        )
        try persistIndexLocked()
      } catch {
        try? fileManager.removeItem(at: url)
      }
    }
  }

  func removeImage(forKey key: String) {
    queue.sync {
      guard let entry = index.entries[key] else { return }
      removeEntryLocked(key: key, entry: entry, persistImmediately: true)
    }
  }

  func removeAllImages() {
    queue.sync {
      cancelScheduledPersistLocked()
      for entry in index.entries.values {
        try? fileManager.removeItem(at: fileURL(for: entry.fileName))
      }
      index.entries.removeAll()
      indexDirty = false
      try? persistIndexLocked()
    }
  }

  @discardableResult
  func enforceLimits(sizeLimit: Int, ttl: TimeInterval?) -> Int {
    queue.sync {
      let now = Date().timeIntervalSince1970
      var removed = 0

      if let ttl {
        for key in Array(index.entries.keys) {
          guard let entry = index.entries[key] else { continue }
          if now - entry.createdAt >= ttl {
            removeEntryLocked(key: key, entry: entry, persistImmediately: false)
            removed += 1
          }
        }
      }

      var totalBytes = index.entries.values.reduce(0) { $0 + $1.byteCount }
      guard sizeLimit > 0, totalBytes > sizeLimit else {
        flushIndexIfDirtyLocked()
        return removed
      }

      let sortedKeys = index.entries.keys.sorted {
        let lhs = index.entries[$0]?.lastAccessAt ?? 0
        let rhs = index.entries[$1]?.lastAccessAt ?? 0
        return lhs < rhs
      }

      for key in sortedKeys where totalBytes > sizeLimit {
        guard let entry = index.entries[key] else { continue }
        totalBytes -= entry.byteCount
        removeEntryLocked(key: key, entry: entry, persistImmediately: false)
        removed += 1
      }
      flushIndexIfDirtyLocked()
      return removed
    }
  }

  func statistics() -> (entryCount: Int, byteCount: Int) {
    queue.sync {
      let bytes = index.entries.values.reduce(0) { $0 + $1.byteCount }
      return (index.entries.count, bytes)
    }
  }

  func flushPendingIndexWrites() {
    queue.sync {
      flushIndexIfDirtyLocked(force: true)
    }
  }

  // MARK: - Private

  private func validEntry(
    forKey key: String,
    ttl: TimeInterval?,
    now: TimeInterval = Date().timeIntervalSince1970
  ) -> IndexEntry? {
    guard let entry = index.entries[key] else { return nil }
    if let ttl, now - entry.createdAt >= ttl {
      removeEntryLocked(key: key, entry: entry, persistImmediately: true)
      return nil
    }
    return entry
  }

  private func fileURL(for fileName: String) -> URL {
    rootDirectory.appendingPathComponent(fileName, isDirectory: false)
  }

  private func removeEntryLocked(key: String, entry: IndexEntry, persistImmediately: Bool) {
    try? fileManager.removeItem(at: fileURL(for: entry.fileName))
    index.entries.removeValue(forKey: key)
    if persistImmediately {
      try? persistIndexLocked()
    } else {
      markIndexDirtyLocked()
    }
  }

  private func markIndexDirtyLocked() {
    indexDirty = true
    guard persistDelay > 0 else {
      try? persistIndexLocked()
      return
    }
    cancelScheduledPersistLocked()
    let work = DispatchWorkItem { [weak self] in
      // Already running on `queue` via asyncAfter — do not re-enter with queue.sync.
      self?.flushIndexIfDirtyLocked(force: true)
    }
    persistWorkItem = work
    queue.asyncAfter(deadline: .now() + persistDelay, execute: work)
  }

  private func cancelScheduledPersistLocked() {
    persistWorkItem?.cancel()
    persistWorkItem = nil
  }

  private func flushIndexIfDirtyLocked(force: Bool = false) {
    guard force || indexDirty else { return }
    try? persistIndexLocked()
  }

  private func persistIndexImmediately() throws {
    try queue.sync {
      try persistIndexLocked()
    }
  }

  private func persistIndexLocked() throws {
    let data = try JSONEncoder().encode(index)
    try data.write(to: indexURL, options: .atomic)
    indexDirty = false
    cancelScheduledPersistLocked()
  }

  private static func fileName(for key: String) -> String {
    let digest = SHA256.hash(data: Data(key.utf8))
    return digest.map { String(format: "%02x", $0) }.joined() + ".fkimg"
  }
}
