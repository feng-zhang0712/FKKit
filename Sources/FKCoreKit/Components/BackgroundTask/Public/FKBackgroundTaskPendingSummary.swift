import Foundation

/// Readable summary of a pending `BGTaskScheduler` request (debug / opt-in).
public struct FKBackgroundTaskPendingSummary: Sendable, Hashable {
  /// Task identifier.
  public let identifier: String

  /// Registration kind inferred from the pending request type.
  public let kind: FKBackgroundTaskRegistration.Kind

  /// Earliest begin date from the pending request, if any.
  public let earliestBeginDate: Date?

  /// Whether the pending request requires network connectivity (processing only).
  public let requiresNetworkConnectivity: Bool

  /// Whether the pending request requires external power (processing only).
  public let requiresExternalPower: Bool

  /// Creates a pending task summary.
  public init(
    identifier: String,
    kind: FKBackgroundTaskRegistration.Kind,
    earliestBeginDate: Date?,
    requiresNetworkConnectivity: Bool = false,
    requiresExternalPower: Bool = false
  ) {
    self.identifier = identifier
    self.kind = kind
    self.earliestBeginDate = earliestBeginDate
    self.requiresNetworkConnectivity = requiresNetworkConnectivity
    self.requiresExternalPower = requiresExternalPower
  }
}
