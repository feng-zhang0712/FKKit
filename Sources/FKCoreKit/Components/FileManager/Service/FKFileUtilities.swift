import Foundation
import UniformTypeIdentifiers

/// Resolves MIME types from file extensions using `UTType` and a small fallback table.
public enum FKFileMimeResolver {
  private static let fallbackMap: [String: String] = [
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png",
    "gif": "image/gif",
    "webp": "image/webp",
    "heic": "image/heic",
    "pdf": "application/pdf",
    "json": "application/json",
    "txt": "text/plain",
    "html": "text/html",
    "zip": "application/zip",
    "mp4": "video/mp4",
    "mp3": "audio/mpeg",
  ]

  /// Returns MIME type for a normalized file extension (without leading dot).
  public static func mimeType(forFileExtension fileExtension: String) -> String {
    mimeType(for: fileExtension)
  }

  /// Returns MIME type inferred from a file URL extension.
  public static func mimeType(forFileURL fileURL: URL) -> String {
    mimeType(for: fileURL.pathExtension)
  }

  static func mimeType(for fileExtension: String) -> String {
    let ext = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !ext.isEmpty else { return "application/octet-stream" }
    if let type = UTType(filenameExtension: ext), let preferred = type.preferredMIMEType {
      return preferred
    }
    return fallbackMap[ext] ?? "application/octet-stream"
  }
}

actor FKTransferPersistenceStore {
  private let key: String
  private let defaults: UserDefaults

  init(key: String, defaults: UserDefaults = .standard) {
    self.key = key
    self.defaults = defaults
  }

  func save(_ transfers: [FKPersistedTransfer]) {
    if let data = try? JSONEncoder().encode(transfers) {
      defaults.set(data, forKey: key)
    }
  }

  func load() -> [FKPersistedTransfer] {
    guard let data = defaults.data(forKey: key),
          let items = try? JSONDecoder().decode([FKPersistedTransfer].self, from: data) else {
      return []
    }
    return items
  }
}
