import Foundation
import UIKit
public struct FKCellComparisonRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellComparisonConfiguration
  public init(id: String, configuration: FKCellComparisonConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
