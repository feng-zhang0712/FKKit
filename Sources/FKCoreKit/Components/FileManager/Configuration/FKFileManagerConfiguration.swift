import Foundation

/// Runtime configuration for FKFileManager.
public struct FKFileManagerConfiguration: Sendable, Equatable {
  /// Unique identifier used for URLSession background download container.
  public var backgroundSessionIdentifier: String
  /// Minimum required bytes before starting large operations.
  public var minimumRequiredDiskSpace: Int64
  /// UserDefaults key used for persisted transfer snapshots.
  public var persistenceKey: String
  /// Root folder under Caches used by FKFileManager for temporary artifacts.
  public var workingDirectoryName: String
  /// When `false`, ZIP APIs throw `zipUnavailable` even when the platform supports ZIP.
  public var isZipEnabled: Bool
  /// Multiplier applied to source size when estimating required disk space before zipping.
  public var zipDiskSpaceSafetyFactor: Double

  public init(
    backgroundSessionIdentifier: String = "com.fkkit.filemanager.background",
    minimumRequiredDiskSpace: Int64 = 50 * 1024 * 1024,
    persistenceKey: String = "com.fkkit.filemanager.transfers",
    workingDirectoryName: String = "FKFileManager",
    isZipEnabled: Bool = true,
    zipDiskSpaceSafetyFactor: Double = 1.1
  ) {
    self.backgroundSessionIdentifier = backgroundSessionIdentifier
    self.minimumRequiredDiskSpace = minimumRequiredDiskSpace
    self.persistenceKey = persistenceKey
    self.workingDirectoryName = workingDirectoryName
    self.isZipEnabled = isZipEnabled
    self.zipDiskSpaceSafetyFactor = zipDiskSpaceSafetyFactor
  }
}
