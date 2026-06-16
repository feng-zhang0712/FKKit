import Foundation

/// Request to schedule an `BGAppRefreshTask`.
public struct FKBackgroundAppRefreshRequest: Sendable, Hashable {
  /// Registered task identifier.
  public var identifier: String

  /// Earliest date the task may begin; `nil` means as soon as the system allows.
  public var earliestBeginDate: Date?

  /// Creates an app refresh schedule request.
  public init(identifier: String, earliestBeginDate: Date? = nil) {
    self.identifier = identifier
    self.earliestBeginDate = earliestBeginDate
  }
}
