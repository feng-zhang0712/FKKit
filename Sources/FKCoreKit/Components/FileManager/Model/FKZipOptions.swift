import Foundation

/// Compression strategy applied when creating ZIP archives.
public enum FKZipCompressionMethod: Sendable, Equatable {
  /// Store entries without compression.
  case none
  /// Compress entries using DEFLATE.
  case deflate
}

/// Options controlling ZIP archive creation.
public struct FKZipOptions: Sendable, Equatable {
  /// When `true`, directory archives include a root entry named after the source item.
  public var includesRootDirectoryName: Bool
  /// Compression method applied to archive entries.
  public var compressionMethod: FKZipCompressionMethod

  public init(
    includesRootDirectoryName: Bool = true,
    compressionMethod: FKZipCompressionMethod = .deflate
  ) {
    self.includesRootDirectoryName = includesRootDirectoryName
    self.compressionMethod = compressionMethod
  }
}

/// Options controlling ZIP extraction behavior.
public struct FKUnzipOptions: Sendable, Equatable {
  /// Policy applied when an extracted entry already exists on disk.
  public enum OverwritePolicy: Sendable, Equatable {
    /// Replace existing files and directories.
    case replaceExisting
    /// Fail when any target path already exists.
    case failIfExists
  }

  public var overwritePolicy: OverwritePolicy

  public init(overwritePolicy: OverwritePolicy = .replaceExisting) {
    self.overwritePolicy = overwritePolicy
  }
}
