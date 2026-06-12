import Foundation
public struct FKCellCheckboxRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellCheckboxConfiguration
  public init(id: String, configuration: FKCellCheckboxConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
