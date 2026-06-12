import Foundation
public struct FKCellDeviceRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellDeviceConfiguration
  public init(id: String, configuration: FKCellDeviceConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
