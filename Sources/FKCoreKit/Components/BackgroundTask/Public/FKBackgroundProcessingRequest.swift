import Foundation

/// Request to schedule a `BGProcessingTask`.
public struct FKBackgroundProcessingRequest: Sendable, Hashable {
  /// Registered task identifier.
  public var identifier: String

  /// Earliest date the task may begin; `nil` means as soon as the system allows.
  public var earliestBeginDate: Date?

  /// When `true`, the task runs only when network connectivity is available.
  public var requiresNetworkConnectivity: Bool

  /// When `true`, the task runs only when external power is connected.
  public var requiresExternalPower: Bool

  /// Creates a processing schedule request.
  public init(
    identifier: String,
    earliestBeginDate: Date? = nil,
    requiresNetworkConnectivity: Bool = false,
    requiresExternalPower: Bool = false
  ) {
    self.identifier = identifier
    self.earliestBeginDate = earliestBeginDate
    self.requiresNetworkConnectivity = requiresNetworkConnectivity
    self.requiresExternalPower = requiresExternalPower
  }
}
