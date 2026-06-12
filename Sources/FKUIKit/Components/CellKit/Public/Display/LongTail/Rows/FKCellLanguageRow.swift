import Foundation
public struct FKCellLanguageRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellLanguageConfiguration
  public init(id: String, configuration: FKCellLanguageConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
