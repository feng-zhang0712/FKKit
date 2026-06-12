import Foundation

/// ListKit-friendly row model for ``FKCellCouponCell``.
public struct FKCellCouponRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellCouponConfiguration

  /// Creates a coupon row model.
  public init(id: String, configuration: FKCellCouponConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
