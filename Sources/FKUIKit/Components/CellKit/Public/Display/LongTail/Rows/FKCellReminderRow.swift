import Foundation
public struct FKCellReminderRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellReminderConfiguration
  public init(id: String, configuration: FKCellReminderConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
