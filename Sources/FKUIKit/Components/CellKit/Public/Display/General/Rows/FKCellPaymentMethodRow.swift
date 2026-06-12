import Foundation

/// ListKit-friendly row model for ``FKCellPaymentMethodCell`` (D-30).
public struct FKCellPaymentMethodRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellPaymentMethodConfiguration

  public init(id: String, configuration: FKCellPaymentMethodConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
