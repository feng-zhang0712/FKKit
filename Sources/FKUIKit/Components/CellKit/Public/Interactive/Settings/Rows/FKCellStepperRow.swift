import Foundation
public struct FKCellStepperRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellStepperConfiguration
  public init(id: String, configuration: FKCellStepperConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
