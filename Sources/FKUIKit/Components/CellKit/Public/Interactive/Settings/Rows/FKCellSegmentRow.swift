import Foundation
public struct FKCellSegmentRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellSegmentConfiguration
  public init(id: String, configuration: FKCellSegmentConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
