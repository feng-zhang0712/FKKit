import Foundation
import UIKit
public struct FKCellTransactionRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellTransactionConfiguration
  public init(id: String, configuration: FKCellTransactionConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
