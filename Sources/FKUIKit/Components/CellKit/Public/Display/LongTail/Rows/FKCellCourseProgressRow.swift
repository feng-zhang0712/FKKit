import Foundation
public struct FKCellCourseProgressRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellCourseProgressConfiguration
  public init(id: String, configuration: FKCellCourseProgressConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
