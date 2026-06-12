import Foundation
public struct FKCellSliderRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellSliderConfiguration
  public init(id: String, configuration: FKCellSliderConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
