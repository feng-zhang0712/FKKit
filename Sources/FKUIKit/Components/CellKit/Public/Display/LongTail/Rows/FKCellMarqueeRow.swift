import Foundation
public struct FKCellMarqueeRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellMarqueeConfiguration
  public init(id: String, configuration: FKCellMarqueeConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
