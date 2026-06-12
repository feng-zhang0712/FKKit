import Foundation
import UIKit
public struct FKCellTaskRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellTaskConfiguration
  public init(id: String, configuration: FKCellTaskConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
