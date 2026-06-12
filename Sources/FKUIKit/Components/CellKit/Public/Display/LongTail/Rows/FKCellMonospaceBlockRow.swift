import Foundation
public struct FKCellMonospaceBlockRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellMonospaceBlockConfiguration
  public init(id: String, configuration: FKCellMonospaceBlockConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
