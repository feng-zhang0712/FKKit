import Foundation

/// Snapshot of cache and in-flight loader state (intended for debug UI).
public struct FKImageLoaderStatistics: Sendable, Equatable {
  /// Number of images currently held in memory.
  public var memoryEntryCount: Int
  /// Estimated RGBA byte cost of memory entries.
  public var memoryCostBytes: Int
  /// Number of on-disk cache entries.
  public var diskEntryCount: Int
  /// Total bytes stored on disk.
  public var diskByteCount: Int
  /// Active coalesced fetch/decode operations.
  public var inFlightLoadCount: Int
  /// Active prefetch tasks.
  public var activePrefetchCount: Int

  /// Creates a statistics snapshot.
  public init(
    memoryEntryCount: Int,
    memoryCostBytes: Int,
    diskEntryCount: Int,
    diskByteCount: Int,
    inFlightLoadCount: Int,
    activePrefetchCount: Int
  ) {
    self.memoryEntryCount = memoryEntryCount
    self.memoryCostBytes = memoryCostBytes
    self.diskEntryCount = diskEntryCount
    self.diskByteCount = diskByteCount
    self.inFlightLoadCount = inFlightLoadCount
    self.activePrefetchCount = activePrefetchCount
  }
}
