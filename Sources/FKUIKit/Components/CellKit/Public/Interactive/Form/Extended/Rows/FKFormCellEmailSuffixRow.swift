import Foundation
public struct FKFormCellEmailSuffixRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellEmailSuffixConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellEmailSuffixConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
