import Foundation
public struct FKCellSubscriptionPlanRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellSubscriptionPlanConfiguration
  public init(id: String, configuration: FKCellSubscriptionPlanConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
