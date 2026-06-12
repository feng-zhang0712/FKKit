import Foundation
/// Semantic form row preset (F-14).
public struct FKFormEmailRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKFormCellEmailSuffixConfiguration
  public init(id: String, configuration: FKFormCellEmailSuffixConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
