import Foundation

public extension FileManager {
  /// Application home directory URL.
  static var fk_homeDirectory: URL {
    URL(fileURLWithPath: NSHomeDirectory())
  }

  /// Application documents directory URL.
  static var fk_documentsDirectory: URL {
    `default`.urls(for: .documentDirectory, in: .userDomainMask).first ?? fk_homeDirectory
  }

  /// Application caches directory URL.
  static var fk_cachesDirectory: URL {
    `default`.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fk_homeDirectory
  }

  /// System temporary directory URL.
  static var fk_temporaryDirectory: URL {
    URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
  }

  /// Returns file or recursive directory size in bytes.
  func fk_fileSize(at url: URL) -> Int64 {
    let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
    if values?.isDirectory == true {
      return fk_folderSize(at: url)
    }
    return Int64(values?.fileSize ?? 0)
  }

  private func fk_folderSize(at url: URL) -> Int64 {
    guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey]) else {
      return 0
    }
    var total: Int64 = 0
    for case let fileURL as URL in enumerator {
      let values = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey])
      if values?.isDirectory != true {
        total += Int64(values?.fileSize ?? 0)
      }
    }
    return total
  }
}
