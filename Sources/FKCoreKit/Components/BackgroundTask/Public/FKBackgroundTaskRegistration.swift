import Foundation

/// Descriptor for a background task registration installed at app launch.
public struct FKBackgroundTaskRegistration: Sendable, Hashable {
  /// Background task kind matching `BGAppRefreshTask` or `BGProcessingTask`.
  public enum Kind: Sendable, Hashable {
    /// Lightweight refresh work (~30 seconds).
    case appRefresh

    /// Heavier processing work; network/power constraints are set at schedule time.
    case processing
  }

  /// Task identifier; must match an entry in `BGTaskSchedulerPermittedIdentifiers`.
  public let identifier: String

  /// Whether this registration is for app refresh or processing.
  public let kind: Kind

  /// Creates a registration descriptor.
  public init(identifier: String, kind: Kind) {
    self.identifier = identifier
    self.kind = kind
  }
}
