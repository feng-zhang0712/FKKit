import Foundation
import UIKit
public struct FKCellQuoteRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellQuoteConfiguration
  public init(id: String, configuration: FKCellQuoteConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
