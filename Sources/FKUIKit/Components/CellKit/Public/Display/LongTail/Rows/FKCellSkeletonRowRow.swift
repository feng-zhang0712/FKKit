import Foundation
public struct FKCellSkeletonRowRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellSkeletonRowConfiguration
  public init(id: String, configuration: FKCellSkeletonRowConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
