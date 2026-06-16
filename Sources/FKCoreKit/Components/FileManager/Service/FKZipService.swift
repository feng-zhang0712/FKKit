import Foundation

/// Internal contract for ZIP compression and extraction backends.
protocol FKZipOperating: Sendable {
  /// Whether the backend can perform ZIP operations on the current platform.
  static var isSupported: Bool { get }

  /// Compresses a file or directory into a ZIP archive.
  func zipItem(at sourceURL: URL, to destinationURL: URL, options: FKZipOptions) async throws

  /// Expands a ZIP archive into a destination directory.
  func unzipItem(at sourceURL: URL, to destinationURL: URL, options: FKUnzipOptions) async throws
}